/* A Demo of a Java-Based Push-Parser */
%define api.push-pull push

/* Java doesn't have Unions, so we will declare a dumb struct-like class to use called Yystype */
%define api.value.type {Yystype}

/* Define the semantic types of our simple grammar. %token for TERMINALS and %type for non_terminals */
%token <Yystype> INT_TERM
%type  <Yystype> int_non_term
%token <Yystype> STR_TERM
%type  <Yystype> str_non_term
/* No semantic value is associated with this token */
%token COMMA

/* Declarations that affect the produced Java File start here */

/* The package should be self-explanatory */
%define package com.mwberry.yacc.examples

/* Our simple demo doesn't require any additional imports, but they would go here */
%code imports {

}

/* This makes the produced parser class public. There is sadly no equivalent declaration for the Lexer class */
%define public

/* The body of the constructor for the parser class */
%code init {

}

/* The default YYLexer interface throws IOException, but Java 8+ made Checked Exceptions less of a good idea */
%define lex_throws {}

/* A "%code lexer {}" block could be put here, but the lexer class will be private and non-static
   Thanks to the YYLexer interface, the implementation doesn't have to live in this file. For compactness,
   I've chosen to include it, but in a generic "%code {}" block so it could be made public, static. */

/* Generic "%code {}" blocks will appear within the produced parser class, but outside any methods */
%code {

  /**
   * Main entry point for the Hybrid Java/JNI parser. Expects one argument, which is the file to parse
   */
  public static void main(String[] args) {
    // Loads the JNI library where the Flex-generated lexer lives
    System.loadLibrary("javalexer");

    if (args.length < 1) {
      System.err.println("Please provide a file to parse as input");
      return;
    }

    // Strictly speaking, the parser does not need a reference to the lexer.
    // However, as of Bison 3.0.4, "api.push-pull push" still implements both push and pull interfaces in Java
    YYLexer lexer = new YYLexer(args[0]);
    YYParser parser = new YYParser(lexer);

    // Since this is a demonstration, debugging is left on
    parser.setDebugLevel(1);

    /* This is the main driver loop, it invokes the lexer to get a token and passes the associated lval
       to the push interface of the parser. I'm not a huge fan of the choice of having a getLVal() method
       vs. having a more C-like out-param for the lval */
    int status;
    do {
      status = parser.push_parse(lexer.yylex(), lexer.getLVal());
    } while(status == YYPUSH_MORE);

  }

  /**
   * Java doesn't have a concept of a Union, so this struct-like class will have to suffice
   */
  public static class Yystype {
      // Exactly one should be set at a time, since we are emulating a union.
      // These will be set directly from the JNI Lexer, so you will not find setters here
      private int int_value;
      private String str_value;

      public Yystype() {
        this.int_value = -1;
        this.str_value = null;
      }

      public int getIntValue() {
        if (str_value != null) {
          throw new IllegalStateException("Value was: " + str_value);
        }
        return int_value;
      }

      public String getStringValue() {
        if (str_value == null) {
          throw new IllegalStateException("Value is not a string, maybe it is: " + int_value);
        }
        return str_value;
      }
  }

  /**
   * The Java half of the lexer implementation. It holds a pointer to the JNI structure holding the C implementation.
   */
  public static class YYLexer implements Lexer {
      private final long scanner_ptr;
      private Yystype lval = null;

      /**
       * This constructor simply delegates directly to a JNI wrapper for yylex_init.
       */
      public YYLexer(String inputFile) {
        this.scanner_ptr = native_init(inputFile);
      }
      private native long native_init(String inputFile);

      /**
       * Another slightly puzzling choice by the folks over at Bison. The use of this method might become
       * clearer if location tracking was enabled, as the lexer and parser need to coordinate to produce an
       * error message containing the most accurate and useful information
       */
      @Override
      public void yyerror (String msg) {
        System.err.println(msg);
      }

      /**
       * Advances the lexer over the input. Produces one token and possibly an associated semantic value.
       * The Java implementation quickly delegates to the JNI implementation.
       */
      @Override
      public int yylex() {
        this.lval = new Yystype();
        return native_yylex(lval, scanner_ptr);
      }
      private native int native_yylex(Yystype lval, long scanner_ptr);

      @Override
      public Yystype getLVal() {
        return lval;
      }

      // TODO: Finalizer or implements AutoClosable?
      /**
       * This might be the only marginally legitimate use-case for a finalizer. Even then, my intuition is still
       * telling me to implement the AutoClosable interface and rely on that instead. This method wraps yylex_destroy()
       */
      @Override
      protected void finalize() throws Throwable {
          native_destroy(scanner_ptr);
      }
      private native void native_destroy(long scanner_ptr);
    }

}
%%

complete : int_non_term str_non_term {
             // This is where Bison puts the ugly casts in. $1 and $2 are each casted to Yystype
             System.out.printf(" === %d === %s === \n", $1.getIntValue(), $2.getStringValue());
         }

int_non_term : INT_TERM COMMA { $$ = $1; }
str_non_term : STR_TERM COMMA { $$ = $1; }


