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
    }


init : ( Model, Cmd Msg )
init =
    ( { game = Game.init
      , me = Just (User.init "Dan")
      , nameInput = ""
      }
    , Cmd.none
    )



-- UPDATE


type Msg
    = TypedInNameField String
    | ClickedSetName
    | ClickedStart
    | ClickedWordOption String


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

        ClickedStart ->
            ( { model
                | game = Game.start model.game
              }
            , Cmd.none
            )



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
            , viewGuessingInput model
            , viewUserList model
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


viewGuessingInput model =
    H.div []
        [ H.input [] [] ]


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
            [ p_8
            , w_40
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
