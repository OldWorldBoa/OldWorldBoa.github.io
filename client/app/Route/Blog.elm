module Route.Blog exposing (ActionData, Data, Model, Msg, route)

import BackendTask exposing (BackendTask)
import BackendTask.Http
import Css exposing (auto, center, margin, pct, textAlign, width)
import Effect exposing (Effect(..))
import ErrorPage exposing (ErrorPage)
import FatalError exposing (FatalError)
import Head
import Head.Seo as Seo
import Html.Styled exposing (br, div, h1, text)
import Html.Styled.Attributes exposing (css, href, target)
import Json.Decode as D exposing (Decoder, andThen, succeed)
import OWBTheme
import Pages.Url
import PagesMsg exposing (PagesMsg)
import Route
import Route.Portfolio.ContractionTimer exposing (Msg(..))
import RouteBuilder exposing (App)
import Server.Request exposing (Request)
import Server.Response as Response exposing (Response)
import Shared
import Task
import Time
import UrlPath
import View exposing (View)


type alias Model =
    { zone : Time.Zone
    }


type Msg
    = AdjustTimeZone Time.Zone


type alias RouteParams =
    {}


type alias Data =
    { message : String
    , posts : List Post
    }


type alias ActionData =
    {}


init :
    App Data ActionData RouteParams
    -> Shared.Model
    -> ( Model, Effect Msg )
init _ _ =
    ( Model Time.utc
    , Cmd
        (Task.perform AdjustTimeZone Time.here)
    )


route : RouteBuilder.StatefulRoute RouteParams Data ActionData Model Msg
route =
    RouteBuilder.serverRender
        { head = head
        , data = data
        , action = \_ _ -> BackendTask.succeed (Response.render {})
        }
        |> RouteBuilder.buildWithLocalState
            { view = view
            , subscriptions = \_ _ _ _ -> Sub.none
            , update = update
            , init = init
            }


data : RouteParams -> Request -> BackendTask FatalError (Response Data ErrorPage)
data _ _ =
    BackendTask.Http.getJson
        "http://localhost:8000/posts"
        postDecoder
        |> BackendTask.map
            (\posts -> Response.render (Data "" posts))
        |> BackendTask.allowFatal


type alias Post =
    { id : Int
    , path : String
    , publish_time : Time.Posix
    , title : String
    , author : String
    , tags : String
    , preview : String
    }


postDecoder : Decoder (List Post)
postDecoder =
    D.list
        (D.map7 Post
            (D.field "id" D.int)
            (D.field "path" D.string)
            (D.field "publish_time" (D.int |> andThen (\val -> succeed (Time.millisToPosix val))))
            (D.field "title" D.string)
            (D.field "author" D.string)
            (D.field "tags" D.string)
            (D.field "preview" D.string)
        )


update :
    App Data ActionData RouteParams
    -> Shared.Model
    -> Msg
    -> Model
    -> ( Model, Effect Msg )
update _ _ msg model =
    case msg of
        AdjustTimeZone zone ->
            ( { model | zone = zone }, Effect.none )


head :
    App Data ActionData RouteParams
    -> List Head.Tag
head _ =
    Seo.summary
        { canonicalUrlOverride = Nothing
        , siteName = "oldworldboa"
        , image =
            { url = [ "images", "icon-png.png" ] |> UrlPath.join |> Pages.Url.fromPath
            , alt = "elm-pages logo"
            , dimensions = Nothing
            , mimeType = Nothing
            }
        , description = "Welcome to The Byte Station!"
        , locale = Nothing
        , title = "Blog - Welcome to the Byte Station!"
        }
        |> Seo.website


view :
    App Data ActionData RouteParams
    -> Shared.Model
    -> Model
    -> View (PagesMsg Msg)
view app _ model =
    { title = "The Byte Station Blog"
    , body =
        [ Html.Styled.toUnstyled
            (div []
                (List.append
                    [ div [ css [ margin auto, width (pct 100), textAlign center ] ]
                        [ h1 [] [ text "Welcome!" ]
                        , text "Please, "
                        , OWBTheme.link
                            [ href "https://mygeekwisdom.com/2011/09/12/be-excellent-to-each-other/"
                            , target "_blank"
                            ]
                            [ text "be excellent to each other." ]
                        , br [] []
                        , br [] []
                        ]
                    ]
                    (getPostsHtml model app.data.posts)
                )
            )
        ]
    }


getPostsHtml : Model -> List Post -> List (Html.Styled.Html msg)
getPostsHtml model posts =
    List.map
        (OWBTheme.getPostHtml model.zone)
        posts
