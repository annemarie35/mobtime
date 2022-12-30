module UI.Css exposing (..)

import Css


center : List Css.Style
center =
    [ Css.position Css.absolute
    , Css.top <| Css.pct 50
    , Css.left <| Css.pct 50
    , Css.transform <| Css.translate2 (Css.pct -50) (Css.pct -50)
    ]


fullpage : List Css.Style
fullpage =
    [ Css.position Css.absolute
    , Css.top Css.zero
    , Css.bottom Css.zero
    , Css.left Css.zero
    , Css.right Css.zero
    ]


roundBorder : Css.Style
roundBorder =
    Css.borderRadius <| Css.rem 0.2
