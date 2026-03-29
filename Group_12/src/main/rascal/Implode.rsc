module Implode

import Parser;
import AST;
import Syntax;
import ParseTree;

/*
 * Implosion: CST -> AST
 *
 * This module transforms the concrete structure (ParseTree) into the abstract
 * structure (AST), abstracting over layout, keywords, and non-essential syntax.
 */

public AST::Game implodeGame(start[Game] cst) = implode(#AST::Game, cst);

public AST::Game loadGame(loc l) = implodeGame(parseGame(l));

public AST::Game loadGame(str src, loc l) = implodeGame(parseGame(src, l));
