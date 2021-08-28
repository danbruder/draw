module Domain.Game exposing (..)

import Dict exposing (Dict)
import Domain.Turn as Turn exposing (..)
import Domain.User as User exposing (User)
import Set exposing (Set)


type alias Game =
    { turn : Turn
    , words : Set String
    , usedWords : Set String
    , points : Dict String Int
    , users : Dict String User
    }


init : Game
init =
    { turn = Turn.WaitingForUsersToJoin
    , words =
        Set.fromList
            [ "one"
            , "two"
            , "three"
            ]
    , usedWords = Set.empty
    , points = Dict.empty
    , users = Dict.empty
    }
