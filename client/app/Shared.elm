module Shared exposing (Data, Model, Msg(..), SharedMsg(..), template)

import BackendTask exposing (BackendTask)
import Css exposing (absolute, active, auto, backgroundColor, backgroundImage, backgroundPosition, backgroundRepeat, backgroundSize, block, border3, borderBottom3, borderBox, borderLeft3, borderRadius, borderRadius4, boxShadow4, boxSizing, center, column, cursor, display, displayFlex, flexDirection, height, justifyContent, margin, marginBottom, marginRight, maxWidth, noRepeat, none, overflow, padding, paddingBottom, paddingLeft, paddingRight, paddingTop, pct, pointer, position, px, rgb, right, scroll, solid, textDecoration, url, width)
import Effect exposing (Effect)
import FatalError exposing (FatalError)
import Html exposing (Html)
import Html.Events
import Html.Styled exposing (Attribute, div, node, text)
import Html.Styled.Attributes exposing (css, href, rel)
import Html.Styled.Events exposing (onClick)
import LanguageTag.Language exposing (sc)
import OWBTheme exposing (desktop, faLink, initGlobalStyles, menuBtn, menuIconBtn, mobile, spacer, theme)
import Pages.Flags
import Pages.PageUrl exposing (PageUrl)
import Route exposing (Route)
import SharedTemplate exposing (SharedTemplate)
import UrlPath exposing (UrlPath)
import View exposing (View)


template : SharedTemplate Msg Model Data msg
template =
    { init = init
    , update = update
    , view = view
    , data = data
    , subscriptions = subscriptions
    , onPageChange = Nothing
    }


type Msg
    = SharedMsg SharedMsg
    | MenuClicked


type alias Data =
    ()


type SharedMsg
    = NoOp


type alias Model =
    { showMenu : Bool
    }


init :
    Pages.Flags.Flags
    ->
        Maybe
            { path :
                { path : UrlPath
                , query : Maybe String
                , fragment : Maybe String
                }
            , metadata : route
            , pageUrl : Maybe PageUrl
            }
    -> ( Model, Effect Msg )
init flags maybePagePath =
    ( { showMenu = False }
    , Effect.none
    )


update : Msg -> Model -> ( Model, Effect Msg )
update msg model =
    case msg of
        SharedMsg globalMsg ->
            ( model, Effect.none )

        MenuClicked ->
            ( { model | showMenu = not model.showMenu }, Effect.none )


subscriptions : UrlPath -> Model -> Sub Msg
subscriptions _ _ =
    Sub.none


data : BackendTask FatalError Data
data =
    BackendTask.succeed ()


view :
    Data
    ->
        { path : UrlPath
        , route : Maybe Route
        }
    -> Model
    -> (Msg -> msg)
    -> View msg
    -> { body : List (Html msg), title : String }
view sharedData page model toMsg pageView =
    { body =
        [ Html.Styled.toUnstyled
            (div
                [ css [ height (pct 100) ] ]
                [ node "link"
                    [ href "https://fonts.googleapis.com/css2?family=Megrim&display=swap"
                    , rel "stylesheet"
                    ]
                    []
                , initGlobalStyles
                , div
                    [ css
                        [ height (pct 100)
                        , displayFlex
                        , justifyContent center
                        , boxSizing borderBox
                        , paddingTop (px 10)
                        , paddingBottom (px 10)
                        ]
                    ]
                    [ div
                        [ css
                            [ displayFlex
                            , flexDirection column
                            , width (px 850)
                            , height (pct 100)
                            , maxWidth (px 1200)
                            , paddingRight (px 20)
                            , paddingLeft (px 20)
                            , overflow scroll
                            ]
                        ]
                        -- main content
                        [ div []
                            [ OWBTheme.title
                                []
                                [ text pageView.title ]
                            , spacer
                            , div
                                [ css
                                    [ overflow auto
                                    , paddingBottom (px 6)
                                    ]
                                ]
                                [ Html.Styled.fromUnstyled (Html.main_ [] pageView.body) ]
                            ]
                        ]
                    , desktopNav model
                    , mobileNav model |> Html.Styled.map toMsg
                    ]
                ]
            )
        ]
    , title = pageView.title
    }


desktopNav : Model -> Html.Styled.Html msg
desktopNav model =
    div
        [ css
            [ display none
            , desktop [ displayFlex ]
            ]
        ]
        [ div
            [ css
                [ border3 (px 3) solid theme.primary
                , borderRadius (px 6)
                , backgroundColor theme.primary
                ]
            ]
            []
        , div []
            [ div
                [ css
                    [ backgroundImage (url "\"../res/img/menu/Circle Lines logo.png\"")
                    , height (px 100)
                    , width (px 160)
                    , marginBottom (px 40)
                    , backgroundPosition center
                    , backgroundSize (px 100)
                    , backgroundRepeat noRepeat
                    ]
                ]
                []
            , menuBtn [ href "/about" ] [ text "About" ]
            , menuBtn [ href "/portfolio" ] [ text "Portfolio" ]
            , menuBtn [ href "/blog" ] [ text "Blog" ]
            , menuBtn [ href "/contact" ] [ text "Contact" ]
            ]
        ]


mobileNav : Model -> Html.Styled.Html Msg
mobileNav model =
    div
        [ css
            [ display block
            , position absolute
            , right (px 0)
            , desktop [ display none ]
            , marginRight (px 10)
            ]
        ]
        [ menuIconBtn
            [ Html.Styled.Events.onClick MenuClicked ]
            "/res/img/menu/Circle Lines logo.png"
        , div
            [ css
                [ if model.showMenu then
                    display block

                  else
                    display none
                ]
            ]
            [ div
                [ mobileNavStyle ]
                [ faLink
                    theme.link
                    [ css
                        [ height (px 25)
                        , width (px 25)
                        , mobile [ height (px 20), width (px 20) ]
                        ]
                    ]
                    "/about"
                    "fa-regular fa-user"
                ]
            , div
                [ mobileNavStyle ]
                [ faLink
                    theme.link
                    [ css
                        [ height (px 30)
                        , width (px 30)
                        , mobile [ height (px 25), width (px 25) ]
                        ]
                    ]
                    "/portfolio"
                    "fa-solid fa-briefcase"
                ]
            , div
                [ mobileNavStyle ]
                [ faLink
                    theme.link
                    [ css
                        [ height (px 30)
                        , width (px 30)
                        , mobile [ height (px 25), width (px 25) ]
                        ]
                    ]
                    "/blog"
                    "fa-solid fa-blog"
                ]
            , div
                [ mobileNavStyle
                , css [ borderRadius4 (px 0) (px 0) (px 6) (px 6) ]
                ]
                [ faLink
                    theme.link
                    [ css
                        [ height (px 35)
                        , width (px 35)
                        , mobile [ height (px 30), width (px 30) ]
                        ]
                    ]
                    "/contact"
                    "fa-regular fa-comments"
                ]
            ]
        ]


mobileNavStyle : Attribute msg
mobileNavStyle =
    css
        [ display block
        , backgroundColor theme.background
        , width (px 35)
        , height (px 35)
        , textDecoration none
        , cursor pointer
        , boxShadow4 (px -2) (px 2) (px 7) (rgb 0 0 0)
        , borderBottom3 (px 2) solid theme.primary
        , borderLeft3 (px 2) solid theme.primary
        , padding (px 10)
        , paddingBottom (px 5)
        , margin auto
        , active
            [ boxShadow4 (px -1) (px 1) (px 4) (rgb 0 0 0) ]
        , mobile [ width (px 30), height (px 30) ]
        ]
