module SvgText exposing (document, error, escape, validColor)


escape : String -> String
escape text =
    text
        |> String.map xmlCharacter
        |> String.replace "&" "&amp;"
        |> String.replace "<" "&lt;"
        |> String.replace ">" "&gt;"
        |> String.replace "\"" "&quot;"
        |> String.replace "'" "&apos;"


xmlCharacter : Char -> Char
xmlCharacter char =
    let
        code =
            Char.toCode char
    in
    if code == 9 || code == 10 || code == 13 || (code >= 32 && code <= 0xD7FF) || (code >= 0xE000 && code <= 0xFFFD) || (code >= 0x00010000 && code <= 0x0010FFFF) then
        char

    else
        '�'


document : Int -> Int -> String -> String -> String
document width height title body =
    "<svg xmlns=\"http://www.w3.org/2000/svg\" width=\""
        ++ String.fromInt width
        ++ "\" height=\""
        ++ String.fromInt height
        ++ "\" viewBox=\"0 0 "
        ++ String.fromInt width
        ++ " "
        ++ String.fromInt height
        ++ "\" role=\"img\"><title>"
        ++ escape title
        ++ "</title>"
        ++ body
        ++ "</svg>\n"


validColor : String -> Bool
validColor color =
    (String.length color == 4 || String.length color == 7)
        && String.startsWith "#" color
        && String.all (\char -> String.contains (String.fromChar char) "0123456789abcdefABCDEF") (String.dropLeft 1 color)


error : String -> String
error message =
    document 960
        300
        "Demo input error"
        ("<rect width=\"960\" height=\"300\" fill=\"#fff4ee\"/>"
            ++ "<g font-family=\"monospace\" fill=\"#962f20\">"
            ++ "<text x=\"24\" y=\"38\" font-size=\"22\">Demo input error</text>"
            ++ (message
                    |> String.lines
                    |> List.take 10
                    |> List.indexedMap
                        (\index line ->
                            "<text x=\"24\" y=\""
                                ++ String.fromInt (70 + index * 20)
                                ++ "\" font-size=\"14\">"
                                ++ escape (String.left 105 line)
                                ++ "</text>"
                        )
                    |> String.concat
               )
            ++ "</g>"
        )
