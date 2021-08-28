module Domain.Turn exposing (..)

import Domain.User as User exposing (User)


type Turn
    = WaitingForUsersToJoin
    | TakingATurn
        { artist : User
        , guessers : List User
        , secondsLeft : Int
        , guesses : List Guess
        }
    | EndingATurn
    | ChoosingAWord
        { artist : User
        , secondsLeft : Int
        , words : List String
        }


type alias Guess =
    { at : Int
    , user : User
    , value : String
    , correct : Bool
    }
