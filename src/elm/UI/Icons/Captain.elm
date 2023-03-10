module UI.Icons.Captain exposing (display)

import Svg.Styled as Svg exposing (path, svg)
import Svg.Styled.Attributes as SvgAttr
import UI.Color as Color
import UI.Icons.Common exposing (Icon)
import UI.Size as Size


display : Icon msg
display { size, color } =
    svg
        [ SvgAttr.version "1.0"
        , SvgAttr.height <| String.fromFloat <| Size.toPixels size
        , SvgAttr.viewBox "0 0 512.000000 512.000000"
        , SvgAttr.preserveAspectRatio "xMidYMid meet"
        ]
        [ Svg.g
            [ SvgAttr.transform "translate(0.000000,512.000000) scale(0.100000,-0.100000)"
            , SvgAttr.fill <| Color.toCss color
            , SvgAttr.stroke "none"
            ]
            [ path
                [ SvgAttr.d "M2355 4314 c-405 -39 -688 -106 -1010 -238 -234 -97 -548 -284 -750\n-447 -165 -133 -406 -351 -450 -407 -148 -188 -184 -448 -95 -684 41 -111 109\n-194 354 -438 l236 -235 0 -223 c0 -238 5 -268 51 -311 33 -31 399 -209 566\n-275 838 -332 1790 -329 2623 6 167 68 519 240 549 268 46 45 51 74 51 312 l0\n223 236 235 c304 303 353 374 391 575 28 147 6 299 -62 435 -50 100 -99 155\n-272 307 -330 291 -532 432 -818 573 -334 164 -632 255 -1000 305 -113 15\n-509 28 -600 19z m545 -314 c220 -28 448 -85 665 -164 233 -86 567 -275 759\n-430 144 -116 402 -347 423 -378 88 -131 94 -302 16 -438 -14 -25 -132 -152\n-262 -282 l-235 -238 -1706 0 -1706 0 -235 238 c-130 130 -248 257 -262 282\n-86 150 -67 352 44 471 30 33 167 153 334 295 161 137 403 292 607 389 322\n151 612 228 1023 269 72 7 448 -3 535 -14z m1280 -2348 l0 -119 -187 -91\nc-339 -164 -629 -252 -1018 -309 -171 -25 -659 -25 -830 0 -236 35 -455 86\n-647 153 -144 50 -200 74 -390 166 l-168 82 0 118 0 118 1620 0 1620 0 0 -118z"
                ]
                []
            , path
                [ SvgAttr.d "M2505 3666 c-64 -29 -95 -85 -95 -171 0 -54 0 -54 -36 -61 -66 -12\n-124 -80 -124 -146 0 -71 68 -148 131 -148 l29 0 0 -160 c0 -186 9 -180 -109\n-76 -47 42 -86 68 -107 72 -114 21 -201 -67 -179 -183 19 -101 418 -376 545\n-376 128 0 526 275 545 376 15 77 -18 147 -81 173 -73 31 -124 13 -217 -72\n-102 -95 -97 -100 -97 86 l0 160 25 0 c58 0 119 54 131 115 14 78 -35 157\n-111 176 l-43 11 -4 69 c-4 72 -20 104 -69 142 -34 24 -96 31 -134 13z"
                ]
                []
            ]
        ]
