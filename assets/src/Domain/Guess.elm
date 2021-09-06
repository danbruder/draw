module Domain.Guess exposing (..)

import Domain.User as User exposing (User)
import Json.Decode as JD


type alias Guess =
    { val : String
    , correct : Bool
    , user : String
    }


decoder =
    JD.map3 Guess
        (JD.field "val" JD.string)
        (JD.field "correct" JD.bool)
        (JD.field "user" JD.string)
