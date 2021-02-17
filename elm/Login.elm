module Login exposing (..)

-- MODEL

import Browser.Navigation as Nav
import Html exposing (Html, button, div, form, h1, header, i, input, label, text)
import Html.Attributes exposing (class, for, id, placeholder, required, type_, value)
import Html.Events exposing (onInput, onSubmit)


type alias Model =
    { mobName : String
    }


init : Model
init =
    { mobName = "" }



-- UPDATE


type Msg
    = MobNameChanged String
    | JoinMob


update : Model -> Msg -> Nav.Key -> ( Model, Cmd Msg )
update model msg navKey =
    case msg of
        MobNameChanged name ->
            ( { model | mobName = name }, Cmd.none )

        JoinMob ->
            ( model, Nav.pushUrl navKey <| "/mob/" ++ model.mobName )



-- VIEW


title : String
title =
    "Login | Mob Time !"


view : Model -> Html Msg
view model =
    div
        [ id "login", class "container" ]
        [ header []
            [ h1 [] [ text "Mob Time" ]
            ]
        , form [ onSubmit JoinMob ]
            [ label [ for "mob-name" ] []
            , input
                [ id "mob-name"
                , type_ "text"
                , onInput MobNameChanged
                , placeholder "My Mob Name"
                , required True
                , Html.Attributes.min "4"
                , Html.Attributes.max "50"
                , value model.mobName
                ]
                []
            , button
                [ type_ "submit" ]
                [ text "Join"
                , i [ class "fas fa-paper-plane" ] []
                ]
            ]
        ]
