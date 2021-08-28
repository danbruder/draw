module Domain.Game exposing (..)

import Array exposing (Array)
import Dict exposing (Dict)
import Domain.Guess as Guess exposing (Guess)
import Domain.Turn as Turn exposing (..)
import Domain.User as User exposing (User)
import Set exposing (Set)


type alias Game =
    { turn : Turn
    , words : Set String
    , usedWords : Set String
    , points : Dict String Int
    , users : Array User
    , activeUser : Int
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
    , users =
        [ "Dan", "Brittany", "Adelynn", "Paul", "Viola", "Poppy" ]
            |> List.map User.init
            |> Array.fromList
    , activeUser = 1
    }
        |> start
        |> wordChosen "one"


users : Game -> List User
users game =
    game.users
        |> Array.toList


start : Game -> Game
start game =
    -- Select a user
    case Array.get game.activeUser game.users of
        Just user ->
            { game
                | turn =
                    Turn.ChoosingAWord
                        { artist = user
                        , secondsLeft = 180
                        , words = game.words |> Set.toList
                        }
            }

        Nothing ->
            Debug.todo ""


wordChosen : String -> Game -> Game
wordChosen word game =
    case game.turn of
        Turn.ChoosingAWord { artist } ->
            { game
                | turn =
                    Turn.TakingATurn
                        { artist = artist
                        , secondsLeft = 180
                        , guessers = game.users |> Array.toList |> List.filter (\u -> u.id == artist.id)
                        , guesses = []
                        , currentWord = word
                        }
            }

        _ ->
            Debug.todo ""


userGuessed : User -> String -> Game -> Game
userGuessed me guess game =
    case game.turn of
        Turn.TakingATurn subModel ->
            { game
                | turn =
                    Turn.TakingATurn
                        { subModel
                            | guesses =
                                Guess 0 me guess (guess == subModel.currentWord)
                                    :: subModel.guesses
                        }
            }

        _ ->
            Debug.todo ""


guesses : User -> Game -> List Guess
guesses me game =
    case game.turn of
        Turn.TakingATurn subModel ->
            subModel.guesses

        _ ->
            Debug.todo ""
