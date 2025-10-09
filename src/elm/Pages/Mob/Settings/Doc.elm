module Pages.Mob.Settings.Doc exposing (theChapter)

import Components.Form.Volume.Type as Volume
import ElmBook.Actions exposing (logAction, logActionWith)
import ElmBook.Chapter exposing (chapter, renderComponentList)
import ElmBook.ElmCSS exposing (Chapter)
import Lib.Duration
import Model.MobName exposing (MobName(..))
import Pages.Mob.Settings.PageView as Page
import Sounds


theChapter : Chapter x
theChapter =
    chapter "Settings"
        |> renderComponentList
            [ ( "Page"
              , Page.view
                    { currentPlaylist = Sounds.ClassicWeird
                    , devMode = False
                    , mob = MobName "Awesome"
                    , onBack = logAction "Back"
                    , onPlaylistChange = logActionWith Sounds.title "Playlist changed"
                    , onPomodoroChange = logActionWith Lib.Duration.print "Pomodoro changed"
                    , onTurnLengthChange = logActionWith Lib.Duration.print "Turn changed"
                    , onVolumeChange = logActionWith Volume.print "Volume changed"
                    , onVolumeCheck = logAction "Volume check"
                    , pomodoro = Lib.Duration.ofMinutes 25
                    , turnLength = Lib.Duration.ofMinutes 6
                    , volume = Volume.default
                    }
              )
            , ( "In dev mode"
              , Page.view
                    { currentPlaylist = Sounds.ClassicWeird
                    , devMode = True
                    , mob = MobName "Awesome"
                    , onBack = logAction "Back"
                    , onPlaylistChange = logActionWith Sounds.title "Playlist changed"
                    , onPomodoroChange = logActionWith Lib.Duration.print "Pomodoro changed"
                    , onTurnLengthChange = logActionWith Lib.Duration.print "Turn changed"
                    , onVolumeChange = logActionWith Volume.print "Volume changed"
                    , onVolumeCheck = logAction "Volume check"
                    , pomodoro = Lib.Duration.ofSeconds 25
                    , turnLength = Lib.Duration.ofSeconds 6
                    , volume = Volume.default
                    }
              )
            ]
