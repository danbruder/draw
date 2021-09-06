module Domain.Machine exposing (..)

import Domain.DrawingModel as DrawingModel exposing (DrawingModel)
import Json.Decode as JD


type Machine
    = Joining
    | SelectingWord
        { artist : String
        }
    | Drawing DrawingModel


init =
    Joining


decoder =
    let
        msgFromType : String -> JD.Decoder Machine
        msgFromType ty =
            case ty of
                "Joining" ->
                    JD.succeed Joining

                "SelectingWord" ->
                    JD.field "artist" JD.string
                        |> JD.andThen
                            (\artist ->
                                JD.succeed
                                    (SelectingWord
                                        { artist = artist
                                        }
                                    )
                            )

                "Drawing" ->
                    DrawingModel.decoder
                        |> JD.andThen (\drawing -> JD.succeed (Drawing drawing))

                _ ->
                    JD.fail "Unknown server message"
    in
    JD.field "type" JD.string
        |> JD.andThen msgFromType
