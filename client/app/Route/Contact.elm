module Route.Contact exposing (ActionData, Data, Model, Msg(..), RouteParams, action, data, route)

import BackendTask exposing (BackendTask)
import BackendTask.Http
import Css exposing (LengthOrAuto, borderRadius, center, color, displayFlex, flexWrap, height, justifyContent, margin, marginRight, marginTop, px, spaceAround, textAlign, visited, width, wrap)
import Effect exposing (Effect)
import ErrorPage exposing (ErrorPage)
import FatalError exposing (FatalError)
import Head
import Html.Styled exposing (Html, br, div, i, img, p, text)
import Html.Styled.Attributes exposing (class, css, href, src, target)
import Json.Decode as Decode
import OWBTheme exposing (link, mobile, theme)
import PagesMsg exposing (PagesMsg)
import RouteBuilder exposing (App)
import Server.Request exposing (Request)
import Server.Response
import Shared
import UrlPath exposing (UrlPath)
import View exposing (View)


type alias Model =
    {}


type Msg
    = NoOp


type alias RouteParams =
    {}


route =
    RouteBuilder.serverRender { data = data, action = action, head = head }
        |> RouteBuilder.buildWithLocalState
            { view = view
            , subscriptions = subscriptions
            , update = update
            , init = init
            }


init :
    App Data ActionData RouteParams
    -> Shared.Model
    -> ( Model, Effect Msg )
init app shared =
    ( {}, Effect.none )


update :
    App Data ActionData RouteParams
    -> Shared.Model
    -> Msg
    -> Model
    -> ( Model, Effect Msg )
update app shared msg model =
    case msg of
        NoOp ->
            ( model, Effect.none )


subscriptions :
    RouteParams
    -> UrlPath
    -> Shared.Model
    -> Model
    -> Sub Msg
subscriptions routeParams path shared model =
    Sub.none


type alias Data =
    {}


type alias ActionData =
    {}


data :
    RouteParams
    -> Request
    -> BackendTask FatalError (Server.Response.Response Data ErrorPage)
data routeParams request =
    BackendTask.succeed
        (Server.Response.render
            {}
        )


head : App Data ActionData RouteParams -> List Head.Tag
head app =
    []


view :
    App Data ActionData RouteParams
    -> Shared.Model
    -> Model
    -> View (PagesMsg Msg)
view app shared model =
    { title = "Contact"
    , body =
        [ Html.Styled.toUnstyled
            (div
                [ css
                    [ margin (px 10)
                    ]
                ]
                [ p
                    [ css
                        [ textAlign center
                        ]
                    ]
                    [ text "If you have any comments, questions, or concerns you can find me here"
                    ]
                , br [] []
                , div
                    [ css
                        [ displayFlex
                        , justifyContent spaceAround
                        ]
                    ]
                    [ iconLink (px 75) "https://github.com/oldworldboa" "fa-brands fa-github"
                    , iconLink (px 75) "https://www.twitch.tv/oldworldboa" "fa-brands fa-twitch"
                    , iconLink (px 75) "https://patreon.com/oldworldboa" "fa-brands fa-patreon"
                    ]
                ]
            )
        ]
    }


iconLink : LengthOrAuto compatible -> String -> String -> Html msg
iconLink size url icon =
    div
        [ css
            [ height size
            , width size
            ]
        ]
        [ link
            [ target "_blank"
            , href url
            , css
                [ color theme.text
                , visited
                    [ color theme.text
                    ]
                ]
            ]
            [ i [ class icon ] [] ]
        ]


action :
    RouteParams
    -> Request
    -> BackendTask.BackendTask FatalError.FatalError (Server.Response.Response ActionData ErrorPage.ErrorPage)
action routeParams request =
    BackendTask.succeed (Server.Response.render {})
