module Check

import AST;
import List;
import Message;

/*
 * Static Semantics (Type Checking & Validation)
 *
 * This module performs static analysis on the AST to identify errors
 * before runtime/code generation.
 */

public set[Message] checkGame(Game g) {
  set[Message] msgs = {};
  
  msgs += checkDuplicates(g);
  msgs += checkUndefinedReferences(g);
  msgs += checkObligationRules(g);
  
  return msgs;
}

// Check for duplicate definitions
public set[Message] checkDuplicates(Game g) {
  set[Message] msgs = {};
  set[str] definedPlayers = {};
  set[str] definedCardTypes = {};
  set[str] definedStateVars = {};
  set[str] definedViolations = {};

  for (p <- g.players) {
    str name = "";
    if (player(n) := p) name = n;
    if (playerWithHand(n, _) := p) name = n;
    
    if (name in definedPlayers) {
      msgs += {error("Duplicate player definition: " + name, p.src)};
    }
    definedPlayers += name;
  }

  for (ct <- g.cardTypes) {
    if (ct.name in definedCardTypes) {
      msgs += {error("Duplicate card type definition: " + ct.name, ct.src)};
    }
    definedCardTypes += ct.name;
  }

  for (sv <- g.stateVars) {
    if (sv.name in definedStateVars) {
      msgs += {error("Duplicate state variable definition: " + sv.name, sv.src)};
    }
    definedStateVars += sv.name;
  }

  for (v <- g.violations) {
    if (v.name in definedViolations) {
      msgs += {error("Duplicate violation definition: " + v.name, v.src)};
    }
    definedViolations += v.name;
  }

  return msgs;
}

// Check for undefined references
public set[Message] checkUndefinedReferences(Game g) {
  set[Message] msgs = {};
  
  set[str] definedPlayers = {};
  for (p <- g.players) {
    if (player(n) := p) definedPlayers += n;
    if (playerWithHand(n, _) := p) definedPlayers += n;
  }

  set[str] definedCardTypes = { ct.name | ct <- g.cardTypes };
  set[str] definedStateVars = { sv.name | sv <- g.stateVars };

  // Check turn player
  if (g.turn.player notin definedPlayers) {
    msgs += {error("Undefined player in initial turn: " + g.turn.player, g.turn.src)};
  }

  // Check card types usage in deck
  visit(g.deck) {
    case d:mixedCard(_, SuitName s, list[str] typeIds): {
      str typeName = "";
      bool isWild = (typeIds == []);
    
      if (!isWild) {
        typeName = typeIds[0];
      } else if (custom(id) := s) {
        typeName = id;
      }
      
      if (typeName != "" && typeName notin definedCardTypes)
        msgs += {error("Undefined card type in deck: " + typeName, d.src)};
      else if (typeName == "" && isWild) {
        msgs += {error("Invalid card type reference (standard suit used as identifier?)", d.src)};
      }
    }
  }

  // Check references in Setup
  visit(g.setup) {
    case s:dealToPlayer(name, _):
      if (name notin definedPlayers)
        msgs += {error("Undefined player in setup: " + name, s.src)};
    case s:initState(varName, _):
      if (varName notin definedStateVars)
        msgs += {error("Undefined state variable in setup: " + varName, s.src)};
  }

  // Check references in Conditions (Rules, Violations, EndConditions)
  visit(g.rules + g.violations + g.endConditions) {
    case c:playerHandSizeEq(name, _):
      if (name notin definedPlayers)
        msgs += {error("Undefined player in condition: " + name, c.src)};
    case c:playerDeclared(name, _):
      if (name notin definedPlayers)
        msgs += {error("Undefined player in condition: " + name, c.src)};
  }

  // Check references in Effects
  visit(g.cardTypes + g.violations + g.endConditions + g.rules) {
    case e:playerAction(specific(name), _):
      if (name notin definedPlayers)
        msgs += {error("Undefined player target in effect: " + name, e.src)};
    case e:stateChange(setState(varName, _)):
      if (varName notin definedStateVars)
        msgs += {error("Undefined state variable in effect: " + varName, e.src)};
  }
  
  return msgs;
}

// Check obligation rule configuration (requirement/must/deadline/on_violation)
public set[Message] checkObligationRules(Game g) {
  set[Message] msgs = {};

  list[Rule] obligationRules = [r | r <- g.rules, obligationRule(_, _, _, _, _, _) := r];

  if (size(obligationRules) > 1) {
    msgs += {error("At most one obligation rule is currently supported by the runtime", obligationRules[1].src)};
  }

  for (r <- obligationRules) {
    if (obligationRule(name, requirements, must, deadline, enforcement, onViolation) := r) {
      if (name == "") {
        msgs += {error("rule obligation must define a non-empty name/token", r.src)};
      }

      // Currently supported must-clause: current_player declares <name>
      if (currentPlayerDeclares(declaredToken) := must) {
        if (declaredToken != name) {
          msgs += {error("Obligation name must match must-clause declaration token", must.src)};
        }
      }

      // Currently supported deadline: before_next_turn
      if (!(beforeNextTurn() := deadline)) {
        msgs += {error("Unsupported obligation deadline (currently supported by runtime: before_next_turn)", deadline.src)};
      }

      // Currently supported enforcement: callout_by_next_player before_next_player_plays
      bool hasSupportedEnforcement = false;
      if (calloutByNextPlayer(expiry) := enforcement) {
        if (beforeNextPlayerPlays() := expiry) {
          hasSupportedEnforcement = true;
        } else {
          msgs += {error("Unsupported obligation enforcement expiry (currently supported by runtime: before_next_player_plays)", expiry.src)};
        }
      }

      if (!hasSupportedEnforcement) {
        msgs += {error("Unsupported obligation enforcement (currently supported by runtime: callout_by_next_player before_next_player_plays)", enforcement.src)};
      }

      if (size(g.players) < 2) {
        msgs += {error("Obligation rule requires at least two players", r.src)};
      }

      for (c <- requirements) {
        if (!isSupportedCalloutTrigger(c)) {
          msgs += {error("Unsupported condition in obligation requirement", c.src)};
        }
      }

      bool hasDrawEffect = false;
      for (e <- onViolation) {
        switch (e) {
          case playerAction(current(), draws(n)): {
            if (n <= 0) {
              msgs += {error("Obligation on_violation draw effect must be greater than 0", e.src)};
            } else {
              hasDrawEffect = true;
            }
          }
          default: {
            msgs += {error("Unsupported obligation on_violation effect (currently supported by runtime: current_player: draws N)", e.src)};
          }
        }
      }

      if (!hasDrawEffect) {
        msgs += {error("Obligation rule requires an on_violation current_player: draws N effect", r.src)};
      }
    }
  }

  return msgs;
}

bool isSupportedCalloutTrigger(Condition c) {
  switch(c) {
    case handSizeEq(_): return true;
    case handSizeLt(_): return true;
    case handSizeLte(_): return true;
    case handSizeGt(_): return true;
    case handSizeGte(_): return true;
    case and(lhs, rhs): return isSupportedCalloutTrigger(lhs) && isSupportedCalloutTrigger(rhs);
    case or(lhs, rhs): return isSupportedCalloutTrigger(lhs) && isSupportedCalloutTrigger(rhs);
    case not(cond): return isSupportedCalloutTrigger(cond);
    case parens(cond): return isSupportedCalloutTrigger(cond);
    default: return false;
  }
}
