# SVG Demos With `pine apply`

Ordinary Elm functions that generate a geometric wallpaper, a solvable maze, and
a CSV bar chart.

This is an Elm application project used as a collection of batch functions, not a browser `main` program.

Install a Pine CLI build that supports batch `--watch`, then run the commands
below **from this directory**.

## Run Once

```sh
pine  apply  src/Demos.elm/wallpaperFromFile  --input-file inputs/wallpaper.json  --output-file output/wallpaper.svg
pine  apply  src/Demos.elm/mazeFromFile  --input-file inputs/maze.json  --output-file output/maze.svg
pine  apply  src/Demos.elm/chartFromFiles  --input-file inputs/sales.csv  --input-file inputs/chart.json  --output-file output/chart.svg
```

Open the generated SVGs in a browser or an editor's SVG preview. `output/`
already exists, and generated SVGs are git-ignored.

## Save a File and Watch the Picture Change

```sh
pine  apply  src/Demos.elm/wallpaperFromFile  --input-file inputs/wallpaper.json  --output-file output/wallpaper.svg  --watch
```

Put `inputs/wallpaper.json` on the left and a **live-reloading SVG preview** of
`output/wallpaper.svg` on the right. Change `inputs/wallpaper.json` and save.
Pine reruns the function and replaces the SVG; there is no need to rerun the
command.

The other demos work the same way:

```sh
pine  apply  src/Demos.elm/mazeFromFile  --input-file inputs/maze.json  --output-file output/maze.svg  --watch
pine  run  src/Demos.elm/chartFromFiles  --input-file inputs/sales.csv  --input-file inputs/chart.json  --output-file output/chart.svg  --watch
```

For the chart, edit a sales value, a label, the title, or the color and save the
corresponding input file. Try `inputs/temperatures.csv` as a second dataset.
`run` and `apply` have the same batch watch behavior. Stop with Ctrl+C.

Watch mode monitors the selected local input files, including editor saves that
replace a file by renaming.
All arguments must be explicit, at least one must be a local
`--input-file`, and `--output-file` must be distinct from every input. Fixed
`--input` literals are also allowed. Prompts, remote input files, interactive
applications, and `--transform-file` are not supported in watch mode.

## The Original Typed Functions

The file entry points decode JSON/text and call these same functions:

```elm
wallpaper : Int -> ( Int, Int ) -> List String -> String
maze : Int -> ( Int, Int ) -> String
chart : String -> { title : String, color : String } -> String
```

```sh
pine  apply  src/Demos.elm/wallpaper  --input 42  --input '(960, 540)'  --input '["#101820", "#fee715", "#f96167", "#ffffff"]'  --output-file output/wallpaper.svg
pine  apply  src/Demos.elm/maze  --input 17  --input '(12, 8)'  --output-file output/maze.svg
pine  apply  src/Demos.elm/chart  --input-file inputs/sales.csv  --input '{ title = "Weekend market sales", color = "#237d92" }'  --output-file output/chart.svg
```

Omit the final `--input` on the chart command for a guided parameter prompt.
For a watch command with fixed styling, keep that `--input` and add `--watch`;
saving the CSV will still rerender the chart.

## Input Formats and Limits

Wallpaper JSON contains integer `seed`, `width`, `height`, and a `palette` list.
Sizes range from 120 x 120 through 1920 x 1080. Supply one to eight colors in
`#RGB` or `#RRGGBB` form.

Maze JSON contains integer `seed`, `columns`, and `rows`, with 1..40 columns and
1..30 rows. Depth-first carving creates a spanning tree: every cell is reachable
and there is exactly one route between any two cells. The entrance is at the
top-left and the exit at the bottom-right. Start with the supplied 12 x 8 grid.

Chart CSV starts with `label,value` and contains 1..20 nonblank data rows.
Values must be finite numbers between 0 and 1,000,000,000. The parser supports
quoted commas, doubled quotes, quoted newlines, CRLF/LF line endings, and empty
fields; a missing label/value is an error. Blank rows are ignored. Chart JSON
contains string `title` and `color`; the color uses the same hex syntax as the
wallpaper. Long labels/titles are shortened visually, with full values retained
in SVG titles. This is a nonnegative horizontal bar chart, not a general chart
library. The temperature fixture uses nonnegative Celsius readings.

Input data is XML-escaped before rendering. **Malformed JSON, CSV, or unsupported
configuration produces a visibly labeled error SVG**, rather than an empty
picture or a silent fallback. This intentionally replaces the previous picture
so a recording shows the error. It is still a successful `String` result to
Pine, not a command failure. File-read/evaluation/write failures are reported by
Pine and leave the previous output intact; watch mode stays ready for another
save.

## Tests and Source Layout

```sh
pine  elm  test  .
pine  elm  format  src  tests  --verify-no-changes
```

The portable Elm tests check reproducibility, maze connectivity/acyclicity,
CSV quoting/error cases, zero-valued charts, file configuration, and escaping.

`Demos.elm` exposes the typed and file-based entry points. `Wallpaper.elm`,
`Maze.elm`, and `Chart.elm` implement the demos; `Csv.elm`, `Seeded.elm`, and
`SvgText.elm` are small shared helpers. Only `elm/core` and `elm/json` are needed
for generation; test dependencies are listed separately in `elm.json`.
