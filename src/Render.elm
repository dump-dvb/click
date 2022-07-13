module Render exposing  (..)

import Msg exposing (Msg)
import Css exposing (..)

import Html.Styled as Html exposing (Html, button, div, text, br, p, table, thead, tbody, th, tr, td, h3, input, a)
import Html.Styled.Attributes as Attributes exposing (css, type_, checked, value, disabled)
import Html.Styled.Events exposing (onClick, onCheck, onInput)

import Model exposing (Model, Modifyable, ModifyingState)
import Requests exposing (storeRegions, storeStations)
import Serialization exposing (stationDictEncoder, stationDictDecoder)

import Dict exposing (Dict)

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

-- TODO make editable
renderRegion r =
  tr [] <|
    case r.state of
      Model.Editing rd ->
        let
          region = r.value
        in
          [ td [ css [ cellStyle ] ] [ text <| String.fromInt region.id ]
          , td [ css [ cellStyle ] ] [ text <| region.name ]
          , td [ css [ cellStyle ] ] [ text <| region.transport_company ]
          , td [ css [ cellStyle ] ] [ text <| String.fromInt region.frequency ]
          , td [ css [ cellStyle ] ] [ text <| region.protocol ]
          ]
      Model.Dirty region ->
        [ td [ css [ cellStyle ] ] [ text <| String.fromInt region.id ]
        , td [ css [ cellStyle ] ] [ text <| region.name ]
        , td [ css [ cellStyle ] ] [ text <| region.transport_company ]
        , td [ css [ cellStyle ] ] [ text <| String.fromInt region.frequency ]
        , td [ css [ cellStyle ] ] [ text <| region.protocol ]
        ]
      Model.Unchanged ->
        let
          region = r.value
        in
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

updateFnGenerator:
    (Model -> List (Modifyable a))
 -> (Model -> List (Modifyable a) -> Model)
 -> (a -> Bool)
 -> (a -> a)
 -> (Model -> Model)

updateFnGenerator getList setList matcher setter =
  \model ->
    setList model <| List.map
      (\element ->
        if matcher element.value
        --then { element | state = Model.Editing (setter element.value) }
        then { element | value = setter element.value }
        else element
      )
      (getList model)

updateDictFnGenerator:
    (Model -> List (Modifyable a))
 -> (Model -> List (Modifyable a) -> Model)
 -> (a -> Bool)
 -> String
 -> String
 -> (Model -> Model)

updateDictFnGenerator getList setList matcher key newValue =
  \model ->
    setList model <| List.map
      (\element ->
        if matcher element.value
        then
          case element.state of
            Model.Editing d ->
              -- assumes that the key is what we want (e.g. is already in the dict)
              -- alternative: use Dict.update and fail (silently), if key is not contained
              { element | state = Model.Editing (Dict.insert key newValue d) }
            _ ->
              element
        else element
      )
      (getList model)

updateMetaFnGenerator:
    (Model -> List (Modifyable a))
 -> (Model -> List (Modifyable a) -> Model)
 -> (a -> Bool)
 -> (Modifyable a -> Modifyable a)
 -> (Model -> Model)
updateMetaFnGenerator getList setList matcher setter =
  \model ->
    setList model <| List.map
      (\element ->
        if matcher element.value
        then setter element
        else element
      )
      (getList model)


renderStation s =
  let
    updateMessage key =
      \value ->
        Msg.UpdateData <| updateDictFnGenerator
          .stations
          storeStations
          (\station -> station.id == s.value.id)
          key value
    metaMessage updateMeta =
      Msg.UpdateData <| updateMetaFnGenerator
        .stations
        storeStations
        (\station -> station.id == s.value.id)
        updateMeta

    renderUneditableStation station dirty =
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
          , Attributes.disabled True
          ] []
        ]
      , td [ css [ cellStyle ] ] <|
        [ a
          [ onClick <| metaMessage (\ms -> { ms | state = Model.Editing (stationDictEncoder ms.value) })
          ] [text "edit"]
        ] ++ if dirty then [ text "(bearbeitet)" ] else []
      ]

    renderEditableStation stationd =
      let
        getOrEmpty key = Maybe.withDefault "" <| Dict.get key stationd
        editTextCell key attributes =
          td [ css [ cellStyle ] ]
            [ input
              ( [ value <| getOrEmpty key
                , onInput <| updateMessage key
                ] ++ attributes )
              []
            ]

      in
        [ td [ css [ cellStyle ] ] [ text <| getOrEmpty "id" ]
        , editTextCell "token" []
        , editTextCell "name" []
        , editTextCell "lat" [css [ width (em 3) ]]
        , editTextCell "lon" [css [ width (em 3) ]]
        , editTextCell "region" [css [ width (em 6) ]]
        , editTextCell "owner" []
        , td [ css [ cellStyle ] ]
          [ input
            [ Attributes.checked <| if getOrEmpty "approved" == "true" then True else False
            , type_ "checkbox"
            , onCheck (\appr -> updateMessage "approved" <| if appr then "true" else "false")
            ] []
          ]
        , td [ css [ cellStyle ] ]
          [ a
            [ onClick <|
                let
                  decoded = stationDictDecoder s.value stationd
                  newState = if s.value == decoded then Model.Unchanged else Model.Dirty decoded
                in
                  metaMessage (\ms -> { ms | state = newState })
            ] [text "finish"]
          ]
        ]
  in
    tr [] <|
      case s.state of
        Model.Editing station ->
          renderEditableStation station
        Model.Unchanged ->
          renderUneditableStation s.value False
        Model.Dirty station ->
          renderUneditableStation station True
