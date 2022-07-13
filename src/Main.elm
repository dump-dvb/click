module Main exposing (..)

import Msg exposing (Msg)

import Browser

import Html.Styled as Html exposing (Html, button, div, text, br, p, table, thead, tbody, th, tr, td, h3)
import Html.Styled.Events exposing (onClick)

import Render exposing (renderPanel)

import Json.Encode as Encode exposing (Value, encode)
import Json.Decode as Decode exposing (Decoder)
import Json.Decode.Pipeline as JDPipeline

import PortFunnel exposing (decodeGenericMessage)
import PortFunnel.WebSocket as WebSocket

import Messaging exposing (send, parseResponse)

import Port exposing (cmdPort, subPort)

import Requests exposing (performRequest)
import Config exposing (socketKey, socketURL)
import Model exposing (Model, expector)


main =
  Browser.element
  { init = init
  , update = update
  , view = view >> Html.toUnstyled
  , subscriptions = subscriptions
  }

init: () -> ( Model, Cmd Msg )
init _ =
  { websocket = WebSocket.initialState
  , isConnected = False
  , regions = []
  , stations = []
  , expect = Nothing
  } |> withNoCmd

subscriptions : Model -> Sub Msg
subscriptions model =
  subPort Msg.Process

withCmd: Cmd msg -> Model -> (Model, Cmd msg)
withCmd command model = (model, command)

withNoCmd: Model -> (Model, Cmd msg)
withNoCmd model = (model, Cmd.none)


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
        logIncoming = Debug.log "incoming to-process" <| Encode.encode 0 value
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
        Ok (newmodel, WebSocket.NoResponse) ->
          -- connect upon startup
          let
            tagResult = Decode.decodeValue (Decode.field "tag" Decode.string) value
          in
            case tagResult of
              Ok "startup" ->
                update Msg.Connect model
              _ ->
                model |> withNoCmd

        Ok (newmodel, WebSocket.ConnectedResponse ms) ->
          { newmodel | isConnected = True } |> withNoCmd

        Ok (newmodel, WebSocket.ReconnectedResponse ms) ->
          { newmodel | isConnected = True } |> withNoCmd

        Ok (newmodel, WebSocket.ClosedResponse ms) ->
          { newmodel | isConnected = False } |> withNoCmd

        Ok (newmodel, WebSocket.CmdResponse ms) ->
          newmodel |> withCmd (WebSocket.send cmdPort ms)

        Ok (newmodel, WebSocket.MessageReceivedResponse { message }) ->
          case model.expect of
            Just (Model.Expector expect) ->
              (Result.withDefault newmodel <| expect message <| newmodel) |> withNoCmd
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

    Msg.Request r ->
      performRequest r model

    Msg.UpdateData fn ->
      fn model |> withNoCmd


view: Model -> Html Msg
view model =
  div []
    (
      if not model.isConnected
      then
        [ button [ onClick Msg.Connect ] [ text "Connect" ] ]
      else
        [ button [ onClick Msg.Login ] [ text "Login" ]
        , br [] []
        , div [] <| renderPanel model
        ]
    )
