Examples of Flex / Bison Generated Lexer / Parsers
==================================================

The lex/yacc input formats take some getting used to and there has been an explosion of non-POSIX flags, 
declarations, and options to keep track of. This repo serves as a quick reference for some commonly used
configurations. Each configuration builds on the previous one, to make it clear which sets of declarations
work together closely.

Union
-----

The first example is the canonical lex/yacc example. It uses a simple grammar, two terminals of which have
semantic values passed around in a union.

Building and Running
====================

Each sub-directory of this repository contains one example. The lex and yacc files are checked in, but the
flex and bison tools are required to produce functional binaries.

```bash
$ flex -V
flex 2.6.4

$ bison -V | head -n 1
bison (GNU Bison) 3.0.4

$ cmake .

$ make all
[ 17%] Built target unionParser
```

Once built, each example is bundled with a sample input file (named `chat`) to parse. For the C-based 
examples, it is sufficient to pass that file to the produced binary.

```bash
$ make unionParser
$ ./union/bin/unionParser ./union/chat
```

------

*Copyright notice:* 

*Please see the COPYING file for information about the copyright restrictions for this repository.*
