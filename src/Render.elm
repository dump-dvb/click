module Render exposing  (..)

import Msg exposing (Msg)
import Css exposing (..)

import Html.Styled as Html exposing (Html, button, div, text, br, p, table, thead, tbody, th, tr, td, h3, input)
import Html.Styled.Attributes as Attributes exposing (css, type_, checked)
import Html.Styled.Events exposing (onClick)

renderPanel model =
  [ h3 [] [ text "Regions" ]
  , button [ onClick <| Msg.Request Msg.ListRegions ] [ text "List Regions" ]
  , renderRegions model.regions
  , h3 [] [ text "Stations" ]
  , button [ onClick <| Msg.Request Msg.ListStations ] [ text "List Stations" ]
  , renderStations model.stations
  ]

borderStyle =
  Css.batch
    [ border3 (px 1) solid (rgb 0 0 0)
    , borderCollapse collapse
    ]

cellStyle =
  Css.batch
    [ borderStyle
    , padding (em 0.3) ]

renderRegions regions =
  div []
    [ Html.table
      [ css
        [ borderStyle
        , marginTop (em 1)
        ]
      ]
      [ thead []
        [ th [ css [ cellStyle ] ] [ text "ID" ]
        , th [ css [ cellStyle ] ] [ text "Name" ]
        , th [ css [ cellStyle ] ] [ text "Transport Company" ]
        , th [ css [ cellStyle ] ] [ text "Frequency" ]
        , th [ css [ cellStyle ] ] [ text "Protocol" ]
        ]
      , tbody [] <| List.map renderRegion regions
      ]
    ]

renderRegion region =
  tr []
    [ td [ css [ cellStyle ] ] [ text <| String.fromInt region.id ]
    , td [ css [ cellStyle ] ] [ text <| region.name ]
    , td [ css [ cellStyle ] ] [ text <| region.transport_company ]
    , td [ css [ cellStyle ] ] [ text <| String.fromInt region.frequency ]
    , td [ css [ cellStyle ] ] [ text <| region.protocol ]
    ]

renderStations stations =
  div []
    [ Html.table
      [ css
        [ borderStyle
        , marginTop (em 1)
        ]
      ]
      [ thead []
        [ th [ css [ cellStyle ] ] [ text "ID" ]
        , th [ css [ cellStyle ] ] [ text "Token" ]
        , th [ css [ cellStyle ] ] [ text "Name" ]
        , th [ css [ cellStyle ] ] [ text "Lat" ]
        , th [ css [ cellStyle ] ] [ text "Lon" ]
        , th [ css [ cellStyle ] ] [ text "Region" ]
        , th [ css [ cellStyle ] ] [ text "Owner" ]
        ]
      , tbody [] <| List.map renderStation stations
      ]
    ]

renderStation station =
  tr []
    [ td [ css [ cellStyle ] ] [ text <| station.id ]
    , td [ css [ cellStyle ] ] [ text <| Maybe.withDefault "" station.token ]
    , td [ css [ cellStyle ] ] [ text <| station.name ]
    , td [ css [ cellStyle ] ] [ text <| String.fromFloat station.lat ]
    , td [ css [ cellStyle ] ] [ text <| String.fromFloat station.lon ]
    , td [ css [ cellStyle ] ] [ text <| String.fromInt station.region ]
    , td [ css [ cellStyle ] ] [ text <| station.owner ]
    , td [ css [ cellStyle ] ]
      [ input
        [ Attributes.checked station.approved
        , type_ "checkbox"
        ] []
      ]
    ]
