module Canvas.Encode exposing (..)

import Canvas.Internal.Canvas exposing (..)
import Color exposing (Color)
import Json.Encode as JE


encodeDrawOp : DrawOp -> JE.Value
encodeDrawOp op =
    case op of
        NotSpecified ->
            JE.object
                [ ( "type", JE.string "NotSpecified" )
                ]

        Fill color ->
            JE.object
                [ ( "type", JE.string "Fill" )
                , ( "color", encodeColor color )
                ]

        Stroke color ->
            JE.object
                [ ( "type", JE.string "Stroke" )
                , ( "color", encodeColor color )
                ]

        FillAndStroke c1 c2 ->
            JE.object
                [ ( "type", JE.string "FillAndStroke" )
                , ( "color1", encodeColor c1 )
                , ( "color2", encodeColor c2 )
                ]


encodeDrawable : Drawable -> JE.Value
encodeDrawable drawable =
    case drawable of
        DrawableShapes shapes ->
            JE.object
                [ ( "type", JE.string "DrawableShapes" )
                , ( "shapes", JE.list encodeShape shapes )
                ]

        _ ->
            JE.null


encodeColor : Color -> JE.Value
encodeColor color =
    Color.toCssString color
        |> JE.string


encodePoint : Point -> JE.Value
encodePoint ( x, y ) =
    JE.object
        [ ( "x", JE.float x )
        , ( "y", JE.float y )
        ]


encodeShape : Shape -> JE.Value
encodeShape shape =
    case shape of
        Path point segments ->
            JE.object
                [ ( "type", JE.string "Path" )
                , ( "point", encodePoint point )
                , ( "segments", JE.list encodeSegment segments )
                ]

        _ ->
            JE.null


encodeSegment : PathSegment -> JE.Value
encodeSegment segment =
    case segment of
        QuadraticCurveTo point1 point2 ->
            JE.object
                [ ( "type", JE.string "QuadraticCurveTo" )
                , ( "point1", encodePoint point1 )
                , ( "point2", encodePoint point2 )
                ]

        _ ->
            JE.null
