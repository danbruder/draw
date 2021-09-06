module Pages.Room.Id_ exposing (Model, Msg, page)

import Css
import Css.Global
import Dict exposing (Dict)
import Domain.Machine as Machine exposing (Machine)
import Domain.Room as Room exposing (Room)
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
      , room = Room.init
      }
    , Cmd.none
    )



-- UPDATE


type Msg
    = TypedInNameField String
    | ClickedSetName
    | GotMessage (Result String ServerMsgIn)


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

        GotMessage serverMsg ->
            case serverMsg of
                Ok { me, room } ->
                    ( { model | me = Just me, room = room }, Cmd.none )

                _ ->
                    ( model, Cmd.none )


type alias ServerMsgIn =
    { me : String
    , room : Room
    }


type ServerMsgOut
    = SetName
        { id : String
        , name : String
        }


encodeServerMsgOut out =
    case out of
        SetName { id, name } ->
            JE.object
                [ ( "id", JE.string id )
                , ( "name", JE.string name )
                , ( "type", JE.string "SetName" )
                ]


serverMsgInDecoder =
    JD.map2 ServerMsgIn
        (JD.field "me" JD.string)
        (JD.field "payload" Room.decoder)



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    let
        doDecode val =
            JD.decodeValue serverMsgInDecoder val
                |> Result.mapError
                    (\err ->
                        let
                            _ =
                                Debug.log "err" err
                        in
                        "Invalid"
                    )
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
            [ H.ul [] <| List.map (\i -> H.li [] [ H.text i.name ]) (Dict.values model.room.users)
            ]
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
