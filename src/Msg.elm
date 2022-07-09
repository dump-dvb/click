module Msg exposing (..)

import Json.Encode exposing (Value, encode)

type RequestType = ListRegions | ListStations

type Msg =
    Connect
  | Login
  | Request RequestType
  | Process Json.Encode.Value
