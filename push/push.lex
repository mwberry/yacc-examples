/* Bison is responsible for generating the union, so lex must include the yacc header */
%{
#include "push.yacc.h"
%}

/*
  Options: reentrant and bison-bridge
  These two options are closely related but do very different things.

  In the union example, yylval was a global variable and therefore is in
  scope in the body of the lexer (yylex(void)). In this example, we tell Bison
  to generate a reentrant parser, so yylval will no longer be a global.
  With the bison-bridge option the lexer body accepts yylval as a parameter.
  This does not itself make the lexer (which is now yylex(YYSTYPE*)) reentrant.

  To make the lexer itself reentrant, we add the reentrant option. This makes
  the formerly global lexer variables, such as yyin (the input source) into members
  of an opaque structure of type yyscan_t. This type is an opaque version of
  struct yyguts_t, which is private to the generated lexer code. Access to the
  formerly global variables is now done through methods which accept the opaque
  yyscan_t type as an argument. Note that this also adds an argument to yylex(void),
  turning it into yylex(yyscan_t).

  There are use-cases where one might be used without the other, but when using
  Bison and Flex together both options should be used. That being said, there
  isn't really anything Bison specific about the bison-bridge other than the
  naming conventions.

  Together these options change the yylex(void) method into yylex(YYSTYPE*,yyscan_t).
 */
%option reentrant bison-bridge

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
[0-9]+     { yylval->int_value = atoi(yytext); return INT_TERM; }
[a-zA-Z]+  { yylval->str_value = strdup(yytext); return STR_TERM; }
,          { return COMMA;    }
