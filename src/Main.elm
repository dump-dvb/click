module Main exposing (..)

import Msg exposing (Msg)

import Browser

import Html.Styled.Attributes exposing (type_)
import Html.Styled as Html exposing (Html, button, div, text, br, p, table, thead, tbody, th, tr, td, h3, label, input)
import Html.Styled.Events exposing (onClick, onInput)

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

import Serialization exposing (successDecoder)


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
  , username = ""
  , password = ""
  , loggedIn = False
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
          { newmodel | isConnected = False, loggedIn = False } |> withNoCmd

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

    Msg.SetUsername username ->
      { model | username = username } |> withNoCmd

    Msg.SetPassword password ->
      { model | password = password } |> withNoCmd

    Msg.Login ->
      let
          request = Encode.encode 0
                <| Encode.object
                   [ ("operation", Encode.string "user/login")
                   , ("body",
                       Encode.object
                       [ ("name", Encode.string model.username)
                       , ("password", Encode.string model.password)
                       ]
                     )
                   ]
          cmd = WebSocket.makeSend socketKey request
            |> WebSocket.send cmdPort
          expect = expector
            (Decode.decodeString successDecoder)
            (\m { success } ->
              { m
              | loggedIn = success
              , password = if success then model.password else ""
              })
      in
        { model | expect = expect } |> withCmd cmd


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
        (
          if model.loggedIn
          then
            [ text <| "Logged in as " ++ model.username ]
          else
            [ label [] [ text "Username: " ]
            , input [ onInput (\username -> Msg.SetUsername username) ] []
            , label [] [ text " Password: " ]
            , input
              [ onInput (\password -> Msg.SetPassword password)
              , type_ "password"
              ] []
            , button [ onClick Msg.Login ] [ text "Login" ]
            ]
        ) ++
        [ br [] []
        , div [] <| renderPanel model
        ]
    )
