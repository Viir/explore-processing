module DemosTests exposing (tests)

import Chart
import Csv
import Demos
import Expect
import Maze
import Set exposing (Set)
import SvgText
import Test exposing (Test, describe, test)


tests : Test
tests =
    describe "File-driven SVG demos"
        [ test "wallpaper is deterministic and changes with the seed" <|
            \_ ->
                let
                    render seed =
                        Demos.wallpaper seed ( 960, 540 ) [ "#101820", "#fee715", "#f96167" ]
                in
                Expect.all
                    [ \_ -> Expect.equal (render 42) (render 42)
                    , \_ -> Expect.notEqual (render 42) (render 43)
                    , \_ -> Expect.equal 84 (String.indexes "<g transform=" (render 42) |> List.length)
                    ]
                    ()
        , test "wallpaper validates sizes and palettes" <|
            \_ ->
                [ Demos.wallpaper 1 ( 0, 540 ) [ "#fff" ]
                , Demos.wallpaper 1 ( 960, 540 ) []
                , Demos.wallpaper 1 ( 960, 540 ) [ "red\" onload=\"bad" ]
                ]
                    |> List.all (String.contains "Demo input error")
                    |> Expect.equal True
        , test "file entry points decode configuration and report malformed JSON in SVG" <|
            \_ ->
                Expect.all
                    [ \_ ->
                        Demos.wallpaperFromFile "{\"seed\":42,\"width\":960,\"height\":540,\"palette\":[\"#123\",\"#abc\"]}"
                            |> String.contains "Geometric wallpaper - seed 42"
                            |> Expect.equal True
                    , \_ ->
                        Demos.mazeFromFile "{\"seed\":17,\"columns\":12,\"rows\":8}"
                            |> String.contains "Maze - seed 17"
                            |> Expect.equal True
                    , \_ ->
                        Demos.wallpaperFromFile "{broken"
                            |> String.contains "Demo input error"
                            |> Expect.equal True
                    ]
                    ()
        , describe "Maze spanning trees"
            (List.map mazeTest [ 0, 17, 42, -1 ])
        , test "single-cell maze has no internal edges" <|
            \_ ->
                Expect.equal [] (Maze.passages 17 1 1)
        , test "invalid maze dimensions are explicit SVG errors" <|
            \_ ->
                Demos.maze 17 ( 0, 8 )
                    |> String.contains "Demo input error"
                    |> Expect.equal True
        , test "CSV handles commas, doubled quotes, newlines, empty fields and CRLF" <|
            \_ ->
                Csv.parse "a,\"b,c\",\"say \"\"hi\"\"\",\"line\nbreak\",,\u{000D}\n"
                    |> Expect.equal (Ok [ [ "a", "b,c", "say \"hi\"", "line\nbreak", "", "" ] ])
        , test "CSV retains an empty quoted field and rejects malformed quoting" <|
            \_ ->
                Expect.all
                    [ \_ -> Expect.equal (Ok [ [ "" ] ]) (Csv.parse "\"\"")
                    , \_ -> Expect.err (Csv.parse "\"unfinished")
                    , \_ -> Expect.err (Csv.parse "un\"quoted")
                    , \_ -> Expect.err (Csv.parse "\"closed\"extra")
                    ]
                    ()
        , test "chart parses the schema and rejects invalid numbers or row shapes" <|
            \_ ->
                Expect.all
                    [ \_ -> Expect.equal (Ok [ ( "Coffee, hot", 12.5 ) ]) (Chart.parse "label,value\n\"Coffee, hot\",12.5\n")
                    , \_ -> Expect.err (Chart.parse "label,value\nx,-1\n")
                    , \_ -> Expect.err (Chart.parse "label,value\nx,not-a-number\n")
                    , \_ -> Expect.err (Chart.parse "label,value\nx,1,2\n")
                    , \_ -> Expect.err (Chart.parse "wrong,header\nx,1\n")
                    , \_ -> Expect.err (Chart.parse "label,value\n")
                    ]
                    ()
        , test "zero-valued chart is finite and labels are XML escaped" <|
            \_ ->
                let
                    svg =
                        Demos.chart "label,value\nTea & <cake>,0\n"
                            { title = "<Sales> & \"more\"", color = "#123abc" }
                in
                Expect.all
                    [ \_ -> Expect.equal 1 (List.length (String.indexes "class=\"bar\"" svg))
                    , \_ -> Expect.equal True (String.contains "Tea &amp; &lt;cake&gt;" svg)
                    , \_ -> Expect.equal True (String.contains "&lt;Sales&gt; &amp; &quot;more&quot;" svg)
                    , \_ -> Expect.equal False (String.contains "NaN" svg || String.contains "Infinity" svg)
                    , \_ -> Expect.equal True (String.contains "width=\"0\"" svg)
                    ]
                    ()
        , test "chart accepts file-based options and surfaces malformed inputs" <|
            \_ ->
                Expect.all
                    [ \_ ->
                        Demos.chartFromFiles "label,value\nA,2\nB,3\n" "{\"title\":\"Sales\",\"color\":\"#123\"}"
                            |> String.indexes "class=\"bar\""
                            |> List.length
                            |> Expect.equal 2
                    , \_ ->
                        Demos.chartFromFiles "label,value\nA,2\n" "{}"
                            |> String.contains "Demo input error"
                            |> Expect.equal True
                    , \_ ->
                        Demos.chart "label,value\nA,2\n" { title = "Sales", color = "unsafe" }
                            |> String.contains "Demo input error"
                            |> Expect.equal True
                    ]
                    ()
        , test "SVG text escapes all XML metacharacters" <|
            \_ ->
                Expect.equal "&amp;&lt;&gt;&quot;&apos;" (SvgText.escape "&<>\"'")
        , test "SVG text replaces characters forbidden by XML 1.0" <|
            \_ ->
                Expect.equal "A\u{FFFD}B" (SvgText.escape "A\u{0000}B")
        ]


mazeTest : Int -> Test
mazeTest seed =
    test ("seed " ++ String.fromInt seed ++ " connects all 96 cells without cycles") <|
        \_ ->
            let
                edges =
                    Maze.passages seed 12 8
            in
            Expect.all
                [ \_ -> Expect.equal 95 (List.length edges)
                , \_ -> Expect.equal 96 (Set.size (reachable edges [ ( 0, 0 ) ] Set.empty))
                , \_ ->
                    edges
                        |> List.all
                            (\( ( ax, ay ), ( bx, by ) ) ->
                                abs (ax - bx) + abs (ay - by) == 1
                                    && bx >= 0
                                    && bx < 12
                                    && by >= 0
                                    && by < 8
                            )
                        |> Expect.equal True
                ]
                ()


reachable : List ( Maze.Cell, Maze.Cell ) -> List Maze.Cell -> Set Maze.Cell -> Set Maze.Cell
reachable edges pending visited =
    case pending of
        [] ->
            visited

        current :: rest ->
            if Set.member current visited then
                reachable edges rest visited

            else
                let
                    neighbors =
                        edges
                            |> List.filterMap
                                (\( first, second ) ->
                                    if first == current then
                                        Just second

                                    else if second == current then
                                        Just first

                                    else
                                        Nothing
                                )
                in
                reachable edges (neighbors ++ rest) (Set.insert current visited)
