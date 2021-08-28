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
import Tailwind.Utilities as TW
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
      , me = Nothing
      , nameInput = ""
      }
    , Cmd.none
    )



-- UPDATE


type Msg
    = TypedInNameField String
    | ClickedSetName


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        ClickedSetName ->
            ( { model
                | nameInput = ""
                , me = Just (User.init model.nameInput)
              }
            , Cmd.none
            )

        TypedInNameField name ->
            ( { model | nameInput = name }, Cmd.none )



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none



-- VIEW


view : Model -> View Msg
view model =
    { title = "Room 123"
    , body =
        [ H.toUnstyled <|
            H.div []
                [ H.h1 [] [ H.text "Room 123" ]
                , case model.game.turn of
                    Turn.WaitingForUsersToJoin ->
                        case model.me of
                            Nothing ->
                                viewUserJoin model

                            Just me ->
                                viewWaitingForOthersToJoin me model

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


viewWaitingForOthersToJoin user model =
    H.div []
        [ H.h1 []
            [ H.text ("Hello, " ++ user.id) ]
        , viewDrawing
        ]


viewDrawing =
    H.div [] [ H.text "Drawing" ]
