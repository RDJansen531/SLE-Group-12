module AST

import util::Maybe;

/*
 * Abstract Syntax Tree for Card Game DSL
 */

data Game
  = game(
      list[DeckSize] deckSize,
      list[RankPoints] rankPoints,
      list[CardType] cardTypes,
      list[StateVar] stateVars,
      list[Violation] violations,
      list[Rule] rules,
      list[EndCondition] endConditions,
      list[Setup] setup,
      list[Player] players,
      Deck deck,
      Turn turn,
      list[Action] actions,
      loc src=|unknown:///|
    );

data DeckSize = deckSize(int size, loc src=|unknown:///|);

data RankPoints = rankPoints(list[RankPointValue] vals, loc src=|unknown:///|);
data RankPointValue = rankValue(Rank rank, int val, loc src=|unknown:///|);

data Setup = setup(list[SetupAction] actions, loc src=|unknown:///|);

data Deck = deck(list[DeckItem] items, loc src=|unknown:///|);

data Turn = turn(str player, loc src=|unknown:///|);

data Player
  = playerWithHand(str name, Hand hand, loc src=|unknown:///|)
  | player(str name, loc src=|unknown:///|);

data Hand = hand(list[Card] cards, loc src=|unknown:///|);

data RankPoint
  = rankPoint(Rank rank, int points, loc src=|unknown:///|);

data DeckItem
  = standardRange(list[Multiplier] mult, SuitName suit, RankRange range, loc src=|unknown:///|)
  | mixedCard(list[Multiplier] mult, SuitName suit, list[str] typeIds, loc src=|unknown:///|);

data Multiplier = mult(int count, loc src=|unknown:///|);

data RankRange
  = numericRange(int startRank, int endRank, loc src=|unknown:///|)
  | singleRank(Rank rank, loc src=|unknown:///|);

data SuitName
  = standard(Suit suit, loc src=|unknown:///|)
  | custom(str name, loc src=|unknown:///|);

data Card
  = standard(SuitName suit, Rank rank, loc src=|unknown:///|)
  | mixed(SuitName suit, list[str] typeIds, loc src=|unknown:///|);

data Suit
  = hearts(loc src=|unknown:///|)
  | diamonds(loc src=|unknown:///|)
  | clubs(loc src=|unknown:///|)
  | spades(loc src=|unknown:///|);

data Rank
  = ace(loc src=|unknown:///|)
  | numeral(int n, loc src=|unknown:///|)
  | jack(loc src=|unknown:///|)
  | queen(loc src=|unknown:///|)
  | king(loc src=|unknown:///|);

data CardType
  = cardType(str name, int points, list[Effect] effects, loc src=|unknown:///|);

data StateVar
  = stateVar(str name, str val, loc src=|unknown:///|);

data SetupAction
  = dealToEach(int count, loc src=|unknown:///|)
  | dealToPlayer(str name, int count, loc src=|unknown:///|)
  | discardTopCard(loc src=|unknown:///|)
  | initState(str variable, str val, loc src=|unknown:///|);

data Rule
  = rule(ActionType actionType, list[Condition] conditions, loc src=|unknown:///|);

data ActionType
  = play(loc src=|unknown:///|)
  | draw(loc src=|unknown:///|)
  | discard(loc src=|unknown:///|)
  | shuffle(loc src=|unknown:///|)
  | pass(loc src=|unknown:///|)
  | declare(loc src=|unknown:///|)
  | challenge(loc src=|unknown:///|);

data Condition
  = turnCheck(loc src=|unknown:///|)
  | deckNotEmpty(loc src=|unknown:///|)
  | hasCard(Card card, loc src=|unknown:///|)
  | cardMatches(CardProperty property, CardLocation location, loc src=|unknown:///|)
  | cardMatchesExact(CardLocation location, loc src=|unknown:///|)
  | handSizeLte(int limit, loc src=|unknown:///|)
  | handSizeGte(int limit, loc src=|unknown:///|)
  | handSizeLt(int limit, loc src=|unknown:///|)
  | handSizeGt(int limit, loc src=|unknown:///|)
  | handSizeEq(int limit, loc src=|unknown:///|)
  | playerHandSizeEq(str name, int limit, loc src=|unknown:///|)
  | playerDeclared(str name, str declaration, loc src=|unknown:///|)
  | anyPlayerHasHandSize(int limit, loc src=|unknown:///|)
  | and(Condition lhs, Condition rhs, loc src=|unknown:///|)
  | or(Condition lhs, Condition rhs, loc src=|unknown:///|)
  | not(Condition cond, loc src=|unknown:///|)
  | parens(Condition cond, loc src=|unknown:///|);

data CardProperty
  = suit(loc src=|unknown:///|)
  | rank(loc src=|unknown:///|)
  | other(loc src=|unknown:///|);

data CardLocation
  = hand(loc src=|unknown:///|)
  | topDiscard(loc src=|unknown:///|)
  | deck(loc src=|unknown:///|);

data EndCondition
  = roundEnd(list[Condition] conditions, list[Effect] effects, loc src=|unknown:///|)
  | gameEnd(list[Condition] conditions, loc src=|unknown:///|);

data Effect
  = playerAction(PlayerTarget target, PlayerEffect effect, loc src=|unknown:///|)
  | stateChange(StateChange change, loc src=|unknown:///|);

data PlayerTarget
  = current(loc src=|unknown:///|)
  | relative(int offset, loc src=|unknown:///|)
  | specific(str name, loc src=|unknown:///|)
  | allPlayers(loc src=|unknown:///|);

data PlayerEffect
  = draws(int count, loc src=|unknown:///|)
  | discards(int count, loc src=|unknown:///|)
  | skipsTurn(loc src=|unknown:///|)
  | choosesSuit(loc src=|unknown:///|)
  | choosesRank(loc src=|unknown:///|)
  | swapsHandsWith(PlayerTarget target, loc src=|unknown:///|)
  | shuffleAllHands(loc src=|unknown:///|)
  | addPoints(int points, loc src=|unknown:///|)
  | addHandValue(loc src=|unknown:///|);

data StateChange
  = setState(str variable, str val, loc src=|unknown:///|)
  | reverseTurnOrder(loc src=|unknown:///|)
  | startNewRound(loc src=|unknown:///|);

data Violation
  = violation(str name, list[Condition] conditions, list[Effect] penalties, loc src=|unknown:///|);

data Action
  = play(str player, list[Card] cards, loc src=|unknown:///|)
  | draw(str player, list[Card] cards, loc src=|unknown:///|)
  | discard(str player, list[Card] cards, loc src=|unknown:///|)
  | shuffle(str player, Deck deck, loc src=|unknown:///|)
  | pass(str player, loc src=|unknown:///|)
  | declare(str player, str declaration, loc src=|unknown:///|)
  | challenge(str challenger, str target, str violation, loc src=|unknown:///|);

/*
 * Helper Functions
 */
public Rank rankFromInt(int n) {
  if (n == 1) return ace();
  if (n >= 2 && n <= 10) return numeral(n);
  if (n == 11) return jack();
  if (n == 12) return queen();
  if (n == 13) return king();
  throw "Invalid rank integer: <n>";
}

public int rankToInt(Rank r) {
  switch(r) {
    case ace(): return 1;
    case numeral(n): return n;
    case jack(): return 11;
    case queen(): return 12;
    case king(): return 13;
    default: return 0;
  }
}

public bool inRange(Rank r, int low, int high) {
  int val = rankToInt(r);
  return val >= low && val <= high;
}
