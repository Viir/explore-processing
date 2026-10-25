module Wallpaper exposing (render)

import Seeded
import SvgText


render : Int -> ( Int, Int ) -> List String -> String
render seed ( width, height ) palette =
    if width < 120 || width > 1920 || height < 120 || height > 1080 then
        SvgText.error "Wallpaper size must be between 120 x 120 and 1920 x 1080."

    else if List.length palette > 8 || not (List.all SvgText.validColor palette) then
        SvgText.error "Use one to eight palette colors, each in #RGB or #RRGGBB form."

    else
        case palette of
            [] ->
                SvgText.error "The wallpaper palette must not be empty."

            background :: accents ->
                let
                    columns =
                        (width + 79) // 80

                    rows =
                        (height + 79) // 80

                    tile index =
                        let
                            random =
                                Seeded.next (seed + index * 31)

                            color =
                                Seeded.pick (Seeded.next random) background accents

                            shape =
                                case modBy 4 random of
                                    0 ->
                                        "<circle cx=\"40\" cy=\"40\" r=\"31\"/>"

                                    1 ->
                                        "<path d=\"M0 0H80V80A80 80 0 0 1 0 0Z\"/>"

                                    2 ->
                                        "<path d=\"M0 0L80 80H0Z\"/>"

                                    _ ->
                                        "<path d=\"M0 18H80M0 40H80M0 62H80\" fill=\"none\" stroke=\""
                                            ++ color
                                            ++ "\" stroke-width=\"10\"/>"
                        in
                        "<g transform=\"translate("
                            ++ String.fromInt (modBy columns index * 80)
                            ++ " "
                            ++ String.fromInt (index // columns * 80)
                            ++ ")\" fill=\""
                            ++ color
                            ++ "\">"
                            ++ shape
                            ++ "</g>"
                in
                SvgText.document width
                    height
                    ("Geometric wallpaper - seed " ++ String.fromInt seed)
                    ("<rect width=\"100%\" height=\"100%\" fill=\""
                        ++ background
                        ++ "\"/>"
                        ++ (List.range 0 (columns * rows - 1) |> List.map tile |> String.concat)
                    )
