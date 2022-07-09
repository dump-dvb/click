module Msg exposing (..)

import Json.Encode exposing (Value, encode)

type Msg = Connect | Login | ListRegions | Process Json.Encode.Value
