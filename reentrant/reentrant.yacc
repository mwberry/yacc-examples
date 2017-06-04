/* Includes / forward declarations needed for both the parser and for the main method */
%{
#include <stdio.h>

// This appears to be a bug. This typedef breaks a dependency cycle between the headers.
// See https://stackoverflow.com/questions/44103798/cyclic-dependency-in-reentrant-flex-bison-headers-with-union-yystype
typedef void * yyscan_t;

#include "reentrant.yacc.h"
#include "reentrant.lex.h"

// You may notice that these methods have gained a parameter, read on to see why.
void yyerror(yyscan_t scanner, char * msg);
int yywrap(yyscan_t scanner);
%}

/*
  This is the bison equivalent of Flex's %option reentrant, in the sense that it also makes formerly global
  variables into local ones. Unlike the lexer, there is no state structure for Bison. All the formerly global
  variables become local to the yyparse() method. Which really begs the question: why were they ever global?

  Although it is similar in nature to Flex's %option reentrant, this is truly the counterpart of
  Flex's %option bison-bridge. Adding this declaration is what causes Bison to invoke yylval(YYSTYPE*) instead
  of yylval(void), which is the same change that %option bison-bridge does in Flex.
 */
%define api.pure full

/*
  These two options are related to Flex's %option reentrant, These options add an argument to
  each of the yylex() call and the yyparse() method, respectively.

  Since the %option reentrant in Flex added an argument to make the yylex(void) method into yylex(yyscan_t),
  Bison must be told to pass that new argument when it invokes the lexer. This is what the %lex-param declaration does.

  How Bison obtains an instance of yyscan_t is up to you, but the most sensible way is to pass it into the
  yyparse(void) method, making the  new signature yyparse(yyscan_t). This is what the %parse-param does.
 */
%lex-param {yyscan_t scanner}
%parse-param {yyscan_t scanner}

/* This is the union that will become known as YYSTYPE in the generated code */
%union {
  int int_value;
  char * str_value;
}

/* Define the semantic types of our simple grammar. %token for TERMINALS and %type for non_terminals */
%token <int_value> INT_TERM
%type  <int_value> int_non_term
%token <str_value> STR_TERM
%type  <str_value> str_non_term
/* No semantic value is associated with this token */
%token COMMA

%%

complete : int_non_term str_non_term { printf(" === %d === %s === \n", $1, $2); }

int_non_term : INT_TERM COMMA { $$ = $1; }
str_non_term : STR_TERM COMMA { $$ = $1; }

%%

int main(int argc, char** argv) {
  FILE *input_file;

  /* Here's the opaque lexer state structure. Formerly these were a bunch of global variables
     defined by the lexer. We must also initialize this structure before we use it */
  yyscan_t scanner;
  yylex_init(&scanner) ;

  if (argc < 1) {
    input_file = stdin;
  } else {
    if ( ! (input_file = fopen(argv[1], "r"))) {
      fprintf(stderr, strerror(errno));
      return errno;
    }
  }
  // Note: no longer a global, but rather a member of yyguts_t
  yyset_in(input_file, scanner);

  /* For this demonstration, we will leave debugging on */
  yyset_debug(1, scanner); // For Flex (no longer a global, but rather a member of yyguts_t)
  yydebug = 1;             // For Bison (still global, even in a reentrant parser)

  /* The effects of %parse-param are seen here. Open up the corresponding reentrant.yacc.c file to see
     the call site of yylex and the effects of %lex-param */
  int val = yyparse(scanner);

  yylex_destroy (scanner) ;
  return val;
}

int yywrap(yyscan_t scanner) {
  /* Since this is a simple demonstration, so we will just terminate when we reach the end of the input file */
  return 1;
}

void yyerror(yyscan_t scanner, char * msg) {
  fprintf(stderr, msg);
}

