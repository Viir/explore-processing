module Seeded exposing (next, pick)


next : Int -> Int
next seed =
    modBy 65521 (modBy 65521 seed * 173 + 13849)


pick : Int -> a -> List a -> a
pick seed first rest =
    first
        :: rest
        |> List.drop (modBy (1 + List.length rest) seed)
        |> List.head
        |> Maybe.withDefault first
