module Msg exposing (..)

import Json.Encode exposing (Value, encode)
import Model exposing (Model)

type RequestType = ListRegions | ListStations

type Msg =
    Connect
  | SetUsername String
  | SetPassword String
  | Login
  | Request RequestType
  | UpdateData (Model -> Model)
  | Process Json.Encode.Value
