module Route exposing
    ( Route(..), segmentsToRoute, urlToRoute, baseUrl, routeToPath, baseUrlAsPath
    , toPath, toString, redirectTo, toLink, link, withoutBaseUrl
    )

{-|
@docs Route, segmentsToRoute, urlToRoute, baseUrl, routeToPath, baseUrlAsPath
@docs toPath, toString, redirectTo, toLink, link, withoutBaseUrl
-}


import Html
import Html.Attributes
import Server.Response
import UrlPath


{-| . -}
type Route
    = Portfolio__ContractionTimer
    | Blog__Slug_ { slug : String }
    | About
    | Contact
    | Portfolio
    | Index


{-| . -}
segmentsToRoute : List String -> Maybe Route
segmentsToRoute segments =
    case segments of
    [ "portfolio", "contraction-timer" ] ->
        Just Portfolio__ContractionTimer

    [ "blog", slug ] ->
        Just (Blog__Slug_ { slug = slug })

    [ "about" ] ->
        Just About

    [ "contact" ] ->
        Just Contact

    [ "portfolio" ] ->
        Just Portfolio

    [] ->
        Just Index

    _ ->
        Nothing


{-| . -}
urlToRoute : { url | path : String } -> Maybe Route
urlToRoute url =
    segmentsToRoute (splitPath url.path)


{-| . -}
baseUrl : String
baseUrl =
    "/"


{-| . -}
routeToPath : Route -> List String
routeToPath route =
    List.concat
        (case route of
             Portfolio__ContractionTimer ->
                 [ [ "portfolio", "contraction-timer" ] ]
         
             Blog__Slug_ params ->
                 [ [ "blog" ], [ params.slug ] ]
         
             About ->
                 [ [ "about" ] ]
         
             Contact ->
                 [ [ "contact" ] ]
         
             Portfolio ->
                 [ [ "portfolio" ] ]
         
             Index ->
                 [ [] ]
        )


{-| . -}
baseUrlAsPath : List String
baseUrlAsPath =
    List.filter
        (\item -> Basics.not (String.isEmpty item))
        (String.split "/" baseUrl)


{-| . -}
toPath : Route -> UrlPath.UrlPath
toPath route =
    UrlPath.fromString (String.join "/" (baseUrlAsPath ++ routeToPath route))


{-| . -}
toString : Route -> String
toString route =
    UrlPath.toAbsolute (toPath route)


{-| . -}
redirectTo : Route -> Server.Response.Response data error
redirectTo route =
    Server.Response.temporaryRedirect (toString route)


{-| . -}
toLink : (List (Html.Attribute msg) -> abc) -> Route -> abc
toLink toAnchorTag route =
    toAnchorTag
        [ Html.Attributes.href (toString route)
        , Html.Attributes.attribute "elm-pages:prefetch" ""
        ]


{-| . -}
link :
    List (Html.Attribute msg) -> List (Html.Html msg) -> Route -> Html.Html msg
link attributes children route =
    toLink (\anchorAttrs -> Html.a (anchorAttrs ++ attributes) children) route


{-| . -}
withoutBaseUrl : String -> String
withoutBaseUrl path =
    if String.startsWith baseUrl path then
        String.dropLeft (String.length baseUrl) path
    
    else
        path


splitPath path =
    List.filter (\item -> item /= "") (String.split "/" path)


maybeToList : Maybe String -> List String
maybeToList maybeString =
    case maybeString of
        Nothing ->
            []
    
        Just string ->
            [ string ]