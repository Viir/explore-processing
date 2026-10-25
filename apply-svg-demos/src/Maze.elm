module Maze exposing (Cell, passages, render)

import Seeded
import Set exposing (Set)
import SvgText


type alias Cell =
    ( Int, Int )


passages : Int -> Int -> Int -> List ( Cell, Cell )
passages seed columns rows =
    if columns < 1 || rows < 1 || columns > 40 || rows > 30 then
        []

    else
        walk columns rows seed [ ( 0, 0 ) ] (Set.singleton ( 0, 0 )) []


walk : Int -> Int -> Int -> List Cell -> Set Cell -> List ( Cell, Cell ) -> List ( Cell, Cell )
walk columns rows seed stack visited carved =
    case stack of
        [] ->
            carved

        (( x, y ) as current) :: remaining ->
            let
                available =
                    [ ( x + 1, y ), ( x, y + 1 ), ( x - 1, y ), ( x, y - 1 ) ]
                        |> List.filter
                            (\(( nx, ny ) as cell) ->
                                nx >= 0 && nx < columns && ny >= 0 && ny < rows && not (Set.member cell visited)
                            )
            in
            case available of
                [] ->
                    walk columns rows seed remaining visited carved

                first :: rest ->
                    let
                        nextSeed =
                            Seeded.next seed

                        destination =
                            Seeded.pick nextSeed first rest
                    in
                    walk columns rows nextSeed (destination :: stack) (Set.insert destination visited) (( current, destination ) :: carved)


edge : Cell -> Cell -> ( Cell, Cell )
edge first second =
    if first < second then
        ( first, second )

    else
        ( second, first )


render : Int -> ( Int, Int ) -> String
render seed ( columns, rows ) =
    if columns < 1 || columns > 40 || rows < 1 || rows > 30 then
        SvgText.error "Maze dimensions must be 1..40 columns and 1..30 rows."

    else
        let
            openEdges =
                passages seed columns rows |> List.map (\( a, b ) -> edge a b) |> Set.fromList

            right =
                32 + columns * 32

            bottom =
                64 + rows * 32

            line x1 y1 x2 y2 =
                "<line x1=\""
                    ++ String.fromInt x1
                    ++ "\" y1=\""
                    ++ String.fromInt y1
                    ++ "\" x2=\""
                    ++ String.fromInt x2
                    ++ "\" y2=\""
                    ++ String.fromInt y2
                    ++ "\"/>"

            walls index =
                let
                    x =
                        modBy columns index

                    y =
                        index // columns

                    px =
                        32 + x * 32

                    py =
                        64 + y * 32
                in
                (if x + 1 < columns && not (Set.member (edge ( x, y ) ( x + 1, y )) openEdges) then
                    line (px + 32) py (px + 32) (py + 32)

                 else
                    ""
                )
                    ++ (if y + 1 < rows && not (Set.member (edge ( x, y ) ( x, y + 1 )) openEdges) then
                            line px (py + 32) (px + 32) (py + 32)

                        else
                            ""
                       )
        in
        SvgText.document (right + 32)
            (bottom + 48)
            ("Maze - seed " ++ String.fromInt seed)
            ("<rect width=\"100%\" height=\"100%\" fill=\"#fcfaf5\"/>"
                ++ "<g font-family=\"sans-serif\" fill=\"#183049\">"
                ++ "<text x=\"32\" y=\"26\" font-size=\"18\">Seed "
                ++ String.fromInt seed
                ++ "</text><text x=\"32\" y=\"52\" font-size=\"11\">IN</text>"
                ++ "<text x=\""
                ++ String.fromInt (right - 28)
                ++ "\" y=\""
                ++ String.fromInt (bottom + 24)
                ++ "\" font-size=\"11\">OUT</text></g>"
                ++ "<g id=\"maze-walls\" stroke=\"#183049\" stroke-width=\"3\" stroke-linecap=\"round\">"
                ++ line 64 64 right 64
                ++ line 32 64 32 bottom
                ++ line right 64 right bottom
                ++ line 32 bottom (right - 32) bottom
                ++ (List.range 0 (columns * rows - 1) |> List.map walls |> String.concat)
                ++ "</g>"
            )
