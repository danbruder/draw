module Domain.Guess exposing (..)

import Domain.User as User exposing (User)


type alias Guess =
    { at : Int
    , user : User
    , value : String
    , correct : Bool
    }
