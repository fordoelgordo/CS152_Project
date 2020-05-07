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

%error-verbose
%start input
%token FUNCTION BEGINPARAMS ENDPARAMS BEGINBODY ENDBODY BEGINLOCALS ENDLOCALS INTEGER IF THEN ELSE ENDIF RETURN READ WRITE DO BEGINLOOP WHILE AND OR CONTINUE ENDLOOP ARRAY OF TRUE FALSE
%token SEMICOLON COLON L_PAREN R_PAREN SUB ADD MULT DIV LTE LT GTE GT EQ ASSIGN L_SQUARE_BRACKET R_SQUARE_BRACKET MOD COMMA FOR
%token <ival> NUMBER
%token <cval> IDENT
%type <cval> identifier

%%
input:	input function
	| /* epsilon */
	;
function: FUNCTION identifier SEMICOLON BEGINPARAMS declaration SEMICOLON ENDPARAMS
	;
identifier: IDENT {printf("identifier -> IDENT %s\n", $$);}
	  ;
identifiers: identifier COMMA identifiers {printf("identifiers -> identifier COMMA identifiers\n");}
declaration: /* epsion */
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
