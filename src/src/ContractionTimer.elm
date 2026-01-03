module ContractionTimer exposing (..)

import Chart as C
import Chart.Attributes as CA
import Css exposing (..)
import FontAwesome.Regular exposing (edit)
import FontAwesome.Solid
import Html.Styled exposing (..)
import Html.Styled.Attributes exposing (css)
import Html.Styled.Events exposing (onClick)
import List.Extra
import Messages exposing (..)
import OWBTheme exposing (..)
import Task
import Time


type alias ContractionGraphed =
    { elapsed : Float, duration : Float }


newContractionGraphed : Time.Posix -> Contraction -> ContractionGraphed
newContractionGraphed now contraction =
    ContractionGraphed
        (toFloat (Time.posixToMillis contraction.end - Time.posixToMillis now) / 1000 / 60)
        (toFloat contraction.duration / 1000 / 60)


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
    { contractions : List Contraction
    , now : Maybe Time.Posix
    , zone : Time.Zone
    , task : ModelTask
    , view : ModelView
    }


type ModelTask
    = Timer Contraction
    | Idle


type ModelView
    = Graph
    | Table


init : () -> ( Model, Cmd Message )
init _ =
    ( Model [] Nothing Time.utc Idle Graph
    , Task.perform CT_AdjustTimeZone Time.here
    )


update : Message -> Model -> ( Model, Cmd Message )
update msg model =
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
            ( { model | now = Just time, task = task }, Cmd.none )

        CT_AdjustTimeZone zone ->
            ( { model | zone = zone }, Cmd.none )

        CT_InitTimer time ->
            ( { model | task = Timer (newContraction time time) }
            , Cmd.none
            )

        CT_Start ->
            case model.now of
                Just now ->
                    ( { model | task = Timer (newContraction now now) }
                    , Task.perform CT_InitTimer Time.now
                    )

                Nothing ->
                    ( model, Cmd.none )

        CT_Stop ->
            let
                contractions =
                    case model.task of
                        Timer timer ->
                            newContraction timer.start timer.end :: model.contractions

                        Idle ->
                            model.contractions
            in
            ( { model | task = Idle, contractions = contractions }, Cmd.none )

        CT_ToggleView ->
            case model.view of
                Table ->
                    ( { model | view = Graph }, Cmd.none )

                Graph ->
                    ( { model | view = Table }, Cmd.none )

        CT_Delete index ->
            ( { model | contractions = List.Extra.removeAt index model.contractions }, Cmd.none )

        _ ->
            ( model, Cmd.none )


subscriptions : Model -> Sub Message
subscriptions model =
    Time.every 1000 CT_Tick


view : Model -> ( String, Html Message )
view model =
    let
        statsRow =
            case model.now of
                Just now ->
                    createStatsRow now model.contractions

                Nothing ->
                    div [] [ text "Loading..." ]

        body =
            div
                [ css [ textAlign center ]
                ]
                [ statsRow
                , hr [] []
                , contractionGraph model
                , contractionTable model
                , br [] []
                , div [ css [ displayFlex, justifyContent center, alignItems end ] ]
                    [ recordButton model
                    , faButton CT_ToggleView
                        (if model.view == Graph then
                            edit

                         else
                            FontAwesome.Solid.table
                        )
                    ]
                ]
    in
    ( "Contraction Timer", body )


contractionGraph : Model -> Html Message
contractionGraph model =
    let
        graphDisplay =
            case model.view of
                Graph ->
                    display block

                Table ->
                    display none
    in
    div [ css [ maxWidth (px 650), margin auto, graphDisplay ] ]
        [ Html.Styled.fromUnstyled
            (C.chart
                [ CA.height 150
                , CA.width 600
                , CA.margin { top = 10, bottom = 20, right = 40, left = 20 }
                , CA.range
                    [ CA.lowest -60 CA.exactly
                    , CA.highest 0 CA.exactly
                    ]
                , CA.domain
                    [ CA.lowest 0 CA.orLower
                    , CA.highest 2 CA.exactly
                    ]
                ]
                [ C.xLabels [ CA.withGrid ]
                , C.yTicks [ CA.flip ]
                , C.yLabels [ CA.withGrid, CA.flip ]
                , C.series .elapsed
                    [ C.scatter .duration []
                    ]
                    (getGraphData model)
                ]
            )
        ]


getGraphData : Model -> List ContractionGraphed
getGraphData model =
    case model.now of
        Just now ->
            List.map (newContractionGraphed now) model.contractions

        Nothing ->
            []


contractionTable : Model -> Html Message
contractionTable model =
    let
        tableDisplay =
            case model.view of
                Graph ->
                    display none

                Table ->
                    display block
    in
    div [ css [ displayFlex, justifyContent center ] ]
        [ Html.Styled.table
            [ css [ tableDisplay ] ]
            (List.append
                (List.indexedMap
                    (createZonedRow model.zone)
                    model.contractions
                )
                [ thead []
                    [ tr [ css [ width (pct 100) ] ]
                        [ th [ css [ paddingRight (px 20), paddingLeft (px 20) ] ] []
                        , th [ css [ paddingRight (px 20), paddingLeft (px 20) ] ] [ text "Start" ]
                        , th [ css [ paddingRight (px 20), paddingLeft (px 20) ] ] [ text "End" ]
                        , th [ css [ paddingRight (px 20), paddingLeft (px 20) ] ] [ text "Sec." ]
                        ]
                    ]
                ]
            )
        ]


createZonedRow : Time.Zone -> Int -> Contraction -> Html.Styled.Html Message
createZonedRow zone index contraction =
    tr [ css [ width (pct 100) ] ]
        [ td [] [ faButton (CT_Delete index) FontAwesome.Regular.trashCan ]
        , td [] [ text (formatPosixTime zone contraction.start) ]
        , td [] [ text (formatPosixTime zone contraction.end) ]
        , td [] [ text (String.fromInt (contraction.duration // 1000)) ]
        ]


recordButton : Model -> Html Message
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
                    ( CT_Start, "Start" )

                Timer _ ->
                    ( CT_Stop, "Stop" )
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


createStatsRow : Time.Posix -> List Contraction -> Html.Styled.Html Message
createStatsRow now contractions =
    let
        targetContractions =
            List.filter (inPeriod now) contractions

        firstContractions =
            List.tail (List.reverse targetContractions)

        nextContractions =
            List.tail targetContractions

        total =
            List.length targetContractions

        intervalSum =
            case firstContractions of
                Just firstList ->
                    case nextContractions of
                        Just nextList ->
                            List.sum
                                (List.map2 (-)
                                    (List.map getEndMillis (List.reverse firstList))
                                    (List.map getEndMillis nextList)
                                )

                        Nothing ->
                            0

                Nothing ->
                    0

        durationSum =
            List.sum (List.map getDuration targetContractions)
    in
    Html.Styled.table
        [ css [ width (pct 100), maxWidth (px 650), margin auto ]
        ]
        [ tr []
            [ td []
                [ text "Period: 1hr"
                ]
            , td []
                [ text ("Total: " ++ String.fromInt total)
                ]
            , td []
                [ text ("Avg. Interval (s): " ++ String.fromInt (intervalSum // total // 1000))
                ]
            , td []
                [ text ("Avg. Duration (s): " ++ String.fromInt (durationSum // total // 1000))
                ]
            ]
        ]


inPeriod : Time.Posix -> Contraction -> Bool
inPeriod now contraction =
    if Time.posixToMillis contraction.end > (Time.posixToMillis now - 1 * 60 * 60 * 1000) then
        True

    else
        False


formatPosixTime : Time.Zone -> Time.Posix -> String
formatPosixTime zone time =
    let
        hour =
            Time.toHour zone time

        minute =
            Time.toMinute zone time

        second =
            Time.toSecond zone time
    in
    String.padLeft 2 '0' (String.fromInt hour)
        ++ ":"
        ++ String.padLeft 2 '0' (String.fromInt minute)
        ++ ":"
        ++ String.padLeft 2 '0' (String.fromInt second)


formatMillisTime : Int -> String
formatMillisTime millis =
    let
        seconds =
            millis // 1000

        second_only =
            modBy 60 seconds

        minute =
            seconds // 60

        minutes_only =
            modBy 60 minute
    in
    String.padLeft 2 '0' (String.fromInt minutes_only)
        ++ ":"
        ++ String.padLeft 2 '0' (String.fromInt second_only)
