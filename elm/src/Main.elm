port module Main exposing (main)

{-| The eHS Dashboards mock — an offline, single-page Elm app that hosts both
the Facility (Dashboard II) and Program (Dashboard III) dashboards and their
per-KPI drill-downs. There is no backend: all figures come from `Data`, and the
only ports are outgoing (`printPage` triggers the browser print dialog;
`exportData` is a stub the mock logs).
-}

import Browser
import Data
import Html exposing (Html)
import Json.Encode as Encode
import Types
    exposing
        ( Dashboard(..)
        , Filter
        , Flags
        , Model
        , Msg(..)
        , Screen(..)
        , YearSel(..)
        )
import View



-- PORTS


port printPage : () -> Cmd msg


port exportData : Encode.Value -> Cmd msg



-- MAIN


main : Program Flags Model Msg
main =
    Browser.element
        { init = init
        , update = update
        , view = view
        , subscriptions = \_ -> Sub.none
        }


init : Flags -> ( Model, Cmd Msg )
init _ =
    ( { screen = DashboardScreen Facility
      , facilityTrendKpi = Data.defaultTrendKpi Facility
      , facilityTrendYear = Year 2028
      , programTrendKpi = Data.defaultTrendKpi Program
      , programTrendYear = Year 2028
      , facilityFilters = Data.filtersFor Facility
      , programFilters = Data.filtersFor Program
      }
    , Cmd.none
    )



-- UPDATE


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        NoOp ->
            ( model, Cmd.none )

        SwitchDashboard dashboard ->
            ( { model | screen = DashboardScreen dashboard }, Cmd.none )

        OpenDrill dashboard kpi ->
            ( { model | screen = DrillScreen dashboard kpi }, Cmd.none )

        CloseDrill ->
            ( { model | screen = DashboardScreen (currentDashboard model.screen) }, Cmd.none )

        SelectTrendKpi dashboard kpiId ->
            ( case dashboard of
                Facility ->
                    { model | facilityTrendKpi = kpiId }

                Program ->
                    { model | programTrendKpi = kpiId }
            , Cmd.none
            )

        SelectTrendYear dashboard year ->
            ( case dashboard of
                Facility ->
                    { model | facilityTrendYear = year }

                Program ->
                    { model | programTrendYear = year }
            , Cmd.none
            )

        SetFilter dashboard key selectedValue ->
            ( applyFilter dashboard key selectedValue model, Cmd.none )

        PrintView ->
            ( model, printPage () )

        ExportView ->
            ( model, exportData (Encode.string "mock-export") )


currentDashboard : Screen -> Dashboard
currentDashboard screen =
    case screen of
        DashboardScreen d ->
            d

        DrillScreen d _ ->
            d


{-| Update the `selected` value of one filter in the relevant dashboard's list.
Cosmetic in this mock — it drives the visible dropdown, not the figures. -}
applyFilter : Dashboard -> String -> String -> Model -> Model
applyFilter dashboard key selectedValue model =
    let
        set : List Filter -> List Filter
        set filters =
            List.map
                (\filter ->
                    if filter.key == key then
                        { filter | selected = selectedValue }

                    else
                        filter
                )
                filters
    in
    case dashboard of
        Facility ->
            { model | facilityFilters = set model.facilityFilters }

        Program ->
            { model | programFilters = set model.programFilters }



-- VIEW


view : Model -> Html Msg
view =
    View.view
