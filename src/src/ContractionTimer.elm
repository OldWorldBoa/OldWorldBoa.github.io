module ContractionTimer exposing (..)

import Array exposing (Array, append, slice)
import Chart as C
import Chart.Attributes as CA
import Chart.Item as CI
import Css exposing (..)
import FontAwesome.Regular exposing (edit)
import FontAwesome.Solid
import Html.Styled exposing (..)
import Html.Styled.Attributes exposing (css, placeholder, type_, value)
import Html.Styled.Events exposing (onClick)
import Json.Decode as D exposing (andThen, array, succeed)
import Json.Encode as E
import Messages exposing (..)
import OWBTheme exposing (..)
import Svg as S
import Task
import Time exposing (Month(..))


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
    , task : ModelTask
    , view : ModelView
    }


emptyModel : Model
emptyModel =
    Model Array.empty Nothing Time.utc Idle Graph


type ModelTask
    = Timer Contraction
    | Idle


type ModelView
    = Graph
    | Table
    | Edit (Maybe Int) Contraction


init : () -> ( Model, Cmd Message )
init _ =
    ( emptyModel, Task.perform CT_AdjustTimeZone Time.here )


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
                            Array.push (newContraction timer.start timer.end) model.contractions

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

                Edit _ _ ->
                    ( model, Cmd.none )

        CT_Delete index ->
            ( { model
                | contractions =
                    append
                        (slice 0 index model.contractions)
                        (slice (index + 1) (Array.length model.contractions) model.contractions)
              }
            , Cmd.none
            )

        CT_Reset ->
            ( { model | contractions = Array.empty }, Cmd.none )

        CT_Add start end ->
            ( { model
                | view =
                    Edit
                        Nothing
                        (newContraction (Time.millisToPosix start) (Time.millisToPosix end))
              }
            , Cmd.none
            )

        CT_Save index start end ->
            let
                contractions =
                    Array.push
                        (newContraction (Time.millisToPosix start) (Time.millisToPosix end))
                        (Array.append
                            (slice 0 index model.contractions)
                            (slice (index + 1) (Array.length model.contractions) model.contractions)
                        )
            in
            ( { model | contractions = contractions }, Cmd.none )

        CT_Edit index ->
            case Array.get index model.contractions of
                Just contraction ->
                    ( { model | view = Edit (Just index) contraction }, Cmd.none )

                Nothing ->
                    ( model, Cmd.none )

        CT_Cancel ->
            ( { model | view = Graph }, Cmd.none )

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
                [ css [ textAlign center ] ]
                [ statsRow
                , hr [] []
                , contractionGraph model
                , contractionTable model
                , contractionEdit model
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

                _ ->
                    display none
    in
    div [ css [ maxWidth (px 650), margin auto, graphDisplay ] ]
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


contractionTable : Model -> Html Message
contractionTable model =
    let
        tableDisplay =
            case model.view of
                Table ->
                    display block

                _ ->
                    display none
    in
    div [ css [ displayFlex, justifyContent center ] ]
        [ Html.Styled.table
            [ css [ tableDisplay ] ]
            (List.append
                (List.indexedMap
                    (createZonedRow model.zone)
                    (Array.toList model.contractions)
                )
                [ thead []
                    [ tr [ css [ width (pct 100) ] ]
                        [ th [ css [ paddingRight (px 20), paddingLeft (px 20) ] ]
                            [ div [ css [ displayFlex, width (px 60), justifyContent spaceBetween ] ]
                                [ faButton CT_Reset FontAwesome.Solid.arrowsRotate
                                , faButton
                                    (case model.now of
                                        Just time ->
                                            CT_Add
                                                (Time.posixToMillis time)
                                                (Time.posixToMillis time)

                                        Nothing ->
                                            Pass
                                    )
                                    FontAwesome.Solid.plus
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


contractionEdit : Model -> Html.Styled.Html Message
contractionEdit model =
    let
        editDisplay =
            case model.view of
                Edit _ _ ->
                    display block

                _ ->
                    display none
    in
    case model.view of
        Edit idx contraction ->
            div [ css [ editDisplay ] ]
                [ input [ type_ "date", placeholder "from", value "" ] []
                , input [ type_ "date", placeholder "to", value "" ] []
                ]

        _ ->
            div [] []


createZonedRow : Time.Zone -> Int -> Contraction -> Html.Styled.Html Message
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
                [ faButton (CT_Delete index) FontAwesome.Regular.trashCan
                , faButton (CT_Delete index) FontAwesome.Regular.edit
                ]
            ]
        , td [] [ text (toClock zone contraction.start) ]
        , td [] [ text (toClock zone contraction.end) ]
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


createStatsRow : Time.Posix -> Array Contraction -> Html.Styled.Html Message
createStatsRow now contractions =
    let
        targetContractions =
            Array.filter (inPeriod now) contractions

        firstContractions =
            Array.toList <| slice 0 (Array.length targetContractions - 1) targetContractions

        nextContractions =
            Array.toList <| slice 1 (Array.length targetContractions) targetContractions

        total =
            Array.length targetContractions

        intervalSum =
            List.sum
                (List.map2 (-)
                    (List.map getEndMillis (List.reverse firstContractions))
                    (List.map getEndMillis nextContractions)
                )

        durationSum =
            List.sum <| Array.toList <| Array.map getDuration targetContractions
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


toClock : Time.Zone -> Time.Posix -> String
toClock zone time =
    let
        hour =
            Time.toHour zone time

        minute =
            Time.toMinute zone time

        second =
            Time.toSecond zone time
    in
    String.padLeft
        2
        '0'
        (String.fromInt hour)
        ++ ":"
        ++ String.padLeft 2 '0' (String.fromInt minute)
        ++ ":"
        ++ String.padLeft 2 '0' (String.fromInt second)


toDate : Time.Zone -> Time.Posix -> String
toDate zone time =
    let
        day =
            Time.toDay zone time

        month =
            Time.toMonth zone time

        year =
            Time.toYear zone time
    in
    toEnglishMonth month ++ " " ++ String.fromInt day ++ " " ++ String.fromInt year


toEnglishMonth : Month -> String
toEnglishMonth month =
    case month of
        Jan ->
            "Jan"

        Feb ->
            "Feb"

        Mar ->
            "Mar"

        Apr ->
            "Apr"

        May ->
            "May"

        Jun ->
            "Jun"

        Jul ->
            "Jul"

        Aug ->
            "Aug"

        Sep ->
            "Sept"

        Oct ->
            "Oct"

        Nov ->
            "Nov"

        Dec ->
            "Dec"


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
    D.map5 Model
        (D.field "contractions" (array decodeContraction))
        (succeed Nothing)
        (succeed Time.utc)
        (succeed Idle)
        (succeed Graph)


decodeContraction : D.Decoder Contraction
decodeContraction =
    D.map3 Contraction
        (D.field "start" (D.int |> andThen (\val -> succeed (Time.millisToPosix val))))
        (D.field "end" (D.int |> andThen (\val -> succeed (Time.millisToPosix val))))
        (D.field "duration" D.int)
