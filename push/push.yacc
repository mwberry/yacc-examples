/* Includes / forward declarations needed for both the parser and for the main method */
%{
#include <stdio.h>

// This appears to be a bug. This typedef breaks a dependency cycle between the headers.
// See https://stackoverflow.com/questions/44103798/cyclic-dependency-in-reentrant-flex-bison-headers-with-union-yystype
typedef void * yyscan_t;

#include "push.yacc.h"
#include "push.lex.h"

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

/*
  As far as the grammar file goes, this is the only change needed to tell Bison to switch to a push-parser
  interface instead of a pull-parser interface. Bison has the capability to generate both, but that is a
  far more advanced case not covered here.
*/
%define api.push-pull push

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

  /* This section is new with the addition of the push-parser interface. In a pull-parser,
     Bison does not return control to the calling function until all input has been consumed.
     Bison expects all input to be available at the time yyparse(...) is called. In a push-
     parser, Bison returns control to the caller after processing each lexigraphical token.
     This means that the calling program has the opportunity to obtain more input or doing
     any other book-keeping needed. In order for Bison to maintain state between invocations,
     a new structure is added called yypstate. This is not dissimilar to the purpose of the
     yyscan_t structure added when the lexer was made reentrant.
  */
  int status;
  yypstate *ps = yypstate_new ();

  YYSTYPE pushed_value;

  do {
    /* The yyparse(...) method is now yypush_parse(...), and it has picked up a number of arguments
       There is the state token yypstate, described above. The next argument is the token that the
       lexer found. Up until this point, Bison invoked yylex(...), but now with the push parser that
       responsibility is on the calling code. The lval that the lexer wants to associate with the
       scanned token comes next followed by the lexer state token from previous examples.
    */
    status = yypush_parse(ps, yylex(&pushed_value, scanner), &pushed_value, scanner);
  } while(status == YYPUSH_MORE);

  yypstate_delete (ps);
  yylex_destroy (scanner) ;
  return 0;
}

int yywrap(yyscan_t scanner) {
  /* Since this is a simple demonstration, so we will just terminate when we reach the end of the input file */
  return 1;
}

void yyerror(yyscan_t scanner, char * msg) {
  fprintf(stderr, msg);
}