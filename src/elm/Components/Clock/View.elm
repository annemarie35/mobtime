module Components.Clock.View exposing (view)

import Css
import Html.Styled as Html exposing (Html)
import Html.Styled.Attributes as Attr
import Html.Styled.Events as Evts
import Lib.Duration as Duration exposing (Duration)
import Model.Clock as Clock
import Time
import UI.Button.View
import UI.CircularProgressBar
import UI.Color as Color
import UI.Css
import UI.Icons.Ion
import UI.Palettes as Palettes
import UI.Size as Size


view :
    List (Html.Attribute msg)
    ->
        { state : Clock.ClockState
        , now : Time.Posix
        , buttonSize : UI.Button.View.Size
        , messages :
            { onStart : Maybe msg
            , onStop : msg
            }
        , content : Html.Html msg
        , style :
            { strokeWidth : Size.Size
            , diameter : Size.Size
            }
        , refreshRate : Duration
        }
    -> Html msg
view attributes { style, now, state, buttonSize, messages, content, refreshRate } =
    Html.div
        (Attr.css
            [ Css.position Css.relative
            , Css.maxWidth Css.fitContent
            , Css.displayFlex
            ]
            :: attributes
        )
        [ UI.CircularProgressBar.draw
            { colors =
                { main = Palettes.monochrome.on.background
                , background = Palettes.monochrome.on.background |> Color.lighten 0.9
                , border = Palettes.monochrome.on.background |> Color.lighten 0.7
                }
            , strokeWidth = style.strokeWidth
            , diameter = style.diameter
            , progress = Clock.ratio now state
            , refreshRate = refreshRate |> Duration.multiply 2
            }
        , Html.button
            [ case state of
                Clock.On _ ->
                    Attr.disabled True

                Clock.Off ->
                    case messages.onStart of
                        Just msg ->
                            Evts.onClick msg

                        Nothing ->
                            Attr.disabled True
            , Attr.css
                [ Css.backgroundColor Css.transparent
                , Css.position Css.absolute
                , Css.width <| Css.pct 100
                , Css.height <| Css.pct 100
                , Css.border Css.zero
                , Css.overflow Css.hidden
                , Css.top Css.zero
                , Css.left Css.zero
                , Css.borderRadius <| Css.pct 50
                , Css.color <| Color.toElmCss <| Palettes.monochrome.on.background
                , Css.hover [ Css.backgroundColor Css.transparent ]
                , Css.disabled
                    [ Css.hover [ Css.backgroundColor Css.transparent ]
                    , Css.opacity <| Css.num 1
                    ]
                ]
            ]
            [ Html.div
                [ Attr.css
                    (UI.Css.center
                        ++ [ Css.displayFlex
                           , Css.flexDirection Css.column
                           , Css.alignItems Css.center
                           , Css.width <| Css.pct 100
                           ]
                    )
                ]
                [ content
                ]
            ]
        , case state of
            Clock.On _ ->
                UI.Button.View.button
                    [ Attr.css
                        [ Css.position Css.absolute
                        , Css.bottom Css.zero
                        , Css.left <| Css.pct 50
                        , Css.transform <| Css.translate2 (Css.pct -50) (Css.pct 40)
                        ]
                    ]
                    { content = UI.Button.View.Both { icon = UI.Icons.Ion.stop, text = "Stop" }
                    , variant = UI.Button.View.Primary
                    , size = buttonSize
                    , action = UI.Button.View.OnPress <| Just messages.onStop
                    }

            Clock.Off ->
                Html.span [] []
        ]
