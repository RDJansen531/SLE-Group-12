module Syntax

extend lang::std::Layout;
extend lang::std::Id;

lexical Integer = [0-9]+ !>> [0-9];

// TypeId must start with a lowercase letter, preventing conflicts with
// uppercase rank keywords (A, J, Q, K) in the Card/DeckItem grammars.
lexical TypeId = [a-z][A-Za-z0-9_]* !>> [A-Za-z0-9_];

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
  = rankPoints: "rank_points" ":" RankPointValue+ vals;

syntax RankPointValue
  = rankValue: Rank rank "=" Integer val;

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
  = standardRange: Multiplier? mult SuitName suit RankRange range
  > mixedCard: Multiplier? mult SuitName suit TypeId? typeIds;

syntax Multiplier
  = mult: Integer count "x";

syntax RankRange
  = numericRange: Integer startRank "-" Integer endRank
  | singleRank: Rank rank;

syntax Setup
  = setup: "setup" ":" SetupAction+ actions;

syntax SetupAction
  = dealToEach: "each_player" "draws" Integer count
  | dealToPlayer: "player" Id name "draws" Integer count
  | discardTopCard: "discard" "top_card" "from" "deck"
  | initState: Id variable "=" Id val;

syntax Turn
  = turn: "turn" Id player;

syntax CardType
  = cardType: "card_type" Id name "points" Integer points ":" Effect+ effects;

syntax StateVar
  = stateVar: Id name "=" Id val;

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
  = setState: "set" Id variable "=" Id val
  | reverseTurnOrder: "reverse" "turn_order"
  | startNewRound: "start_new_round";

syntax Rule
  = rule: "rule" "for" ActionType ":" Condition+ conditions
  | obligationRule: "rule" "obligation" Id name ":"
                   "requirement" ":" Condition+ requirements
                   "must" ":" ObligationMust must
                   "deadline" ":" ObligationDeadline deadline
                   "enforcement" ":" ObligationEnforcement enforcement
                   "on_violation" ":" Effect+ onViolation;

syntax ObligationMust
  = currentPlayerDeclares: "current_player" "declares" Id declaration;

syntax ObligationDeadline
  = beforeNextTurn: "before_next_turn";

syntax ObligationEnforcement
  = calloutByNextPlayer: "callout_by_next_player" ObligationCalloutExpiry expiry;

syntax ObligationCalloutExpiry
  = beforeNextPlayerPlays: "before_next_player_plays";

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
  | parens: "(" Condition cond ")"
  > not: "not" Condition cond
  > left and: Condition lhs "and" Condition rhs
  > left or: Condition lhs "or" Condition rhs;

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
  > mixed: SuitName suit TypeId? typeIds;

syntax Suit
  = hearts:   "hearts"
  | diamonds: "diamonds"
  | clubs:    "clubs"
  | spades:   "spades";

syntax Rank
  = ace:   "A"
  | numeral: Integer
  | jack:  "J"
  | queen: "Q"
  | king:  "K";