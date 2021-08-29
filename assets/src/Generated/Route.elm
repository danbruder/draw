module Generated.Route exposing
    ( Route(..)
    , fromUrl
    , toHref
    )

import Url exposing (Url)
import Url.Parser as Parser exposing ((</>), Parser)


type Route
    = Home_
    | Room_Id_


fromUrl : Url -> Maybe Route
fromUrl =
    Parser.parse routes


routes : Parser (Route -> a) a
routes =
    Parser.oneOf
        [ Parser.map Home_ (Parser.s "home_")
        , Parser.map Room_Id_ (Parser.s "room" </> Parser.s "id_")
        ]


toHref : Route -> String
toHref route =
    let
        segments : List String
        segments =
            case route of
                Home_ ->
                    [ "home_" ]
                
                Room_Id_ ->
                    [ "room", "id_" ]
    in
    segments
        |> String.join "/"
        |> String.append "/"