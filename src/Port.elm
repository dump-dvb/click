port module Port exposing (..)

import Json.Encode exposing (Value, encode)

port cmdPort : Value -> Cmd msg
port subPort : (Value -> msg) -> Sub msg
