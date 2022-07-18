module Msg exposing (..)

import Json.Encode exposing (Value, encode)
import Model exposing (Model)
import Serialization exposing (Station, Region)

type RequestType = ListRegions | ListStations

type Msg =
    Connect
  | SetUsername String
  | SetPassword String
  | Login
  | ModifyRegion Region
  | ModifyStation Station
  | Request RequestType
  | UpdateData (Model -> Model)
  | Process Json.Encode.Value
