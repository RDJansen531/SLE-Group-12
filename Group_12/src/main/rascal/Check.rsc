module Check

import AST;
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
  visit(g.cardTypes + g.violations + g.endConditions) {
    case e:playerAction(specific(name), _):
      if (name notin definedPlayers)
        msgs += {error("Undefined player target in effect: " + name, e.src)};
    case e:stateChange(setState(varName, _)):
      if (varName notin definedStateVars)
        msgs += {error("Undefined state variable in effect: " + varName, e.src)};
  }
  
  return msgs;
}
