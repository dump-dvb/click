module Serialization exposing (..)

import Json.Decode as Decode exposing (..)
import Json.Decode.Pipeline as JDPipeline exposing (optional, required)

-- Region

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
    |> required "id" Decode.int
    |> required "name" Decode.string
    |> required "transport_company" Decode.string
    |> required "frequency" Decode.int
    |> required "protocol" Decode.string


-- Station

type alias Station =
  { id: String
  , token: Maybe String
  , name: String
  , lat: Float
  , lon: Float
  , region: Int
  , owner: String
  , approved: Bool
  }

stationListDecoder stationList = Decode.decodeString (Decode.list stationDecoder) stationList

stationDecoder: Decode.Decoder Station
stationDecoder =
  Decode.succeed Station
    |> required "id" Decode.string
    |> required "token" (Decode.nullable Decode.string)
    |> required "name" Decode.string
    |> required "lat" Decode.float
    |> required "lon" Decode.float
    |> required "region" Decode.int
    |> required "owner" Decode.string
    |> required "approved" Decode.bool
