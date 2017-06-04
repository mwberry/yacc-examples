/* Bison is responsible for generating the union, so lex must include the yacc header */
%{
#include "union.yacc.h"
%}

%%

  /*
    A simple lexicon with just three tokens.
    - INT_TERM is a terminal (token) that matches positive integers.
               It associates the parsed int as the semantic value via the global yylval.
    - STR_TERM is similar but it matches strings of alphabetic characters.
               Note that this simple demonstration leaks the memory allocated to duplicate yytext.
               Flex does ensure that yytext is null-terminated, but if it didn't we have yyleng available to us.
    - COMMA    matches the literal comma and has no semantic value.
  */
[0-9]+     { yylval.int_value = atoi(yytext); return INT_TERM; }
[a-zA-Z]+  { yylval.str_value = strdup(yytext); return STR_TERM; }
,          { return COMMA;    }
