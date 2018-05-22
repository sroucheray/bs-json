(* Decode a JSON tree structure *)
type 'a tree =
| Node of 'a * 'a tree list
| Leaf of 'a

module Decode = struct
  open Json.Decode

  let rec tree decoder =
    obj (fun ~field ->
      field.required "type" (string |> andThen (
        function | "node" -> node decoder
                | "leaf" -> leaf decoder
                | _      -> failwith "unknown node type"
      ))
    )

  and node decoder =
    obj (fun ~field ->
      Node (
        (field.required "value" decoder),
        (field.required "children" (array (tree decoder) |> map Array.to_list))
      )
    )

  and leaf decoder =
    obj (fun ~field ->
      Leaf (field.required "value" decoder)
    )
end

let rec indent =
  function | n when n <= 0 -> ()
           | n -> print_string "  "; indent (n - 1)

let print =
  let rec aux level =
    function | Node (value, children) ->
               indent level;
               Js.log value;
               children |> List.iter (fun child -> aux (level + 1) child)
             | Leaf value ->
               indent level;
               Js.log value
    in
  aux 0 

let json = {| {
  "type": "node",
  "value": 9,
  "children": [{
    "type": "node",
    "value": 5,
    "children": [{
      "type": "leaf",
      "value": 3
    }, {
      "type": "leaf",
      "value": 2
    }]
  }, {
      "type": "leaf",
      "value": 4
  }]
} |}

let myTree =
  json |> Json.parseOrRaise 
       |> Decode.tree Json.Decode.int
       |> function | Ok tree   -> print tree
                   | Error msg -> Js.log msg