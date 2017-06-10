/* Bison is responsible for generating the union, so lex must include the yacc header */
%{
#include "buffer.yacc.h"
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

%option noinput

%{

/* Instead of reading from a file, which is the default source of input, we're going to read from
   buffers in memory. These buffers will simulate packets arriving over the network, buffers for
   communication over serial, or just about anything else.
   Since flex expects the memory to be mutable, these literals will just be the initial contents.
   We will copy these into mutable buffers later */
char * packets[]= {"10,", "asd", "f,"};
int current_packet = 0;


/* The macro YY_INPUT is how flex fills its buffer. The default macro uses either getc() if the
   input stream is a TTY or fread() if it is a file. Since we are choosing to read from memory,
   we re-define YY_INPUT. Since our new YY_INPUT makes no use of yyin, that can be safely set to
   NULL whenever it is an input to a function (such as in yyrestart()). */
/* This example is simple enough that we could have implemented it entirely in a macro, but
   in practical usage this would be more complex and likely merit a function call. Also note that
   it is bad form to rely on yyg being available, but since this is a macro we have access to the
   closure where the macro is used. */
#define YY_INPUT(buffer, size, max_size) { \
  read_more_input(buffer, &(size), max_size, yyg->yy_flex_debug_r); \
}

/* Since this is a demonstration, the replacement YY_INPUT naively uses global variables and fixed
   messages. In a real situation, this might block on network input and then copy the payload into
   flex's buffer space.
   It is not advised to try to implement a zero-copy buffer by re-assigning flex's buffer. Flex
   makes note in the buffer structure whether it allocated the buffer or not and it will attempt
   to free buffers it thinks it owns.
   Flex will read buffers it doesn't own if yy_scan_buffer() is utilized, but be aware that the
   buffer must have the complete input, as no attempt to refill it via YY_INPUT will be made when
   the end of the buffer is reached. */
void read_more_input(char * buffer, int * size, int max_size, int debug) {
  if (current_packet >= 3) {
    *size = 0;
    return;
  }
  if (debug) {
    fprintf(stderr, "read_more_input: Setting up buffer containing: %s\n", packets[current_packet]);
  }
  *size = strlen(packets[current_packet]);
  memcpy(buffer, packets[current_packet], *size);
  current_packet++;
}

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
[0-9]+     { yylval->int_value = atoi(yytext); return INT_TERM; }
[a-zA-Z]+  { yylval->str_value = strdup(yytext); return STR_TERM; }
,          { return COMMA;    }
