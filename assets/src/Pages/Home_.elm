module Pages.Home_ exposing (view)

import Css
import Css.Global
import Drawing
import Html.Styled as Html exposing (..)
import Html.Styled.Attributes as HA exposing (css)
import Tailwind.Breakpoints as TB
import Tailwind.Utilities as TW
import View exposing (View)


view : View msg
view =
    { title = "Homepage"
    , body =
        [ Html.toUnstyled <|
            div
                [ css
                    [ TW.bg_green_500
                    ]
                ]
                [ text "Hello, world!"
                ]
        ]
    }
