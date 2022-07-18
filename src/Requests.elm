module Requests exposing (..)

import PortFunnel.WebSocket as WebSocket
import Msg exposing (..)
import Port exposing (cmdPort, subPort)
import Serialization exposing (Region, regionListDecoder, Station, stationListDecoder)
import Config exposing (socketKey, socketURL)
import Model exposing (Model, expector, makeModifyable)

performRequest r model =
  case r of
    Msg.ListRegions ->
      let
          cmd = WebSocket.makeSend socketKey """
                  {
                      "operation": "region/list"
                  }
                  """
            |> WebSocket.send cmdPort
      in
        ({ model | expect = expector regionListDecoder storeNewRegions }, cmd)

    Msg.ListStations ->
      let
          cmd = WebSocket.makeSend socketKey """
                  {
                      "operation": "station/list"
                  }
                  """
            |> WebSocket.send cmdPort
      in
        ({ model | expect = expector stationListDecoder storeNewStations }, cmd)

storeNewRegions: Model -> List Region -> Model
storeNewRegions model rl =
  storeRegions model <| List.map makeModifyable rl

storeRegions: Model -> List (Model.Modifyable Region) -> Model
storeRegions model rl =
  { model | regions = rl }

storeNewStations: Model -> List Station -> Model
storeNewStations model st =
  storeStations model <| List.map makeModifyable st

storeStations: Model -> List (Model.Modifyable Station) -> Model
storeStations model st =
  { model | stations = st }
