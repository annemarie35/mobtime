module Pages.Mob.Tabs.Mobbers exposing (..)

import Field
import Field.String
import Html as Unstyled
import Html.Attributes as UnstyledAttr
import Html.Events as UnstyledEvts
import Html.Styled exposing (Html, button, div, form, li, p, text, ul)
import Html.Styled.Attributes exposing (class, disabled, id, type_)
import Html.Styled.Events exposing (onClick, onSubmit)
import Lib.Toaster as Toaster
import Lib.UpdateResult exposing (UpdateResult)
import Model.Events
import Model.MobName exposing (MobName)
import Model.Mobber exposing (Mobber)
import Model.Mobbers as Mobbers exposing (Mobbers)
import Model.Role exposing (Role)
import Model.State exposing (State)
import Random
import UI.Icons.Ion as Icons
import UI.Palettes
import UI.Rem
import Uuid


type alias Model =
    { mobberName : Field.String.Field }


init : Model
init =
    { mobberName = Field.init "" }



-- UPDATE


type Msg
    = NameChanged String
    | StartAdding
    | Add Mobber
    | Shuffle
    | ShareEvent Model.Events.Event


update : Msg -> Mobbers -> MobName -> Model -> UpdateResult Model Msg
update msg mobbers mob model =
    case msg of
        NameChanged name ->
            { model = { model | mobberName = name |> Field.resetValue model.mobberName |> Field.String.notEmpty }
            , command = Cmd.none
            , toasts = []
            }

        StartAdding ->
            let
                name =
                    model.mobberName |> Field.String.notEmpty
            in
            case Field.toResult name of
                Ok validMobberName ->
                    { model = { model | mobberName = Field.init "" }
                    , command =
                        Random.generate
                            (\id ->
                                Add
                                    { id = id |> Uuid.toString |> Model.Mobber.idFromString
                                    , name = validMobberName
                                    }
                            )
                            Uuid.uuidGenerator
                    , toasts = []
                    }

                Err _ ->
                    { model = { model | mobberName = name }
                    , command = Cmd.none
                    , toasts = [ Toaster.error "The mobber name cannot be empty" ]
                    }

        Add mobber ->
            { model = model
            , command =
                mobber
                    |> Model.Events.AddedMobber
                    |> Model.Events.MobEvent mob
                    |> Model.Events.mobEventToJson
                    |> Model.Events.sendEvent
            , toasts = []
            }

        Shuffle ->
            { model = model
            , command = Random.generate (ShareEvent << Model.Events.ShuffledMobbers) <| Mobbers.shuffle mobbers
            , toasts = []
            }

        ShareEvent event ->
            -- TODO duplicated code
            { model = model
            , command =
                event
                    |> Model.Events.MobEvent mob
                    |> Model.Events.mobEventToJson
                    |> Model.Events.sendEvent
            , toasts = []
            }



-- VIEW


view : State -> Model -> Html Msg
view { mobbers, roles } model =
    div
        [ id "mobbers", class "tab" ]
        [ form
            [ id "add", onSubmit StartAdding ]
            [ Field.view (textFieldConfig "Mobber to be added" NameChanged) model.mobberName
                |> Html.Styled.fromUnstyled
            , button [ type_ "submit" ]
                [ Icons.plus
                    { size = UI.Rem.Rem 1
                    , color = UI.Palettes.monochrome.on.background
                    }
                ]
            ]
        , div [ class "button-row" ]
            [ button
                [ class "labelled-icon-button"
                , disabled (not <| Mobbers.rotatable mobbers)
                , onClick <| ShareEvent <| Model.Events.RotatedMobbers
                ]
                [ Icons.rotate
                    { size = UI.Rem.Rem 1
                    , color = UI.Palettes.monochrome.on.background
                    }
                , text "Rotate"
                ]
            , button
                [ class "labelled-icon-button"
                , disabled (not <| Mobbers.shufflable mobbers)
                , onClick Shuffle
                ]
                [ Icons.shuffle
                    { size = UI.Rem.Rem 1
                    , color = UI.Palettes.monochrome.on.background
                    }
                , text "Shuffle"
                ]
            ]
        , ul []
            (Mobbers.assignRoles roles mobbers
                |> List.map mobberView
            )
        ]


textFieldConfig : String -> (String -> msg) -> Field.String.ViewConfig msg
textFieldConfig title toMsg =
    { valid =
        \meta value ->
            Unstyled.div [ UnstyledAttr.class "form-field" ]
                [ textInput title toMsg value meta ]
    , invalid =
        \meta value _ ->
            Unstyled.div [ UnstyledAttr.class "form-field" ]
                [ textInput title toMsg value meta
                ]
    }


textInput : String -> (String -> msg) -> String -> { a | disabled : Bool } -> Unstyled.Html msg
textInput title toMsg value meta =
    Unstyled.input
        [ UnstyledEvts.onInput toMsg
        , UnstyledAttr.type_ "text"
        , UnstyledAttr.placeholder title
        , UnstyledAttr.value value
        , UnstyledAttr.disabled meta.disabled
        ]
        []


mobberView : ( Role, Mobber ) -> Html Msg
mobberView ( role, mobber ) =
    li []
        [ p [ class "role" ] [ text <| Model.Role.print role ]
        , div
            []
            [ p [ class "name" ] [ text mobber.name ]
            , button
                [ onClick <| ShareEvent <| Model.Events.DeletedMobber mobber ]
                [ Icons.delete
                    { size = UI.Rem.Rem 1
                    , color = UI.Palettes.monochrome.on.background
                    }
                ]
            ]
        ]