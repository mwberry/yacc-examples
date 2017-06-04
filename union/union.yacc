/* Includes / forward declarations needed for both the parser and for the main method */
%{
#include <stdio.h>
#include "union.lex.h"

extern int yy_flex_debug;

void yyerror(char * msg);
int yywrap(void);
%}

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

  if (argc < 1) {
    input_file = stdin;
  } else {
    if ( ! (input_file = fopen(argv[1], "r"))) {
      fprintf(stderr, strerror(errno));
      return errno;
    }
  }

  yyin = input_file;

  /* For this demonstration, we will leave debugging on */
  yy_flex_debug = 1; // For Flex
  yydebug = 1;       // For Bison
  return yyparse();
}

int yywrap(void) {
  /* Since this is a simple demonstration, so we will just terminate when we reach the end of the input file */
  return 1;
}

void yyerror(char * msg) {
  fprintf(stderr, msg);
}
