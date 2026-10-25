module Demos exposing (chart, chartFromFiles, maze, mazeFromFile, wallpaper, wallpaperFromFile)

import Chart
import Json.Decode as Decode exposing (Decoder)
import Maze
import SvgText
import Wallpaper


wallpaper : Int -> ( Int, Int ) -> List String -> String
wallpaper seed dimensions palette =
    Wallpaper.render seed dimensions palette


wallpaperFromFile : String -> String
wallpaperFromFile configJson =
    decodeAndRender
        (Decode.map4
            (\seed width height palette -> ( seed, ( width, height ), palette ))
            (Decode.field "seed" Decode.int)
            (Decode.field "width" Decode.int)
            (Decode.field "height" Decode.int)
            (Decode.field "palette" (Decode.list Decode.string))
        )
        (\( seed, size, palette ) -> wallpaper seed size palette)
        configJson


maze : Int -> ( Int, Int ) -> String
maze seed dimensions =
    Maze.render seed dimensions


mazeFromFile : String -> String
mazeFromFile configJson =
    decodeAndRender
        (Decode.map3
            (\seed columns rows -> ( seed, ( columns, rows ) ))
            (Decode.field "seed" Decode.int)
            (Decode.field "columns" Decode.int)
            (Decode.field "rows" Decode.int)
        )
        (\( seed, size ) -> maze seed size)
        configJson


chart : String -> { title : String, color : String } -> String
chart csv options =
    Chart.render csv options


chartFromFiles : String -> String -> String
chartFromFiles csv optionsJson =
    decodeAndRender
        (Decode.map2
            (\title color -> { title = title, color = color })
            (Decode.field "title" Decode.string)
            (Decode.field "color" Decode.string)
        )
        (chart csv)
        optionsJson


decodeAndRender : Decoder a -> (a -> String) -> String -> String
decodeAndRender decoder render source =
    case Decode.decodeString decoder source of
        Ok config ->
            render config

        Err error ->
            SvgText.error (Decode.errorToString error)
