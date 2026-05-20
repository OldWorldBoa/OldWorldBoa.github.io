port module Route.Portfolio.ContractionTimer exposing (ActionData, Data, Model, Msg(..), RouteParams, action, data, route)

import Array exposing (Array, slice)
import BackendTask exposing (BackendTask)
import Bytes exposing (Bytes, Endianness)
import Bytes.Encode as Encode exposing (sequence, string)
import Chart as C
import Chart.Attributes as CA
import Chart.Item as CI
import Css exposing (absolute, active, alignItems, auto, backgroundColor, block, borderRadius, borderTop3, boxShadow4, center, color, column, cursor, display, displayFlex, fitContent, flexDirection, height, inlineBlock, justifyContent, left, margin, marginRight, maxWidth, none, padding, paddingLeft, paddingRight, pct, pointer, position, px, rgb, rgba, solid, spaceAround, spaceBetween, start, textAlign, top, width)
import Effect exposing (Effect(..))
import ErrorPage exposing (ErrorPage)
import FatalError exposing (FatalError)
import File.Download as Download
import Head
import Html.Styled exposing (Html, br, div, hr, input, label, p, sup, td, text, th, thead, tr)
import Html.Styled.Attributes exposing (css, href, type_, value)
import Html.Styled.Events exposing (onClick, onInput)
import Json.Decode as D exposing (andThen, array, succeed)
import Json.Encode as E
import OWBTheme exposing (faButton, theme)
import PagesMsg exposing (PagesMsg)
import RouteBuilder exposing (App)
import Server.Request exposing (Request)
import Server.Response
import Shared
import Svg as S
import Task
import Time exposing (Month(..), Zone)
import UrlPath exposing (UrlPath)
import View exposing (View)
import TimeUtils exposing (..)

port setContractions : E.Value -> Cmd msg

port loadContractions : (String -> msg) -> Sub msg

type alias ContractionGraphed =
    { elapsed : Float, duration : Float }

newContractionGraphed : Time.Posix -> Contraction -> ContractionGraphed
newContractionGraphed now contraction =
    ContractionGraphed
        (toFloat (Time.posixToMillis contraction.end - Time.posixToMillis now) / 1000 / 60)
        (toFloat contraction.duration / 1000)

type alias Contraction =
    { start : Time.Posix
    , end : Time.Posix
    , duration : Int
    }

newContraction : Time.Posix -> Time.Posix -> Contraction
newContraction start end =
    Contraction start end (Time.posixToMillis end - Time.posixToMillis start)

getDuration : Contraction -> Int
getDuration contraction =
    contraction.duration

getEndMillis : Contraction -> Int
getEndMillis contraction =
    Time.posixToMillis contraction.end

type alias Model =
    { contractions : Array Contraction
    , now : Maybe Time.Posix
    , zone : Time.Zone
    , endianness : Maybe Endianness
    , task : ModelTask
    , showTable : Bool
    , modalView : ModalView
    }

emptyModel : Model
emptyModel =
    Model Array.empty Nothing Time.utc Nothing Idle False None

type ModelTask
    = Timer Contraction
    | Idle

type ModalView
    = Edit (Maybe Int) Contraction
    | Confirm
    | None

type Msg
    = CT_Tick Time.Posix
    | CT_AdjustTimeZone Time.Zone
    | CT_AdjustEndianness Bytes.Endianness
    | LoadContractions String
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
    | CT_ToggleCTList

type alias RouteParams =
    {}

route =
    RouteBuilder.serverRender { data = data, action = action, head = head }
        |> RouteBuilder.buildWithLocalState
            { view = view
            , subscriptions = subscriptions
            , update = updateWithStorage
            , init = init
            }

init :
    App Data ActionData RouteParams
    -> Shared.Model
    -> ( Model, Effect Msg )
init _ _ =
    ( emptyModel
    , Cmd
        (Cmd.batch
            [ Task.perform CT_AdjustTimeZone Time.here
            , Task.perform CT_AdjustEndianness Bytes.getHostEndianness
            ]
        )
    )

updateWithStorage :
    App Data ActionData RouteParams
    -> Shared.Model
    -> Msg
    -> Model
    -> ( Model, Effect Msg )
updateWithStorage app mdl msg model =
    let
        ( newModel, effect ) =
            update app mdl msg model
    in
    ( newModel
    , Effect.Batch
        [ setContractions (encodeContractionTimer model) |> Effect.fromCmd
        , effect
        ]
    )

update :
    App Data ActionData RouteParams
    -> Shared.Model
    -> Msg
    -> Model
    -> ( Model, Effect Msg )
update _ _ msg model =
    case msg of
        CT_Tick time ->
            let
                task =
                    case model.task of
                        Timer contraction ->
                            Timer (newContraction contraction.start time)

                        _ ->
                            model.task
            in
            ( { model | now = Just time, task = task }, Effect.none )

        CT_AdjustTimeZone zone ->
            ( { model | zone = zone }, Effect.none )

        CT_AdjustEndianness endianness ->
            ( { model | endianness = Just endianness }, Effect.none )

        CT_InitTimer time ->
            ( { model | task = Timer (newContraction time time) }
            , Effect.none
            )

        LoadContractions json ->
            ( case D.decodeString decodeContractionTimer json of
                Ok decodedModel ->
                    decodedModel

                Err _ ->
                    emptyModel
            , Effect.none
            )

        CT_Start ->
            case model.now of
                Just now ->
                    ( { model | task = Timer (newContraction now now) }
                    , Effect.fromCmd (Task.perform CT_InitTimer Time.now)
                    )

                Nothing ->
                    ( model, Effect.none )

        CT_Stop ->
            let
                contractions =
                    case model.task of
                        Timer timer ->
                            Array.push (newContraction timer.start timer.end) model.contractions

                        Idle ->
                            model.contractions
            in
            ( { model | task = Idle, contractions = contractions }, Effect.none )

        CT_Delete index ->
            ( { model
                | contractions =
                    Array.append
                        (slice 0 index model.contractions)
                        (slice (index + 1) (Array.length model.contractions) model.contractions)
              }
            , Effect.none
            )

        CT_ConfirmReset ->
            ( { model | modalView = Confirm }, Effect.none )

        CT_Reset ->
            ( { model | contractions = Array.empty, modalView = None }, Effect.none )

        CT_Add ->
            case model.now of
                Just now ->
                    ( { model
                        | modalView =
                            Edit
                                Nothing
                                (newContraction now now)
                      }
                    , Effect.none
                    )

                Nothing ->
                    ( model, Effect.none )

        CT_Edit index ->
            case Array.get index model.contractions of
                Just contraction ->
                    ( { model | modalView = Edit (Just index) contraction }, Effect.none )

                Nothing ->
                    ( model, Effect.none )

        CT_Save ->
            let
                contractions =
                    case model.modalView of
                        Edit idxMaybe contraction ->
                            case idxMaybe of
                                Just idx ->
                                    Array.push
                                        contraction
                                        (Array.append
                                            (slice 0 idx model.contractions)
                                            (slice
                                                (idx + 1)
                                                (Array.length model.contractions)
                                                model.contractions
                                            )
                                        )

                                Nothing ->
                                    Array.push contraction model.contractions

                        _ ->
                            model.contractions
            in
            ( { model | contractions = contractions, modalView = None }, Effect.none )

        CT_ShadowStart start ->
            let
                newViewMaybe =
                    case model.modalView of
                        Edit idx contraction ->
                            Just
                                (Edit idx
                                    (newContraction
                                        (fromInputDateTime start)
                                        contraction.end
                                    )
                                )

                        _ ->
                            Nothing
            in
            case newViewMaybe of
                Just newView ->
                    ( { model | modalView = newView }, Effect.none )

                Nothing ->
                    ( model, Effect.none )

        CT_ToggleCTList ->
            ( { model | showTable = not model.showTable }, Effect.none )

        CT_ShadowEnd end ->
            let
                newViewMaybe =
                    case model.modalView of
                        Edit idx contraction ->
                            Just
                                (Edit idx
                                    (newContraction
                                        contraction.start
                                        (fromInputDateTime end)
                                    )
                                )

                        _ ->
                            Nothing
            in
            case newViewMaybe of
                Just newView ->
                    ( { model | modalView = newView }, Effect.none )

                Nothing ->
                    ( model, Effect.none )

        CT_DownloadContractions ->
            ( model, Effect.fromCmd (Download.bytes "contractions.csv" "text/csv" (getCsvData model)) )

        CT_Cancel ->
            ( { model | modalView = None }, Effect.none )

        _ ->
            ( model, Effect.none )

subscriptions :
    RouteParams
    -> UrlPath
    -> Shared.Model
    -> Model
    -> Sub Msg
subscriptions _ _ _ _ =
    Sub.batch
        [ Time.every 1000 CT_Tick
        , loadContractions LoadContractions
        ]

type alias Data =
    {}

type alias ActionData =
    {}

data :
    RouteParams
    -> Request
    -> BackendTask FatalError (Server.Response.Response Data ErrorPage)
data _ _ =
    BackendTask.succeed
        (Server.Response.render
            {}
        )

head : App Data ActionData RouteParams -> List Head.Tag
head _ =
    []

view :
    App Data ActionData RouteParams
    -> Shared.Model
    -> Model
    -> View (PagesMsg Msg)
view _ _ model =
    let
        statsRow =
            case model.now of
                Just now ->
                    createStatsRow now model.contractions

                Nothing ->
                    div [] [ text "Loading..." ]
    in
    { title = "About"
    , body =
        [ Html.Styled.toUnstyled
            (div
                [ css [ textAlign center ] ]
                [ statsRow
                , hr [] []
                , contractionGraph model
                , br [] []
                , div [ css [ displayFlex, justifyContent spaceAround, alignItems start ] ]
                    [ recordButton model
                    , contractionTable model
                    ]
                , modal model
                ]
            )
        ]
    }

contractionGraph : Model -> Html msg
contractionGraph model =
    div [ css [ maxWidth (px 650), margin auto ] ]
        [ Html.Styled.fromUnstyled
            (C.chart
                [ CA.height 150
                , CA.width 600
                , CA.margin { top = 10, bottom = 20, right = 40, left = 20 }
                , CA.range
                    [ CA.lowest -30 CA.exactly
                    , CA.highest 0 CA.exactly
                    ]
                , CA.domain
                    [ CA.lowest 0 CA.orLower
                    , CA.highest 90 CA.exactly
                    ]
                ]
                [ C.xLabels [ CA.format (\num -> String.fromFloat num ++ "m") ]
                , C.yTicks []
                , C.yLabels [ CA.withGrid, CA.flip, CA.hideOverflow ]
                , C.series .elapsed
                    [ C.scatter .duration
                        [ CA.opacity 0.2
                        , CA.borderWidth 1
                        , CA.color CA.yellow
                        , CA.border CA.darkYellow
                        , CA.size 150
                        ]
                    ]
                    (getGraphData model)
                , C.eachDot <|
                    \p dot ->
                        [ C.label
                            [ CA.moveDown 6, CA.color (CI.getColor dot) ]
                            [ S.text (String.fromInt (Basics.round (CI.getData dot).duration) ++ "s") ]
                            (CI.getCenter p dot)
                        ]
                , C.withPlane <|
                    \p ->
                        [ C.rect
                            [ CA.x1 p.x.min
                            , CA.y1 55
                            , CA.x2 p.x.max
                            , CA.y2 p.y.max
                            , CA.color CA.green
                            , CA.opacity 0.3
                            , CA.borderWidth 0
                            ]
                        ]
                ]
            )
        ]

getGraphData : Model -> List ContractionGraphed
getGraphData model =
    case model.now of
        Just now ->
            List.map (newContractionGraphed now) (Array.toList model.contractions)

        Nothing ->
            []

getCsvData : Model -> Bytes
getCsvData model =
    let
        contractionArray =
            Array.toList (Array.map (bytesEncodeContraction model.zone) model.contractions)
    in
    Encode.encode
        (sequence
            (string "Start,End,Duration(ms)\n"
                :: contractionArray
            )
        )

bytesEncodeContraction : Zone -> Contraction -> Encode.Encoder
bytesEncodeContraction zone contraction =
    sequence
        [ string (toDateClock zone contraction.start ++ ",")
        , string (toDateClock zone contraction.end ++ ",")
        , string (String.fromInt contraction.duration ++ "\n")
        ]

contractionTable : Model -> Html (PagesMsg Msg)
contractionTable model =
    let
        total =
            Array.length model.contractions

        tableDisplay =
            if model.showTable then
                display block

            else
                display none

        toggleButton =
            if not model.showTable then
                faButton theme.text (PagesMsg.fromMsg CT_ToggleCTList) "fa-regular fa-square-caret-down"

            else
                faButton theme.text (PagesMsg.fromMsg CT_ToggleCTList) "fa-regular fa-square-caret-up"
    in
    div [ css [ displayFlex, justifyContent center, flexDirection column ] ]
        [ div [ css [ displayFlex, justifyContent center, alignItems center ] ]
            [ toggleButton
            , div [ css [ width (px 5) ] ] []
            , text ("Contractions (" ++ String.fromInt total ++ ")")
            ]
        , div
            [ css [ tableDisplay ] ]
            [ Html.Styled.table
                []
                (List.append
                    (List.indexedMap
                        (createZonedRow model.zone)
                        (Array.toList model.contractions)
                    )
                    [ thead []
                        [ tr [ css [ width (pct 100) ] ]
                            [ th [ css [ paddingRight (px 20), paddingLeft (px 20) ] ]
                                [ div [ css [ displayFlex, width (px 60), justifyContent spaceBetween ] ]
                                    [ faButton theme.text (PagesMsg.fromMsg CT_ConfirmReset) "fa-solid fa-arrows-rotate"
                                    , faButton theme.text (PagesMsg.fromMsg CT_Add) "fa-solid fa-plus"
                                    , faButton theme.text (PagesMsg.fromMsg CT_DownloadContractions) "fa-solid fa-download"
                                    ]
                                ]
                            , th [ css [ paddingRight (px 20), paddingLeft (px 20) ] ] [ text "Start" ]
                            , th [ css [ paddingRight (px 20), paddingLeft (px 20) ] ] [ text "End" ]
                            , th [ css [ paddingRight (px 20), paddingLeft (px 20) ] ] [ text "Sec." ]
                            ]
                        ]
                    ]
                )
            ]
        ]

modal : Model -> Html (PagesMsg Msg)
modal model =
    let
        modalDisplay =
            case model.modalView of
                Edit _ _ ->
                    displayFlex

                Confirm ->
                    displayFlex

                _ ->
                    display none
    in
    div
        [ css
            [ modalDisplay
            , position absolute
            , top (px 0)
            , left (px 0)
            , height (pct 100)
            , width (pct 100)
            , backgroundColor (rgba 1 1 1 0.5)
            ]
        ]
        [ div
            [ css
                [ backgroundColor theme.background
                , maxWidth fitContent
                , margin auto
                , padding (px 25)
                , borderRadius (px 6)
                ]
            ]
            [ contractionEdit model
            , deleteConfirm model
            ]
        ]

contractionEdit : Model -> Html (PagesMsg Msg)
contractionEdit model =
    let
        editDisplay =
            case model.modalView of
                Edit _ _ ->
                    display block

                _ ->
                    display none
    in
    case model.modalView of
        Edit _ contraction ->
            div [ css [ editDisplay ] ]
                [ div [ css [ textAlign left, maxWidth fitContent, margin auto ] ]
                    [ label [] [ text "Contraction Start" ]
                    , br [] []
                    , input
                        [ type_ "datetime-local"
                        , value (toInputDateTime model.zone contraction.start)
                        , onInput (\s -> PagesMsg.fromMsg (CT_ShadowStart s))
                        ]
                        []
                    , br [] []
                    , br [] []
                    , label [] [ text "Contraction End" ]
                    , br [] []
                    , input
                        [ type_ "datetime-local"
                        , value (toInputDateTime model.zone contraction.end)
                        , onInput (\s -> PagesMsg.fromMsg (CT_ShadowEnd s))
                        ]
                        []
                    , br [] []
                    , br [] []
                    , div [ css [ displayFlex, justifyContent spaceBetween ] ]
                        [ faButton theme.secondary (PagesMsg.fromMsg CT_Cancel) "fa-solid fa-ban"
                        , faButton theme.primary (PagesMsg.fromMsg CT_Save) "fa-solid fa-save"
                        ]
                    ]
                ]

        _ ->
            div [] []

createZonedRow : Time.Zone -> Int -> Contraction -> Html (PagesMsg Msg)
createZonedRow zone index contraction =
    tr [ css [ width (pct 100), borderTop3 (px 1) solid (rgb 110 11 11) ] ]
        [ td []
            [ div
                [ css
                    [ displayFlex
                    , width (px 60)
                    , justifyContent spaceAround
                    , margin auto
                    ]
                ]
                [ faButton theme.text (PagesMsg.fromMsg (CT_Delete index)) "fa-regular fa-trash-can"
                , faButton theme.text (PagesMsg.fromMsg (CT_Edit index)) "fa-regular fa-edit"
                ]
            ]
        , td [] [ text (toClock zone contraction.start) ]
        , td [] [ text (toClock zone contraction.end) ]
        , td [] [ text (String.fromInt (contraction.duration // 1000)) ]
        ]

recordButton : Model -> Html (PagesMsg Msg)
recordButton model =
    let
        diff =
            case model.task of
                Timer timer ->
                    formatMillisTime timer.duration

                Idle ->
                    ""

        ( cmd, cmdLabel ) =
            case model.task of
                Idle ->
                    ( PagesMsg.fromMsg CT_Start, "Start" )

                Timer _ ->
                    ( PagesMsg.fromMsg CT_Stop, "Stop" )
    in
    div
        [ onClick cmd
        , css
            [ cursor pointer
            , height (px 100)
            , width (px 100)
            , backgroundColor theme.secondary
            , displayFlex
            , justifyContent center
            , alignItems center
            , textAlign center
            , borderRadius (px 50)
            , boxShadow4 (px 0) (px 0) (px 9) (rgb 0 0 0)
            , active
                [ boxShadow4 (px 0) (px 0) (px 3) (rgb 0 0 0)
                ]
            ]
        ]
        [ text cmdLabel
        , br [] []
        , text diff
        ]

deleteConfirm : Model -> Html (PagesMsg Msg)
deleteConfirm model =
    let
        deleteConfirmDisplay =
            case model.modalView of
                Confirm ->
                    display block

                _ ->
                    display none
    in
    div [ css [ deleteConfirmDisplay ] ]
        [ div [ css [ textAlign left, maxWidth fitContent, margin auto ] ]
            [ text "Are you sure you want to delete all contractions?"
            , br [] []
            , br [] []
            , div [ css [ displayFlex, justifyContent spaceAround ] ]
                [ faButton theme.secondary (PagesMsg.fromMsg CT_Cancel) "fa-solid fa-ban"
                , faButton theme.primary (PagesMsg.fromMsg CT_Reset) "fa-solid fa-save"
                ]
            ]
        ]

createStatsRow : Time.Posix -> Array Contraction -> Html.Styled.Html msg
createStatsRow now contractions =
    let
        targetContractions =
            Array.fromList <|
                List.sortBy
                    getEndMillis
                    (Array.toList
                        (Array.filter (inPeriod now) contractions)
                    )

        firstContractions =
            Array.toList <| slice 0 (Array.length targetContractions - 1) targetContractions

        nextContractions =
            Array.toList <| slice 1 (Array.length targetContractions) targetContractions

        contractionHead =
            let
                maybeHead =
                    Array.get 0 targetContractions
            in
            case maybeHead of
                Just justHead ->
                    Time.posixToMillis justHead.end

                Nothing ->
                    0

        tail =
            let
                maybeTail =
                    Array.get (Array.length targetContractions - 1) targetContractions
            in
            case maybeTail of
                Just justTail ->
                    Time.posixToMillis justTail.end

                Nothing ->
                    0

        total =
            Array.length targetContractions

        ( totalTimeMin, _ ) =
            millisToMinSec (tail - contractionHead)

        totalTimeHr =
            roundToFigures 1 (toFloat totalTimeMin / 60.0)

        ( avgIntervalMin, avgIntervalSec ) =
            millisToMinSec
                (abs
                    (List.sum
                        (List.map2 (-)
                            (List.map getEndMillis firstContractions)
                            (List.map getEndMillis nextContractions)
                        )
                    )
                    // (total - 1)
                )

        avgIntervalMinAccu =
            roundToFigures 1 (toFloat avgIntervalMin + (toFloat avgIntervalSec / 60.0))

        ( durationMin, durationSec ) =
            millisToMinSec
                ((List.sum <|
                    Array.toList <|
                        Array.map getDuration targetContractions
                 )
                    // total
                )

        durationMinAccu =
            roundToFigures 1 (toFloat durationMin + (toFloat durationSec / 60.0))

        stage =
            if
                (avgIntervalMinAccu
                    >= 4.9
                    && avgIntervalMinAccu
                    <= 5.1
                )
                    && durationMinAccu
                    >= 0.9
                    && totalTimeHr
                    >= 0.9
            then
                div
                    [ css
                        [ display inlineBlock
                        , marginRight (px 5)
                        , color theme.primary
                        ]
                    ]
                    [ text "Active" ]

            else
                div
                    [ css
                        [ display inlineBlock
                        , marginRight (px 5)
                        ]
                    ]
                    [ text "Latent" ]
    in
    div []
        [ stage
        , div [ css [ display inlineBlock ] ]
            [ text
                (" | Every "
                    ++ String.fromFloat avgIntervalMinAccu
                    ++ "m lasting "
                    ++ String.fromFloat durationMinAccu
                    ++ "m over "
                    ++ String.fromFloat totalTimeHr
                    ++ "hr"
                )
            ]
        , sup []
            [ text " "
            , OWBTheme.link
                [ Html.Styled.Attributes.target "_blank"
                , href "https://biologyinsights.com/what-is-the-511-rule-in-pregnancy/"
                ]
                [ text "511?" ]
            ]
        ]

roundToFigures : Int -> Float -> Float
roundToFigures figures num =
    let
        factor =
            10.0 ^ toFloat figures
    in
    toFloat (Basics.round (num * factor)) / factor

millisToMinSec : Int -> ( Int, Int )
millisToMinSec millis =
    let
        min =
            millis // 1000 // 60

        sec =
            (millis // 1000) - (min * 60)
    in
    ( min, sec )

inPeriod : Time.Posix -> Contraction -> Bool
inPeriod now contraction =
    if Time.posixToMillis contraction.end > (Time.posixToMillis now - 1 * 60 * 60 * 1000) then
        True

    else
        False

action :
    RouteParams
    -> Request
    -> BackendTask.BackendTask FatalError.FatalError (Server.Response.Response ActionData ErrorPage.ErrorPage)
action _ _ =
    BackendTask.succeed (Server.Response.render {})

encodeContractionTimer : Model -> E.Value
encodeContractionTimer model =
    E.object
        [ ( "contractions"
          , E.array
                (\a -> a)
                (Array.map encodeContraction model.contractions)
          )
        ]

encodeContraction : Contraction -> E.Value
encodeContraction contraction =
    E.object
        [ ( "start", E.int (Time.posixToMillis contraction.start) )
        , ( "end", E.int (Time.posixToMillis contraction.end) )
        , ( "duration", E.int contraction.duration )
        ]

decodeContractionTimer : D.Decoder Model
decodeContractionTimer =
    D.map7 Model
        (D.field "contractions" (array decodeContraction))
        (succeed Nothing)
        (succeed Time.utc)
        (succeed Nothing)
        (succeed Idle)
        (succeed False)
        (succeed None)

decodeContraction : D.Decoder Contraction
decodeContraction =
    D.map3 Contraction
        (D.field "start" (D.int |> andThen (\val -> succeed (Time.millisToPosix val))))
        (D.field "end" (D.int |> andThen (\val -> succeed (Time.millisToPosix val))))
        (D.field "duration" D.int)
