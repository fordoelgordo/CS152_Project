/*
 * Create flex scanner specification file for MINI-L language
*/

 /* Variable declaration */
%{
	#include "y.tab.h"
	int currPos = 1;
	int currLine = 1;
%}

 /* Definitions */
DIGIT [0-9]
LETTER [a-zA-Z]
IDENTIFIER ({LETTER}({LETTER}|{DIGIT}|"_")*({LETTER}|{DIGIT}))|{LETTER}
ERROR_IDENTIFIER_DIGIT_UNDERSCORE_START ({DIGIT}|"_")+{IDENTIFIER}
ERROR_IDENTIFIER_UNDERSCORE_END {IDENTIFIER}"_"+

%%

 /* Rules */
"function"						{currPos += yyleng; return FUNCTION;}
"beginparams"						{currPos += yyleng; return BEGINPARAMS;}
"endparams"						{currPos += yyleng; return ENDPARAMS;}
"beginbody"						{currPos += yyleng; return BEGINBODY;}
"endbody"						{currPos += yyleng; return ENDBODY;}
"beginlocals"						{currPos += yyleng; return BEGINLOCALS;}
"endlocals"						{currPos += yyleng; return ENDLOCALS;}
"integer"						{currPos += yyleng; return INTEGER;}
"if"							{currPos += yyleng; return IF;}
"then"							{currPos += yyleng; return THEN;}
"else"							{currPos += yyleng; return ELSE;}
"endif"							{currPos += yyleng; return ENDIF;}
"return"						{currPos += yyleng; return RETURN;}
"read"							{currPos += yyleng; return READ;}
"write"							{currPos += yyleng; return WRITE;}
"do"							{currPos += yyleng; return DO;}
"beginloop"						{currPos += yyleng; return BEGINLOOP;}
"while"							{currPos += yyleng; return WHILE;}
"and"							{currPos += yyleng; return AND;}
"or"							{currPos += yyleng; return OR;}
"continue"						{currPos += yyleng; return CONTINUE;}
"endloop"						{currPos += yyleng; return ENDLOOP;}
"array"							{currPos += yyleng; return ARRAY;}
"of"							{currPos += yyleng; return OF;}
"true"							{currPos += yyleng; return TRUE;}
"false"							{currPos += yyleng; return FALSE;}
"for"							{currPos += yyleng; return FOR;}
";"							{++currPos; return SEMICOLON;}
":"							{++currPos; return COLON;}
"("							{++currPos; return L_PAREN;}
")"							{++currPos; return R_PAREN;}
"-"							{++currPos; return SUB;}
"+"							{++currPos; return ADD;}
"*"							{++currPos; return MULT;}
"/"							{++currPos; return DIV;}
"<="							{currPos += yyleng; return LTE;}
"<"							{currPos += yyleng; return LT;}
">="							{currPos += yyleng; return GTE;}
">"							{++currPos; return GT;}
"="							{++currPos; return EQ;}
":="							{currPos += yyleng; return ASSIGN;}
"=="							{currPos += yyleng; return EQ;}
"["							{++currPos; return L_SQUARE_BRACKET;}
"]"							{++currPos; return R_SQUARE_BRACKET;}
"%"							{++currPos; return MOD;}
","							{++currPos; return COMMA;}
##[^\n]*						{/* Ignore comments and tabs on the current line */ currPos += yyleng;} 
{IDENTIFIER}						{currPos += yyleng; yylval.cval = yytext; return IDENT;}
{DIGIT}+						{currPos += yyleng; yyval.dval = atoi(yytext); return NUMBER;}
[ \t]+							{/* Ignore spaces and tabs on current line */ currPos += yyleng;}
"\n"							{++currLine; currPos = 1; return END;}
"\r"							{++currLine; currPos = 1; return END;}
{ERROR_IDENTIFIER_DIGIT_UNDERSCORE_START}    		{printf("Error at line %d, column %d: identifier \"%s\" must begin with a letter\n", currLine, currPos, yytext); exit(0); }
{ERROR_IDENTIFIER_UNDERSCORE_END} 			{printf("Error at line %d, column %d: identifier \"%s\" cannot end with an underscore\n", currLine, currPos, yytext); exit(0); }
.              						{printf("Error at line %d, column %d: unrecognized symbol \"%s\"\n", currLine, currPos, yytext); exit(0);}

%%
