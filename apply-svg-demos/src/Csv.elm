module Csv exposing (parse)


type Mode
    = Unquoted
    | Quoted
    | AfterQuote


parse : String -> Result String (List (List String))
parse source =
    source
        |> String.replace "\u{000D}\n" "\n"
        |> String.replace "\u{000D}" "\n"
        |> String.toList
        |> consume Unquoted [] [] []


consume : Mode -> List Char -> List String -> List (List String) -> List Char -> Result String (List (List String))
consume mode field row rows chars =
    let
        value =
            case field of
                [] ->
                    ""

                _ ->
                    String.fromList (List.reverse field)

        finishRow =
            List.reverse (value :: row)
    in
    case chars of
        [] ->
            case mode of
                Quoted ->
                    Err "CSV has an unterminated quoted field."

                _ ->
                    if mode == Unquoted && List.isEmpty field && List.isEmpty row then
                        Ok (List.reverse rows)

                    else
                        Ok (List.reverse (finishRow :: rows))

        char :: rest ->
            case ( mode, char ) of
                ( Quoted, '"' ) ->
                    consume AfterQuote field row rows rest

                ( Quoted, _ ) ->
                    consume Quoted (char :: field) row rows rest

                ( AfterQuote, '"' ) ->
                    consume Quoted ('"' :: field) row rows rest

                ( _, ',' ) ->
                    consume Unquoted [] (value :: row) rows rest

                ( _, '\n' ) ->
                    consume Unquoted [] [] (finishRow :: rows) rest

                ( AfterQuote, _ ) ->
                    Err "CSV has an unexpected character after a closing quote."

                ( Unquoted, '"' ) ->
                    if List.isEmpty field then
                        consume Quoted [] row rows rest

                    else
                        Err "CSV quotes must begin at the start of a field."

                ( Unquoted, _ ) ->
                    consume Unquoted (char :: field) row rows rest
