module UI.Range.Doc exposing (..)

import ElmBook.Actions exposing (updateStateWith)
import ElmBook.Chapter exposing (chapter, render, withStatefulComponent)
import ElmBook.ElmCSS exposing (Chapter)
import UI.Range.Component


type alias State =
    Int


type alias SharedState x =
    { x | range : State }


initState : State
initState =
    50


updateSharedState : State -> SharedState x -> SharedState x
updateSharedState state x =
    { x | range = state }


rangeChapter : Chapter (SharedState x)
rangeChapter =
    chapter "Range"
        |> withStatefulComponent component
        |> render content


component { range } =
    UI.Range.Component.display
        { onChange = updateStateWith updateSharedState
        , value = range
        , min = 0
        , max = 100
        }


content : String
content =
    """
<component />
"""