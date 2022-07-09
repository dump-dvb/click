module Serialization exposing (..)

import Json.Decode as Decode exposing (..)
import Json.Decode.Pipeline as JDPipeline

type alias Region =
  { id: Int
  , name: String
  , transport_company: String
  , frequency: Int
  , protocol: String
  }

regionListDecoder regionList = Decode.decodeString (Decode.list regionDecoder) regionList

regionDecoder: Decode.Decoder Region
regionDecoder =
  Decode.succeed Region
    |> JDPipeline.required "id" Decode.int
    |> JDPipeline.required "name" Decode.string
    |> JDPipeline.required "transport_company" Decode.string
    |> JDPipeline.required "frequency" Decode.int
    |> JDPipeline.required "protocol" Decode.string
