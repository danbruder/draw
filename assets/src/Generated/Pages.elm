module Generated.Pages exposing
    ( Model
    , Msg
    , init
    , subscriptions
    , update
    , view
    )

import Generated.Route as Route exposing (Route)
import Global
import Page exposing (Bundle, Document)
import Pages.Home_
import Pages.Room.Id_



-- TYPES


type Model
    = Home__Model Pages.Home_.Model
    | Room_Id__Model Pages.Room.Id_.Model


type Msg
    = Home__Msg Pages.Home_.Msg
    | Room_Id__Msg Pages.Room.Id_.Msg



-- PAGES


type alias UpgradedPage flags model msg =
    { init : flags -> Global.Model -> ( Model, Cmd Msg, Cmd Global.Msg )
    , update : msg -> model -> Global.Model -> ( Model, Cmd Msg, Cmd Global.Msg )
    , bundle : model -> Global.Model -> Bundle Msg
    }


type alias UpgradedPages =
    { home_ : UpgradedPage Pages.Home_.Flags Pages.Home_.Model Pages.Home_.Msg
    , room_id_ : UpgradedPage Pages.Room.Id_.Flags Pages.Room.Id_.Model Pages.Room.Id_.Msg
    }


pages : UpgradedPages
pages =
    { home_ = Pages.Home_.page |> Page.upgrade Home__Model Home__Msg
    , room_id_ = Pages.Room.Id_.page |> Page.upgrade Room_Id__Model Room_Id__Msg
    }



-- INIT


init : Route -> Global.Model -> ( Model, Cmd Msg, Cmd Global.Msg )
init route =
    case route of
        Route.Home_ ->
            pages.home_.init ()
        
        Route.Room_Id_ ->
            pages.room_id_.init ()



-- UPDATE


update : Msg -> Model -> Global.Model -> ( Model, Cmd Msg, Cmd Global.Msg )
update bigMsg bigModel =
    case ( bigMsg, bigModel ) of
        ( Home__Msg msg, Home__Model model ) ->
            pages.home_.update msg model
        
        ( Room_Id__Msg msg, Room_Id__Model model ) ->
            pages.room_id_.update msg model
        
        _ ->
            always ( bigModel, Cmd.none, Cmd.none )



-- BUNDLE - (view + subscriptions)


bundle : Model -> Global.Model -> Bundle Msg
bundle bigModel =
    case bigModel of
        Home__Model model ->
            pages.home_.bundle model
        
        Room_Id__Model model ->
            pages.room_id_.bundle model


view : Model -> Global.Model -> Document Msg
view model =
    bundle model >> .view


subscriptions : Model -> Global.Model -> Sub Msg
subscriptions model =
    bundle model >> .subscriptions