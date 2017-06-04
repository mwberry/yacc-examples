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

Reentrant
---------

Any program beyond the most simple or purpose-built will likely want to use a reentrant lexer/parser. Even
if multithreading is not needed, it is just better coding practice to avoid globals and keep code self-
contained. The same gammar and union type is used from the previous example, to make it obvious which
declarations were changed solely to make the lexer/parser thread-safe.

Push
----

If the input being parsed is not completelly locally buffered, then a push parser is needed. As more input
arrives, it can be fed into the push-parser piecemeal until an accepting state is reached. This example
is both reentrant and a push-parser, so it is actually apt for most C-based usages.

Java
----

If a lexer/parser is needed in Java, you needn't leave your old tools behind. Bison supports Java as a
target language, and this example illustrates the minimum JNI needed to wrap a native-C Flex-based lexer.
This example is also reentrant and a push-parser, so it can be diff'd with the previous example. You will
notice there are two Yacc files in this example. This is partially so a pure-C parser can be generated to
aid in debugging, but partially because the lexer needs the YYSTYPE and tokends #define'd, which is done
by Bison only if it is generating a C-based parser.

Building and Running
====================

Each sub-directory of this repository contains one example. The lex and yacc files are checked in, but the
flex and bison tools are required to produce functional binaries. The Java example produces both a native
binary and a JAR, so a JDK is needed to build that example as well.

```bash
$ flex -V
flex 2.6.4

$ bison -V | head -n 1
bison (GNU Bison) 3.0.4

$ javac -version
javac 1.8.0_121

$ cmake .

$ make all
[ 17%] Built target unionParser
[ 35%] Built target reentrantParser
[ 53%] Built target pushParser
[ 67%] Built target javalexer
[ 85%] Built target nativeparser
[100%] Built target javaparser
```

Once built, each example is bundled with a sample input file (named `chat`) to parse. For the C-based 
examples, it is sufficient to pass that file to the produced binary.

```bash
$ make unionParser
$ ./union/bin/unionParser ./union/chat
```

For the Java example a native C-based parser is generated with the `nativeParser` target. The `javaParser`
target produces the Java-based parser, which can be invoked using Java:

```bash
$ make javaParser
$ java \
    -classpath './java/lib/*' \
    -Djava.library.path=./java/lib \
    com.mwberry.yacc.examples.YYParser \
    ./java/com/mwberry/yacc/examples/chat
```

------

*Copyright notice:* 

*Please see the COPYING file for information about the copyright restrictions for this repository.*

