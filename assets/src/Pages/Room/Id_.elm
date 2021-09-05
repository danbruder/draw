module Pages.Room.Id_ exposing (Model, Msg, page)

import Css
import Css.Global
import Dict exposing (Dict)
import Domain.Game as Game
import Domain.Turn as Turn
import Domain.User as User exposing (User)
import Gen.Params.Room.Id_ exposing (Params)
import Html.Styled as H
import Html.Styled.Attributes as HA exposing (css)
import Html.Styled.Events as HE
import Json.Decode as JD
import Json.Encode as JE
import Net
import Page
import Request
import Shared
import Tailwind.Breakpoints as TB
import Tailwind.Utilities as TW exposing (..)
import View exposing (View)


page : Shared.Model -> Request.With Params -> Page.With Model Msg
page shared req =
    Page.element
        { init = init
        , update = update
        , view = view
        , subscriptions = subscriptions
        }



-- INIT


type alias Model =
    { me : Maybe String
    , nameInput : String
    , room : Room
    }


init : ( Model, Cmd Msg )
init =
    ( { me = Nothing
      , nameInput = ""
      , room =
            { users = Dict.empty
            , magicNumber = 1
            }
      }
    , Cmd.none
    )



-- UPDATE


type Msg
    = TypedInNameField String
    | ClickedSetName
      -- | ClickedStart
      -- | ClickedWordOption String
      -- | TypedInGuess String
      -- | ClickedGuessSubmit User
    | GotMessage ServerMsgIn


send =
    encodeServerMsgOut >> Net.tx


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        ClickedSetName ->
            ( { model | nameInput = "" }
            , send
                (SetName
                    { id = model.me |> Maybe.withDefault ""
                    , name = model.nameInput
                    }
                )
            )

        TypedInNameField name ->
            ( { model | nameInput = name }, Cmd.none )

        -- ClickedWordOption word ->
        --     ( { model
        --         | game = Game.wordChosen word model.game
        --       }
        --     , Cmd.none
        --     )
        -- TypedInGuess guess ->
        --     ( { model | guessInput = guess }, Cmd.none )
        -- ClickedGuessSubmit me ->
        --     ( { model
        --         | game = Game.userGuessed me model.guessInput model.game
        --         , guessInput = ""
        --       }
        --     , Cmd.none
        --     )
        -- ClickedStart ->
        --     ( { model | game = Game.start model.game }
        --     , Net.tx (JE.int 1)
        --     )
        GotMessage serverMsg ->
            case serverMsg of
                JoinPayload { me, room } ->
                    ( { model | me = Just me }, Cmd.none )

                _ ->
                    ( model, Cmd.none )


type ServerMsgIn
    = JoinPayload
        { me : String
        , room : Room
        }
    | Invalid


type ServerMsgOut
    = SetName
        { id : String
        , name : String
        }


type alias Room =
    { users : Dict String String
    , magicNumber : Int
    }


encodeServerMsgOut out =
    case out of
        SetName { id, name } ->
            JE.object
                [ ( "id", JE.string id )
                , ( "name", JE.string name )
                , ( "type", JE.string "SetName" )
                ]



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    let
        roomDecoder =
            JD.map2 Room
                (JD.field "users" (JD.dict JD.string))
                (JD.field "magic_number" JD.int)

        joinPayloadDecoder : JD.Decoder ServerMsgIn
        joinPayloadDecoder =
            JD.map2 (\me room -> JoinPayload { me = me, room = room })
                (JD.field "me" JD.string)
                (JD.field "room" roomDecoder)

        msgFromType : String -> JD.Decoder ServerMsgIn
        msgFromType ty =
            case ty of
                "JoinPayload" ->
                    joinPayloadDecoder

                _ ->
                    JD.fail "Unknown server message"

        msgDecoder : JD.Decoder ServerMsgIn
        msgDecoder =
            JD.field "type" JD.string
                |> JD.andThen msgFromType

        doDecode val =
            case JD.decodeValue msgDecoder val of
                Ok msg ->
                    msg

                Err _ ->
                    Invalid
    in
    Net.rx (doDecode >> GotMessage)



-- VIEW


view : Model -> View Msg
view model =
    { title = "Room 123"
    , body =
        [ -- Like this:
          H.toUnstyled <|
            H.div []
                [ Css.Global.global globalStyles
                , viewUserJoin model
                ]
        ]
    }


viewUserJoin : Model -> H.Html Msg
viewUserJoin model =
    H.div []
        [ H.h1 [] [ H.text "Welcome!" ]
        , H.p [] [ H.text "Please enter your name" ]
        , H.input
            [ HA.placeholder "Name"
            , HE.onInput TypedInNameField
            , HA.value model.nameInput
            ]
            []
        , H.button
            [ HE.onClick ClickedSetName
            ]
            [ H.text "Let's go!"
            ]
        , H.div []
            [ H.ul [] <| List.map (\i -> H.text i) (Dict.values model.room.users)
            ]
        ]



-- viewTakingATurn user subModel model =
--     if Turn.userIsActive user model.game.turn then
--         viewBase
--             [ viewDrawing
--             , viewUserList model
--             ]
--             model
--     else
--         viewBase
--             [ viewReadonlyDrawing
--             , H.div
--                 []
--                 [ viewUserList model
--                 , viewGuessingInput user model
--                 , viewAllGuesses user model
--                 ]
--             ]
--             model
-- viewChoosingAWord user subModel model =
--     if Turn.userIsActive user model.game.turn then
--         viewBase
--             [ viewWordSelection subModel
--             , viewUserList model
--             ]
--             model
--     else
--         viewBase
--             [ viewDrawing
--             , viewUserList model
--             ]
--             model
-- viewAllGuesses me model =
--     let
--         guesses =
--             Game.guesses me model.game
--         viewSingleGuess guess =
--             H.li []
--                 [ H.span [ css [ font_bold ] ]
--                     [ H.text guess.user.id
--                     ]
--                 , H.text ": "
--                 , H.span []
--                     [ H.text guess.value
--                     ]
--                 ]
--     in
--     H.div
--         [ css
--             [ rounded
--             , w_full
--             , m_4
--             , border
--             , h_80
--             , overflow_y_scroll
--             ]
--         ]
--         [ H.div
--             [ css
--                 [ bg_gray_100
--                 , p_2
--                 ]
--             ]
--             [ H.text "All Guesses" ]
--         , H.div
--             [ css
--                 [ p_2
--                 ]
--             ]
--             [ if List.length guesses > 0 then
--                 H.ul [] <| List.map viewSingleGuess guesses
--       else
--         H.text "No guesses yet"
--     ]
-- ]
-- viewGuessingInput me model =
--     H.div
--         [ css
--             [ bg_gray_100
--             , rounded
--             , p_2
--             , w_full
--             , m_4
--             ]
--         ]
--         [ H.div [] [ H.text "Guess a word!" ]
--         , H.form [ HE.onSubmit (ClickedGuessSubmit me) ]
--             [ H.input
--                 [ HA.placeholder "Guess"
--                 , css
--                     [ border
--                     , border_gray_300
--                     , px_2
--                     , py_1
--                     , rounded
--                     , my_2
--                     ]
--                 , HE.onInput TypedInGuess
--                 , HA.value model.guessInput
--                 ]
--                 []
--             , H.input
--                 [ HA.type_ "submit"
--                 , HA.value "Submit"
--                 , css
--                     [ bg_white
--                     , rounded
--                     , border
--                     , bg_purple_100
--                     , border_gray_300
--                     , px_2
--                     , mx_1
--                     , py_1
--                     ]
--                 ]
--                 []
--             ]
--         ]
-- viewWordSelection { words } =
--     let
--         viewWordOption word =
--             H.li
--                 [ HE.onClick (ClickedWordOption word)
--                 ]
--                 [ H.text word ]
--     in
--     H.div []
--         [ H.text "Choose a word :)"
--         , H.ul [] <| List.map viewWordOption words
--         ]


viewBase content model =
    H.div []
        [ viewHeader
        , H.div
            [ css
                [ flex
                , justify_between
                ]
            ]
            content

        -- , viewControls model
        ]


viewWaitingForOthersToJoin user model =
    viewBase
        [ viewDrawing
        ]
        model


viewHeader =
    H.div
        [ css
            [ flex
            , justify_center
            , text_sm
            , text_gray_600
            , uppercase
            , font_bold
            , bg_gray_100
            , p_2
            ]
        ]
        [ H.text "Room 123" ]


viewDrawing =
    H.div
        [ css
            [ w_72
            , h_72
            , border
            , shadow
            , rounded
            ]
        ]
        [ H.text "Drawing" ]


viewReadonlyDrawing =
    H.div
        [ css
            [ w_72
            , h_72
            , border
            , shadow
            , rounded
            ]
        ]
        [ H.text "Read only Drawing" ]


viewUserList model =
    let
        viewUser user =
            H.div [] [ H.text user.id ]
    in
    H.div
        [ css
            [ p_2
            , bg_gray_100
            , m_4
            , w_full
            , rounded
            ]
        ]
    <|
        List.map viewUser (Game.users model.game)



-- viewControls model =
--     H.div
--         []
--         [ case model.game.turn of
--             Turn.WaitingForUsersToJoin ->
--                 H.button
--                     [ css [ bg_purple_200, text_red_500, font_bold, border, p_4, rounded, border_purple_300, shadow ]
--                     , HE.onClick ClickedStart
--                     ]
--                     [ H.text "Start" ]
--             _ ->
--                 H.text ""
--         , H.div [] [ H.text "Game State:" ]
--         , H.div []
--             [ model.game.turn |> Turn.toString |> H.text
--             ]
--         ]
