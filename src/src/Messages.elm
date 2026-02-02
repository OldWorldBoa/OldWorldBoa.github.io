module Messages exposing (..)

import Browser
import Bytes
import Time
import Url


type Message
    = LinkClicked Browser.UrlRequest
    | UrlChanged Url.Url
    | ButtonNav String
    | ToggleMobileNav
    | CT_Tick Time.Posix
    | CT_AdjustTimeZone Time.Zone
    | CT_AdjustEndianness Bytes.Endianness
    | CT_DownloadContractions
    | CT_InitTimer Time.Posix
    | CT_Start
    | CT_Stop
    | CT_ToggleView
    | CT_Delete Int
    | CT_Reset
    | CT_Add
    | CT_Edit Int
    | CT_Save
    | CT_Cancel
    | CT_ShadowEnd String
    | CT_ShadowStart String
    | CT_ConfirmReset


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

        CT_AdjustEndianness _ ->
            True

        CT_DownloadContractions ->
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

        CT_Reset ->
            True

        CT_Add ->
            True

        CT_Edit _ ->
            True

        CT_Save ->
            True

        CT_Cancel ->
            True

        CT_ShadowEnd _ ->
            True

        CT_ShadowStart _ ->
            True

        CT_ConfirmReset ->
            True

        _ ->
            False
