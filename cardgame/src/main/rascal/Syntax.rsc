module Syntax

extend lang::std::Layout;
extend lang::std::Id;

lexical Integer = [0-9]+ !>> [0-9];

// ---------------------------------------------------------------------------
// Concrete syntax
// ---------------------------------------------------------------------------

start syntax Game
  = game: "game" 
          DeckSize? deckSize
          RankPoints? rankPoints
          CardType* cardTypes
          StateVar* stateVars
          Violation* violations
          Rule* rules
          EndCondition* endConditions
          Setup? setup
          Player+ players
          Deck deck
          Turn turn
          Action* actions;

syntax DeckSize
  = deckSize: "deck_size" Integer size;

syntax RankPoints
  = rankPoints: "rank_points" ":" RankPointValue+ values;

syntax RankPointValue
  = rankValue: Rank rank "=" Integer points;

syntax Player
  = playerWithHand: "player" Id name "{" Hand hand "}"
  | player: "player" Id name;

syntax Hand
  = hand: "hand" Card* cards;

syntax Deck
  = deck: "deck" DeckItem* items;

syntax SuitName
  = standard: Suit suit
  | custom: Id name;

syntax DeckItem
  = singleCard: Card card
  | standardRange: Multiplier? mult SuitName suit RankRange range
  | customCard: Multiplier? mult SuitName suit Id cardType
  | wildCard: Multiplier? mult Id cardType;

syntax Multiplier
  = mult: Integer count "x";

syntax RankRange
  = numericRange: Integer start "-" Integer end
  | singleRank: Rank rank;

syntax Setup
  = setup: "setup" ":" SetupAction+ actions;

syntax SetupAction
  = dealToEach: "each_player" "draws" Integer count
  | dealToPlayer: "player" Id name "draws" Integer count
  | discardTopCard: "discard" "top_card" "from" "deck"
  | setState: Id variable "=" Id value;

syntax Turn
  = turn: "turn" Id player;

syntax CardType
  = cardType: "card_type" Id name "points" Integer points ":" Effect+ effects;

syntax StateVar
  = stateVar: Id name "=" Id value;

syntax Violation
  = violation: "violation" Id name ":" Condition+ conditions "penalty" ":" Effect+ penalties;

syntax EndCondition
  = roundEnd: "round_ends_when" ":" Condition+ conditions "then" ":" Effect+ effects
  | gameEnd: "game_ends_when" ":" Condition+ conditions;

syntax Effect
  = playerAction: PlayerTarget ":" PlayerEffect
  | stateChange: StateChange;

syntax PlayerTarget
  = current: "current_player"
  | relative: "player_at_offset" Integer offset
  | specific: "player" Id name
  | allPlayers: "all_players";

syntax PlayerEffect
  = draws: "draws" Integer count
  | discards: "discards" Integer count
  | skipsTurn: "skips_turn"
  | choosesSuit: "chooses" "suit"
  | choosesRank: "chooses" "rank"
  | swapsHandsWith: "swaps_hands_with" PlayerTarget target
  | shuffleAllHands: "shuffle_all_hands"
  | addPoints: "add_points" Integer points
  | addHandValue: "add_hand_value";

syntax StateChange
  = setState: Id variable "=" Id value
  | reverseTurnOrder: "reverse" "turn_order"
  | startNewRound: "start_new_round";

syntax Rule
  = rule: "rule" "for" ActionType ":" Condition+ conditions;

syntax ActionType
  = \play: "play"
  | \draw: "draw"
  | \discard: "discard"
  | \shuffle: "shuffle"
  | \pass: "pass"
  | \declare: "declare"
  | \challenge: "challenge";

syntax Condition
  = turnCheck: "player" "is" "current_turn"
  | deckNotEmpty: "deck" "not" "empty"
  | hasCard: "player" "has" Card card
  | cardMatches: "card" "matches" CardProperty "of" CardLocation
  | cardMatchesExact: "card" "matches_exactly" CardLocation location
  | handSizeLte: "hand_size" "at_most" Integer limit
  | handSizeGte: "hand_size" "at_least" Integer limit
  | handSizeLt: "hand_size" "less_than" Integer limit
  | handSizeGt: "hand_size" "greater_than" Integer limit
  | handSizeEq: "hand_size" "equals" Integer limit
  | playerHandSizeEq: "player" Id name "hand_size" "equals" Integer limit
  | playerDeclared: "player" Id name "declared" Id declaration
  | anyPlayerHasHandSize: "any_player" "hand_size" "equals" Integer limit
  | and: Condition lhs "and" Condition rhs
  | or: Condition lhs "or" Condition rhs
  | not: "not" Condition cond
  | parens: "(" Condition cond ")";

syntax CardProperty 
  = suit: "suit" 
  | rank: "rank" 
  | other: "other";

syntax CardLocation 
  = hand: "hand" 
  | topDiscard: "top_discard" 
  | deck: "deck";

syntax Action
  = play: "play" Id player Card+ cards
  | draw: "draw" Id player Card+ cards
  | discard: "discard" Id player Card+ cards
  | shuffle: "shuffle" Id player Deck deck
  | pass: "pass" Id player
  | declare: "declare" Id player Id declaration
  | challenge: "challenge" Id challenger Id target Id violation;

syntax Card
  = standard: SuitName suit Rank rank
  | custom: SuitName suit Id cardType
  | wild: Id cardType;

syntax Suit
  = hearts:   "hearts"
  | diamonds: "diamonds"
  | clubs:    "clubs"
  | spades:   "spades";

syntax Rank
  = ace:   "A"
  | two:   "2"
  | three: "3"
  | four:  "4"
  | five:  "5"
  | six:   "6"
  | seven: "7"
  | eight: "8"
  | nine:  "9"
  | ten:   "10"
  | jack:  "J"
  | queen: "Q"
  | king:  "K";