module Messaging exposing (..)

import PortFunnel exposing (messageToJsonString)
import PortFunnel.WebSocket as WebSocket

import Port exposing (cmdPort, subPort)

--send : Model -> WebSocket.Message -> Cmd Msg
send model message =
  WebSocket.send cmdPort (WebSocket.makeSend model.key message)

parseResponse response =
  case response of
    WebSocket.ListResponse list ->
      List.map parseResponse list |> List.foldl (++) "list response!\n"
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
    WebSocket.ErrorResponse err ->
      "error: " ++ parseError err

parseError err =
  case err of
    WebSocket.SocketAlreadyOpenError _ ->
      "SocketAlreadyOpenError"
    WebSocket.SocketConnectingError _ ->
      "SocketConnectingError"
    WebSocket.SocketClosingError _ ->
      "SocketClosingError"
    WebSocket.SocketNotOpenError _ ->
      "SocketNotOpenError"
    WebSocket.LowLevelError _ ->
      "LowLevelError"
    WebSocket.UnexpectedConnectedError { key, description } ->
      "UnexpectedConnectedError: " ++ description
    WebSocket.UnexpectedMessageError { key, message } ->
      "UnexpectedMessageError: " ++ message
    WebSocket.InvalidMessageError { message } ->
      "InvalidMessageError: " ++ (messageToJsonString WebSocket.moduleDesc message)
