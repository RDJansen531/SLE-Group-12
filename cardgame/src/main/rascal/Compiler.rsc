module Compiler

import AST;
import IO;
import List;
import String;

/*
 * Code Generator: AST -> Python
 */

public void compileAndSave(Game g, loc targetFile) {
  str code = compile(g);
  writeFile(targetFile, code);
  println("Compiled successfully to: " + targetFile.path);
}

public str compile(Game g) {
  str py = "# Generated Python code for Card Game\n";
  py += "import random\n";
  py += "import sys\n\n";

  // 1. Initial State
  py += compileGameState(g);

  // 2. Deck Creation
  py += compileDeckCreation(g.deck);

  // 3. Player Setup
  py += compilePlayerSetup(g.players);

  // 4. Analysis & Rules
  py += compileRulesAndHelpers(g);
  py += compileEffects(g);
  
  // 5. Game Loop Structure
  py += compileGameLoop(g);

  return py;
}

str compileGameState(Game g) {
  str s = "# --- Game State ---\n";
  s += "state_vars = {\n";
  for (sv <- g.stateVars) {
    s += "    \"<sv.name>\": \"<sv.val>\",\n"; 
  }
  s += "}\n\n";
  
  s += "players = []\n";
  s += "deck = []\n";
  s += "discard_pile = []\n";
  s += "current_turn_index = 0\n";
  s += "turn_direction = 1\n\n";
  
  return s;
}

str compileDeckCreation(Deck d) {
  str s = "# --- Deck Creation ---\n";
  s += "def create_deck():\n";
  s += "    d = []\n";
  
  for (item <- d.items) {
    switch(item) {
      case standardRange(multList, suitName, rRange): {
        int count = 1;
        // Use pattern matching instead of dot access
        if (!isEmpty(multList) && mult(c) := multList[0]) count = c;
        
        // Handle Range
        str suitStr = compileSuitName(suitName);
        if (numericRange(sRank, eRank) := rRange) {
             s += "    for _ in range(<count>):\n";
             s += "        for r in range(<sRank>, <eRank> + 1):\n";
             s += "            d.append({\"suit\": \"<suitStr>\", \"rank\": r, \"type\": \"standard\"})\n";
        } 
        if (singleRank(r) := rRange) {
             int rVal = rankToInt(r);
             s += "    for _ in range(<count>):\n";
             s += "        d.append({\"suit\": \"<suitStr>\", \"rank\": <rVal>, \"type\": \"standard\"})\n";
        }
      }
      case mixedCard(multList, suitName, typeIds): {
        int count = 1;
        if (!isEmpty(multList) && mult(c) := multList[0]) count = c;
        if (typeIds != []) {
          str typeName = typeIds[0];
          str suitStr = compileSuitName(suitName);
          s += "    for _ in range(<count>):\n";
          s += "        d.append({\"suit\": \"<suitStr>\", \"type\": \"<typeName>\"})\n";
        } else {
             // Wild Card
             if (custom(id) := suitName) {
                 s += "    for _ in range(<count>):\n";
                 s += "        d.append({\"type\": \"<id>\", \"suit\": \"wild\"})\n";
             }
        }
      }
    }
  }
  s += "    return d\n\n";
  return s;
}

str compileCard(Card c) {
  switch(c) {
    case standard(s, r): return "{\"suit\": \"" + compileSuitName(s) + "\", \"rank\": " + "<rankToInt(r)>" + ", \"type\": \"standard\"}";
    case mixed(s, types): {
        if (types != []) {
             return "{\"suit\": \"" + compileSuitName(s) + "\", \"type\": \"" + types[0] + "\"}";
        } else {
             if (custom(id) := s) {
                 return "{\"type\": \"" + id + "\", \"suit\": \"wild\"}";
             }
        }
    }
  }
  return "{}";
}

str compileSuitName(SuitName sn) {
  switch(sn) {
    case standard(hearts()): return "hearts";
    case standard(diamonds()): return "diamonds";
    case standard(clubs()): return "clubs";
    case standard(spades()): return "spades";
    case custom(n): return n;
  }
  return "unknown";
}

str compilePlayerSetup(list[Player] players) {
  str s = "# --- Player Setup ---\n";
  s += "def setup_game():\n";
  s += "    global deck, descriptor\n";
  s += "    deck = create_deck()\n";
  s += "    random.shuffle(deck)\n";
  
  for (p <- players) {
      str name = "";
      if (player(n) := p) name = n;
      if (playerWithHand(n, _) := p) name = n;
      s += "    players.append({\"name\": \"<name>\", \"hand\": []})\n";
  }
  s += "\n";
  return s;
}

str compileRulesAndHelpers(Game g) {
    str py = "# --- Rules & Helpers ---\n";
    py += "def advance_turn(step=1):\n";
    py += "    global current_turn_index, turn_direction\n";
    py += "    current_turn_index = (current_turn_index + (step * turn_direction)) % len(players)\n\n";

    py += "def can_play_immediately(card, top_card):\n    return can_play(card, top_card)\n\n";

    py += "def can_play(card, top_card):\n";
    py += "    if card.get(\'suit\') == \'wild\': return True\n";
    
    bool hasPlayRules = false;
    for (r <- g.rules) {
        if (rule(at, conds) := r && play() := at) {
             hasPlayRules = true;
             py += "    if <compileConditions(conds)>: return True\n";
        }
    }
    
    if (hasPlayRules) py += "    return False\n\n";
    else py += "    return True\n\n";

    return py;
}

str compileConditions(list[Condition] conds) {
    if (conds == []) return "True";
    return intercalate(" and ", [compileCondition(c) | c <- conds]);
}

str compileCondition(Condition c) {
    switch(c) {
       case turnCheck(): return "True"; 
       case cardMatches(suit(), topDiscard()): 
            return "(card.get(\'suit\') == top_card.get(\'suit\') or card.get(\'suit\') == state_vars.get(\'current_color\', \'\') or top_card.get(\'suit\') == \'wild\')";
       case cardMatches(rank(), topDiscard()):
            return "(card.get(\'rank\') is not None and card.get(\'rank\') == top_card.get(\'rank\'))";
       case or(lhs, rhs): return "(<compileCondition(lhs)> or <compileCondition(rhs)>)";
       case and(lhs, rhs): return "(<compileCondition(lhs)> and <compileCondition(rhs)>)";
       case parens(sub): return "(<compileCondition(sub)>)";
    }
    return "True";
}

str compileEffects(Game g) {
    str s = "# --- Effects ---\n";
    s += "def apply_effects(card):\n";
    s += "    global turn_direction, current_turn_index\n";
    s += "    ctype = card.get(\'type\', \'\')\n";
    
    for (ct <- g.cardTypes) {
        if (ct.effects != []) {
             s += "    if ctype == \"<ct.name>\":\n";
             for (eff <- ct.effects) {
                 s += compileEffectItems(eff);
             }
        }
    }
    s += "    pass\n\n";
    return s;
}

str compileEffectItems(Effect eff) {
    str s = "";
    switch(eff) {
       case stateChange(reverseTurnOrder()): s += "        turn_direction *= -1\n";
       case playerAction(relative(1), skipsTurn()): s += "        advance_turn(1) # Skip next\n";
       case playerAction(relative(1), draws(n)): 
            s += "        target_idx = (current_turn_index + turn_direction) % len(players)\n        print(f\"Player {players[target_idx][\'name\']} draws <n> cards\")\n        for _ in range(<n>): players[target_idx][\'hand\'].append(deck.pop())\n";
       case playerAction(current(), choosesSuit()):
             s += "        state_vars[\'current_color\'] = input(\"Choose Color (red/green/blue/yellow): \").strip()\n";
    }
    return s;
}

str compileGameLoop(Game g) {
  str s = "# --- Game Loop ---\n";
  s += "def run_game():\n";
  s += "    global discard_pile, deck, players, state_vars, current_turn_index\n";
  s += "    setup_game()\n";
  
  // Setup Actions
  for (stup <- g.setup) {
    for (act <- stup.actions) {
       switch(act) {
         case dealToEach(count): 
            s += "    for p in players:\n        [p[\"hand\"].append(deck.pop()) for _ in range(<count>)]\n";
         case discardTopCard():
            s += "    discard_pile.append(deck.pop())\n    state_vars[\'current_color\'] = discard_pile[-1].get(\'suit\', \'red\')\n";
         case initState(varName, val):
            s += "    state_vars[\"<varName>\"] = \"<val>\"\n";
       }
    }
  }

  s += "\n    global current_turn_index\n";
  // Determine initial turn
  str firstPlayer = g.turn.player;
  s += "    for i, p in enumerate(players):\n";
  s += "        if p[\"name\"] == \"<firstPlayer>\":\n";
  s += "            current_turn_index = i\n";
  s += "            break\n\n";

  s += "    while True:\n";
  s += "        if not deck:\n";
  s += "            if len(discard_pile) \> 1:\n";
  s += "                print(\"Reshuffling...\")\n";
  s += "                active = discard_pile[-1]\n";
  s += "                deck.extend(discard_pile[:-1])\n";
  s += "                random.shuffle(deck)\n";
  s += "                discard_pile = [active]\n";
  s += "            else:\n";
  s += "                print(\"Deck empty and no discard to shuffle.\")\n";
  s += "        current_player = players[current_turn_index]\n";
  s += "        top_card = discard_pile[-1]\n";
  s += "        print(f\"\\n=== {current_player[\'name\']}\'s Turn ===\")\n";
  s += "        print(f\"Top Card: {top_card} (Active Color: {state_vars.get(\'current_color\', \'None\')})\")\n";
  s += "        for idx, c in enumerate(current_player[\'hand\']): print(f\"{idx}: {c.get(\'suit\', \'\') if c.get(\'suit\') != \'wild\' else \'wild\'} {c.get(\'rank\', \'\')} {c.get(\'type\', \'\')}\")\n";
  s += "\n";
  s += "        cmd = input(\"Action (play \<idx\> / draw): \").split()\n";
  s += "        if not cmd: continue\n";
  s += "\n";
  s += "        if cmd[0] == \"play\":\n";
  s += "             try:\n";
  s += "                 idx = int(cmd[1])\n";
  s += "                 card = current_player[\'hand\'][idx]\n";
  s += "                 if can_play(card, top_card):\n";
  s += "                      current_player[\'hand\'].pop(idx)\n";
  s += "                      discard_pile.append(card)\n";
  s += "                      if card.get(\'suit\') != \'wild\': state_vars[\'current_color\'] = card.get(\'suit\')\n";
  s += "                      apply_effects(card)\n";
  s += "                      if len(current_player[\'hand\']) == 0: \n                          print(f\"{current_player[\'name\']} Wins!\"); break\n";
  s += "                      advance_turn()\n";
  s += "                 else: print(\"Invalid Move!\")\n";
  s += "             except (IndexError, ValueError):\n                 print(\"Invalid selection\")\n                 # import traceback; traceback.print_exc()\n";
  s += "        elif cmd[0] == \"draw\":\n";
  s += "             if deck:\n";
  s += "                 card = deck.pop()\n";
  s += "                 print(f\"Drew {card}\")\n";
  s += "                 current_player[\'hand\'].append(card)\n";
  s += "                 if can_play_immediately(card, top_card):\n";
  s += "                      pass # Optional: prompt to play\n";
  s += "                 advance_turn()\n";
  s += "             else:\n";
  s += "                 print(\"Deck Empty!\")\n";
  s += "        elif cmd[0] == \"quit\": break\n";
  
  s += "\nif __name__ == \"__main__\":\n";
  s += "    run_game()\n";
  
  return s;
}
