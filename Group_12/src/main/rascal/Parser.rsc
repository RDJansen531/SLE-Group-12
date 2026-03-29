module Parser

import Syntax;
import ParseTree;
import Set;
import List;
import IO;
import String;

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
            println("Found ambiguity with <size(alts)> alternatives");
            if (isDeckItemListAmbiguity(alts)) {
                println("Disambiguating DeckItem list...");
                insert getShortestList(alts);
            } else if (isSuitNameAmbiguity(alts)) {
                println("Disambiguating SuitName...");
                insert preferStandardSuit(alts);
            } else {
                println("Unknown ambiguity, leaving unresolved");
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

bool isSuitNameAmbiguity(set[Tree] alts) {
    if (isEmpty(alts) || size(alts) != 2) return false;
    
    str allText = "<alts>";
    
    // Check if this is a SuitName ambiguity by looking for "standard" and "custom" labels
    // within the context of SuitName sort
    return contains(allText, "SuitName") && contains(allText, "standard") && contains(allText, "custom");
}

Tree preferStandardSuit(set[Tree] alts) {
    // Return the alternative with "standard" label
    for (alt <- alts) {
        str s = "<alt>";
        // Check for "standard" in the tree representation
        if (contains(s, "standard") && !contains(s, "custom")) {
            return alt;
        }
    }
    // Fallback: return first alternative
    return getOneFrom(alts);
}
