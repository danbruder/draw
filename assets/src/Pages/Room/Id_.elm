module Pages.Room.Id_ exposing (Model, Msg, page)

import Css
import Css.Global
import Dict
import Domain.Game as Game
import Domain.Turn as Turn
import Domain.User as User exposing (User)
import Gen.Params.Room.Id_ exposing (Params)
import Html.Styled as H
import Html.Styled.Attributes as HA exposing (css)
import Html.Styled.Events as HE
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
    { game : Game.Game
    , me : Maybe User
    , nameInput : String
    , guessInput : String
    }


init : ( Model, Cmd Msg )
init =
    ( { game = Game.init
      , me = Just (User.init "Dan")
      , nameInput = ""
      , guessInput = ""
      }
    , Cmd.none
    )



-- UPDATE


type Msg
    = TypedInNameField String
    | ClickedSetName
    | ClickedStart
    | ClickedWordOption String
    | TypedInGuess String
    | ClickedGuessSubmit User


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        ClickedWordOption word ->
            ( { model
                | game = Game.wordChosen word model.game
              }
            , Cmd.none
            )

        ClickedSetName ->
            ( { model
                | nameInput = ""
                , me = Just (User.init model.nameInput)
              }
            , Cmd.none
            )

        TypedInNameField name ->
            ( { model | nameInput = name }, Cmd.none )

        TypedInGuess guess ->
            ( { model | guessInput = guess }, Cmd.none )

        ClickedGuessSubmit me ->
            ( { model
                | game = Game.userGuessed me model.guessInput model.game
                , guessInput = ""
              }
            , Cmd.none
            )

        ClickedStart ->
            ( { model | game = Game.start model.game }, Cmd.none )



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none



-- VIEW


view : Model -> View Msg
view model =
    { title = "Room 123"
    , body =
        [ -- Like this:
          H.toUnstyled <|
            H.div []
                [ Css.Global.global globalStyles
                , case model.me of
                    Nothing ->
                        viewUserJoin model

                    Just me ->
                        case model.game.turn of
                            Turn.WaitingForUsersToJoin ->
                                viewWaitingForOthersToJoin me model

                            Turn.ChoosingAWord subModel ->
                                viewChoosingAWord me subModel model

                            Turn.TakingATurn subModel ->
                                viewTakingATurn me subModel model

                            _ ->
                                Debug.todo ""
                ]
        ]
    }


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
        ]


viewTakingATurn user subModel model =
    if Turn.userIsActive user model.game.turn then
        viewBase
            [ viewDrawing
            , viewUserList model
            ]
            model

    else
        viewBase
            [ viewReadonlyDrawing
            , H.div
                []
                [ viewUserList model
                , viewGuessingInput user model
                , viewAllGuesses user model
                ]
            ]
            model


viewChoosingAWord user subModel model =
    if Turn.userIsActive user model.game.turn then
        viewBase
            [ viewWordSelection subModel
            , viewUserList model
            ]
            model

    else
        viewBase
            [ viewDrawing
            , viewUserList model
            ]
            model


viewAllGuesses me model =
    let
        guesses =
            Game.guesses me model.game

        viewSingleGuess guess =
            H.li []
                [ H.span [ css [ font_bold ] ]
                    [ H.text guess.user.id
                    ]
                , H.text ": "
                , H.span []
                    [ H.text guess.value
                    ]
                ]
    in
    H.div
        [ css
            [ rounded
            , w_full
            , m_4
            , border
            , h_80
            , overflow_y_scroll
            ]
        ]
        [ H.div
            [ css
                [ bg_gray_100
                , p_2
                ]
            ]
            [ H.text "All Guesses" ]
        , H.div
            [ css
                [ p_2
                ]
            ]
            [ if List.length guesses > 0 then
                H.ul [] <| List.map viewSingleGuess guesses

              else
                H.text "No guesses yet"
            ]
        ]


viewGuessingInput me model =
    H.div
        [ css
            [ bg_gray_100
            , rounded
            , p_2
            , w_full
            , m_4
            ]
        ]
        [ H.div [] [ H.text "Guess a word!" ]
        , H.form [ HE.onSubmit (ClickedGuessSubmit me) ]
            [ H.input
                [ HA.placeholder "Guess"
                , css
                    [ border
                    , border_gray_300
                    , px_2
                    , py_1
                    , rounded
                    , my_2
                    ]
                , HE.onInput TypedInGuess
                , HA.value model.guessInput
                ]
                []
            , H.input
                [ HA.type_ "submit"
                , HA.value "Submit"
                , css
                    [ bg_white
                    , rounded
                    , border
                    , bg_purple_100
                    , border_gray_300
                    , px_2
                    , mx_1
                    , py_1
                    ]
                ]
                []
            ]
        ]


viewWordSelection { words } =
    let
        viewWordOption word =
            H.li
                [ HE.onClick (ClickedWordOption word)
                ]
                [ H.text word ]
    in
    H.div []
        [ H.text "Choose a word :)"
        , H.ul [] <| List.map viewWordOption words
        ]


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
        , viewControls model
        ]


viewWaitingForOthersToJoin user model =
    viewBase
        [ viewDrawing
        , viewUserList model
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


viewControls model =
    H.div
        []
        [ case model.game.turn of
            Turn.WaitingForUsersToJoin ->
                H.button
                    [ css [ bg_purple_200, text_red_500, font_bold, border, p_4, rounded, border_purple_300, shadow ]
                    , HE.onClick ClickedStart
                    ]
                    [ H.text "Start" ]

            _ ->
                H.text ""
        , H.div [] [ H.text "Game State:" ]
        , H.div []
            [ model.game.turn |> Turn.toString |> H.text
            ]
        ]
