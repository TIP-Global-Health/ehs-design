module View exposing (view)

{-| Renders the eHS Dashboards mock: a mock view-switcher, the Facility
(Dashboard II) and Program (Dashboard III) dashboards, and the per-KPI
year/month drill-down modal. Colours and layout follow the HealthyStart
mockups, recoloured to eheza's live palette.
-}

import Chart
import Data
import Html exposing (Html, button, div, h1, h2, label, li, option, p, select, span, table, tbody, td, text, th, thead, tr, ul)
import Html.Attributes exposing (attribute, class, classList, for, id, selected, style, title, type_, value)
import Html.Events exposing (onClick, onInput)
import Svg
import Svg.Attributes as SA
import Types
    exposing
        ( Alert
        , Coverage
        , Dashboard(..)
        , Filter
        , Kpi
        , Model
        , Msg(..)
        , Screen(..)
        , Tile
        , Trend(..)
        , YearSel(..)
        , dashboardTitle
        , kpiById
        , yearLabel
        )



-- ROOT


view : Model -> Html Msg
view model =
    let
        dashboard =
            currentDashboard model.screen
    in
    div [ class "mx-auto w-full max-w-[1440px] px-3 py-4 md:px-6" ]
        [ switcher dashboard
        , dashboardView model dashboard
        , case model.screen of
            DrillScreen d kpi ->
                drillModal d kpi

            DashboardScreen _ ->
                text ""
        ]


currentDashboard : Screen -> Dashboard
currentDashboard screen =
    case screen of
        DashboardScreen d ->
            d

        DrillScreen d _ ->
            d



-- MOCK VIEW SWITCHER (stands in for the two real logins we are skipping)


switcher : Dashboard -> Html Msg
switcher active =
    div [ class "mb-3 flex flex-col gap-2 rounded-lg bg-slate-900 px-4 py-2.5 text-white sm:flex-row sm:items-center sm:justify-between" ]
        [ p [ class "text-sm font-semibold" ]
            [ text "eHS Dashboards — interactive mockup" ]
        , div [ class "flex gap-2", attribute "role" "group", attribute "aria-label" "Choose dashboard" ]
            [ switchButton active Facility "Facility view (Dashboard II)"
            , switchButton active Program "Program view (Dashboard III)"
            ]
        ]


switchButton : Dashboard -> Dashboard -> String -> Html Msg
switchButton active target lbl =
    let
        isActive =
            active == target
    in
    button
        [ type_ "button"
        , onClick (SwitchDashboard target)
        , attribute "aria-pressed"
            (if isActive then
                "true"

             else
                "false"
            )
        , class "rounded-md px-3 py-1.5 text-sm font-semibold focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-white"
        , classList
            [ ( "bg-white text-slate-900", isActive )
            , ( "bg-white/10 text-white hover:bg-white/20", not isActive )
            ]
        ]
        [ text lbl ]



-- ONE DASHBOARD


dashboardView : Model -> Dashboard -> Html Msg
dashboardView model dashboard =
    div [ class "overflow-hidden rounded-lg bg-white shadow-sm ring-1 ring-slate-200" ]
        [ banner dashboard
        , div [ class "px-4 py-4 md:px-6" ]
            [ filterRow dashboard (filtersFor model dashboard)
            , tileRow (Data.tilesFor dashboard)
            , div [ class "mt-6 grid grid-cols-1 gap-6 lg:grid-cols-2" ]
                [ leftColumn dashboard
                , rightColumn model dashboard
                ]
            ]
        ]


filtersFor : Model -> Dashboard -> List Filter
filtersFor model dashboard =
    case dashboard of
        Facility ->
            model.facilityFilters

        Program ->
            model.programFilters



-- BANNER


banner : Dashboard -> Html Msg
banner dashboard =
    let
        ( num, subtitle, site ) =
            dashboardTitle dashboard
    in
    div [ class "grid grid-cols-1 items-center gap-3 bg-accent px-4 py-4 text-white md:grid-cols-3 md:px-6" ]
        [ div [ class "flex items-center gap-3" ]
            [ div [ class "flex h-12 w-12 shrink-0 items-center justify-center rounded bg-white/90 text-accent", attribute "aria-hidden" "true" ]
                [ dashboardIcon dashboard ]
            , div []
                [ p [ class "text-xl font-extrabold underline decoration-white/60 underline-offset-4" ] [ text num ]
                , p [ class "text-sm text-white/90" ] [ text subtitle ]
                ]
            ]
        , div [ class "text-center" ]
            [ h1 [ class "border-b border-white/60 pb-1 text-2xl font-extrabold tracking-tight md:text-3xl" ]
                [ text "HealthyStart" ]
            , p [ class "mt-1 text-lg font-semibold" ] [ text site ]
            ]
        , div [ class "flex items-center justify-start gap-6 md:justify-end" ]
            [ bannerAction ExportView "Export"
            , bannerAction PrintView "Print"
            ]
        ]


bannerAction : Msg -> String -> Html Msg
bannerAction msg lbl =
    button
        [ type_ "button"
        , onClick msg
        , class "text-lg font-semibold underline decoration-2 underline-offset-4 hover:text-white/80 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-white"
        ]
        [ text lbl ]


dashboardIcon : Dashboard -> Html msg
dashboardIcon dashboard =
    case dashboard of
        Facility ->
            Svg.svg
                [ SA.viewBox "0 0 24 24", SA.class "h-7 w-7", SA.fill "currentColor" ]
                [ Svg.path [ SA.d "M4 21V7l8-4 8 4v14h-5v-5h-6v5H4Zm7-9h2v-2h2V9h-2V7h-2v2H9v2h2v1Z" ] [] ]

        Program ->
            Svg.svg
                [ SA.viewBox "0 0 24 24", SA.class "h-7 w-7", SA.fill "currentColor" ]
                [ Svg.circle [ SA.cx "12", SA.cy "5", SA.r "2.4" ] []
                , Svg.circle [ SA.cx "5", SA.cy "12", SA.r "2.4" ] []
                , Svg.circle [ SA.cx "19", SA.cy "12", SA.r "2.4" ] []
                , Svg.circle [ SA.cx "12", SA.cy "19", SA.r "2.4" ] []
                , Svg.path [ SA.d "M12 7v10M7 12h10", SA.stroke "currentColor", SA.strokeWidth "1.6" ] []
                ]



-- FILTER ROW


filterRow : Dashboard -> List Filter -> Html Msg
filterRow dashboard filters =
    div [ class "flex flex-wrap items-end gap-x-5 gap-y-3" ]
        (span [ class "rounded bg-accent px-3 py-1 text-sm font-semibold text-white" ] [ text "Filter" ]
            :: List.map (filterControl dashboard) filters
        )


filterControl : Dashboard -> Filter -> Html Msg
filterControl dashboard filter =
    let
        selectId =
            "filter-" ++ dashboardSlug dashboard ++ "-" ++ filter.key
    in
    div [ class "flex flex-col gap-1" ]
        [ label [ for selectId, class "text-sm font-bold text-slate-800" ] [ text filter.label ]
        , select
            [ id selectId
            , class "rounded border border-slate-300 bg-white px-2 py-1.5 text-sm text-slate-900 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-accent"
            , onInput (SetFilter dashboard filter.key)
            ]
            (List.map (\opt -> option [ value opt, selected (opt == filter.selected) ] [ text opt ]) filter.options)
        ]


dashboardSlug : Dashboard -> String
dashboardSlug dashboard =
    case dashboard of
        Facility ->
            "facility"

        Program ->
            "program"



-- SUMMARY TILE ROW


tileRow : List Tile -> Html Msg
tileRow tiles =
    div [ class "mt-4 grid grid-cols-2 gap-2 sm:grid-cols-3 md:grid-cols-5 lg:grid-cols-9" ]
        (List.map tileView tiles)


tileView : Tile -> Html Msg
tileView tile =
    div [ class "flex flex-col overflow-hidden rounded ring-1 ring-slate-200" ]
        [ div [ class "flex min-h-[3.25rem] items-center justify-center bg-accent px-2 py-1.5 text-center text-[11px] font-bold leading-tight text-white" ]
            [ text tile.label ]
        , div [ class "bg-white py-1 text-center text-xl font-extrabold text-accent" ]
            [ text tile.value ]
        ]



-- LEFT COLUMN: KPI BLOCKS + COVERAGE BARS


leftColumn : Dashboard -> Html Msg
leftColumn dashboard =
    div []
        [ div [ class "grid grid-cols-1 gap-4 sm:grid-cols-2 xl:grid-cols-3" ]
            (List.map (kpiBlock dashboard) (Data.kpisFor dashboard))
        , div [ class "mt-6 flex flex-col gap-4" ]
            (List.map coverageBar (Data.coverageFor dashboard))
        ]


kpiBlock : Dashboard -> Kpi -> Html Msg
kpiBlock dashboard kpi =
    button
        [ type_ "button"
        , onClick (OpenDrill dashboard kpi)
        , attribute "aria-label" ("Open month-by-month detail for " ++ kpi.label)
        , class "flex w-full flex-col rounded-lg border border-slate-200 p-3 text-left transition hover:border-accent hover:shadow-sm focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-accent"
        ]
        [ h2 [ class "min-h-[2.5rem] text-sm font-bold leading-tight text-slate-800" ] [ text kpi.label ]
        , div [ class "mt-2 flex items-stretch gap-3 border-t border-slate-100 pt-2" ]
            [ div [ class "flex flex-col" ]
                [ span [ class "text-3xl font-extrabold leading-none text-accent" ] [ text kpi.current ]
                , trendIndicator kpi
                ]
            , div [ class "w-px self-stretch bg-slate-200" ] []
            , div [ class "flex flex-col justify-center gap-1 text-sm" ]
                (targetLine kpi.target
                    :: (case kpi.average of
                            Just avg ->
                                [ averageLine avg ]

                            Nothing ->
                                []
                       )
                )
            ]
        ]


targetLine : String -> Html msg
targetLine v =
    div []
        [ span [ class "font-bold text-accent" ] [ text v ]
        , span [ class "ml-1 text-xs text-slate-600" ] [ text "Prog. Target" ]
        ]


averageLine : String -> Html msg
averageLine v =
    div []
        [ span [ class "font-bold text-accent" ] [ text v ]
        , span [ class "ml-1 text-xs text-slate-600" ] [ text "Int. Site Average" ]
        ]


trendIndicator : Kpi -> Html msg
trendIndicator kpi =
    let
        ( glyph, colorClass ) =
            case kpi.deltaDir of
                Up ->
                    ( "▲", "text-trend-avg" )

                Down ->
                    ( "▼", "text-alert" )
    in
    div [ class "mt-1 flex items-center gap-1" ]
        [ span [ class ("text-xs " ++ colorClass), attribute "aria-hidden" "true" ] [ text glyph ]
        , span [ class "text-xs italic text-slate-600" ] [ text kpi.deltaText ]
        ]


coverageBar : Coverage -> Html msg
coverageBar cov =
    div []
        [ p [ class "mb-1 text-sm" ]
            [ span [ class "font-bold text-accent" ] [ text cov.emphasis ]
            , span [ class "font-semibold text-slate-800" ] [ text cov.label ]
            ]
        , div
            [ class "relative h-6 w-full overflow-hidden rounded bg-bar-track"
            , attribute "role" "img"
            , attribute "aria-label" (cov.emphasis ++ cov.label ++ ": " ++ String.fromInt cov.pct ++ " percent")
            ]
            [ div
                [ class "flex h-full items-center justify-end rounded bg-accent pr-2"
                , style "width" (String.fromInt cov.pct ++ "%")
                ]
                [ span [ class "text-xs font-bold text-white" ] [ text (String.fromInt cov.pct ++ "%") ] ]
            ]
        ]



-- RIGHT COLUMN: TRENDS + CRITICAL ALERTS


rightColumn : Model -> Dashboard -> Html Msg
rightColumn model dashboard =
    div []
        [ trendsPanel model dashboard
        , alertsPanel dashboard
        ]


trendsPanel : Model -> Dashboard -> Html Msg
trendsPanel model dashboard =
    let
        kpis =
            Data.kpisFor dashboard

        ( selectedId, selectedYear ) =
            trendState model dashboard

        selectedKpi =
            kpiById kpis selectedId
                |> Maybe.withDefault (List.head kpis |> Maybe.withDefault fallbackKpi)

        series =
            Data.trendSeries selectedKpi selectedYear

        chartSeries =
            [ { color = "#0273B2", label = "Current Performance", dash = "", points = series.current }
            , { color = "#C25E00", label = targetLegendLabel dashboard, dash = "8 4", points = series.target }
            ]
                ++ (case dashboard of
                        Facility ->
                            [ { color = "#2F7D32", label = "Int. Site Average", dash = "2 4", points = series.avg } ]

                        Program ->
                            []
                   )
    in
    div [ class "overflow-hidden rounded-lg border border-slate-200" ]
        [ div [ class "flex flex-wrap items-center gap-3 bg-accent px-3 py-2 text-white" ]
            [ h2 [ class "text-lg font-bold" ] [ text "Trends" ]
            , label [ for ("trend-kpi-" ++ dashboardSlug dashboard), class "sr-only" ] [ text "Select KPI to plot" ]
            , select
                [ id ("trend-kpi-" ++ dashboardSlug dashboard)
                , class "max-w-full rounded border border-white/40 bg-white px-2 py-1 text-sm font-semibold text-slate-900 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-white"
                , onInput (SelectTrendKpi dashboard)
                ]
                (List.map (\k -> option [ value k.id, selected (k.id == selectedId) ] [ text k.label ]) kpis)
            ]
        , div [ class "bg-white p-3" ]
            [ yearSelector dashboard selectedYear
            , Chart.view
                { xLabels = Data.monthLabels
                , series = chartSeries
                , ariaLabel = chartAria selectedKpi dashboard selectedYear
                }
            , legend chartSeries
            ]
        ]


trendState : Model -> Dashboard -> ( String, YearSel )
trendState model dashboard =
    case dashboard of
        Facility ->
            ( model.facilityTrendKpi, model.facilityTrendYear )

        Program ->
            ( model.programTrendKpi, model.programTrendYear )


targetLegendLabel : Dashboard -> String
targetLegendLabel dashboard =
    case dashboard of
        Facility ->
            "Institutional Target"

        Program ->
            "Program Target"


yearSelector : Dashboard -> YearSel -> Html Msg
yearSelector dashboard current =
    div [ class "mb-2 flex flex-wrap items-center gap-3" ]
        (span [ class "font-bold text-slate-900" ] [ text "Year:" ]
            :: List.map (yearButton dashboard current) (AllYears :: List.map Year [ 2029, 2028, 2027, 2026 ])
        )


yearButton : Dashboard -> YearSel -> YearSel -> Html Msg
yearButton dashboard current sel =
    let
        isActive =
            current == sel
    in
    button
        [ type_ "button"
        , onClick (SelectTrendYear dashboard sel)
        , attribute "aria-pressed"
            (if isActive then
                "true"

             else
                "false"
            )
        , class "rounded px-1.5 text-lg focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-accent"
        , classList
            [ ( "font-extrabold text-accent underline underline-offset-4", isActive )
            , ( "font-medium text-slate-700 hover:text-accent", not isActive )
            ]
        ]
        [ text (yearLabel sel) ]


legend : List Chart.Series -> Html msg
legend series =
    div [ class "mt-2 flex flex-wrap items-center justify-center gap-x-6 gap-y-1" ]
        (List.map legendItem series)


legendItem : Chart.Series -> Html msg
legendItem s =
    div [ class "flex items-center gap-2" ]
        [ Svg.svg
            [ SA.viewBox "0 0 28 10", SA.class "h-2.5 w-7", attribute "aria-hidden" "true" ]
            [ Svg.line
                [ SA.x1 "0"
                , SA.y1 "5"
                , SA.x2 "28"
                , SA.y2 "5"
                , SA.stroke s.color
                , SA.strokeWidth "3"
                , SA.strokeDasharray s.dash
                ]
                []
            ]
        , span [ class "text-sm text-slate-800" ] [ text s.label ]
        ]


alertsPanel : Dashboard -> Html Msg
alertsPanel dashboard =
    let
        alerts =
            Data.alertsFor dashboard
    in
    div [ class "mt-6 overflow-hidden rounded-lg border border-slate-200" ]
        [ h2 [ class "bg-accent px-3 py-2 text-lg font-bold text-white" ] [ text "Critical Alerts" ]
        , div [ class "bg-white p-3" ]
            [ if List.isEmpty alerts then
                p [ class "text-sm text-slate-600" ] [ text "No active alerts." ]

              else
                ul [ class "flex flex-col gap-2" ] (List.map alertItem alerts)
            ]
        ]


alertItem : Alert -> Html msg
alertItem alert =
    li [ class "flex items-center gap-2.5" ]
        [ span [ class "inline-block h-3.5 w-3.5 shrink-0 rounded-full bg-alert", attribute "aria-hidden" "true" ] []
        , span [ class "text-base text-slate-800" ] [ text alert.text ]
        ]



-- DRILL-DOWN MODAL


drillModal : Dashboard -> Kpi -> Html Msg
drillModal dashboard kpi =
    div
        [ class "fixed inset-0 z-50 flex items-start justify-center overflow-y-auto bg-slate-900/50 p-4"
        , attribute "role" "dialog"
        , attribute "aria-modal" "true"
        , attribute "aria-label" (kpi.label ++ " — month-by-month detail")
        ]
        [ div [ class "mt-10 w-full max-w-[1200px] rounded-lg bg-white p-5 shadow-2xl md:p-6" ]
            [ h2 [ class "mb-3 text-2xl font-bold text-accent" ] [ text kpi.label ]
            , div [ class "overflow-x-auto" ]
                [ drillTable dashboard kpi ]
            , div [ class "mt-4 flex justify-end gap-6" ]
                [ bannerLink ExportView "Export"
                , bannerLink PrintView "Print"
                , bannerLink CloseDrill "Return"
                ]
            ]
        ]


bannerLink : Msg -> String -> Html Msg
bannerLink msg lbl =
    button
        [ type_ "button"
        , onClick msg
        , class "text-lg font-semibold text-accent underline decoration-2 underline-offset-4 hover:text-accent-dark focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-accent"
        ]
        [ text lbl ]


drillTable : Dashboard -> Kpi -> Html Msg
drillTable dashboard kpi =
    let
        thirdHeader =
            case dashboard of
                Facility ->
                    "Avg."

                Program ->
                    "Δ"
    in
    table [ class "w-full min-w-[760px] border-collapse text-sm" ]
        [ thead []
            [ tr []
                (th [ class "bg-brand-navy p-2", attribute "scope" "col" ] [ span [ class "sr-only" ] [ text "Month" ] ]
                    :: List.map yearGroupHeader Data.drillYears
                )
            , tr []
                (th [ class "bg-slate-200 p-2", attribute "scope" "col" ] [ span [ class "sr-only" ] [ text "Month" ] ]
                    :: List.concatMap (subHeaders thirdHeader) Data.drillYears
                )
            ]
        , tbody []
            (List.indexedMap (drillMonthRow dashboard kpi) Data.drillMonths)
        ]


yearGroupHeader : Int -> Html msg
yearGroupHeader year =
    th
        [ class "bg-brand-navy p-2 text-lg font-bold text-white"
        , attribute "colspan" "3"
        , attribute "scope" "colgroup"
        ]
        [ text (String.fromInt year) ]


subHeaders : String -> Int -> List (Html msg)
subHeaders thirdHeader year =
    [ subHeaderCell year "Perf."
    , subHeaderCell year "Targ."
    , subHeaderCell year thirdHeader
    ]


subHeaderCell : Int -> String -> Html msg
subHeaderCell year lbl =
    th [ class "bg-slate-200 px-3 py-1.5 font-semibold text-slate-800", attribute "scope" "col" ]
        [ span [ class "sr-only" ] [ text (String.fromInt year ++ " ") ]
        , text lbl
        ]


drillMonthRow : Dashboard -> Kpi -> Int -> String -> Html msg
drillMonthRow dashboard kpi monthIx monthName =
    let
        zebra =
            if modBy 2 monthIx == 0 then
                "bg-slate-50"

            else
                "bg-slate-100"
    in
    tr [ class zebra ]
        (th [ class "bg-slate-300 px-3 py-1.5 text-left font-semibold text-slate-900", attribute "scope" "row" ] [ text monthName ]
            :: List.concatMap (drillCells dashboard kpi monthIx) Data.drillYears
        )


drillCells : Dashboard -> Kpi -> Int -> Int -> List (Html msg)
drillCells dashboard kpi monthIx year =
    let
        ( perf, targ, third ) =
            Data.drillRow dashboard kpi year monthIx

        thirdStr =
            case dashboard of
                Facility ->
                    pct third

                Program ->
                    signedPct third
    in
    [ dataCell (pct perf)
    , dataCell (pct targ)
    , dataCell thirdStr
    ]


dataCell : String -> Html msg
dataCell v =
    td [ class "px-3 py-1.5 text-center text-slate-800" ] [ text v ]



-- HELPERS


pct : Float -> String
pct v =
    String.fromInt (round v) ++ "%"


signedPct : Float -> String
signedPct v =
    let
        r =
            round v
    in
    (if r > 0 then
        "+"

     else
        ""
    )
        ++ String.fromInt r


fallbackKpi : Kpi
fallbackKpi =
    Kpi "none" "—" "—" "—" Nothing "" Up 1 50 60 50


chartAria : Kpi -> Dashboard -> YearSel -> String
chartAria kpi dashboard sel =
    let
        base =
            "Line chart of " ++ kpi.label ++ " by month for " ++ yearLabel sel ++ ", showing current performance, "
    in
    case dashboard of
        Facility ->
            base ++ "institutional target, and inter-site average."

        Program ->
            base ++ "and program target."
