module Pages.Mob exposing (..)

import Css
import Html.Styled as Html exposing (..)
import Html.Styled.Attributes exposing (class, classList, css, id, title)
import Html.Styled.Events exposing (onClick)
import Js.Commands
import Js.Events
import Js.EventsMapping as EventsMapping exposing (EventsMapping)
import Lib.Duration as Duration exposing (DurationStringParts)
import Lib.UpdateResult as UpdateResult exposing (UpdateResult)
import Model.Clock as Clock exposing (ClockState(..))
import Model.Events
import Model.MobName exposing (MobName)
import Model.State
import Pages.Mob.Tabs.Clocks
import Pages.Mob.Tabs.Dev
import Pages.Mob.Tabs.Home
import Pages.Mob.Tabs.Mobbers
import Pages.Mob.Tabs.Share
import Pages.Mob.Tabs.Sound
import Peers.Sync.Adapter
import Peers.Sync.Core exposing (PeerId)
import Random
import Shared exposing (Shared)
import Socket
import Sounds
import Spa
import Svg.Styled exposing (Svg)
import Task
import Time
import UI.Buttons
import UI.CircularProgressBar
import UI.Color
import UI.Column
import UI.Css
import UI.Icons
import UI.Icons.Ion
import UI.Icons.Tape
import UI.Icons.Tea
import UI.Layout
import UI.Palettes
import UI.Rem
import UI.Text
import UserPreferences
import View exposing (View)



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
    | Dev


type alias Model =
    { name : MobName
    , state : Model.State.State
    , mobbersSettings : Pages.Mob.Tabs.Mobbers.Model
    , clockSettings : Pages.Mob.Tabs.Clocks.Model
    , soundSettings : Pages.Mob.Tabs.Sound.Model
    , clockSync : Peers.Sync.Adapter.Model
    , alarm : AlarmState
    , now : Time.Posix
    , tab : Tab
    , peerId : Maybe PeerId
    }


init : MobName -> UserPreferences.Model -> ( Model, Cmd Msg )
init name preferences =
    let
        ( clockSync, clockSyncCommand ) =
            Peers.Sync.Adapter.init name
    in
    ( { name = name
      , state = Model.State.init
      , mobbersSettings = Pages.Mob.Tabs.Mobbers.init
      , clockSettings = Pages.Mob.Tabs.Clocks.init
      , soundSettings = Pages.Mob.Tabs.Sound.init preferences.volume
      , clockSync = clockSync
      , alarm = Standby
      , now = Time.millisToPosix 0
      , tab = Main
      , peerId = Nothing
      }
    , Cmd.batch
        [ Socket.joinRoom <| Model.MobName.print name
        , Time.now |> Task.perform TimePassed
        , Cmd.map GotClockSyncMsg clockSyncCommand
        ]
    )



-- UPDATE


type Msg
    = ShareEvent Model.Events.MobEvent
    | ReceivedEvent Model.Events.Event
    | ReceivedHistory (List Model.Events.Event)
    | StartClicked
    | StartWith ( Time.Posix, Sounds.Sound )
    | StopSound
    | AlarmEnded
    | TimePassed Time.Posix
    | GotMainTabMsg Pages.Mob.Tabs.Home.Msg
    | GotClockSettingsMsg Pages.Mob.Tabs.Clocks.Msg
    | GotShareTabMsg Pages.Mob.Tabs.Share.Msg
    | GotMobbersSettingsMsg Pages.Mob.Tabs.Mobbers.Msg
    | GotSoundSettingsMsg Pages.Mob.Tabs.Sound.Msg
    | GotClockSyncMsg Peers.Sync.Adapter.Msg
    | SwitchTab Tab
    | GotSocketId PeerId


timePassed : Time.Posix -> Model -> ( Model, Cmd Msg )
timePassed now model =
    let
        timePassedResult =
            Model.State.timePassed now model.state

        toto =
            case timePassedResult.turnEvent of
                Clock.Ended ->
                    Js.Commands.send Js.Commands.SoundAlarm

                Clock.Continued ->
                    Cmd.none
    in
    ( { model
        | alarm =
            case timePassedResult.turnEvent of
                Clock.Ended ->
                    Playing

                Clock.Continued ->
                    model.alarm
        , now = now
        , state = timePassedResult.updated
      }
    , Cmd.batch
        [ toto
        , Js.Commands.send <| Js.Commands.ChangeTitle <| timeLeftTitle <| timeLeftString model
        ]
    )


update : Shared -> Msg -> Model -> UpdateResult Model Msg
update _ msg model =
    case msg of
        ShareEvent event ->
            { model = model
            , command = Model.Events.sendEvent <| Model.Events.mobEventToJson event
            , toasts = []
            }

        ReceivedEvent event ->
            let
                ( updated, command ) =
                    Model.State.evolve event model.state
            in
            { model =
                { model
                    | state = updated
                    , alarm =
                        -- Handle alarm (command) as separate from the evolve method ?
                        case event of
                            Model.Events.Clock (Model.Events.Started _) ->
                                Stopped

                            _ ->
                                model.alarm
                }
            , command = command
            , toasts = []
            }

        ReceivedHistory eventsResults ->
            let
                ( updated, command ) =
                    Model.State.evolveMany eventsResults model.state
            in
            { model = { model | state = updated }
            , command = command
            , toasts = []
            }

        StartClicked ->
            { model = model
            , command =
                Time.now
                    |> Task.map
                        (\now -> ( now, selectSound now model.state.soundProfile ))
                    |> Task.perform StartWith
            , toasts = []
            }

        StartWith ( now, sound ) ->
            { model = { model | now = now }
            , command =
                Model.Events.Started
                    { time = now
                    , alarm = sound
                    , length = model.state.turnLength
                    }
                    |> Model.Events.Clock
                    |> Model.Events.MobEvent model.name
                    |> Model.Events.mobEventToJson
                    |> Model.Events.sendEvent
            , toasts = []
            }

        StopSound ->
            { model = { model | alarm = Stopped }
            , command = Js.Commands.send Js.Commands.StopAlarm
            , toasts = []
            }

        AlarmEnded ->
            { model = { model | alarm = Stopped }
            , command = Cmd.none
            , toasts = []
            }

        GotMainTabMsg subMsg ->
            { model = model
            , command = Pages.Mob.Tabs.Home.update subMsg |> Cmd.map GotMainTabMsg
            , toasts = []
            }

        GotMobbersSettingsMsg subMsg ->
            let
                mobbersResult =
                    Pages.Mob.Tabs.Mobbers.update subMsg model.state.mobbers model.name model.mobbersSettings
            in
            { model =
                { model
                    | mobbersSettings = mobbersResult.model
                }
            , command = Cmd.map GotMobbersSettingsMsg mobbersResult.command
            , toasts = mobbersResult.toasts
            }

        SwitchTab tab ->
            { model = { model | tab = tab }
            , command = Cmd.none
            , toasts = []
            }

        GotShareTabMsg subMsg ->
            { model = model
            , command = Pages.Mob.Tabs.Share.update subMsg |> Cmd.map GotShareTabMsg
            , toasts = []
            }

        GotClockSettingsMsg subMsg ->
            let
                ( clockSettings, command ) =
                    Pages.Mob.Tabs.Clocks.update subMsg model.clockSettings model.name
            in
            { model = { model | clockSettings = clockSettings }
            , command = Cmd.map GotClockSettingsMsg command
            , toasts = []
            }

        GotSoundSettingsMsg subMsg ->
            let
                ( soundSettings, command ) =
                    Pages.Mob.Tabs.Sound.update subMsg model.soundSettings
            in
            { model = { model | soundSettings = soundSettings }
            , command = Cmd.map GotSoundSettingsMsg command
            , toasts = []
            }

        GotClockSyncMsg sub ->
            Peers.Sync.Adapter.update sub model.clockSync model.now
                |> UpdateResult.map
                    (\m -> { model | clockSync = m })
                    GotClockSyncMsg

        GotSocketId peerId ->
            UpdateResult.fromModel { model | peerId = Just peerId }

        TimePassed now ->
            let
                ( updated, command ) =
                    timePassed now model
            in
            { model = updated
            , toasts = []
            , command = command
            }


selectSound : Time.Posix -> Sounds.Profile -> Sounds.Sound
selectSound now profile =
    Random.step (Sounds.pick profile)
        (now
            |> Time.posixToMillis
            |> Random.initialSeed
        )
        |> Tuple.first



-- SUBSCRIPTIONS


turnRefreshRate : Duration.Duration
turnRefreshRate =
    Duration.ofMillis 500


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        [ Model.Events.receiveOne <| Model.Events.fromJson >> ReceivedEvent
        , Model.Events.receiveHistory <| List.map Model.Events.fromJson >> ReceivedHistory
        , Sub.map GotClockSyncMsg Peers.Sync.Adapter.subscriptions
        , case ( Clock.isOn model.state.clock, Clock.isOn model.state.pomodoro ) of
            ( True, _ ) ->
                Time.every (Duration.toMillis turnRefreshRate |> toFloat) TimePassed

            ( False, True ) ->
                Time.every 2000 TimePassed

            _ ->
                Sub.none
        ]


jsEventMapping : EventsMapping Msg
jsEventMapping =
    EventsMapping.batch
        [ EventsMapping.create <|
            [ Js.Events.EventMessage "AlarmEnded" (always AlarmEnded)
            , Js.Events.EventMessage "GotSocketId" GotSocketId
            ]
        , EventsMapping.map GotClockSyncMsg Peers.Sync.Adapter.jsEventMapping
        ]



-- VIEW


view : Shared -> Model -> View (Spa.Msg Msg)
view shared model =
    let
        action =
            detectAction model
    in
    { title = timeLeftTitle action.timeLeft
    , modal =
        case ( model.alarm, model.state.clock, model.state.pomodoro ) of
            ( Playing, _, _ ) ->
                Just <| Html.map Spa.Regular musicModal

            ( _, Clock.Off, Clock.On pomodoro ) ->
                if Duration.secondsBetween model.now pomodoro.end <= 0 then
                    Just <| Html.map Spa.Regular <| breakModal model.name

                else
                    Nothing

            _ ->
                Nothing
    , body = [ UI.Layout.wrap shared model.name <| body shared model action ]
    }


body : Shared -> Model -> ActionDescription -> Html Msg
body shared model action =
    div [ class "container" ]
        [ clockArea model action
        , nav []
            ([ button
                [ onClick <| SwitchTab Main
                , classList [ ( "active", model.tab == Main ) ]
                , title "Home"
                ]
                [ UI.Icons.Ion.home
                    { size = UI.Rem.Rem 1
                    , color = UI.Palettes.monochrome.on.background
                    }
                ]
             , button
                [ onClick <| SwitchTab Clock
                , classList [ ( "active", model.tab == Clock ) ]
                , title "Clock Settings"
                ]
                [ UI.Icons.Ion.clock
                    { size = UI.Rem.Rem 1
                    , color = UI.Palettes.monochrome.on.background
                    }
                ]
             , button
                [ onClick <| SwitchTab Mobbers
                , classList [ ( "active", model.tab == Mobbers ) ]
                , title "Mobbers"
                ]
                [ UI.Icons.Ion.people
                    { size = UI.Rem.Rem 1
                    , color = UI.Palettes.monochrome.on.background
                    }
                ]
             , button
                [ onClick <| SwitchTab Sound
                , classList [ ( "active", model.tab == Sound ) ]
                , title "Sound Settings"
                ]
                [ UI.Icons.Ion.sound
                    { size = UI.Rem.Rem 1
                    , color = UI.Palettes.monochrome.on.background
                    }
                ]
             , button
                [ onClick <| SwitchTab Share
                , classList [ ( "active", model.tab == Share ) ]
                , title "Share"
                ]
                [ UI.Icons.Ion.share
                    { size = UI.Rem.Rem 1
                    , color = UI.Palettes.monochrome.on.background
                    }
                ]
             ]
                ++ (if shared.devMode then
                        [ button
                            [ onClick <| SwitchTab Dev
                            , classList [ ( "active", model.tab == Dev ) ]
                            , title "Dev"
                            ]
                            [ UI.Icons.Ion.code
                                { size = UI.Rem.Rem 1
                                , color = UI.Palettes.monochrome.on.background
                                }
                            ]
                        ]

                    else
                        []
                   )
            )
        , case model.tab of
            Main ->
                Pages.Mob.Tabs.Home.view shared model.name model.state
                    |> Html.map GotMainTabMsg

            Clock ->
                Pages.Mob.Tabs.Clocks.view shared model.clockSettings model.now model.state
                    |> Html.map GotClockSettingsMsg

            Mobbers ->
                Pages.Mob.Tabs.Mobbers.view model.state model.mobbersSettings
                    |> Html.map GotMobbersSettingsMsg

            Sound ->
                Pages.Mob.Tabs.Sound.view model.soundSettings model.name model.state.soundProfile
                    |> Html.map GotSoundSettingsMsg

            Share ->
                Pages.Mob.Tabs.Share.view shared model.name
                    |> Html.map GotShareTabMsg

            Dev ->
                Pages.Mob.Tabs.Dev.view model.clockSync
        ]


musicModal : Html Msg
musicModal =
    UI.Column.column
        [ css UI.Css.center ]
        [ UI.Column.Gap <| UI.Rem.Rem 2 ]
        [ UI.Icons.Tape.display
            { height = UI.Rem.Rem 10
            , color = UI.Palettes.monochrome.on.background
            }
        , UI.Text.h2 "Turn ended !"
        , UI.Buttons.button [ css [ Css.width <| Css.pct 100 ] ]
            { content = UI.Buttons.Both { icon = UI.Icons.Ion.mute, text = "Stop music" }
            , variant = UI.Buttons.Primary
            , size = UI.Buttons.L
            , action = UI.Buttons.OnPress <| Just StopSound
            }
        ]


breakModal : MobName -> Html Msg
breakModal mobName =
    UI.Column.column
        [ css UI.Css.center ]
        [ UI.Column.Gap <| UI.Rem.Rem 2 ]
        [ UI.Text.h2 "It's time for a break!"
        , UI.Icons.Tea.display
            { height = UI.Rem.Rem 10
            , color = UI.Palettes.monochrome.on.background
            }
        , Html.p
            [ css [ Css.textAlign Css.justify ] ]
            [ Html.text "Boost your productivity by taking a good break." ]
        , UI.Buttons.button [ css [ Css.width <| Css.pct 100 ] ]
            { content = UI.Buttons.Both { icon = UI.Icons.Ion.check, text = "Break over" }
            , variant = UI.Buttons.Primary
            , size = UI.Buttons.L
            , action =
                Model.Events.PomodoroStopped
                    |> Model.Events.MobEvent mobName
                    |> ShareEvent
                    |> Just
                    |> UI.Buttons.OnPress
            }
        ]


clockArea : Model -> ActionDescription -> Html Msg
clockArea model action =
    header []
        [ section []
            [ Html.div
                [ css
                    [ Css.position Css.relative
                    , Css.margin Css.auto
                    , Css.maxWidth Css.fitContent
                    ]
                ]
                [ UI.CircularProgressBar.draw
                    { colors =
                        { main = UI.Palettes.monochrome.surface |> UI.Color.lighten 0.5
                        , background = UI.Palettes.monochrome.surface |> UI.Color.lighten 0.9
                        , border = UI.Palettes.monochrome.surface |> UI.Color.lighten 0.7
                        }
                    , strokeWidth = UI.Rem.Rem 0.3
                    , diameter = UI.Rem.Rem 8.7
                    , progress = Clock.ratio model.now model.state.pomodoro
                    , refreshRate = turnRefreshRate |> Duration.multiply 2
                    }
                , Html.div
                    [ css
                        [ Css.position Css.absolute
                        , Css.top <| Css.rem 0.4
                        , Css.left <| Css.rem 0.4
                        ]
                    ]
                    [ UI.CircularProgressBar.draw
                        { colors =
                            { main = UI.Palettes.monochrome.surface
                            , background = UI.Palettes.monochrome.surface |> UI.Color.lighten 0.9
                            , border = UI.Palettes.monochrome.surface |> UI.Color.lighten 0.7
                            }
                        , strokeWidth = UI.Rem.Rem 0.5
                        , diameter = UI.Rem.Rem 7.8
                        , progress = Clock.ratio model.now model.state.clock
                        , refreshRate = turnRefreshRate |> Duration.multiply 2
                        }
                    ]
                , UI.Icons.style
                    { class = "action"
                    , size = UI.Rem.Rem 3
                    , colors =
                        { normal = UI.Palettes.monochrome.surface
                        , hover = UI.Palettes.monochrome.surface
                        }
                    }
                  <|
                    actionButton action
                ]
            ]
        ]


actionButton : ActionDescription -> Html Msg
actionButton action =
    button
        [ onClick action.message
        , id "action"
        , class action.class
        , css
            [ Css.width <| Css.rem 6.6
            , Css.height <| Css.rem 6.6
            , Css.borderRadius <| Css.pct 100
            , Css.position Css.absolute
            , Css.top <| Css.rem 1.1
            , Css.left <| Css.rem 1.1
            , Css.flexDirection Css.column
            , Css.backgroundColor <|
                UI.Color.toElmCss <|
                    UI.Color.opactity 0.5 <|
                        UI.Palettes.monochrome.background
            , Css.color <| UI.Color.toElmCss <| UI.Palettes.monochrome.surface
            , Css.hover
                [ Css.backgroundColor <|
                    UI.Color.toElmCss <|
                        UI.Color.opactity 0.8 <|
                            UI.Palettes.monochrome.background
                ]
            ]
        ]
        [ div [] [ action.icon ]
        , div
            [ id "time-left"
            , css
                [ Css.fontWeight Css.bold
                , Css.fontSize <| Css.rem 1.6
                ]
            ]
            (action.timeLeft
                |> List.map
                    (\a ->
                        span
                            [ css [ Css.display Css.block ] ]
                            [ text a ]
                    )
            )
        ]


type alias ActionDescription =
    { icon : Svg Msg
    , message : Msg
    , timeLeft : DurationStringParts
    , class : String
    }


detectAction : Model -> ActionDescription
detectAction model =
    let
        timeLeft =
            timeLeftString model
    in
    case model.state.clock of
        On _ ->
            { icon =
                UI.Icons.Ion.stop
                    { size = UI.Rem.Rem 1
                    , color = UI.Palettes.monochrome.on.background
                    }
            , message =
                Model.Events.Clock Model.Events.Stopped
                    |> Model.Events.MobEvent model.name
                    |> ShareEvent
            , class = "on"
            , timeLeft = timeLeft
            }

        Off ->
            { icon =
                UI.Icons.Ion.play
                    { size = UI.Rem.Rem 1
                    , color = UI.Palettes.monochrome.on.background
                    }
            , message = StartClicked
            , class = ""
            , timeLeft = timeLeft
            }


timeLeftString : Model -> DurationStringParts
timeLeftString model =
    case model.state.clock of
        On on ->
            Duration.between model.now on.end
                |> (if model.clockSettings.displaySeconds then
                        Duration.toLongString

                    else
                        Duration.toShortString
                   )

        _ ->
            []


timeLeftTitle : DurationStringParts -> String
timeLeftTitle action =
    case action of
        [] ->
            "Mob Time"

        _ ->
            String.join " " action ++ " | " ++ "Mob Time"