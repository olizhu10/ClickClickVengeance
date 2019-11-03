open Yojson.Basic.Util

type difficulty = Easy | Med | Hard

type t = {
  song_name: string;
  bpm: int;
  difficulty: difficulty;
  file: string
}

let diff_from_json json = 
  match json |> member "difficulty" |> to_string with
  | "easy" -> Easy
  | "medium" -> Med
  | "hard" -> Hard
  | _ -> failwith "bad song difficulty"

let from_json json = {
  song_name = json |> member "song name" |> to_string;
  bpm = json |> member "bpm" |> to_int;
  difficulty = diff_from_json json;
  file = json |> member "file" |> to_string;
}

let bpm s = s.bpm

let difficulty s = s.difficulty

let song_name s = s.song_name

let music_file s = s.file