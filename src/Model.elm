module Model exposing (..)

import PortFunnel.WebSocket as WebSocket
import Json.Decode as Decode

import Serialization exposing (Region, regionListDecoder, Station, stationListDecoder)

import Dict exposing (Dict)

type alias Model =
  { websocket: WebSocket.State
  , isConnected: Bool
  , regions: List (Modifyable Region)
  , stations: List (Modifyable Station)
  , expect: Maybe Expector
  }

type Expector = Expector (String -> Model -> Result ExpectationError Model)

type ExpectationError = JSONError Decode.Error | NothingExpected

expector: (String -> Result Decode.Error a) -> (Model -> a -> Model) -> Maybe Expector
expector responseDecoder modelUpdater =
  Just <| Expector
    ( \message model ->
        responseDecoder message
          |> Result.andThen (\a -> Ok (modelUpdater model a))
          |> Result.mapError JSONError
    )

type ModifyingState a = Unchanged | Dirty a | Editing (Dict String String)

makeModifyable: a -> Modifyable a
makeModifyable v =
  { value = v
  , state = Unchanged
  }

type alias Modifyable a =
  { value: a
  , state: ModifyingState a
  }
