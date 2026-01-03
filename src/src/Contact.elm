module Contact exposing (..)

import Css exposing (LengthOrAuto, center, color, displayFlex, height, justifyContent, margin, px, spaceAround, spaceBetween, textAlign, visited, width)
import FontAwesome as Icon
import FontAwesome.Brands
import Html.Styled exposing (..)
import Html.Styled.Attributes exposing (css, href, target)
import Messages exposing (Message)
import OWBTheme exposing (link, theme)


view : ( String, Html Message )
view =
    ( "Contact Me"
    , div
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
            [ iconLink (px 75) "https://github.com/oldworldboa" FontAwesome.Brands.github
            , iconLink (px 75) "https://www.twitch.tv/oldworldboa" FontAwesome.Brands.twitch
            , iconLink (px 75) "https://patreon.com/oldworldboa" FontAwesome.Brands.patreon
            ]
        ]
    )


iconLink : LengthOrAuto compatible -> String -> Icon.Icon Icon.WithoutId -> Html msg
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
            [ Html.Styled.fromUnstyled (Icon.view icon) ]
        ]
