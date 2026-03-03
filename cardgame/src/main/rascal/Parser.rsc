module Parser

import Syntax;
import ParseTree;
import Set;
import List;
import IO;

/*
 * Parser for the Card Game DSL
 *
 * This module provides functions to parse source code into a Concrete Syntax Tree.
 * It also handles disambiguation using post-parse filtering.
 */

public start[Game] parseGame(str src, loc l) = disambiguate(parse(#start[Game], src, l, allowAmbiguity=true));

public start[Game] parseGame(loc l) = disambiguate(parse(#start[Game], l, allowAmbiguity=true));

// Helper to filter ambiguity
start[Game] disambiguate(start[Game] t) {
    return visit(t) {
        case amb(set[Tree] alts) : {
            if (isDeckItemListAmbiguity(alts)) {
                println("Disambiguating DeckItem list...");
                insert getShortestList(alts);
            }
        }
    };
}

bool isDeckItemListAmbiguity(set[Tree] alts) {
    if (isEmpty(alts)) return false;
    Tree first = getOneFrom(alts);
    
    // Check if the ambiguity is about a list of DeckItems
    Symbol s;
    if (appl(prod(Symbol sym, _, _), _) := first) s = sym;
    else if (appl(regular(Symbol sym), _) := first) s = sym;
    else return false;

    // Check for various forms of iteration over DeckItem
    if (\iter-star(\sort("DeckItem")) := s) return true;
         if (\iter(\sort("DeckItem")) := s) return true;
         if (\iter-star-seps(\sort("DeckItem"), _) := s) return true;
         if (\iter-seps(\sort("DeckItem"), _) := s) return true;
    
    return false;
}

Tree getShortestList(set[Tree] alts) {
    Tree best = getOneFrom(alts);
    int bestLen = size(best.args);
    
    for (a <- alts) {
        int l = size(a.args);
        if (l < bestLen) {
            best = a;
            bestLen = l;
        }
    }
    return best;
}
