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
%token SEMICOLON COLON L_PAREN R_PAREN SUB ADD MULT DIV LTE LT GTE GT EQ ASSIGN EQ L_SQUARE_BRACKET R_SQUARE_BRACKET MOD COMMA END
%token <ival> NUMBER
%token <cval> IDENT
