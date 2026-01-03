module Portfolio exposing (..)

import Css exposing (Style, auto, boxShadow4, center, displayFlex, flexWrap, fontFamilies, fontSize, height, margin, marginLeft, marginRight, padding, px, rgb, textAlign, width, wrap)
import Html.Styled exposing (Attribute, Html, div, hr, img, p, text)
import Html.Styled.Attributes exposing (css, href, src, target)
import Messages exposing (Message(..))
import OWBTheme exposing (desktop, link, linkBtn, mobile, tablet)
import Url exposing (Url)


type alias Model =
    { url : Url
    }


portfolioEntryStyle : Attribute Message
portfolioEntryStyle =
    css [ displayFlex, mobile [ flexWrap wrap ] ]


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
            , div [ portfolioEntryStyle ]
                [ previewImg [ src "../res/img/pages/portfolio/foe-1-9-calculator.png" ] []
                , previewContent []
                    [ previewTitle [] [ text "Contraction Timer" ]
                    , p []
                        [ text "This is a free contraction timer. See your contraction timing in a graph that tells you when you're approaching active labour."
                        ]
                    , linkBtn [ href (model.url.path ++ "?p=contraction-timer") ] [ text "Check it out!" ]
                    ]
                ]
            , hr [] []
            , div [ portfolioEntryStyle ]
                [ previewImg [ src "../res/img/pages/portfolio/chess_board.png" ] []
                , previewContent []
                    [ previewTitle [] [ text "Checkered Board Game" ]
                    , p [] [ text "This is my WebGL project of a checkered board game. Currently, it only plays chess, but check back later for other games and two-player functionality." ]
                    , linkBtn [] [ text "Check it out!" ]
                    ]
                ]
            ]
        ]
    )


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
