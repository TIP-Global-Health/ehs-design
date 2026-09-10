module Chart exposing (Series, view)

{-| A generic, reusable multi-series trend chart drawn as inline SVG — the
shared component both dashboards use (issue #2233). It is parameterised by an
arbitrary set of monthly series (0–100), so it plots any KPI without knowing
what the KPI is.

Series are distinguished by colour AND line style (solid / dashed / dotted), so
they stay readable without relying on colour alone. The whole chart is exposed
to assistive tech as a single labelled image.
-}

import Html exposing (Html)
import Html.Attributes as HA
import Svg exposing (Svg)
import Svg.Attributes as SA


type alias Series =
    { color : String
    , label : String
    , dash : String -- stroke-dasharray value ("" = solid)
    , points : List Float -- 12 monthly values, 0..100
    }



-- PLOT GEOMETRY (SVG user units; the svg scales to its container width)


plotLeft : Float
plotLeft =
    46


plotRight : Float
plotRight =
    556


plotTop : Float
plotTop =
    14


plotBottom : Float
plotBottom =
    216


plotWidth : Float
plotWidth =
    plotRight - plotLeft


plotHeight : Float
plotHeight =
    plotBottom - plotTop


xAt : Int -> Float
xAt i =
    plotLeft + toFloat i * (plotWidth / 11)


yAt : Float -> Float
yAt v =
    plotBottom - (v / 100) * plotHeight


f : Float -> String
f =
    String.fromFloat



-- VIEW


view : { xLabels : List String, series : List Series, ariaLabel : String } -> Html msg
view { xLabels, series, ariaLabel } =
    Svg.svg
        [ SA.viewBox "0 0 580 250"
        , SA.class "w-full h-auto"
        , HA.attribute "role" "img"
        , HA.attribute "aria-label" ariaLabel
        , HA.attribute "preserveAspectRatio" "xMidYMid meet"
        ]
        (gridAndYAxis
            ++ List.map xLabel (List.indexedMap Tuple.pair xLabels)
            ++ List.concatMap seriesLayer series
        )


{-| Horizontal gridlines and y-axis value labels at 0/20/40/60/80/100. -}
gridAndYAxis : List (Svg msg)
gridAndYAxis =
    [ 0, 20, 40, 60, 80, 100 ]
        |> List.concatMap
            (\v ->
                let
                    y =
                        yAt (toFloat v)
                in
                [ Svg.line
                    [ SA.x1 (f plotLeft)
                    , SA.y1 (f y)
                    , SA.x2 (f plotRight)
                    , SA.y2 (f y)
                    , SA.stroke "#E2E8F0"
                    , SA.strokeWidth "1"
                    ]
                    []
                , Svg.text_
                    [ SA.x (f (plotLeft - 10))
                    , SA.y (f (y + 4))
                    , SA.textAnchor "end"
                    , SA.fontSize "12"
                    , SA.fill "#475569"
                    ]
                    [ Svg.text (String.fromInt v) ]
                ]
            )


xLabel : ( Int, String ) -> Svg msg
xLabel ( i, label ) =
    Svg.text_
        [ SA.x (f (xAt i))
        , SA.y (f (plotBottom + 22))
        , SA.textAnchor "middle"
        , SA.fontSize "12"
        , SA.fill "#334155"
        ]
        [ Svg.text label ]


{-| A polyline plus circular markers for one series. -}
seriesLayer : Series -> List (Svg msg)
seriesLayer s =
    let
        coords =
            List.indexedMap (\i v -> ( xAt i, yAt v )) s.points

        pointStr =
            coords
                |> List.map (\( x, y ) -> f x ++ "," ++ f y)
                |> String.join " "

        marker ( x, y ) =
            Svg.circle
                [ SA.cx (f x)
                , SA.cy (f y)
                , SA.r "3.5"
                , SA.fill s.color
                ]
                []
    in
    Svg.polyline
        [ SA.points pointStr
        , SA.fill "none"
        , SA.stroke s.color
        , SA.strokeWidth "2.5"
        , SA.strokeDasharray s.dash
        , SA.strokeLinejoin "round"
        , SA.strokeLinecap "round"
        ]
        []
        :: List.map marker coords
