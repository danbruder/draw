module Domain.Room exposing (..)

import Dict exposing (Dict)
import Domain.Machine as Machine exposing (Machine)
import Domain.User as User exposing (User)
import Json.Decode as JD


type alias Room =
    { users : Dict String User
    , turnOffset : Int
    , machine : Machine
    }


init =
    Room
        Dict.empty
        0
        Machine.init


decoder =
    JD.map3 Room
        (JD.field "users" (JD.dict User.decoder))
        (JD.field "turn_offset" JD.int)
        (JD.field "machine" Machine.decoder)
