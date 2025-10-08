module Components.Clock.Doc exposing (doc)

import Components.Clock.View exposing (view)
import ElmBook.Actions exposing (logAction)
import ElmBook.Chapter exposing (chapter, renderComponentList)
import ElmBook.ElmCSS exposing (Chapter)
import Html.Styled as Html
import Lib.Duration as Duration
import Model.Clock as Model
import Time
import UI.Button.View
import UI.Size as Size


doc : Chapter x
doc =
    chapter "Clock"
        |> renderComponentList
            [ ( "Stopped"
              , view []
                    { state = Model.Off
                    , now = Time.millisToPosix 0
                    , buttonSize = UI.Button.View.M
                    , messages =
                        { onStart = Just <| logAction "Start"
                        , onStop = logAction "Stop"
                        }
                    , content = Html.text ""
                    , style =
                        { strokeWidth = Size.px 10
                        , diameter = Size.px 200
                        }
                    , refreshRate = Duration.ofMinutes 10
                    }
              )
            , ( "In progress"
              , view []
                    { state =
                        Model.On
                            { end = Time.millisToPosix 30000
                            , length = Duration.ofSeconds 30
                            , ended = False
                            }
                    , now = Time.millisToPosix 10000
                    , buttonSize = UI.Button.View.S
                    , messages =
                        { onStart = Just <| logAction "Start"
                        , onStop = logAction "Stop"
                        }
                    , content = Html.text ""
                    , style =
                        { strokeWidth = Size.px 10
                        , diameter = Size.px 200
                        }
                    , refreshRate = Duration.ofMinutes 10
                    }
              )
            ]
