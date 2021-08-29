port module Net exposing (..)

import Json.Decode as JD


port tx : JD.Value -> Cmd msg


port rx : (JD.Value -> msg) -> Sub msg
