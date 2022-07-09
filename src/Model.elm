module Model exposing (..)

import PortFunnel.WebSocket as WebSocket
import Json.Decode as Decode

import Serialization exposing (Region, regionListDecoder, Station, stationListDecoder)

type alias Model =
  { websocket: WebSocket.State
  , isConnected: Bool
  , regions: List Region
  , stations: List Station
  , expect: Maybe Expector
  }

type Expector = Expector (String -> Model -> Result ExpectationError Model)

type ExpectationError = JSONError Decode.Error | NothingExpected

expector: (String -> Result Decode.Error a) -> (a -> Model -> Model) -> Maybe Expector
expector responseDecoder modelUpdater =
  Just <| Expector
    ( \message model ->
        responseDecoder message
          |> Result.andThen (\a -> Ok (modelUpdater a model))
          |> Result.mapError JSONError
    )

