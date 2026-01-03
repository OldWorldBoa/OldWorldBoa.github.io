module Portfolio exposing (..)

import Css exposing (boxShadow4, center, displayFlex, fontFamilies, fontSize, height, marginLeft, marginRight, padding, px, rgb, textAlign)
import Html.Styled exposing (Attribute, Html, div, hr, img, p, text)
import Html.Styled.Attributes exposing (css, href, src, target)
import Messages exposing (Message(..))
import OWBTheme exposing (link, linkBtn)
import Url exposing (Url)


type alias Model =
    { url : Url
    }


view : Model -> ( String, Html Message )
view model =
    ( "Portfolio"
    , div
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
            , div [ css [ displayFlex ] ]
                [ previewContent []
                    [ previewTitle [] [ text "Contraction Timer" ]
                    , p []
                        [ text "This is a free contraction timer. See your contraction timing in a graph that tells you when you're approaching active labour."
                        ]
                    , linkBtn [ href (model.url.path ++ "?p=contraction-timer") ] [ text "Check it out!" ]
                    ]
                , previewImg [ src "../res/img/pages/portfolio/foe-1-9-calculator.png" ] []
                ]
            , hr [] []
            , div [ css [ displayFlex ] ]
                [ previewImg [ src "../res/img/pages/portfolio/chess_board.png" ] []
                , previewContent []
                    [ previewTitle [] [ text "Checkered Board Game" ]
                    , p [] [ text "This is my WebGL project of a checkered board game. Currently, it only plays chess, but check back later for other games and two-player functionality." ]
                    , linkBtn [] [ text "Check it out!" ]
                    ]
                ]
            , hr [] []
            , div [ css [ displayFlex ] ]
                [ previewContent []
                    [ previewTitle [] [ text "Stock Ticker" ]
                    , p [] [ text "This is a stock ticker powered by TradingView. You can input any stock symbol they support and get that stock's graph. It has an on-screen keyboard if your touchscreen device happens to not have one." ]
                    , linkBtn [] [ text "Check it out!" ]
                    ]
                , previewImg [ src "../res/img/pages/portfolio/stock-ticker.png" ] []
                ]
            , hr [] []
            , div [ css [ displayFlex ] ]
                [ previewImg [ src "../res/img/pages/portfolio/foe-1-9-calculator.png" ] []
                , previewContent []
                    [ previewTitle [] [ text "FOE 1.9 Calculator" ]
                    , p []
                        [ text "This is for the game "
                        , link
                            [ href "https://en0.forgeofempires.com/page/"
                            , target "_blank"
                            ]
                            [ text "Forge of Empires" ]
                        , text " and is used to calculate the forge points required to contribute 1.9 * the reward in a Great Building."
                        ]
                    , linkBtn [] [ text "Check it out!" ]
                    ]
                ]
            ]
        ]
    )


previewImg : List (Attribute msg) -> List (Html msg) -> Html msg
previewImg attributes contents =
    img
        (List.append
            [ css
                [ height (px 200)
                , boxShadow4 (px 0) (px 0) (px 5) (rgb 0 0 0)
                ]
            ]
            attributes
        )
        contents


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
                [ marginLeft (px 5)
                , marginRight (px 5)
                , textAlign center
                ]
            ]
            attributes
        )
        contents
