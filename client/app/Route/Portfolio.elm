module Route.Portfolio exposing (ActionData, Data, Model, Msg(..), RouteParams, action, data, route)

import BackendTask exposing (BackendTask)
import BackendTask.Http
import Css exposing (auto, borderRadius, boxShadow4, center, displayFlex, flexWrap, fontFamilies, fontSize, height, justifyContent, margin, marginLeft, marginRight, marginTop, padding, px, rgb, textAlign, width, wrap)
import Effect exposing (Effect)
import ErrorPage exposing (ErrorPage)
import FatalError exposing (FatalError)
import Head
import Html.Styled exposing (Attribute, Html, div, hr, img, p, text)
import Html.Styled.Attributes exposing (css, href, src, target)
import Json.Decode as Decode
import OWBTheme exposing (linkBtn, mobile)
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
    { title = "Portfolio"
    , body =
        [ Html.Styled.toUnstyled
            (div
                []
                [ p []
                    [ text "Check out most of the projects I'm working on at "
                    , OWBTheme.link
                        [ href "https://github.com/OldWorldBoa"
                        , target "_blank"
                        ]
                        [ text "GitHub" ]
                    ]
                , OWBTheme.subtitle [] [ text "Projects" ]
                , div [ css [ padding (px 10) ] ]
                    [ hr [] []
                    , div [ portfolioEntryStyle ]
                        [ previewImg [ src "/res/img/pages/portfolio/contraction-timer.png" ] []
                        , previewContent []
                            [ previewTitle [] [ text "Contraction Timer" ]
                            , p []
                                [ text "This is a free contraction timer. See your contraction timing in a graph that tells you when you're approaching active labour."
                                ]
                            , linkBtn [ href "/portfolio/contraction-timer" ] [ text "Check it out!" ]
                            ]
                        ]
                    ]
                ]
            )
        ]
    }


portfolioEntryStyle : Attribute msg
portfolioEntryStyle =
    css [ displayFlex, mobile [ flexWrap wrap ] ]


previewImg : List (Attribute msg) -> List (Html msg) -> Html msg
previewImg attributes contents =
    div [ css [ margin auto ] ]
        [ img
            (List.append
                [ css
                    [ height (px 200)
                    , width (px 250)
                    , boxShadow4 (px 0) (px 0) (px 5) (rgb 0 0 0)
                    ]
                ]
                attributes
            )
            contents
        ]


previewTitle : List (Attribute msg) -> List (Html msg) -> Html msg
previewTitle attributes contents =
    div
        (List.append
            [ css
                [ fontFamilies [ "Megrim" ]
                , fontSize (px 22)
                ]
            ]
            attributes
        )
        contents


previewContent : List (Attribute msg) -> List (Html msg) -> Html msg
previewContent attributes contents =
    div
        (List.append
            [ css
                [ marginLeft (px 35)
                , marginRight (px 5)
                , textAlign center
                , mobile [ marginLeft (px 5) ]
                ]
            ]
            attributes
        )
        contents


action :
    RouteParams
    -> Request
    -> BackendTask.BackendTask FatalError.FatalError (Server.Response.Response ActionData ErrorPage.ErrorPage)
action routeParams request =
    BackendTask.succeed (Server.Response.render {})
