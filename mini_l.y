/*
 * MINI-L Bison specification file
*/

%{
	#include <stdio.h>
	#include <stdlib.h>
	void yyerror(const char* msg);
	extern int currLine;
	extern int currPos;
	FILE* yyin;
%}

%union{
	int ival; /* To return NUMBER tokens */
	char* cval; /* To return IDENT tokens */
}

%define parse.error verbose
%define parse.lac full
%start program_start
%token FUNCTION BEGINPARAMS ENDPARAMS BEGINBODY ENDBODY BEGINLOCALS ENDLOCALS INTEGER IF THEN ELSE ENDIF RETURN READ WRITE DO BEGINLOOP WHILE AND OR NOT CONTINUE ENDLOOP ARRAY OF TRUE FALSE
%token SEMICOLON L_PAREN R_PAREN SUB ADD MULT DIV LTE LT GTE GT EQ NEQ ASSIGN L_SQUARE_BRACKET R_SQUARE_BRACKET MOD FOR
%token COLON ":"
%token COMMA ","
%token <ival> NUMBER
%token <cval> IDENT
%type <cval> identifier

%%
program_start: functions {printf("prog_start -> functions\n");}
functions: function functions {printf("functions -> function functions\n");}
           | /* epsilon */ {printf("functions -> epsilon\n");}
           ;
function: FUNCTION identifiers SEMICOLON BEGINPARAMS declarations ENDPARAMS BEGINLOCALS declarations ENDLOCALS BEGINBODY statements ENDBODY {printf("function -> FUNCTION identifiers SEMICOLON BEGINPARAMS declarations ENDPARAMS BEGINLOCALS declarations ENDLOCALS BEGINBODY statements ENDBODY\n");}
	;
identifier: IDENT {printf("identifier -> IDENT %s\n", $$);}
	  ;
identifiers: identifier COMMA identifiers {printf("identifiers -> identifier COMMA identifiers\n");}
	     | identifier {printf("identifiers -> identifier\n");}
	     ;
declarations: /* epsilon */ {printf("declarations -> epsilon\n");}
	      | declaration SEMICOLON declarations {printf("declarations -> declaration SEMICOLON declarations\n");}
	      ;
declaration: identifiers COLON INTEGER {printf("declaration -> identifiers COLON INTEGER\n");}
             | identifiers COLON ARRAY L_SQUARE_BRACKET NUMBER R_SQUARE_BRACKET OF INTEGER {printf("declaration -> identifiers COLON ARRAY L_SQUARE_BRACKET NUMBER R_SQUARE_BRACKET OF INTEGER\n");}
             | identifiers COLON ARRAY L_SQUARE_BRACKET NUMBER R_SQUARE_BRACKET L_SQUARE_BRACKET NUMBER R_SQUARE_BRACKET OF INTEGER {printf("declaration -> identifiers COLON ARRAY L_SQUARE_BRACKET NUMBER R_SQUARE_BRACKET L_SQUARE_BRACKET NUMBER R_SQUARE_BRACKET OF INTEGER\n");}
	     ;
comp: EQ {printf("comp -> EQ\n");}
      | NEQ {printf("comp -> NEQ\n");}
      | LT {printf("comp -> LT\n");}
      | GT {printf("comp -> GT\n");}
      | LTE {printf("comp -> LTE\n");}
      | GTE {printf("comp -> LTE\n");}
      ;
var: identifier {printf("var -> indentifier\n");}
     | identifier L_SQUARE_BRACKET expression R_SQUARE_BRACKET {printf("var -> identifier L_SQUARE_BRACKET expression R_SQUARE_BRACKET\n");}
     | identifier L_SQUARE_BRACKET expression R_SQUARE_BRACKET L_SQUARE_BRACKET expression R_SQUARE_BRACKET {printf("var -> identifier L_SQUARE_BRACKET expression R_SQUARE_BRACKET L_SQUARE_BRACKET expression R_SQUARE_BRACKET\n");}
     ;
vars: var {printf("vars -> var\n");}
      | var COMMA vars {printf("vars -> var COMMA vars\n");}
      ;
term: SUB var {printf("term -> SUB var\n");}
      | SUB NUMBER {printf("term -> SUB NUMBER\n");}
      | SUB L_PAREN expression R_PAREN {printf("term -> SUB L_PAREN expression R_PAREN\n");}
      | var {printf("term -> var\n");}
      | NUMBER {printf("term -> NUMBER \n");}
      | L_PAREN expression R_PAREN {printf("term -> L_PAREN expression R_PAREN\n");}
      | identifier L_PAREN expressions R_PAREN {printf("term -> indentifier L_PAREN expression R_PAREN\n");}
      ;
expressions: expression COMMA expressions {printf("expressions -> expression COMMA expressions\n");}
             | expression {printf("expressions -> expression\n");}
	     ;
expression: multiplicative_expression {printf("expression -> multiplicative_expression\n");}
            | multiplicative_expression ADD expression {printf("expression -> multiplicative_expression ADD expression\n");}
	    | multiplicative_expression SUB expression {printf("expression -> multiplicative_expression SUB expression\n");}
	    ;
multiplicative_expression: term {printf("multiplicative_expression -> term\n");}
			   | term MULT multiplicative_expression {printf("multiplicative_expression -> term MULT multiplicative_expression\n");}
			   | term DIV multiplicative_expression {printf("multiplicative_expression -> term DIV multiplicative_expression\n");}
                           | term MOD multiplicative_expression {printf("multiplicative_expression -> term MOD multiplicative_expression\n");}
                           ;
relation_expression: TRUE {printf("relation_expression -> TRUE\n");}
 		     | FALSE {printf("relation_expression -> FALSE\n");}
		     | expression comp expression {printf("relation_expression -> expression comp expresssion\n");}
		     | L_PAREN bool_expression R_PAREN {printf("relation_expression -> L_PAREN bool_expression R_PAREN\n");}
                     | NOT TRUE {printf("relation_expression -> NOT TRUE\n");}
		     | NOT FALSE {printf("relation_expression -> NOT FALSE\n");}
		     | NOT expression comp expression {printf("relation_expression -> NOT expression comp expression\n");}
		     | NOT L_PAREN bool_expression R_PAREN {printf("relation_expression -> NOT L_PAREN bool_expression R_PAREN\n");}
		     ;
relation_and_expression: relation_expression {printf("relation_and_expression -> relation_expression\n");}
			 | relation_expression AND relation_and_expression {printf("relation_and_expression -> relation_expression AND relation_and_expression\n");}
			 ;
bool_expression: relation_and_expression {printf("bool_expression -> relation_and_expression\n");}
	    	 | relation_and_expression OR relation_and_expression {printf("bool_expression -> relation_and_expression OR relation_and_expression\n");}
		 ;
statements: statement SEMICOLON statements {printf("statements -> statement SEMICOLON statements\n");}
	    | /* epsilon */ {printf("statements -> epsilon\n");}
	    ;
statement: var ASSIGN expression {printf("statement -> var ASSIGN expression\n");}
           | IF bool_expression THEN statements ENDIF {printf("statement -> IF bool_expression THEN statements ENDIF\n");}
	   | IF bool_expression THEN statements ELSE statements ENDIF {printf("statement -> IF bool_expression THEN statements ELSE statements ENDIF\n");}
	   | WHILE bool_expression BEGINLOOP statements ENDLOOP {printf("statement -> WHILE bool_expression BEGINLOOP statements ENDLOOP\n");}
	   | DO BEGINLOOP statements ENDLOOP WHILE bool_expression {printf("statement -> DO BEGINLOOP statements ENDLOOP WHILE bool_expression\n");}
	   | FOR var ASSIGN NUMBER SEMICOLON bool_expression SEMICOLON var ASSIGN expression BEGINLOOP statements ENDLOOP {printf("FOR var ASSIGN NUMBER SEMICOLON bool_expression SEMICOLON var ASSIGN expression BEGINLOOP statements ENDLOOP\n");}
           | READ vars {printf("statement -> READ vars\n");}
	   | WRITE vars {printf("statement -> WRITE vars\n");}
	   | CONTINUE {printf("statement -> CONTINUE\n");}
	   | RETURN expression {printf("statement -> RETURN expression\n");}
	   ;

%%
int main (int argc, char* argv[]) {
	if (argc > 1) { // An input file has been entered
		yyin = fopen(argv[1], "r");
		if (yyin == NULL) {
			printf("syntax: %s filename\n", argv[0]);
		}
	}
	yyparse();
	return 0;
}

void yyerror(const char* msg) {
	printf("** Line %d, position %d: %s\n", currLine, currPos, msg);
}
