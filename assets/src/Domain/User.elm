module Domain.User exposing (User, decoder, init)

import Json.Decode as JD


type alias User =
    { name : String
    , points : Int
    }


init : String -> User
init name =
    User name 0


decoder =
    JD.map2 User
        (JD.field "name" JD.string)
        (JD.field "points" JD.int)
