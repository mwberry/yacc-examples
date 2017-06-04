%{
#include "jni.h"
#include "java.yacc.h"
%}

%option reentrant bison-bridge

%%

[0-9]+     { yylval->int_value = atoi(yytext); return INT_TERM; }
[a-zA-Z]+  { yylval->str_value = yytext; return STR_TERM; }
,          { return COMMA;    }

%%

// Yystype is the Java class that mimics the YYSTYPE union in a native bison parser
jclass yystype_class;
jfieldID yystype_str;
jfieldID yystype_int;

jclass runtimeException;

jint JNI_OnLoad(JavaVM *vm, void* reserved) {
  JNIEnv *env;

  if ((*vm)->GetEnv(vm, (void**) &env, JNI_VERSION_1_4) != JNI_OK) {
    return -1;
  }

  yystype_class = (*env)->FindClass(env, "com/mwberry/yacc/examples/YYParser$Yystype");
  yystype_str = (*env)->GetFieldID(env, yystype_class, "str_value", "Ljava/lang/String;");
  yystype_int = (*env)->GetFieldID(env, yystype_class, "int_value", "I");

  if (!yystype_class | !yystype_str | !yystype_int) {
    fprintf(stderr, "java.lex.so: JNI_OnLoad failed to locate all fields of YYStype\n");
    fprintf(stderr, "class: %p, str: %p, int: %p\n", yystype_class, yystype_str, yystype_int);
    return -1;
  }

  runtimeException = (*env)->FindClass(env, "java/lang/RuntimeException");

  if (!runtimeException) {
    fprintf(stderr, "java.lex.so: JNI_OnLoad failed to locate RuntimeException class\n");
    return -1;
  }

  return JNI_VERSION_1_4;
}

// Initializes lexer with the input file passed in from Java, returns pointer to scanner structure back to Java
jlong Java_com_mwberry_yacc_examples_YYParser_00024YYLexer_native_1init(JNIEnv *env, jobject obj, jstring jpath) {
  yyscan_t *scanner;
  FILE *infile;
  char *path = (char*) (*env)->GetStringUTFChars(env, jpath, 0);

  if (! (scanner = malloc(sizeof(yyscan_t)))) {
    (*env)->ThrowNew(env, runtimeException, "Failed to allocate memory for lexer");
    return 0;
  }

  if (! (infile = fopen(path, "r"))) {
    (*env)->ThrowNew(env, runtimeException, strerror(errno));
    return 0;
  }
  (*env)->ReleaseStringUTFChars(env, jpath, path);

  if (yylex_init(scanner)) {
    (*env)->ThrowNew(env, runtimeException, "Failed to initialize lexer");
    return 0;
  }

  yyset_debug(1, *scanner);
  yyset_in(infile, *scanner);
  return (jlong) *scanner;
}

// Frees the scanner structure passed to it from Java
void Java_com_mwberry_yacc_examples_YYParser_00024YYLexer_native_1destroy(JNIEnv *env, jobject obj, jlong scanner) {
  yylex_destroy((yyscan_t) scanner);
}

// Invokes the lexer and returns the next token. Sets the associated lval to the appropriate Java value
jint Java_com_mwberry_yacc_examples_YYParser_00024YYLexer_native_1yylex(JNIEnv *env, jobject obj,
                                                                        jobject lval, jlong scanner_ptr) {

  YYSTYPE native_lval;
  yyscan_t scanner = (yyscan_t) scanner_ptr;

  jint rtn = (jint) yylex(&native_lval, scanner);

  switch (rtn) {

    case INT_TERM: {
      // The token was an integer term, set the integer property of the Java lval
      (*env)->SetIntField(env, lval, yystype_int, native_lval.int_value);
    } break;

    case STR_TERM: {
      // The token was a string term. Copy it into Java's memory and set it to the Java lval
      jstring java_string = (*env)->NewStringUTF(env, native_lval.str_value);
      (*env)->SetObjectField(env, lval, yystype_str, java_string);
    } break;

    default: {
      // For all other tokens, there is no semantic value. It is an error to call getLVal() in Java.
    } break;
  }

  return rtn;
}

int yywrap (yyscan_t scanner) {
  // This is a simple demonstration, so just stop reading when we reach the end of the file.
  return 1;
}

void yyerror(yyscan_t scanner, char * msg) {
  fprintf(stderr, msg);
}
