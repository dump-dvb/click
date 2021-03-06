module Serialization exposing (..)

import Json.Encode as Encode exposing (..)
import Json.Decode as Decode exposing (..)
import Json.Decode.Pipeline as JDPipeline exposing (optional, required)

import Dict exposing (Dict)

-- Success

type alias SuccessResponse =
  { success: Bool
  }

successDecoder: Decode.Decoder SuccessResponse
successDecoder =
  Decode.succeed SuccessResponse
    |> required "success" Decode.bool

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

regionEncoder region =
  Encode.object
    [ ("id", Encode.int region.id)
    , ("name", Encode.string region.name)
    , ("transport_company", Encode.string region.transport_company)
    , ("frequency", Encode.int region.frequency)
    , ("protocol", Encode.string region.protocol)
    ]

regionDictEncoder region =
  Dict.fromList
    [ ("id", String.fromInt region.id)
    , ("name", region.name)
    , ("transport_company", region.transport_company)
    , ("frequency", String.fromInt region.frequency)
    , ("protocol", region.protocol)
    ]

regionDictDecoder: Region -> (Dict String String) -> Region
regionDictDecoder default dict =
  let
    nothingIfEmpty str = if String.isEmpty <| String.trim str then Nothing else Just str
    toBool str = if str == "true" then Just True else Just False
    getParse parse key accessor =
      Dict.get key dict
      |> Maybe.andThen parse
      |> Maybe.withDefault (accessor default)
    get key accessor = getParse nothingIfEmpty key accessor
  in
    { id = getParse String.toInt "id" .id
    , name = get "name" .name
    , transport_company = get "transport_company" .transport_company
    , frequency = getParse String.toInt "frequency" .frequency
    , protocol = get "protocol" .protocol
    }

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

stationEncoder: Station -> Encode.Value
stationEncoder station =
  Encode.object
    [ ("id", Encode.string station.id)
    , ("token", Encode.string <| Maybe.withDefault "" station.token)
    , ("name", Encode.string station.name)
    , ("lat", Encode.float station.lat)
    , ("lon", Encode.float station.lon)
    , ("region", Encode.int station.region)
    , ("owner", Encode.string station.owner)
    , ("approved", Encode.bool station.approved)
    ]

stationDictEncoder station =
  Dict.fromList
    [ ("id", station.id)
    , ("token", Maybe.withDefault "" station.token)
    , ("name", station.name)
    , ("lat", String.fromFloat station.lat)
    , ("lon", String.fromFloat station.lon)
    , ("region", String.fromInt station.region)
    , ("owner", station.owner)
    , ("approved", if station.approved then "true" else "false")
    ]

stationDictDecoder: Station -> (Dict String String) -> Station
stationDictDecoder default dict =
  let
    nothingIfEmpty str = if String.isEmpty <| String.trim str then Nothing else Just str
    toBool str = if str == "true" then Just True else Just False
    getParse parse key accessor =
      Dict.get key dict
      |> Maybe.andThen parse
      |> Maybe.withDefault (accessor default)
    get key accessor = getParse nothingIfEmpty key accessor
  in
    { id = get "id" .id
    -- should be proper Maybe
    , token = getParse (\a -> Just <| nothingIfEmpty a) "token" .token
    , name = get "name" .name
    , lat = getParse String.toFloat "lat" .lat
    , lon = getParse String.toFloat "lon" .lon
    , region = getParse String.toInt "region" .region
    , owner = get "owner" .owner
    , approved = getParse toBool  "approved" .approved
    }
