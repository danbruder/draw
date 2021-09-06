module Domain.DrawingModel exposing (DrawingModel, decoder)

import Domain.Guess as Guess exposing (Guess)
import Domain.User as User exposing (User)
import Domain.Word as Word exposing (Word)
import Json.Decode as JD


type alias DrawingModel =
    { artist : String
    , word : Word
    , secondsLeft : Int
    , frames : List Int
    , guesses : List Guess
    }


decoder =
    JD.map5 DrawingModel
        (JD.field "artist" JD.string)
        (JD.field "word" Word.decoder)
        (JD.field "seconds_left" JD.int)
        (JD.field "frames" (JD.list JD.int))
        (JD.field "guesses" (JD.list Guess.decoder))
