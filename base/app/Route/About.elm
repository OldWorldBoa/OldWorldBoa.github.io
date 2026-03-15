module Route.About exposing (ActionData, Data, Model, Msg(..), RouteParams, action, data, route)

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
    { title = "About"
    , body =
        [ Html.Styled.toUnstyled
            (div
                [ css
                    [ displayFlex
                    , justifyContent center
                    , mobile [ flexWrap wrap ]
                    ]
                ]
                [ div
                    [ css
                        [ marginRight (px 35)
                        , marginTop (px 18)
                        , mobile [ marginRight (px 0), marginTop (px 0) ]
                        ]
                    ]
                    [ img
                        [ src "../res/img/pages/about/profile.jpg"
                        , css
                            [ height (px 150), borderRadius (px 5), mobile [ height (px 250) ] ]
                        ]
                        []
                    ]
                , div []
                    [ p []
                        [ text "Hello! I'm OldWorldBoa and thanks for coming to check out my website. I've been a software developer since 2016, working on software like CRMs, finance glue, and self-service portals. Join me on twitch and check out my YouTube channel for my content!"
                        ]
                    , p []
                        [ text "I have several personal projects including this website: a bible comparer, a chess game, and an educational maze maker. Check out my portfolio for more!"
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
action routeParams request =
    BackendTask.succeed (Server.Response.render {})
