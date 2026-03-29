

game

  deck_size 108

  rank_points :
    A = 0
    2 = 2
    3 = 3
    4 = 4
    5 = 5
    6 = 6
    7 = 7
    8 = 8
    9 = 9


  card_type skip points 20 :
    player_at_offset 1 : skips_turn

  card_type reverse points 20 :
    reverse turn_order

  card_type draw_two points 20 :
    player_at_offset 1 : draws 2

  card_type wild points 50 :
    current_player: chooses suit

  card_type wild_draw_four points 50 :
    current_player: chooses suit
    player_at_offset 1 : draws 4


  current_color = red


  rule obligation uno :
    requirement :
      hand_size equals 1
    must :
      current_player declares uno
    deadline :
      before_next_turn
    enforcement :
      callout_by_next_player before_next_player_plays
    on_violation :
      current_player: draws 3


  rule for play :
    (player is current_turn and (card matches suit of top_discard or card matches rank of top_discard))

  rule for draw :
    player is current_turn


  round_ends_when :
    hand_size equals 0
  then :
    all_players: add_hand_value

  game_ends_when :
    any_player hand_size equals 0


  setup :
    each_player draws 2
    discard top_card from deck


  player alice
  player bob


  deck
    2x red 0-9
    2x red skip
    2x red reverse
    2x red draw_two
    2x yellow 0-9
    2x yellow skip
    2x yellow reverse
    2x yellow draw_two
    2x green 0-9
    2x green skip
    2x green reverse
    2x green draw_two
    2x blue 0-9
    2x blue skip
    2x blue reverse
    2x blue draw_two
    4x wild
    4x wild_draw_four


  turn alice



