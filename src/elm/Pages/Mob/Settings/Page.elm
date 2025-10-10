module Pages.Mob.Settings.Page exposing (Msg(..), subscriptions, update, view)

import Components.Form.Volume.Field as VolumeField
import Effect exposing (Effect)
import Lib.Duration exposing (Duration)
import Model.Events
import Model.Mob
import Pages.Mob.Routing
import Pages.Mob.Settings.PageView
import Routing
import Shared exposing (Shared)
import Sounds
import UserPreferences
import View exposing (View)


type Msg
    = Back
    | TurnChange Duration
    | PomodoroChange Duration
    | PlaylistChange Sounds.Profile
    | VolumeMsg VolumeField.Msg


update : Shared -> Msg -> Model.Mob.Mob -> ( Model.Mob.Mob, Effect Shared.Msg Msg )
update shared msg model =
    case msg of
        Back ->
            ( model
            , Shared.pushUrl shared <|
                Routing.Mob <|
                    { subRoute = Pages.Mob.Routing.Home, mob = model.name }
            )

        TurnChange turn ->
            ( model
            , turn
                |> Model.Events.TurnLengthChanged
                |> Model.Events.MobEvent model.name
                |> Effect.share
            )

        PomodoroChange pomodoro ->
            ( model
            , pomodoro
                |> Model.Events.PomodoroLengthChanged
                |> Model.Events.MobEvent model.name
                |> Effect.share
            )

        PlaylistChange playlist ->
            ( model
            , playlist
                |> Model.Events.SelectedMusicProfile
                |> Model.Events.MobEvent model.name
                |> Effect.share
            )

        VolumeMsg volumeMsg ->
            ( model, Effect.fromShared <| Shared.PreferencesMsg <| UserPreferences.VolumeMsg volumeMsg )


subscriptions : Model.Mob.Mob -> Sub Msg
subscriptions _ =
    Sub.none


view : Shared -> Model.Mob.Mob -> View Msg
view shared model =
    { title = "Settings"
    , modal = Nothing
    , body =
        Pages.Mob.Settings.PageView.view
            { currentPlaylist = model.soundProfile
            , devMode = shared.devMode
            , mob = model.name
            , onBack = Back
            , onPlaylistChange = PlaylistChange
            , onPomodoroChange = PomodoroChange
            , onTurnLengthChange = TurnChange
            , pomodoro = model.pomodoroLength
            , turnLength = model.turnLength
            , volume =
                { onChange = VolumeMsg << VolumeField.Change
                , onTest = VolumeMsg VolumeField.Test
                , volume = shared.preferences.volume
                }
            }
    }
