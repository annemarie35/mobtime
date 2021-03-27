port module Main exposing (..)

import Browser
import Browser.Navigation as Nav
import Circle
import Clock.Model exposing (ClockState(..))
import Clock.Settings
import Html exposing (..)
import Html.Attributes exposing (class, classList, id)
import Html.Events exposing (onClick)
import Js.Commands
import Js.Events
import Js.EventsMapping as EventsMapping exposing (EventsMapping)
import Json.Decode
import Json.Encode
import Lib.BatchMsg
import Lib.Duration as Duration exposing (Duration)
import Lib.Icons.Ion
import Lib.Ratio
import Lib.Toaster exposing (Toasts)
import Mob.Tabs.Home
import Mob.Tabs.Share
import Mobbers.Settings
import Random
import Shared
import SharedEvents
import Sound.Library
import Sound.Settings
import Svg exposing (Svg, svg)
import Svg.Attributes as Svg
import Task
import Time
import Url


port receiveEvent : (Json.Encode.Value -> msg) -> Sub msg


port receiveHistory : (List Json.Encode.Value -> msg) -> Sub msg



-- MAIN


main : Program () Model Msg
main =
    Browser.application
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        , onUrlChange = UrlChanged
        , onUrlRequest = LinkClicked
        }



-- MODEL


type AlarmState
    = Playing
    | Stopped
    | Standby


type Tab
    = Main
    | Mobbers
    | Clock
    | Sound
    | Share


type alias Model =
    { key : Nav.Key
    , url : Url.Url
    , shared : Shared.State
    , mobbersSettings : Mobbers.Settings.Model
    , clockSettings : Clock.Settings.Model
    , soundSettings : Sound.Settings.Model
    , alarm : AlarmState
    , now : Time.Posix
    , toasts : Toasts
    , tab : Tab
    }


init : () -> Url.Url -> Nav.Key -> ( Model, Cmd Msg )
init _ url key =
    ( { key = key
      , url = url
      , shared = Shared.init
      , mobbersSettings = Mobbers.Settings.init
      , clockSettings = Clock.Settings.init
      , soundSettings = Sound.Settings.init 50
      , alarm = Standby
      , now = Time.millisToPosix 0
      , toasts = []
      , tab = Main
      }
    , Task.perform TimePassed Time.now
    )



-- UPDATE


type Msg
    = LinkClicked Browser.UrlRequest
    | UrlChanged Url.Url
    | ShareEvent SharedEvents.Event
    | ReceivedEvent (Result Json.Decode.Error SharedEvents.Event)
    | ReceivedHistory (List (Result Json.Decode.Error SharedEvents.Event))
    | TimePassed Time.Posix
    | Start
    | StartWithAlarm Sound.Library.Sound
    | StopSound
    | AlarmEnded
    | UnknownEvent
    | GotMainTabMsg Mob.Tabs.Home.Msg
    | GotClockSettingsMsg Clock.Settings.Msg
    | GotShareTabMsg Mob.Tabs.Share.Msg
    | GotMobbersSettingsMsg Mobbers.Settings.Msg
    | GotSoundSettingsMsg Sound.Settings.Msg
    | GotToastMsg Lib.Toaster.Msg
    | SwitchTab Tab
    | Batch (List Msg)


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        LinkClicked _ ->
            ( model, Cmd.none )

        UrlChanged _ ->
            ( model, Cmd.none )

        ShareEvent event ->
            ( model
            , SharedEvents.sendEvent <| SharedEvents.toJson event
            )

        ReceivedEvent eventResult ->
            eventResult
                |> Result.map (Shared.evolve model.shared)
                |> Result.withDefault ( Shared.init, Cmd.none )
                |> Tuple.mapFirst (\shared -> { model | shared = shared })

        ReceivedHistory eventsResults ->
            ( { model | shared = Shared.evolveMany model.shared eventsResults }
            , Cmd.none
            )

        TimePassed now ->
            let
                ( shared, command ) =
                    Shared.timePassed now model.shared
            in
            ( { model
                | alarm =
                    if Clock.Model.clockEnded shared.clock then
                        case model.alarm of
                            Standby ->
                                Playing

                            _ ->
                                model.alarm

                    else
                        case model.alarm of
                            Stopped ->
                                Standby

                            _ ->
                                model.alarm
                , now = now
                , shared = shared
              }
            , command
            )

        Start ->
            ( model, Random.generate StartWithAlarm <| Sound.Library.pick model.shared.soundProfile )

        StartWithAlarm sound ->
            ( model
            , SharedEvents.sendEvent <|
                SharedEvents.toJson <|
                    SharedEvents.Started { time = model.now, alarm = sound, length = model.shared.turnLength }
            )

        StopSound ->
            ( { model | alarm = Stopped }
            , Js.Commands.send Js.Commands.StopAlarm
            )

        AlarmEnded ->
            ( { model | alarm = Stopped }
            , Cmd.none
            )

        UnknownEvent ->
            ( model, Cmd.none )

        GotMainTabMsg subMsg ->
            ( model, Mob.Tabs.Home.update subMsg |> Cmd.map GotMainTabMsg )

        GotMobbersSettingsMsg subMsg ->
            let
                mobbersResult =
                    Mobbers.Settings.update subMsg model.shared.mobbers model.mobbersSettings

                ( toasts, commands ) =
                    Lib.Toaster.add mobbersResult.toasts model.toasts
            in
            ( { model
                | mobbersSettings = mobbersResult.updated
                , toasts = toasts
              }
            , Cmd.batch <|
                Cmd.map GotMobbersSettingsMsg mobbersResult.command
                    :: List.map (Cmd.map GotToastMsg) commands
            )

        GotToastMsg subMsg ->
            Lib.Toaster.update subMsg model.toasts
                |> Tuple.mapBoth
                    (\toasts -> { model | toasts = toasts })
                    (Cmd.map GotToastMsg)

        SwitchTab tab ->
            ( { model | tab = tab }, Cmd.none )

        Batch messages ->
            Lib.BatchMsg.update messages model update

        GotShareTabMsg subMsg ->
            ( model, Mob.Tabs.Share.update subMsg |> Cmd.map GotShareTabMsg )

        GotClockSettingsMsg subMsg ->
            Clock.Settings.update subMsg model.clockSettings
                |> Tuple.mapBoth
                    (\a -> { model | clockSettings = a })
                    (Cmd.map GotClockSettingsMsg)

        GotSoundSettingsMsg subMsg->
            Sound.Settings.update subMsg model.soundSettings
                |> Tuple.mapBoth
                    (\a -> { model | soundSettings = a })
                    (Cmd.map GotSoundSettingsMsg)




-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.batch
        [ Time.every 500 TimePassed
        , receiveEvent <| SharedEvents.fromJson >> ReceivedEvent
        , receiveHistory <| List.map SharedEvents.fromJson >> ReceivedHistory
        , Js.Events.events toMsg
        ]


toMsg : Js.Events.Event -> Msg
toMsg event =
    case event.name of
        "AlarmEnded" ->
            AlarmEnded

        _ ->
            Lib.Toaster.eventsMapping
                |> EventsMapping.map GotToastMsg
                |> EventsMapping.dispatch event
                |> Batch



-- VIEW


view : Model -> Browser.Document Msg
view model =
    let
        action =
            detectAction model

        totalWidth =
            220

        outerRadiant =
            104

        pomodoroCircle =
            Circle.Circle
                outerRadiant
                (Circle.Coordinates (outerRadiant + 6) (outerRadiant + 6))
                (Circle.Stroke 10 "#999")

        mobCircle =
            Circle.inside pomodoroCircle <| Circle.Stroke 18 "#666"
    in
    { title = "Mob Time"
    , body =
        [ div [ class "container" ]
            [ header []
                [ section []
                    [ svg
                        [ id "circles"
                        , Svg.width <| String.fromInt totalWidth
                        , Svg.height <| String.fromInt totalWidth
                        ]
                      <|
                        Circle.draw pomodoroCircle Lib.Ratio.full
                            ++ Circle.draw mobCircle (Clock.Model.clockRatio model.now model.shared.clock)
                    , button
                        [ id "action"
                        , class action.class
                        , onClick action.message
                        ]
                        [ action.icon
                        , span [ id "time-left" ] (action.text |> List.map (\a -> span [] [ text a ]))
                        ]
                    ]
                ]
            , nav []
                [ button [ onClick <| SwitchTab Main, classList [ ( "active", model.tab == Main ) ] ] [ Lib.Icons.Ion.home ]
                , button [ onClick <| SwitchTab Clock, classList [ ( "active", model.tab == Clock ) ] ] [ Lib.Icons.Ion.clock ]
                , button [ onClick <| SwitchTab Mobbers, classList [ ( "active", model.tab == Mobbers ) ] ] [ Lib.Icons.Ion.people ]
                , button [ onClick <| SwitchTab Sound, classList [ ( "active", model.tab == Sound ) ] ] [ Lib.Icons.Ion.sound ]
                , button [ onClick <| SwitchTab Share, classList [ ( "active", model.tab == Share ) ] ] [ Lib.Icons.Ion.share ]
                ]
            , case model.tab of
                Main ->
                    Mob.Tabs.Home.view "Awesome" model.url model.shared.mobbers
                        |> Html.map GotMainTabMsg

                Clock ->
                    Clock.Settings.view model.shared.turnLength model.clockSettings
                        |> Html.map GotClockSettingsMsg

                Mobbers ->
                    Mobbers.Settings.view model.shared.mobbers model.mobbersSettings
                        |> Html.map GotMobbersSettingsMsg

                Sound ->
                    Sound.Settings.view model.soundSettings model.shared.soundProfile
                        |> Html.map GotSoundSettingsMsg

                Share ->
                    Mob.Tabs.Share.view "Awesome" model.url
                        |> Html.map GotShareTabMsg
            , Lib.Toaster.view model.toasts |> Html.map GotToastMsg
            ]
        ]
    }


type alias ActionDescription =
    { icon : Svg Msg
    , message : Msg
    , text : List String
    , class : String
    }


detectAction : Model -> ActionDescription
detectAction model =
    case model.alarm of
        Playing ->
            { icon = Lib.Icons.Ion.mute
            , message = StopSound
            , class = ""
            , text = []
            }

        _ ->
            case model.shared.clock of
                Off ->
                    { icon = Lib.Icons.Ion.play
                    , message = Start
                    , class = ""
                    , text = []
                    }

                On on ->
                    { icon = Lib.Icons.Ion.stop
                    , message = ShareEvent SharedEvents.Stopped
                    , class = "on"
                    , text =
                        Duration.between model.now on.end
                            |> (if model.clockSettings.displaySeconds then
                                    Duration.toLongString

                                else
                                    Duration.toShortString
                               )
                    }
