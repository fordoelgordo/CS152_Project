/*
 * Lexical Analyzer for the MINI-L language
 *
 * Valid tokens:
 *   Identifiers: Begin with a letter, followed by either letters, digits or underscores. Cannot end with an underscore
 *   Comments: begin ## and continue to the end of the current line
 *   Reserved words:
 *     function
 *     beginparams
 *     endparams
 *     beginbody
 *     endbody
 *     beginlocals
 *     endlocals
 *     if
 *     then
 *     else
 *     endif
 *     return
 *     read
 *     write
 *     integer
 *     do
 *     beginloop
 *     while
 *     and
 *     continue
 *     endloop
 *  Numbers: Appear to just be integer values, no decimals or signed values
 * 
 *
 *  Usage: (1) flex mini_l.lex
 *         (2) gcc -o lexer lex.yy.c -lfl
 *         (3) ./lexer <input file>
*/

 /* Variable declaration */
%{
	#include <stdio.h>
	int currPos = 1;
	int currLine = 1;
%}

 /* Definitions */
DIGIT [0-9]
LETTER [a-zA-Z]

%%

 /* Rules */
"function"						{printf("FUNCTION\n"); currPos += yyleng;}
"beginparams"						{printf("BEGIN_PARAMS\n"); currPos += yyleng;}
"endparams"						{printf("END_PARAMS\n"); currPos += yyleng;}
"beginbody"						{printf("BEGIN_BODY\n"); currPos += yyleng;}
"endbody"						{printf("END_BODY\n"); currPos += yyleng;}
"beginlocals"						{printf("BEGIN_LOCALS\n"); currPos += yyleng;}
"endlocals"						{printf("END_LOCALS\n"); currPos += yyleng;}
"integer"						{printf("INTEGER\n"); currPos += yyleng;}
"if"							{printf("IF\n"); currPos += yyleng;}
"then"							{printf("THEN\n"); currPos += yyleng;}
"else"							{printf("ELSE\n"); currPos += yyleng;}
"endif"							{printf("ENDIF\n"); currPos += yyleng;}
"return"						{printf("RETURN\n"); currPos += yyleng;}
"read"							{printf("READ\n"); currPos += yyleng;}
"write"							{printf("WRITE\n"); currPos += yyleng;}
"do"							{printf("DO\n"); currPos += yyleng;}
"beginloop"						{printf("BEGINLOOP\n"); currPos += yyleng;}
"while"							{printf("WHILE\n"); currPos += yyleng;}
"and"							{printf("AND\n"); currPos += yyleng;}
"or"							{printf("OR\n"); currPos += yyleng;}
"continue"						{printf("CONTINUE\n"); currPos += yyleng;}
"endloop"						{printf("ENDLOOP\n"); currPos += yyleng;}
"array"							{printf("ARRAY\n"); currPos += yyleng;}
"of"							{printf("OF\n"); currPos += yyleng;}
"true"							{printf("TRUE\n"); currPos += yyleng;}
"false"							{printf("FALSE\n"); currPos += yyleng;}
";"							{printf("SEMICOLON\n"); ++currPos;}
":"							{printf("COLON\n"); ++currPos;}
"("							{printf("L_PAREN\n"); ++currPos;}
")"							{printf("R_PAREN\n"); ++currPos;}
"-"							{printf("SUB\n"); ++currPos;}
"+"							{printf("ADD\n"); ++currPos;}
"*"							{printf("MULT\n"); ++currPos;}
"<="							{printf("LTE\n"); currPos += yyleng;}
"<"							{printf("LT\n"); currPos += yyleng;}
">="							{printf("GTE\n"); currPos += yyleng;}
">"							{printf("GT\n"); ++currPos;}
"="							{printf("EQ\n"); ++currPos;}
":="							{printf("ASSIGN\n"); currPos += yyleng;}
"=="							{printf("EQ\n"); currPos += yyleng;}
"["							{printf("L_SQUARE_BRACKET\n"); ++currPos;}
"]"							{printf("R_SQUARE_BRACKET\n"); ++currPos;}
"%"							{printf("MOD\n"); ++currPos;}
","							{printf("COMMA\n"); ++currPos;}
##[^\n]*						{/* Ignore comments and tabs on the current line */ currPos += yyleng;}
{LETTER}(({LETTER}|[_]|{DIGIT})*({DIGIT}|{LETTER})*)*	{printf("IDENT %s\n", yytext); currPos += yyleng;} /* Still working on this */
{DIGIT}+						{printf("NUMBER %s\n", yytext); currPos += yyleng;}
[ \t]+							{/* Ignore spaces and tabs on current line */ currPos += yyleng;}
"\n"							{++currLine; currPos = 1;}
"\r"							{++currLine; currPos = 1;}

%%

 /* User Code */
int main(int argc, char* argv[]) {
	if (argc > 1) {
		yyin = fopen(argv[1], "r");
		if (yyin == NULL) {
			yyin = stdin;
		}
	}
	else {
		yyin = stdin;
	}
	yylex();
	// Remove the \n at the end of the file that prints with the last token
	/* This code doesn't remove the newline character yet, still working on it */
	int ch = getc(yyin);
	while (ch != EOF) {
		ch = getc(yyin);
	}
	if (feof(yyin)) {
		ch = '\0';
	}	
	return 0;
}
