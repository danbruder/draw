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


toString : Turn -> String
toString turn =
    case turn of
        WaitingForUsersToJoin ->
            "Waiting to join"

        TakingATurn _ ->
            "Taking a turn"

        EndingATurn ->
            "Ending"

        ChoosingAWord _ ->
            "Choosing a word"


userIsActive : User -> Turn -> Bool
userIsActive user turn =
    case turn of
        TakingATurn { artist } ->
            artist.id == user.id

        ChoosingAWord { artist } ->
            artist.id == user.id

        _ ->
            False
