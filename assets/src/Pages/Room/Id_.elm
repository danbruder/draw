module Pages.Room.Id_ exposing (Model, Msg, page)

import Board
import Canvas
import Css
import Css.Global
import Dict exposing (Dict)
import Domain.DrawingModel as DrawingModel exposing (DrawingModel)
import Domain.Machine as Machine exposing (..)
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
    , board : Board.Model
    }


init : ( Model, Cmd Msg )
init =
    let
        ( boardModel, boardCmd ) =
            Board.init
    in
    ( { me = Nothing
      , nameInput = ""
      , room = Room.init
      , board = boardModel
      }
    , boardCmd
        |> Cmd.map BoardMsg
    )



-- UPDATE


type Msg
    = TypedInNameField String
    | ClickedSetName
    | ClickedWord String
    | ClickedStartGame
    | GotMessage (Result String ServerMsgIn)
    | BoardMsg Board.Msg


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

        ClickedStartGame ->
            ( model
            , send
                (StartGame
                    { id = model.me |> Maybe.withDefault ""
                    }
                )
            )

        ClickedWord word ->
            ( { model | nameInput = "" }
            , send
                (SetWord
                    { id = model.me |> Maybe.withDefault ""
                    , word = word
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

        BoardMsg boardMsg ->
            let
                ( boardModel, boardCmd ) =
                    Board.update boardMsg model.board

                framesCmd =
                    case ( List.length boardModel.toDraw > 0, model.me ) of
                        ( True, Just me ) ->
                            send (GotCanvasFrames { id = me, frames = boardModel.toDraw })

                        _ ->
                            Cmd.none
            in
            ( { model | board = boardModel }
            , Cmd.batch
                [ boardCmd |> Cmd.map BoardMsg
                , framesCmd
                ]
            )


type alias ServerMsgIn =
    { me : String
    , room : Room
    }


type ServerMsgOut
    = SetName
        { id : String
        , name : String
        }
    | SetWord
        { id : String
        , word : String
        }
    | StartGame
        { id : String
        }
    | GotCanvasFrames
        { id : String
        , frames : List Canvas.Renderable
        }


encodeServerMsgOut out =
    case out of
        SetName { id, name } ->
            JE.object
                [ ( "id", JE.string id )
                , ( "name", JE.string name )
                , ( "type", JE.string "SetName" )
                ]

        SetWord { id, word } ->
            JE.object
                [ ( "id", JE.string id )
                , ( "word", JE.string word )
                , ( "type", JE.string "WordSelected" )
                ]

        StartGame { id } ->
            JE.object
                [ ( "id", JE.string id )
                , ( "type", JE.string "StartGame" )
                ]

        GotCanvasFrames { id, frames } ->
            JE.object
                [ ( "id", JE.string id )
                , ( "frames", JE.list Canvas.encodeRenderable frames )
                , ( "type", JE.string "GotCanvasFrames" )
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
    Sub.batch
        [ Board.subscriptions model.board
            |> Sub.map BoardMsg
        , Net.rx
            (doDecode >> GotMessage)
        ]



-- VIEW


view : Model -> View Msg
view model =
    { title = "Room 123"
    , body =
        [ H.toUnstyled <|
            H.div []
                [ Css.Global.global globalStyles
                , case model.room.machine of
                    Joining ->
                        viewUserJoin model

                    SelectingWord { artist } ->
                        if Just artist == model.me then
                            viewSelectAWord model

                        else
                            viewSomeoneElseIsSelectingAWord model

                    Drawing drawing ->
                        viewDrawing drawing model
                ]
        ]
    }


viewUserJoin : Model -> H.Html Msg
viewUserJoin model =
    H.div []
        [ H.h1 [] [ H.text "Welcome!" ]
        , H.p [] [ H.text "Please enter your name" ]
        , H.form [ HE.onSubmit ClickedSetName ]
            [ H.input
                [ HA.placeholder "Name"
                , HE.onInput TypedInNameField
                , HA.value model.nameInput
                ]
                []
            , H.input
                [ HA.type_ "submit"
                , HA.value "Let's go!"
                ]
                []
            ]
        , H.div []
            [ H.ul [] <| List.map (\i -> H.li [] [ H.text i.name ]) (Dict.values model.room.users)
            ]
        , H.div []
            [ H.button [ HE.onClick ClickedStartGame ] [ H.text "Start!" ]
            ]
        ]


viewSelectAWord : Model -> H.Html Msg
viewSelectAWord model =
    H.div []
        [ H.h1 [] [ H.text "Select A Word" ]
        , H.div []
            [ H.ul [] <| List.map (\i -> H.li [ HE.onClick (ClickedWord i) ] [ H.text i ]) sampleWords
            ]
        ]


viewSomeoneElseIsSelectingAWord : Model -> H.Html Msg
viewSomeoneElseIsSelectingAWord model =
    H.div []
        [ H.h1 [] [ H.text "Someone else is selecting a word" ]
        ]


sampleWords =
    [ "House"
    , "Garden"
    , "Superman"
    , "Cheese"
    , "Fire"
    , "Couch"
    , "Tree"
    ]


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


viewDrawing : DrawingModel -> Model -> H.Html Msg
viewDrawing drawing model =
    H.div []
        [ H.h1 [] [ H.text "Drawing time" ]
        , Board.view model.board |> H.fromUnstyled |> H.map BoardMsg
        ]
