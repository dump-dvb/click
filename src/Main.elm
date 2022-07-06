port module Main exposing (..)

import Browser
import Html exposing (Html, button, div, text)
import Html.Events exposing (onClick)
import Json.Encode exposing (Value, encode)

import PortFunnel exposing (decodeGenericMessage)
import PortFunnel.WebSocket as WebSocket

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
  }

init: () -> ( Model, Cmd Msg )
init _ = { value = 0, websocket = WebSocket.initialState } |> withNoCmd

subscriptions : Model -> Sub Msg
subscriptions model =
  subPort Process

withCmd: Cmd msg -> Model -> (Model, Cmd msg)
withCmd command model = (model, command)

withNoCmd: Model -> (Model, Cmd msg)
withNoCmd model = (model, Cmd.none)

port cmdPort : Json.Encode.Value -> Cmd msg
port subPort : (Json.Encode.Value -> msg) -> Sub msg

--send : Model -> WebSocket.Message -> Cmd Msg
send model message =
  WebSocket.send cmdPort (WebSocket.makeSend model.key message)

stateAccessor:
  { get: Model -> WebSocket.State
  , set: WebSocket.State -> Model -> Model
  }
stateAccessor =
  { get = .websocket
  , set = \state model -> { model | websocket = state}
  }

parseResponse response =
  case response of
    WebSocket.ConnectedResponse body ->
      "connected! " ++ body.description
    WebSocket.ReconnectedResponse body ->
      "reconnected! " ++ body.description
    WebSocket.MessageReceivedResponse body ->
      "received! " ++ body.message
    WebSocket.ClosedResponse body ->
      "closed! " ++ body.reason
    WebSocket.BytesQueuedResponse _ ->
      "bytes queued!"
    WebSocket.NoResponse ->
      "no response!"
    WebSocket.CmdResponse _ ->
      "cmd response!"
    _ ->
      "other result!"

type Msg = Increment | Decrement | Login | Process Json.Encode.Value

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
        Ok (newmodel, _) ->
          newmodel |> withNoCmd
        _ ->
          model |> withNoCmd

    Login ->
      let
          cmd = WebSocket.makeOpen "wss://management-backend.staging.dvb.solutions"
            |> WebSocket.send cmdPort
      in
        (model, cmd)

    Increment ->
      { model | value = model.value + 1} |> withNoCmd

    Decrement ->
      { model | value = model.value - 1} |> withNoCmd


view: Model -> Html Msg
view model =
  div []
    [ button [ onClick Login ] [ text "Login" ]
    , button [ onClick Decrement ] [ text "-" ]
    , div [] [ text (String.fromInt model.value) ]
    , button [ onClick Increment ] [ text "+" ]
    ]
