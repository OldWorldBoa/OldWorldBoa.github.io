module Route.Members exposing (ActionData, Data, Model, Msg(..), RouteParams, action, data, route)

import BackendTask exposing (BackendTask)
import BackendTask.Http
import Css exposing (borderRadius, center, displayFlex, flexWrap, height, justifyContent, marginRight, marginTop, px, wrap)
import Effect exposing (Effect)
import ErrorPage exposing (ErrorPage)
import FatalError exposing (FatalError)
import Head
import Html.Styled exposing (div, img, p, text)
import Html.Styled.Attributes exposing (css, src)
import Json.Decode as Decode
import OWBTheme exposing (mobile)
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
init _ _ =
    ( {}, Effect.none )


update :
    App Data ActionData RouteParams
    -> Shared.Model
    -> Msg
    -> Model
    -> ( Model, Effect Msg )
update _ _ msg model =
    case msg of
        NoOp ->
            ( model, Effect.none )


subscriptions :
    RouteParams
    -> UrlPath
    -> Shared.Model
    -> Model
    -> Sub Msg
subscriptions _ _ _ _ =
    Sub.none


type alias Data =
    {}


type alias ActionData =
    {}


data :
    RouteParams
    -> Request
    -> BackendTask FatalError (Server.Response.Response Data ErrorPage)
data _ _ =
    BackendTask.succeed
        (Server.Response.render
            {}
        )


head : App Data ActionData RouteParams -> List Head.Tag
head _ =
    []


view :
    App Data ActionData RouteParams
    -> Shared.Model
    -> Model
    -> View (PagesMsg Msg)
view _ _ _ =
    { title = "Members"
    , body =
        [ Html.Styled.toUnstyled
            (div
                [ css
                    [ displayFlex
                    , justifyContent center
                    , mobile [ flexWrap wrap ]
                    ]
                ]
                [ div []
                    [ p []
                        [ text "Hello member!"
                        ]
                    ]
                ]
            )
        ]
    }


action :
    RouteParams
    -> Request
    -> BackendTask.BackendTask FatalError.FatalError (Server.Response.Response ActionData ErrorPage.ErrorPage)
action _ _ =
    BackendTask.succeed (Server.Response.render {})
