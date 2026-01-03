module Messages exposing (..)

import Browser
import Time
import Url


type Message
    = LinkClicked Browser.UrlRequest
    | UrlChanged Url.Url
    | ButtonNav String
    | ToggleMobileNav
    | CT_Tick Time.Posix
    | CT_AdjustTimeZone Time.Zone
    | CT_InitTimer Time.Posix
    | CT_Start
    | CT_Stop
    | CT_ToggleView
    | CT_Delete Int


forNavigation : Message -> Bool
forNavigation msg =
    case msg of
        LinkClicked _ ->
            True

        UrlChanged _ ->
            True

        ButtonNav _ ->
            True

        ToggleMobileNav ->
            True

        _ ->
            False


forContractionTimer : Message -> Bool
forContractionTimer msg =
    case msg of
        CT_AdjustTimeZone _ ->
            True

        CT_InitTimer _ ->
            True

        CT_Tick _ ->
            True

        CT_Stop ->
            True

        CT_Start ->
            True

        CT_ToggleView ->
            True

        CT_Delete _ ->
            True

        _ ->
            False
