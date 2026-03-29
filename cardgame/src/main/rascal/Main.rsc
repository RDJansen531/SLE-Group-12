module Main

import Parser;
import Implode;
import Check;
import Compiler;
import AST;
import Syntax;
import Message;
import IO;
import Set;

/*
 * Main entry point for the Card Game DSL
 */

void main() {
    loc exampleLoc = |project://cardgame/src/main/rascal/example.simple|;
    println("Processing: " + exampleLoc.path);
    
    if (!exists(exampleLoc)) {
        println("File not found: <exampleLoc>");
        return;
    }

    try {
        start[Game] cst = parseGame(exampleLoc);
        println("Parsing successful.");
        
        println("Imploding to AST...");
        AST::Game g = implodeGame(cst);
        println("Implosion successful.");
        
        println("Checking static semantics...");
        set[Message] errors = checkGame(g);
        
        if (errors == {}) {
            println("Check successful! No errors found.");
            loc targetFile = exampleLoc[extension="py"];
            compileAndSave(g, targetFile);
        } else {
            int errorCount = size(errors);
            println("Check failed with <errorCount> errors:");
            for (e <- errors) {
                println(e);
            }
        }
    } catch loc l: {
        println("Parse failed at location: <l>");
    } catch e: {
        println("Error: <e>");
    }
}
