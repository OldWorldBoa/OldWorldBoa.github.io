module OWBTheme exposing (..)

import Css exposing (..)
import Css.Global exposing (body, descendants, global, html, typeSelector)
import Css.Media exposing (only, screen, withMedia)
import Css.Transitions exposing (transition)
import Html.Styled exposing (..)
import Html.Styled.Attributes exposing (class, css, href, src)
import Html.Styled.Events exposing (onClick)
import Time
import TimeUtils


theme :
    { primary : Color
    , secondary : Color
    , text : Color
    , background : Color
    , lightBackground : Color
    , link : Color
    , linkVisited : Color
    }
theme =
    { primary = hex "408C5E"
    , secondary = hex "A3320B"
    , text = hex "D3D3D3"
    , background = hex "3A4041"
    , lightBackground = hex "808687"
    , link = hex "9FD9BA"
    , linkVisited = hex "D6633F"
    }


desktop : List Style -> Style
desktop =
    withMedia [ only screen [ Css.Media.minWidth (px 1080) ] ]


tablet : List Style -> Style
tablet =
    withMedia [ only screen [ Css.Media.minWidth (px 650), Css.Media.maxWidth (px 1079) ] ]


mobile : List Style -> Style
mobile =
    withMedia [ only screen [ Css.Media.maxWidth (px 649) ] ]


initGlobalStyles : Html msg
initGlobalStyles =
    global
        [ body
            [ height (pct 100)
            , margin (px 0)
            , padding (px 0)
            , backgroundColor theme.background
            , color theme.text
            , fontFamily sansSerif
            , fontSize (px 18)
            ]
        , html [ height (pct 100) ]
        , typeSelector "main"
            [ descendants
                [ typeSelector "img" [ width (pct 100) ]
                ]
            ]
        ]


tabBtn : List (Attribute msg) -> List (Html msg) -> Html msg
tabBtn attributes contents =
    div
        (List.append
            [ css
                [ display block
                , fontFamilies [ "Megrim" ]
                , fontWeight bold
                , fontSize (px 25)
                , color theme.text
                , textDecoration none
                , padding4 (px 15) (px 20) (px 15) (px 20)
                , cursor pointer
                , backgroundSize2 (pct 100) (pct 200)
                , backgroundPosition bottom
                , backgroundImage
                    (linearGradient2
                        toTop
                        (stop2 theme.background <| pct 51)
                        (stop2 theme.secondary <| pct 50)
                        []
                    )
                , hover [ backgroundPosition top ]
                , transition [ Css.Transitions.backgroundPosition 100 ]
                ]
            ]
            attributes
        )
        contents


menuBtn : List (Attribute msg) -> List (Html msg) -> Html msg
menuBtn attributes contents =
    a
        (List.append
            [ css
                [ display block
                , fontFamilies [ "Megrim" ]
                , fontWeight bold
                , fontSize (px 30)
                , color theme.text
                , textDecoration none
                , padding4 (px 15) (px 20) (px 15) (px 20)
                , cursor pointer
                , backgroundSize (pct 200)
                , backgroundPosition right
                , backgroundImage
                    (linearGradient2
                        toLeft
                        (stop2 theme.background <| pct 51)
                        (stop2 theme.secondary <| pct 50)
                        []
                    )
                , hover [ backgroundPosition left ]
                , transition [ Css.Transitions.backgroundPosition 100 ]
                ]
            ]
            attributes
        )
        contents


menuIconBtn : List (Attribute msg) -> String -> Html msg
menuIconBtn attributes iconPath =
    div
        (List.append
            [ css
                [ backgroundColor theme.background
                , display block
                , maxWidth fitContent
                , textDecoration none
                , color theme.link
                , cursor pointer
                , boxShadow4 (px -2) (px 2) (px 7) (rgb 0 0 0)
                , borderBottom3 (px 2) solid theme.primary
                , borderLeft3 (px 2) solid theme.primary
                , borderRadius (px 6)
                , padding (px 10)
                , paddingBottom (px 5)
                , margin auto
                , active
                    [ boxShadow4 (px -1) (px 1) (px 4) (rgb 0 0 0)
                    ]
                , mobile
                    [ padding (px 8)
                    , paddingBottom (px 3)
                    ]
                ]
            ]
            attributes
        )
        [ img
            [ css
                [ width (px 50)
                , height (px 50)
                , mobile
                    [ width (px 42)
                    , height (px 42)
                    ]
                ]
            , src iconPath
            ]
            []
        ]


linkBtn : List (Attribute msg) -> List (Html msg) -> Html msg
linkBtn attributes contents =
    a
        (List.append
            [ css
                [ display block
                , maxWidth fitContent
                , textDecoration none
                , color theme.link
                , cursor pointer
                , boxShadow4 (px -2) (px 2) (px 7) (rgb 0 0 0)
                , borderBottom3 (px 2) solid theme.primary
                , borderLeft3 (px 2) solid theme.primary
                , borderRadius (px 6)
                , padding (px 10)
                , margin auto
                , hover
                    [ backgroundColor theme.background
                    ]
                ]
            ]
            attributes
        )
        contents


btn : List (Attribute msg) -> List (Html msg) -> Html msg
btn attributes contents =
    div
        (List.append
            [ css
                [ display block
                , maxWidth fitContent
                , textDecoration none
                , color theme.link
                , cursor pointer
                , boxShadow4 (px -2) (px 2) (px 7) (rgb 0 0 0)
                , borderBottom3 (px 2) solid theme.primary
                , borderLeft3 (px 2) solid theme.primary
                , borderRadius (px 6)
                , padding (px 10)
                , margin auto
                , hover
                    [ backgroundColor theme.background
                    ]
                ]
            ]
            attributes
        )
        contents


faButton : Color -> msg -> String -> Html msg
faButton clr msg icon =
    div
        [ css [ width (px 25), cursor pointer, color clr ], onClick msg ]
        [ i [ class icon ] [] ]


faLink : Color -> List (Attribute msg) -> String -> String -> Html msg
faLink colr innerStyle path icon =
    a
        [ href path, css [ color colr ] ]
        [ div
            (List.append [ css [ margin auto, cursor pointer ] ] innerStyle)
            [ i [ class icon ] [] ]
        ]


commonTitle : List Style
commonTitle =
    [ fontFamilies [ "Megrim" ]
    , paddingLeft (px 3)
    ]


title : List (Attribute msg) -> List (Html msg) -> Html msg
title attributes contents =
    h1
        (List.append
            [ css
                (List.append
                    [ fontSize (px 54)
                    , tablet [ margin (px 20), fontSize (px 45) ]
                    , mobile [ margin (px 20), fontSize (px 40) ]
                    ]
                    commonTitle
                )
            ]
            attributes
        )
        contents


subtitle : List (Attribute msg) -> List (Html msg) -> Html msg
subtitle attributes contents =
    h2
        (List.append
            [ css
                (List.append
                    [ fontSize (px 36)
                    , tablet [ margin (px 5), fontSize (px 25) ]
                    , mobile [ margin (px 5), fontSize (px 23) ]
                    ]
                    commonTitle
                )
            ]
            attributes
        )
        contents


link : List (Attribute msg) -> List (Html msg) -> Html msg
link attributes contents =
    a
        (List.append
            [ css
                [ color theme.link
                , visited [ color theme.linkVisited ]
                ]
            ]
            attributes
        )
        contents


spacer : Html msg
spacer =
    hr
        [ css
            [ border3 (px 2) solid theme.primary
            , borderRadius (px 6)
            , backgroundColor theme.primary
            ]
        ]
        []


type alias Post =
    { id : Int
    , path : String
    , publish_time : Time.Posix
    , title : String
    , author : String
    , tags : String
    , preview : String
    }


getPostHtml : Time.Zone -> Post -> Html.Styled.Html msg
getPostHtml zone post =
    card
        [ h2 [ css [ marginTop (px 0), textAlign center ] ]
            [ link
                [ href ("blog/" ++ post.path) ]
                [ text post.title ]
            ]
        , h4
            [ css [ textAlign center ] ]
            [ text (post.author ++ " - " ++ TimeUtils.toDate zone post.publish_time) ]
        , div [] [ text post.preview ]
        ]


card : List (Html msg) -> Html msg
card content =
    div
        [ css
            [ paddingLeft (px 15)
            , paddingRight (px 15)
            , paddingBottom (px 15)
            , paddingTop (px 15)
            , margin (px 15)
            , borderRadius (px 5)
            , boxShadow4 (px -2) (px 2) (px 7) (rgb 0 0 0)
            ]
        ]
        content


styledInput : List (Attribute msg) -> List (Html msg) -> Html msg
styledInput attributes contents =
    input
        (List.append
            [ css
                [ backgroundColor theme.lightBackground
                , borderRadius (px 5)
                , border3 (px 2) solid theme.primary
                , width (pct 100)
                , boxSizing borderBox
                , boxShadow6 inset (px 0) (px 0) (px 3) (px 3) (hex "111111")
                , paddingRight (px 10)
                , paddingTop (px 10)
                , paddingBottom (px 10)
                , paddingLeft (px 10)
                , fontSize (px 15)
                ]
            ]
            attributes
        )
        contents


styledTextarea : List (Attribute msg) -> Html msg
styledTextarea attributes =
    textarea
        (List.append
            [ css
                [ backgroundColor theme.lightBackground
                , borderRadius (px 5)
                , border3 (px 2) solid theme.primary
                , width (pct 100)
                , boxSizing borderBox
                , boxShadow6 inset (px 0) (px 0) (px 3) (px 3) (hex "111111")
                , paddingRight (px 10)
                , paddingTop (px 10)
                , paddingBottom (px 10)
                , paddingLeft (px 10)
                , resize vertical
                ]
            ]
            attributes
        )
        []
