module TimeUtils exposing (..)

import Time exposing (Month(..), Zone)
import String exposing (split)

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

toNumberMonth : Month -> String
toNumberMonth month =
    case month of
        Jan ->
            "01"

        Feb ->
            "02"

        Mar ->
            "03"

        Apr ->
            "04"

        May ->
            "05"

        Jun ->
            "06"

        Jul ->
            "07"

        Aug ->
            "08"

        Sep ->
            "09"

        Oct ->
            "10"

        Nov ->
            "11"

        Dec ->
            "12"

toDateClock : Zone -> Time.Posix -> String
toDateClock zone time =
    toDate zone time ++ " " ++ toClock zone time

toInputDateTime : Zone -> Time.Posix -> String
toInputDateTime zone time =
    let
        day =
            Time.toDay zone time

        month =
            Time.toMonth zone time

        year =
            Time.toYear zone time
    in
    String.fromInt year
        ++ "-"
        ++ toNumberMonth month
        ++ "-"
        ++ String.padLeft 2 '0' (String.fromInt day)
        ++ "T"
        ++ toClock zone time

fromInputDateTime : String -> Time.Posix
fromInputDateTime time =
    let
        datetime =
            split "T" time

        dateLst =
            Maybe.map
                (\dt -> List.map stringToInt (split "-" dt))
                (List.head datetime)

        timeLst =
            Maybe.map
                (\n ->
                    Maybe.map
                        (\tm -> List.map stringToInt (split ":" tm))
                        (List.head n)
                )
                (List.tail datetime)

        dateMillis =
            case dateLst of
                Just [ year, month, day ] ->
                    (daysInYearSinceUnix year * 24 * 60 * 60 * 1000)
                        + (daysBeforeMonth year month * 24 * 60 * 60 * 1000)
                        + ((day - 1) * 24 * 60 * 60 * 1000)

                _ ->
                    0

        timeMillis =
            case timeLst of
                Just inner ->
                    case inner of
                        Just [ hour, min, sec ] ->
                            (hour * 60 * 60 * 1000)
                                + (min * 60 * 1000)
                                + (sec * 1000)

                        Just [ hour, min ] ->
                            (hour * 60 * 60 * 1000)
                                + (min * 60 * 1000)

                        Just [ hour ] ->
                            hour * 60 * 60 * 1000

                        _ ->
                            0

                _ ->
                    0
    in
    Time.millisToPosix (dateMillis + timeMillis)

stringToInt : String -> Int
stringToInt string =
    case String.toInt string of
        Just int ->
            int

        Nothing ->
            0

daysInYearSinceUnix : Int -> Int
daysInYearSinceUnix year =
    let
        yearsTot =
            year - 1970

        leapYears =
            floor (toFloat (yearsTot + 2) / 4)

        years =
            yearsTot - leapYears
    in
    (years * 365) + (leapYears * 366)

daysBeforeMonth : Int -> Int -> Int
daysBeforeMonth year month =
    let
        feb =
            if modBy year 4 == 0 then
                29

            else
                28
    in
    case month of
        1 ->
            0

        2 ->
            31

        3 ->
            31 + feb

        4 ->
            31 + feb + 31

        5 ->
            31 + feb + 31 + 30

        6 ->
            31 + feb + 31 + 30 + 31

        7 ->
            31 + feb + 31 + 30 + 31 + 30

        8 ->
            31 + feb + 31 + 30 + 31 + 30 + 31

        9 ->
            31 + feb + 31 + 30 + 31 + 30 + 31 + 31

        10 ->
            31 + feb + 31 + 30 + 31 + 30 + 31 + 31 + 30

        11 ->
            31 + feb + 31 + 30 + 31 + 30 + 31 + 31 + 30 + 31

        12 ->
            31 + feb + 31 + 30 + 31 + 30 + 31 + 31 + 30 + 31 + 30

        _ ->
            0

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
