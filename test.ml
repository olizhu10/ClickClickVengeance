open OUnit2
open Game
open Main
open Song

(** Our approach to testing:
 *unit tests for function
 *testing changes made to the mutable state behave as intended
*)

let one_player_tests = [
  "initial lives" >:: (fun _ -> (assert_equal (get_lives 1) 5));
  "initial score" >:: (fun _ -> (assert_equal (get_score 1) 0 ));
  "speed" >:: (fun _ -> (assert_equal (speed ()) 1.0));
  "pause false" >:: (fun _ -> (assert_equal (get_paused ()) false));
] 

let two_player_tests = [
  "initial lives p1" >:: (fun _ -> (assert_equal (get_lives 1) 5));
  "initial lives p2" >:: (fun _ -> (assert_equal (get_lives 2) 5));
  "initial score p1" >:: (fun _ -> (assert_equal (get_score 1) 0));
  "initial score p2" >:: (fun _ -> (assert_equal (get_score 2) 0));
  "speed" >:: (fun _ -> (assert_equal (speed ()) 1.0 ));
  "pause false" >:: (fun _ -> (assert_equal (get_paused ()) false));
]

let paused_tests = [
  "pause true" >:: (fun _ -> (assert_equal (get_paused ()) true));
  "score doesn't change when paused" >:: (fun _ -> 
      (assert_equal (get_score 1) 0));
]

let suite_one = "test suite one player" >::: (one_player_tests) 
let suite_pause = "test suite pause" >::: (paused_tests) 
let suite_two = "test suite two player" >::: (two_player_tests)

let () = 
  Game.init_state 1 60.0 60; 
  run_test_tt_main suite_one;
  print_endline "done init";
  Game.update "pause" 1;
  run_test_tt_main suite_pause; 
  print_endline "done paused";
  Game.init_state 2 60.0 60;
  run_test_tt_main suite_two  
