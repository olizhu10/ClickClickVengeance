open Graphics
open Graphic

(** Left is 0, Down is 1, Up is 2, Right is 3 *)
type arrow = Left | Down | Up | Right

type cell = arrow option

type matrix = cell list list

type press = Hit | Miss | Other

type player = {
  score: int;
  scored_this_arrow : bool;
  lives_remaining: int;
  last_ten: press list;
  first_of_double: string;
}

type t = {
  matrix: matrix;
  num_players: int;
  speed: float;
  paused: bool;
  length: int;
  beat: int;
  players: player * player option;
}


let leaderboard = ref []

let player_1_ref = ref {
    score = 0;
    scored_this_arrow = false;
    lives_remaining = 5;
    last_ten = [Miss;Miss;Miss;Miss;Miss;Miss;Miss;Miss;Miss;Miss];
    first_of_double = "";
  }

let player_2_ref = ref {
    score = 0;
    scored_this_arrow = false;
    lives_remaining = 5;
    last_ten = [Miss;Miss;Miss;Miss;Miss;Miss;Miss;Miss;Miss;Miss];
    first_of_double = "";
  } 

(** [state] is the reference pointing to the current state of the game. *)
let state = ref {
    matrix = [];
    num_players = 0;
    speed = 0.0;
    paused = false;
    length = 0;
    beat = 0;
    players = (!player_1_ref, None);
  }

let leaderboard = ref []

(** [init_state num bpm len] is the initial state of the game. *)
let init_state num bpm len = 
  state := {
    matrix = [
      [None; None; None; None];
      [None; None; None; None];
      [None; None; None; None];
      [None; None; None; None];
      [None; None; None; None]; 
      [None; None; None; None];
      [None; None; None; None];
      [None; None; None; None];
    ];
    num_players = num;
    speed = bpm;
    paused = false;
    length = len;
    beat = 0;
    players = if num = 1 then (!player_1_ref, None) else (!player_1_ref, Some !player_2_ref);
  }

(* some functions used for testing:*)
let get_paused () = !state.paused

(** [speed ()] is the beats per second for the state's bpm *)
let speed () = 
  1.0 /. (!state.speed /. 60.0)

let rec make_score_list n acc =
  if n > 0 then (make_score_list (n-1) (0::acc)) else acc

let score player = if player = 1 then !player_1_ref.score else !player_2_ref.score

(** [get_lives] is the number of lives remaining in state [t]. *)
let get_lives player = if player = 1 then !player_1_ref.lives_remaining else !player_2_ref.lives_remaining

let get_beat () = !state.beat

let get_length () = !state.length

(** [get_curr_matrix] is the game matrix in state [t]. *)
let get_curr_matrix () = !state.matrix

let single_rows = [
  [Some Left; None; None; None]; [None; Some Down; None; None];
  [None; None; Some Up; None];[None; None; None; Some Right]
]

let double_rows = [
  [Some Left; Some Down; None; None];
  [None; Some Down; Some Up; None];
  [None; None; Some Up; Some Right];
  [None; Some Down; None; Some Right];
  [Some Left; None; Some Up; None];
  [Some Left; None; None; Some Right]
]

(** [generate_random_row ()] is a row with an arrow in a randomly generated 
    position *)
let generate_random_row () = 
  if !state.beat < 10 then
    match Random.int 5 with
    | 0 -> print_endline "0"; [Some Left; None; None; None]
    | 1 -> print_endline "1"; [None; Some Down; None; None]
    | 2 -> print_endline "2"; [None; None; Some Up; None]
    | 3 -> print_endline "3"; [None; None; None; Some Right]
    | 4 -> [None;None;None;None]
    | _ -> failwith "random"
  else 
    match Random.int 11 with 
    | 0 -> print_endline "0"; [Some Left; None; None; None]
    | 1 -> print_endline "1"; [None; Some Down; None; None]
    | 2 -> print_endline "2"; [None; None; Some Up; None]
    | 3 -> print_endline "3"; [None; None; None; Some Right]
    | 4 -> print_endline "4"; [Some Left; Some Down; None; None]
    | 5 -> print_endline "5"; [None; Some Down; Some Up; None]
    | 6 -> print_endline "6"; [None; None; Some Up; Some Right]
    | 7 -> print_endline "7"; [None; Some Down; None; Some Right]
    | 8 -> print_endline "8"; [Some Left; None; Some Up; None]
    | 9 -> print_endline "9"; [Some Left; None; None; Some Right]
    | 10 -> [None;None;None;None]
    | _ -> failwith "random"

let is_hot lst = 
  lst = [Hit;Hit;Hit;Hit;Hit;Hit;Hit;Hit;Hit;Hit]

(** [bottom_row m] is the bottom row of the matrix [m] *)
let bottom_row m = 
  match List.rev m with
  | h :: t -> h
  | _ -> failwith "bad matrix"

let is_double_hit sec_inpt player = 
  let t = !state in
  if not (List.mem (!player.first_of_double) ["right";"left";"up";"down"]) then Miss else
    let fst_inpt = !player.first_of_double in 
    match fst_inpt, sec_inpt with 
    | "up", "left" -> if List.mem (Some Up)(bottom_row t.matrix) && 
                         List.mem (Some Left )(bottom_row t.matrix) then (print_endline "double hit"; Hit) else 
        (print_endline "double miss"; Miss)
    | "left", "up" -> if List.mem (Some Up)(bottom_row t.matrix) && 
                         List.mem (Some Left )(bottom_row t.matrix) then (print_endline "double hit"; Hit) else 
        (print_endline "double miss"; Miss)
    | "up", "right" -> if List.mem (Some Up)(bottom_row t.matrix) && 
                          List.mem (Some Right )(bottom_row t.matrix) then (print_endline "double hit"; Hit) else 
        (print_endline "double miss"; Miss)
    | "right", "up" -> if List.mem (Some Up)(bottom_row t.matrix) && 
                          List.mem (Some Right )(bottom_row t.matrix) then  (print_endline "double hit"; Hit) else 
        (print_endline "double miss"; Miss)
    | "up", "down" -> if List.mem (Some Up)(bottom_row t.matrix) && 
                         List.mem (Some Down )(bottom_row t.matrix) then (print_endline "double hit"; Hit) else 
        (print_endline "double miss"; Miss)
    | "down", "up" -> if List.mem (Some Up)(bottom_row t.matrix) && 
                         List.mem (Some Down )(bottom_row t.matrix) then (print_endline "double hit"; Hit) else 
        (print_endline "double miss"; Miss)
    | "left", "down" -> if List.mem (Some Left)(bottom_row t.matrix) && 
                           List.mem (Some Down )(bottom_row t.matrix) then (print_endline "double hit"; Hit) else 
        (print_endline "double miss"; Miss)
    | "down", "left" -> if List.mem (Some Left)(bottom_row t.matrix) && 
                           List.mem (Some Down )(bottom_row t.matrix) then (print_endline "double hit"; Hit) else 
        (print_endline "double miss"; Miss)
    | "right", "down" -> if List.mem (Some Right)(bottom_row t.matrix) && 
                            List.mem (Some Down )(bottom_row t.matrix) then (print_endline "double hit"; Hit) else 
        (print_endline "double miss"; Miss)
    | "down", "right" -> if List.mem (Some Right)(bottom_row t.matrix) && 
                            List.mem (Some Down )(bottom_row t.matrix) then  (print_endline "double hit"; Hit) else 
        (print_endline "double miss"; Miss)
    | "left", "right" -> if List.mem (Some Right)(bottom_row t.matrix) && 
                            List.mem (Some Left )(bottom_row t.matrix) then  (print_endline "double hit"; Hit) else 
        (print_endline "double miss"; Miss)
    | "right", "left" -> if List.mem (Some Right)(bottom_row t.matrix) && 
                            List.mem (Some Left )(bottom_row t.matrix) then  (print_endline "double hit"; Hit) else 
        (print_endline "double miss"; Miss)
    | "", _ -> Other
    | _, "" -> Other
    | _ -> Miss


(** [is_hit t inpt] is whether or not the player's tap is accurate. 
    A tap is accurate if it is hit at the correct time and position. *)
let is_hit inpt player= 
  if List.mem (bottom_row (!state.matrix)) double_rows then is_double_hit inpt player

  else 
    match inpt with
    | "up" -> if List.mem (Some Up) (bottom_row !state.matrix) then Hit else Miss
    | "down" -> if List.mem (Some Down) (bottom_row !state.matrix) then Hit else Miss
    | "left" -> if List.mem (Some Left) (bottom_row !state.matrix) then Hit else Miss
    | "right" -> if List.mem (Some Right) (bottom_row !state.matrix) then Hit else Miss
    | "" -> Other
    | _ -> Miss

(** [update_matrix t] is a matrix with all of the rows in the matrix of [t] 
    shifted down and pops off the bottom row and adds a new random row to the 
    top. *)
let update_matrix () =
  match List.rev !state.matrix with
  | h :: t -> (generate_random_row ())::(List.rev t)
  | _ -> failwith "bad matrix"


let rec remove_last_three m = 
  if List.length m = 5 then m else 
    match m with
    | h :: t -> remove_last_three t
    | [] -> failwith "last_three error"


let rec resume_matrix m acc = 
  List.rev_append (List.rev (remove_last_three m)) [[None;None;None;None];[None;None;None;None];[None;None;None;None]]

(** [calc-score inpt] is the score of the game, adjusted for hits and misses. *)
let calc_score inpt player = 
  if !player.scored_this_arrow = true then !player.score 
  else if !state.paused = true then !player.score
  else begin
    match is_hit inpt player with
    | Hit -> (if is_hot (!player.last_ten )
              then !player.score + 2 else !player.score + 1)
    | Miss -> !player.score
    | Other -> !player.score
  end

(** [scored_this_arrow inpt new_score] is true if the player already scored 
    during this beat and false otherwise. *)
let scored_this_arrow inpt new_score player = 
  if inpt = "beat" then  false 
  else  (if player.scored_this_arrow = true then true else 
         if (new_score <> player.score) then true else false)

(** [lives_remaining inpt] is the number of remaining lives the player has. *)
let lives_remaining inpt new_matrix p = 
  let player = if p = 1 then player_1_ref else player_2_ref in
  if (List.mem (bottom_row new_matrix) double_rows) &&
     !player.first_of_double = "" then !player.lives_remaining else
    (if inpt <> "beat" && (is_hit inpt player = Miss) then
       (print_endline !player.first_of_double; !player.lives_remaining - 1) else !player.lives_remaining)

(** [increase_speed score] is the increased speed. *)
let increase_speed beat = 
  if (beat mod 20 = 0)
  then begin print_endline "change speed"; !state.speed *. 1.1 end 
  else !state.speed

let update_leaderboard score = 
  leaderboard := List.sort compare (score::!leaderboard);
  print_endline (String.concat "\n" (List.map string_of_int !leaderboard))

let update_graphics () = 
  if is_hot (!player_1_ref.last_ten)then 
    print_endline "hotstreak1";
  if is_hot (!player_2_ref.last_ten)then 
    print_endline "hotstreak2";
  if !state.num_players = 1 
  then begin if !state.paused = true then ()
    else Graphic.update_graphics_1 !state.matrix !player_1_ref.score 
        !player_1_ref.lives_remaining (is_hot (!player_1_ref.last_ten)) end
  else if !state.paused = true then () 
  else begin Graphic.update_graphics_2 !state.matrix !player_1_ref.score 
      !player_1_ref.lives_remaining (is_hot (!player_1_ref.last_ten)) !player_2_ref.score 
      !player_2_ref.lives_remaining (is_hot (!player_2_ref.last_ten)) end

(*last_ten tracks the 10 most recent press results, with the most recent 
  being the last element of the list*)
let update_last_ten (p:press) (lst: press list) = 
  match lst with
  | h::t -> List.concat [t; [p]]
  | _ -> failwith "somethings very wrong"

let pause_game () = 
  let new_state = {
    matrix = !state.matrix;
    num_players = !state.num_players;
    speed = !state.speed;
    paused = true;
    length = !state.length;
    beat = !state.beat;
    players = !state.players;
  } 
  in 
  state := new_state;
  update_graphics ()

let resume_game () = 
  let new_state = {
    matrix = resume_matrix !state.matrix [];
    num_players = !state.num_players;
    speed = !state.speed;
    paused = false;
    length = !state.length;
    beat = !state.beat;
    players = !state.players;
  } 
  in 
  state := new_state;
  update_graphics ()

let rec update_player inpt matrix p = 
  let player = (if p = 1 then player_1_ref else player_2_ref) in
  let new_score = if bottom_row !state.matrix <> [None;None;None;None]
    then calc_score inpt player else !player.score in
  let new_player_state = {
    score = new_score;
    scored_this_arrow = scored_this_arrow inpt new_score !player;
    lives_remaining = lives_remaining inpt matrix p;
    last_ten = if inpt <> "beat" && (!player.scored_this_arrow = false) 
                  && not (List.mem (bottom_row matrix) double_rows && 
                          !player.first_of_double = "") then 
        (update_last_ten (is_hit inpt player) (!player.last_ten)) else
        !player.last_ten;
    first_of_double = if List.mem (bottom_row matrix) double_rows &&
                         inpt <> "beat" then inpt else "";
  } in 
  player := new_player_state

let rec update (inpt: string) (plyr: int): unit =
  if inpt = "pause" then pause_game ()
  else if inpt = "resume" then resume_game ()
  else
    let new_matrix = if inpt = "beat" && (!state.paused = false) then 
    update_matrix () else !state.matrix in
    update_player inpt new_matrix plyr;

    let new_state = {
      matrix = new_matrix;
      num_players = !state.num_players;
      speed = if inpt = "beat" then (increase_speed (!state.beat + 1)) else !state.speed; (* should add increase_speed here *)
      paused = !state.paused;
      length = !state.length;
      beat = if inpt = "beat" then !state.beat + 1 else !state.beat;
      players = !state.players

    } in 
    print_endline "player1 score";
    print_endline (string_of_int !player_1_ref.score);
    state := new_state;
    update_graphics () 

