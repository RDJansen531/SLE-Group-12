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
  
  // 4. Game Loop Structure
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

str compileGameLoop(Game g) {
  str s = "# --- Game Loop ---\n";
  s += "def run_game():\n";
  s += "    setup_game()\n";
  
  // Setup Actions
  for (stup <- g.setup) {
    for (act <- stup.actions) {
       switch(act) {
         case dealToEach(count): 
            s += "    for p in players:\n        [p[\"hand\"].append(deck.pop()) for _ in range(<count>)]\n";
         case discardTopCard():
            s += "    discard_pile.append(deck.pop())\n";
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
  s += "        current_player = players[current_turn_index]\n";
  s += "        print(f\"\\nTurn: {current_player[\'name\']}\")\n";
  s += "        print(f\"Top Discard: {discard_pile[-1] if discard_pile else \'None\'}\")\n";
  s += "        print(f\"Hand: {current_player[\'hand\']}\")\n";
  
  // Here we would input actual game logic / user input handling
  // For now, simulate a basic turn or just print functionality
  
  s += "        break # Stop after one turn for demo\n";
  
  s += "\nif __name__ == \"__main__\":\n";
  s += "    run_game()\n";
  
  return s;
}
