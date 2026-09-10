module Data exposing
    ( alertsFor
    , coverageFor
    , defaultTrendKpi
    , drillMonths
    , drillRow
    , drillYears
    , filtersFor
    , kpisFor
    , monthLabels
    , tilesFor
    , trendSeries
    )

{-| Mock data for the eHS Dashboards, plus a small deterministic series
generator. The numbers are representative maternal/child-health figures, not
live data — but every KPI and year produces a stable, distinct-looking trend so
the chart and drill-down tables feel real when you interact with them.
-}

import Types exposing (Alert, Coverage, Dashboard(..), Filter, Kpi, Tile, Trend(..), YearSel(..))



-- SUMMARY TILES


tilesFor : Dashboard -> List Tile
tilesFor dashboard =
    case dashboard of
        Facility ->
            [ Tile "Women Currently in ANC Care" "142"
            , Tile "Pregnancies 1st Trimester" "38"
            , Tile "Pregnancies 2nd Trimester" "57"
            , Tile "Pregnancies 3rd Trimester" "47"
            , Tile "ANC Miss Rate (≥1 Missed Visit)" "12%"
            , Tile "Total Deliveries (Institutional)" "214"
            , Tile "Total Children on Routine Care" "389"
            , Tile "Graduated Mother–Child Pairs" "156"
            , Tile "Lost to Follow-Up (ANC–PNC–Child)" "23"
            ]

        Program ->
            [ Tile "Women Currently in ANC Care" "2,418"
            , Tile "Pregnancies 1st Trimester" "646"
            , Tile "Pregnancies 2nd Trimester" "921"
            , Tile "Pregnancies 3rd Trimester" "851"
            , Tile "ANC Miss Rate (≥1 Missed Visit)" "14%"
            , Tile "Total Deliveries (Program)" "3,772"
            , Tile "Total Children on Routine Care" "6,540"
            , Tile "Graduated Mother–Child Pairs" "2,689"
            , Tile "Lost to Follow-Up (ANC–PNC–Child)" "402"
            ]



-- KPI BLOCKS


kpisFor : Dashboard -> List Kpi
kpisFor dashboard =
    case dashboard of
        Facility ->
            [ Kpi "anc-booking" "Early ANC Booking Rate" "68%" "80%" (Just "64%") "3.5% from prev. month" Up 11 70 88 66
            , Kpi "median-ga" "Median GA at First ANC" "10.8 wk" "≤ 12 wk" (Just "11.6 wk") "5% from prev. month" Up 23 62 80 58
            , Kpi "ultrasound" "Early Ultrasound Coverage (<20 W)" "74%" "85%" (Just "70%") "1.5% from prev. month" Up 37 74 92 78
            , Kpi "high-risk" "High-Risk Pregnancy Rate" "16%" "< 15%" (Just "18%") "2.5% from prev. month" Down 41 20 15 23
            , Kpi "pph" "Postpartum Hemorrhage Rate" "3.2%" "< 5%" (Just "4.1%") "6% from prev. month" Up 53 12 8 16
            , Kpi "complete-anc" "Complete ANC Attendance Rate" "58%" "70%" (Just "55%") "5% from prev. month" Up 67 60 80 56
            ]

        Program ->
            [ Kpi "anc-cov80" "Early ANC Coverage >80 (1st Trimester)" "72%" "80%" Nothing "3.5% from prev. month" Up 71 72 86 70
            , Kpi "ultrasound-p" "Early Ultrasound Coverage (<20 W)" "66%" "80%" Nothing "1.5% from prev. month" Down 83 68 88 66
            , Kpi "inadequate-gwg" "Sites with Inadequate GWG (>10%)" "18%" "< 10%" Nothing "4.5% from prev. month" Up 91 24 12 26
            , Kpi "delayed-bw" "Sites with Delayed/Missing Birth Weight Recording (>5%)" "14%" "< 5%" Nothing "1.5% from prev. month" Down 97 16 8 18
            , Kpi "preterm-sga" "Sites with Elevated Preterm or SGA Births (>15%)" "20%" "< 15%" Nothing "0.5% from prev. month" Up 103 24 16 26
            , Kpi "poor-growth" "Sites with Poor Child Growth Outcomes (>10%)" "15%" "< 10%" Nothing "1.2% from prev. month" Up 109 18 12 20
            ]


defaultTrendKpi : Dashboard -> String
defaultTrendKpi dashboard =
    case dashboard of
        Facility ->
            "ultrasound"

        Program ->
            "ultrasound-p"



-- COVERAGE BARS


coverageFor : Dashboard -> List Coverage
coverageFor dashboard =
    case dashboard of
        Facility ->
            [ Coverage " Prophylaxis Coverage" "Aspirin" 82
            , Coverage " Prophylaxis Coverage" "Calcium" 74
            , Coverage " Supplement Coverage" "SQLNS" 68
            ]

        Program ->
            [ Coverage " Prophylaxis Coverage" "Aspirin" 79
            , Coverage " Prophylaxis Coverage" "Calcium" 71
            , Coverage " Supplement Coverage" "SQLNS" 65
            ]



-- CRITICAL ALERTS


alertsFor : Dashboard -> List Alert
alertsFor dashboard =
    case dashboard of
        Facility ->
            [ Alert "3 births missing birth weight in last 7 days"
            , Alert "Preterm rate exceeded 15% this month"
            ]

        Program ->
            [ Alert "6 sites with delayed birth weight recording"
            , Alert "4 sites with preterm rate >15%"
            ]



-- FILTERS


filtersFor : Dashboard -> List Filter
filtersFor dashboard =
    case dashboard of
        Facility ->
            [ Filter "site" "Intervention Site" [ "XY Health Center", "Rukara HC", "Nyamata HC", "Gahini HC" ] "XY Health Center"
            , Filter "time" "Time" [ "All", "This month", "This quarter", "This year" ] "All"
            ]

        Program ->
            [ Filter "site" "Intervention Site" [ "All", "XY Health Center", "Rukara HC", "Nyamata HC" ] "All"
            , Filter "service" "Service" [ "ANC", "PNC", "Child Health", "All" ] "ANC"
            , Filter "time" "Time" [ "All", "This month", "This quarter", "This year" ] "All"
            , Filter "location" "Location" [ "All", "Eastern Province", "Kayonza District", "Rwamagana District" ] "All"
            ]



-- MONTH / YEAR LABELS


monthLabels : List String
monthLabels =
    [ "Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sept", "Oct", "Nov", "Dec" ]


drillMonths : List String
drillMonths =
    [ "Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sept", "Oct", "Nov", "Dec" ]


{-| Years shown across the drill-down table header, most recent first. -}
drillYears : List Int
drillYears =
    [ 2029, 2028, 2027, 2026 ]



-- DETERMINISTIC SERIES GENERATION


{-| A tiny LCG-style hash → [0,1). Deterministic, so the same KPI/year always
draws the same curve. -}
rnd : Int -> Float
rnd n =
    let
        x =
            modBy 233280 (abs n * 9301 + 49297)
    in
    toFloat x / 233280


{-| Monthly "performance / average" line: wanders around `base` with a gentle
upward drift across the year plus stable noise. -}
monthly : Int -> Float -> Int -> List Float
monthly seed base yearKey =
    List.map
        (\m ->
            let
                drift =
                    toFloat m * 0.9

                noise =
                    (rnd (seed * 131 + yearKey * 17 + m * 7) - 0.5) * 13
            in
            clamp 0 100 (base - 5 + drift + noise)
        )
        (List.range 0 11)


{-| Target line: rises from a little below `base` early in the year and flattens
near `base` — the calm reference line the mockups show in orange. -}
targetMonthly : Float -> List Float
targetMonthly base =
    List.map
        (\m -> clamp 0 100 (base - 8 + toFloat m / 11 * 8))
        (List.range 0 11)


{-| Element-wise average of equal-length lists (used to collapse the four years
into a single "All" series). -}
elementAvg : List (List Float) -> List Float
elementAvg lists =
    List.map
        (\i ->
            let
                vals =
                    List.filterMap (\l -> List.drop i l |> List.head) lists
            in
            if List.isEmpty vals then
                0

            else
                List.sum vals / toFloat (List.length vals)
        )
        (List.range 0 11)


yearKeys : YearSel -> List Int
yearKeys sel =
    case sel of
        AllYears ->
            [ 2026, 2027, 2028, 2029 ]

        Year y ->
            [ y ]


{-| The three plotted series (current / target / average) for a KPI and the
selected year (or the four-year mean for "All"). -}
trendSeries : Kpi -> YearSel -> { current : List Float, target : List Float, avg : List Float }
trendSeries kpi sel =
    let
        keys =
            yearKeys sel
    in
    { current = elementAvg (List.map (monthly kpi.seed kpi.baseCurrent) keys)
    , target = elementAvg (List.map (\_ -> targetMonthly kpi.baseTarget) keys)
    , avg = elementAvg (List.map (monthly (kpi.seed + 777) kpi.baseAvg) keys)
    }


{-| One (performance, target, third) triple for a drill-down cell. `third` is
the inter-site average on the Facility dashboard, or performance − target (Δ)
on the Program dashboard. -}
drillRow : Dashboard -> Kpi -> Int -> Int -> ( Float, Float, Float )
drillRow dashboard kpi year monthIx =
    let
        nth ix xs =
            List.drop ix xs |> List.head |> Maybe.withDefault 0

        perf =
            nth monthIx (monthly kpi.seed kpi.baseCurrent year)

        targ =
            nth monthIx (targetMonthly kpi.baseTarget)

        avg =
            nth monthIx (monthly (kpi.seed + 777) kpi.baseAvg year)

        third =
            case dashboard of
                Facility ->
                    avg

                Program ->
                    perf - targ
    in
    ( perf, targ, third )
