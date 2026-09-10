module Types exposing
    ( Alert
    , Coverage
    , Dashboard(..)
    , Filter
    , Flags
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

{-| Shared types for the eHS Dashboards mock (offline, no backend).

Two dashboards — Facility Performance (Dashboard II) and Program Monitoring
(Dashboard III) — plus a per-KPI year/month drill-down that opens as a modal
over the dimmed dashboard. All screens live inside a single embedded Elm app;
navigation is model state, not page loads.

-}


type alias Flags =
    {}


{-| The two dashboards. Facility = single intervention site; Program =
aggregated across all sites.
-}
type Dashboard
    = Facility
    | Program


dashboardTitle : Dashboard -> ( String, String, String )
dashboardTitle dashboard =
    case dashboard of
        Facility ->
            ( "Dashboard II", "Facility Performance Dashboard", "XY Health Center" )

        Program ->
            ( "Dashboard III", "Program Monitoring Dashboard", "Program-Level" )


{-| Year selector above the trend chart: "All" or one of four years. -}
type YearSel
    = AllYears
    | Year Int


yearLabel : YearSel -> String
yearLabel sel =
    case sel of
        AllYears ->
            "All"

        Year y ->
            String.fromInt y


{-| The visible screen. A drill-down is a dashboard plus the KPI whose detail
table is open on top of it.
-}
type Screen
    = DashboardScreen Dashboard
    | DrillScreen Dashboard Kpi


{-| Direction of the small "x% from prev. month" indicator. Up renders a green
▲, Down a red ▼ — matching the mockups, which colour by direction, not by
whether the movement is clinically good.
-}
type Trend
    = Up
    | Down


{-| A KPI block. In Facility view each block shows current vs. programme target
vs. inter-site average; in Program view the "% of sites exceeding threshold"
tiles show current vs. target only (`average = Nothing`).

`base*` are the chart centre-lines (0–100) the deterministic series generator
wanders around, so every KPI plots a distinct, believable trend.
-}
type alias Kpi =
    { id : String
    , label : String
    , current : String
    , target : String
    , average : Maybe String
    , deltaText : String
    , deltaDir : Trend
    , seed : Int
    , baseCurrent : Float
    , baseTarget : Float
    , baseAvg : Float
    }


{-| A numeric summary tile in the row beneath the filters. -}
type alias Tile =
    { label : String
    , value : String
    }


{-| A horizontal coverage bar (Aspirin / Calcium / SQLNS). `pct` is the filled
percentage; the remainder renders as a grey track. -}
type alias Coverage =
    { label : String
    , emphasis : String
    , pct : Int
    }


{-| A single critical-alert line. -}
type alias Alert =
    { text : String }


{-| A cosmetic filter dropdown (Intervention Site, Time, Service, Location).
Selecting an option updates `selected`; in this mock it drives the banner label
but not the underlying figures. -}
type alias Filter =
    { key : String
    , label : String
    , options : List String
    , selected : String
    }


type alias Model =
    { screen : Screen
    , facilityTrendKpi : String
    , facilityTrendYear : YearSel
    , programTrendKpi : String
    , programTrendYear : YearSel
    , facilityFilters : List Filter
    , programFilters : List Filter
    }


type Msg
    = NoOp
    | SwitchDashboard Dashboard
    | OpenDrill Dashboard Kpi
    | CloseDrill
    | SelectTrendKpi Dashboard String
    | SelectTrendYear Dashboard YearSel
    | SetFilter Dashboard String String
    | PrintView
    | ExportView


{-| Look up a KPI in a list by id (used when a trend dropdown changes). -}
kpiById : List Kpi -> String -> Maybe Kpi
kpiById kpis id =
    List.filter (\k -> k.id == id) kpis |> List.head
