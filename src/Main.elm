module Main exposing (..)

import Msg exposing (Msg)

import Browser

import Html.Styled as Html exposing (Html, button, div, text, br, p, table, thead, tbody, th, tr, td, h3)
import Html.Styled.Events exposing (onClick)

import Render exposing (renderPanel)

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
    view = view >> Html.toUnstyled,
    subscriptions = subscriptions
  }

type alias Model =
  { websocket: WebSocket.State
  , regions: List Region
  }

init: () -> ( Model, Cmd Msg )
init _ =
  { websocket = WebSocket.initialState
  , regions = []
  } |> withNoCmd

subscriptions : Model -> Sub Msg
subscriptions model =
  subPort Msg.Process

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


update: Msg -> Model -> (Model, Cmd Msg)
update msg model =
  case msg of
    Msg.Process value ->
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

    Msg.Connect ->
      let
          cmd = WebSocket.makeOpenWithKey socketKey socketURL
            |> WebSocket.send cmdPort
      in
        (model, cmd)

    Msg.Login ->
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

    Msg.ListRegions ->
      let
          cmd = WebSocket.makeSend socketKey """
                  {
                      "operation": "region/list"
                  }
                  """
            |> WebSocket.send cmdPort
      in
        (model, cmd)

view: Model -> Html Msg
view model =
  div []
    (
      [ button [ onClick Msg.Connect ] [ text "Connect" ]
      , button [ onClick Msg.Login ] [ text "Login" ]
      , br [] []
      , div [] <| renderPanel model
      ]
    )
