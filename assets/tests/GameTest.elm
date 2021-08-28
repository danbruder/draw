module GameTest exposing (..)

import Domain.Game as Game
import Domain.Turn as Turn
import Expect exposing (Expectation)
import Fuzz exposing (Fuzzer, int, list, string)
import Test exposing (..)


suite : Test
suite =
    describe "Can progress through turms"
        [ test "Can initialize a game" <|
            \_ -> Expect.equal True False
        ]
