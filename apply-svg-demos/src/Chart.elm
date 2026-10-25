module Chart exposing (parse, render)

import Csv
import SvgText


parse : String -> Result String (List ( String, Float ))
parse csv =
    Csv.parse csv
        |> Result.andThen
            (\allRows ->
                case List.filter (\row -> not (List.all (String.trim >> String.isEmpty) row)) allRows of
                    header :: rows ->
                        if List.map String.trim header /= [ "label", "value" ] then
                            Err "CSV must start with the header label,value."

                        else if List.isEmpty rows || List.length rows > 20 then
                            Err "Use between 1 and 20 data rows."

                        else
                            parseRows 2 rows

                    [] ->
                        Err "CSV is empty. Expected label,value and at least one data row."
            )


parseRows : Int -> List (List String) -> Result String (List ( String, Float ))
parseRows rowNumber rows =
    case rows of
        [] ->
            Ok []

        [ label, rawValue ] :: rest ->
            case String.toFloat (String.trim rawValue) of
                Just value ->
                    if isNaN value || isInfinite value || value < 0 || value > 1000000000 then
                        Err ("Row " ++ String.fromInt rowNumber ++ ": value must be finite and between 0 and 1000000000.")

                    else if String.isEmpty (String.trim label) then
                        Err ("Row " ++ String.fromInt rowNumber ++ ": label must not be empty.")

                    else
                        parseRows (rowNumber + 1) rest |> Result.map ((::) ( label, value ))

                Nothing ->
                    Err ("Row " ++ String.fromInt rowNumber ++ ": invalid number " ++ rawValue)

        _ :: _ ->
            Err ("Row " ++ String.fromInt rowNumber ++ ": expected exactly two CSV fields.")


render : String -> { title : String, color : String } -> String
render csv options =
    if not (SvgText.validColor options.color) then
        SvgText.error "Chart color must use #RGB or #RRGGBB form."

    else
        case parse csv of
            Err message ->
                SvgText.error message

            Ok entries ->
                renderEntries options entries


renderEntries : { title : String, color : String } -> List ( String, Float ) -> String
renderEntries options entries =
    let
        maximum =
            max 1 (entries |> List.map Tuple.second |> List.maximum |> Maybe.withDefault 1)

        height =
            156 + List.length entries * 52

        bar index ( label, value ) =
            let
                y =
                    106 + index * 52
            in
            "<g><title>"
                ++ SvgText.escape label
                ++ ": "
                ++ String.fromFloat value
                ++ "</title><text x=\"222\" y=\""
                ++ String.fromInt (y + 23)
                ++ "\" text-anchor=\"end\" font-size=\"15\">"
                ++ SvgText.escape
                    (if String.length label > 25 then
                        String.left 22 label ++ "..."

                     else
                        label
                    )
                ++ "</text><rect class=\"bar\" x=\"240\" y=\""
                ++ String.fromInt y
                ++ "\" width=\""
                ++ String.fromFloat (540 * value / maximum)
                ++ "\" height=\"34\" rx=\"5\" fill=\""
                ++ options.color
                ++ "\"/><text x=\""
                ++ String.fromFloat (252 + 540 * value / maximum)
                ++ "\" y=\""
                ++ String.fromInt (y + 23)
                ++ "\" font-size=\"14\">"
                ++ String.fromFloat value
                ++ "</text></g>"
    in
    SvgText.document 900
        height
        options.title
        ("<rect width=\"900\" height=\""
            ++ String.fromInt height
            ++ "\" fill=\"#f5f7fa\"/>"
            ++ "<g font-family=\"sans-serif\" fill=\"#183049\">"
            ++ "<text x=\"32\" y=\"43\" font-size=\"26\" font-weight=\"bold\">"
            ++ SvgText.escape
                (if String.length options.title > 48 then
                    String.left 45 options.title ++ "..."

                 else
                    options.title
                )
            ++ "</text><text x=\"32\" y=\"72\" font-size=\"14\">CSV to SVG / "
            ++ String.fromInt (List.length entries)
            ++ " categories</text>"
            ++ (List.indexedMap bar entries |> String.concat)
            ++ "</g>"
        )
