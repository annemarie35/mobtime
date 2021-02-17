module Mob.Tabs.Share exposing (..)

import Html exposing (Html, a, button, div, i, strong, text)
import Html.Attributes exposing (class, id)
import Html.Events exposing (onClick)
import Interface.Commands
import QRCode
import Svg.Attributes as Svg
import Url


type Msg
    = PutLinkInPasteBin Url.Url


update : Msg -> Cmd Msg
update msg =
    case msg of
        PutLinkInPasteBin url ->
            Url.toString url
                |> Interface.Commands.CopyInPasteBin
                |> Interface.Commands.send


view : Html msg
view =
    div [ id "share", class "tab" ]
        [ a [ id "share-link" ]
            [ text "You are in the "
            , strong [] [ text "Agicap" ]
            , text " mob"
            , i [ id "share-button", class "fas fa-share-alt" ] []
            ]
        , QRCode.fromString "http://localhost:3000"
            |> Result.map
                (QRCode.toSvg
                    [ Svg.width "300px"
                    , Svg.height "300px"
                    ]
                )
            |> Result.withDefault (Html.text "Error while encoding to QRCode.")
        ]


shareButton : Url.Url -> Html Msg
shareButton url =
    button
        [ onClick <| PutLinkInPasteBin url ]
        [  ]