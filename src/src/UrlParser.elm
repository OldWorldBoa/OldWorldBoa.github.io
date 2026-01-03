module UrlParser exposing (Route(..), fromUrl, toString)

import Url exposing (Url)


type Route
    = About
    | Portfolio
    | ContractionTimer
    | Contact
    | Unknown


toString : Route -> String
toString route =
    case route of
        About ->
            "About"

        Portfolio ->
            "Portfolio"

        ContractionTimer ->
            "ContractionTimer"

        _ ->
            "Unknown"


fromUrl : Url -> Route
fromUrl url =
    case url.query of
        Just query ->
            case query of
                "p=about" ->
                    About

                "p=portfolio" ->
                    Portfolio

                "p=contact" ->
                    Contact

                "p=contraction-timer" ->
                    ContractionTimer

                _ ->
                    About

        Nothing ->
            About
