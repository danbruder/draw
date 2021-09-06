module Domain.Word exposing (..)

import Domain.User as User exposing (User)
import Json.Decode as JD


type alias Word =
    { val : String
    , letters : List (Maybe String)
    }


decoder =
    JD.map2 Word
        (JD.field "val" JD.string)
        (JD.field "letters" (JD.list (JD.nullable JD.string)))
