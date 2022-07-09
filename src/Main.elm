module Main exposing (..)

import Browser
import Html exposing (Html, button, div, text, br, p)
import Html.Events exposing (onClick)
import Json.Encode exposing (Value, encode)
import Json.Decode exposing (Decoder)
import Json.Decode.Pipeline as JDPipeline

import PortFunnel exposing (decodeGenericMessage)
import PortFunnel.WebSocket as WebSocket

import Messaging exposing (send, parseResponse)
import Serialization exposing (Region, regionListDecoder)

import Port exposing (cmdPort, subPort)

main =
  Browser.element {
    init = init,
    update = update,
    view = view,
    subscriptions = subscriptions
  }

type alias Model =
  { value: Int
  , websocket: WebSocket.State
  , regions: List Region
  }

init: () -> ( Model, Cmd Msg )
init _ =
  { value = 0
  , websocket = WebSocket.initialState
  , regions = []
  } |> withNoCmd

subscriptions : Model -> Sub Msg
subscriptions model =
  subPort Process

withCmd: Cmd msg -> Model -> (Model, Cmd msg)
withCmd command model = (model, command)

withNoCmd: Model -> (Model, Cmd msg)
withNoCmd model = (model, Cmd.none)


socketKey = "backend"
socketURL = "wss://management-backend.staging.dvb.solutions"

stateAccessor:
  { get: Model -> WebSocket.State
  , set: WebSocket.State -> Model -> Model
  }
stateAccessor =
  { get = .websocket
  , set = \state model -> { model | websocket = state}
  }



type Msg = Increment | Decrement | Connect | Login | ListRegions | Process Json.Encode.Value

update: Msg -> Model -> (Model, Cmd Msg)
update msg model =
  case msg of
    Process value ->
      let
          logIncoming = Debug.log "incoming to-process" (Json.Encode.encode 0 value)
          result = PortFunnel.decodeGenericMessage value
            |> Result.andThen (\gmessage ->
                 PortFunnel.process stateAccessor WebSocket.moduleDesc gmessage model
               )
          logResponse = case result of
            Ok (_, response) ->
              Debug.log "response" (parseResponse response)
            Err s ->
              "cannot decode message: " ++ s
      in case result of
        Ok (newmodel, WebSocket.CmdResponse ms) ->
          newmodel |> withCmd (WebSocket.send cmdPort ms)
        Ok (newmodel, WebSocket.MessageReceivedResponse { message }) ->
          case regionListDecoder message of
            Ok rl ->
              let
                log = Debug.log "regions" message
              in {newmodel | regions = rl } |> withNoCmd
            _ ->
              newmodel |> withNoCmd
        Ok (newmodel, _) ->
          newmodel |> withNoCmd
        _ ->
          model |> withNoCmd

    Connect ->
      let
          cmd = WebSocket.makeOpenWithKey socketKey socketURL
            |> WebSocket.send cmdPort
      in
        (model, cmd)

    Login ->
      let
          cmd = WebSocket.makeSend socketKey """
                  {
                      "operation": "user/login",
                      "body": {
                          "name": "test",
                          "password": "test"
                      }
                  }
                  """
            |> WebSocket.send cmdPort
      in
        (model, cmd)

    ListRegions ->
      let
          cmd = WebSocket.makeSend socketKey """
                  {
                      "operation": "region/list"
                  }
                  """
            |> WebSocket.send cmdPort
      in
        (model, cmd)

    Increment ->
      { model | value = model.value + 1} |> withNoCmd

    Decrement ->
      { model | value = model.value - 1} |> withNoCmd


renderRegion region =
  div []
    [ p [] [
      text ("#" ++ String.fromInt region.id ++ " " ++ region.name ++ " (" ++ region.transport_company ++ ")")
      ]
    ]


view: Model -> Html Msg
view model =
  div []
    (
      [ button [ onClick Connect ] [ text "Connect" ]
      , button [ onClick Login ] [ text "Login" ]
      , button [ onClick ListRegions ] [ text "List Regions" ]
      , br [] []
      , button [ onClick Decrement ] [ text "-" ]
      , div [] [ text (String.fromInt model.value) ]
      , button [ onClick Increment ] [ text "+" ]
      ] ++ List.map renderRegion model.regions
    )
