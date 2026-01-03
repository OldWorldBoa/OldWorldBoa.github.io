module About exposing (..)

import Css exposing (center, displayFlex, height, justifyContent, px)
import Html.Styled exposing (..)
import Html.Styled.Attributes exposing (css, src)
import Messages exposing (Message)


view : ( String, Html Message )
view =
    ( "About"
    , div
        [ css
            [ displayFlex
            , justifyContent center
            ]
        ]
        [ div []
            [ p []
                [ text "Hello! I'm OldWorldBoa and thanks for coming to check out my website. I've been a software developer since 2016, working on software like CRMs, finance glue, and self-service portals. Join me on twitch and check out my YouTube channel for my content!"
                ]
            , p []
                [ text "I have several personal projects including this website: a bible comparer, a chess game, and an educational maze maker. Check out my portfolio for more!"
                ]
            ]
        , div
            []
            [ img
                [ src "../res/img/pages/about/profile.jpg"
                , css
                    [ height (px 150) ]
                ]
                []
            ]
        ]
    )
