module About exposing (..)

import Css exposing (borderRadius, center, displayFlex, flexWrap, height, justifyContent, marginRight, marginTop, px, wrap)
import Html.Styled exposing (..)
import Html.Styled.Attributes exposing (css, src)
import Messages exposing (Message)
import OWBTheme exposing (mobile)


view : ( String, Html Message )
view =
    ( "About"
    , div
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
