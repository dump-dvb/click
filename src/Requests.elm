module Requests exposing (..)

import PortFunnel.WebSocket as WebSocket
import Msg exposing (..)
import Port exposing (cmdPort, subPort)
import Serialization exposing (Region, regionListDecoder, Station, stationListDecoder)
import Config exposing (socketKey, socketURL)
import Model exposing (Model, expector)

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
        ({ model | expect = expector regionListDecoder storeRegions }, cmd)

    Msg.ListStations ->
      let
          cmd = WebSocket.makeSend socketKey """
                  {
                      "operation": "station/list"
                  }
                  """
            |> WebSocket.send cmdPort
      in
        ({ model | expect = expector stationListDecoder storeStations }, cmd)

storeRegions: List Region -> Model -> Model
storeRegions rl model =
  { model | regions = rl }

storeStations: List Station -> Model -> Model
storeStations st model =
  { model | stations = st }
