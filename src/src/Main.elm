port module Main exposing (..)

import About
import Browser
import Browser.Navigation as Nav
import Contact
import ContractionTimer
import Css exposing (absolute, active, auto, backgroundColor, backgroundImage, backgroundPosition, backgroundRepeat, backgroundSize, block, border3, borderBottom3, borderBox, borderLeft3, borderRadius, borderRadius4, boxShadow4, boxSizing, center, column, cursor, display, displayFlex, flexDirection, height, justifyContent, margin, marginBottom, marginRight, maxWidth, noRepeat, none, overflow, padding, paddingBottom, paddingLeft, paddingRight, paddingTop, pct, pointer, position, px, rgb, right, solid, textDecoration, url, width)
import FontAwesome.Regular
import FontAwesome.Solid
import Html.Events exposing (onClick)
import Html.Styled exposing (..)
import Html.Styled.Attributes exposing (css, href, rel)
import Json.Decode as D
import Json.Encode as E
import Messages exposing (Message(..))
import OWBTheme exposing (desktop, faLink, initGlobalStyles, menuBtn, menuIconBtn, mobile, spacer, theme)
import Portfolio
import Time
import Url
import UrlParser exposing (Route(..))


main : Program E.Value Model Message
main =
    Browser.application
        { init = init
        , view = view
        , update = updateWithStorage
        , subscriptions = subscriptions
        , onUrlChange = UrlChanged
        , onUrlRequest = LinkClicked
        }


type alias Model =
    { key : Nav.Key
    , url : Url.Url
    , route : Route
    , mobileNav : Bool
    , ctModel : ContractionTimer.Model
    }


port setStorage : E.Value -> Cmd msg


init : E.Value -> Url.Url -> Nav.Key -> ( Model, Cmd Message )
init flags url key =
    ( case D.decodeValue (decoder url key) flags of
        Ok model ->
            model

        Err _ ->
            Model
                key
                url
                (UrlParser.fromUrl url)
                False
                (ContractionTimer.Model [] Nothing Time.utc ContractionTimer.Idle ContractionTimer.Graph)
    , Cmd.none
    )


update : Message -> Model -> ( Model, Cmd Message )
update msg model =
    if Messages.forNavigation msg then
        case msg of
            LinkClicked urlRequested ->
                case urlRequested of
                    Browser.Internal url ->
                        ( { model | route = UrlParser.fromUrl url }
                        , Nav.pushUrl model.key (Url.toString url)
                        )

                    Browser.External href ->
                        ( model, Nav.load href )

            UrlChanged url ->
                ( { model | url = url, route = UrlParser.fromUrl url }, Cmd.none )

            ButtonNav path ->
                let
                    url =
                        model.url

                    newUrl =
                        { url | path = url.path ++ path }
                in
                ( { model | route = UrlParser.fromUrl newUrl }
                , Nav.pushUrl model.key (Url.toString newUrl)
                )

            ToggleMobileNav ->
                ( { model | mobileNav = not model.mobileNav }, Cmd.none )

            _ ->
                ( model, Cmd.none )

    else if Messages.forContractionTimer msg then
        sendMessageToContractionTimer msg model

    else
        ( model, Cmd.none )


updateWithStorage : Message -> Model -> ( Model, Cmd Message )
updateWithStorage msg model =
    let
        ( newModel, cmd ) =
            update msg model
    in
    ( newModel, Cmd.batch [ setStorage (encode newModel), cmd ] )


sendMessageToContractionTimer : Message -> Model -> ( Model, Cmd Message )
sendMessageToContractionTimer msg model =
    let
        ( ctUpdate, ctCmd ) =
            ContractionTimer.update msg model.ctModel
    in
    ( { model | ctModel = ctUpdate }, ctCmd )


subscriptions : Model -> Sub Message
subscriptions model =
    case model.route of
        ContractionTimer ->
            ContractionTimer.subscriptions model.ctModel

        _ ->
            Sub.none


view : Model -> Browser.Document Message
view model =
    let
        ( title, page ) =
            case model.route of
                About ->
                    About.view

                Portfolio ->
                    Portfolio.view (Portfolio.Model model.url)

                Contact ->
                    Contact.view

                ContractionTimer ->
                    ContractionTimer.view model.ctModel

                Unknown ->
                    ( "Unkown", div [] [ text "Page not found" ] )

        body =
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
                                ]
                            ]
                            -- main content
                            [ div []
                                [ OWBTheme.title [] [ text title ]
                                , spacer
                                ]
                            , div
                                [ css
                                    [ overflow auto
                                    , paddingBottom (px 6)
                                    ]
                                ]
                                [ page ]
                            ]
                        , desktopNav model
                        , mobileNav model
                        ]
                    ]
                )
            ]
    in
    Browser.Document title body


desktopNav : Model -> Html.Styled.Html Message
desktopNav model =
    div [ css [ display none, desktop [ displayFlex ] ] ]
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
            , menuBtn [ href (model.url.path ++ "?p=about") ] [ text "About" ]
            , menuBtn [ href (model.url.path ++ "?p=portfolio") ] [ text "Portfolio" ]
            , menuBtn [ href (model.url.path ++ "?p=contact") ] [ text "Contact" ]
            ]
        ]


mobileNav : Model -> Html.Styled.Html Message
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
            [ Html.Styled.Attributes.fromUnstyled (onClick ToggleMobileNav) ]
            "../res/img/menu/Circle Lines logo.png"
        , div
            [ css
                [ if model.mobileNav then
                    display block

                  else
                    display none
                ]
            ]
            [ div
                [ mobileNavStyle ]
                [ faLink
                    (if model.route == About then
                        theme.linkVisited

                     else
                        theme.link
                    )
                    [ css
                        [ height (px 25)
                        , width (px 25)
                        , mobile [ height (px 20), width (px 20) ]
                        ]
                    ]
                    (model.url.path ++ "?p=about")
                    FontAwesome.Regular.user
                ]
            , div
                [ mobileNavStyle ]
                [ faLink
                    (if model.route == Portfolio then
                        theme.linkVisited

                     else
                        theme.link
                    )
                    [ css
                        [ height (px 30)
                        , width (px 30)
                        , mobile [ height (px 25), width (px 25) ]
                        ]
                    ]
                    (model.url.path ++ "?p=portfolio")
                    FontAwesome.Solid.briefcase
                ]
            , div
                [ mobileNavStyle
                , css [ borderRadius4 (px 0) (px 0) (px 6) (px 6) ]
                ]
                [ faLink
                    (if model.route == Contact then
                        theme.linkVisited

                     else
                        theme.link
                    )
                    [ css
                        [ height (px 35)
                        , width (px 35)
                        , mobile [ height (px 30), width (px 30) ]
                        ]
                    ]
                    (model.url.path ++ "?p=contact")
                    FontAwesome.Regular.comments
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


encode : Model -> E.Value
encode model =
    E.object
        [ ( "ct"
          , E.object
                [ ( "contractions"
                  , E.list
                        (\a -> a)
                        (List.map ContractionTimer.encodeContraction model.ctModel.contractions)
                  )
                ]
          )
        ]


decoder : Url.Url -> Nav.Key -> D.Decoder Model
decoder url key =
    D.map5
        Model
        (D.succeed key)
        (D.succeed url)
        (D.succeed (UrlParser.fromUrl url))
        (D.succeed False)
        (D.field "ct" ContractionTimer.decoderCT)
