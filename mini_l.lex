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
 *     else
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
	int currPos = 1;
	int currLine = 1;
%}

 /* Definitions */
DIGIT [0-9]
LETTER [a-zA-Z]

%%

 /* Rules */
"function"					{printf("FUNCTION\n"); currPos += yyleng;}
"beginparams"					{printf("BEGIN_PARAMS\n"); currPos += yyleng;}
"endparams"					{printf("END_PARAMS\n"); currPos += yyleng;}
"beginbody"					{printf("BEGIN_BODY\n"); currPos += yyleng;}
"endbody"					{printf("END_BODY\n"); currPos += yyleng;}
";"						{printf("SEMICOLON\n"); ++currPos;}
":"						{printf("COLON\n"); ++currPos;}
{LETTER}+(DIGIT|[_]|LETTER)*(DIGIT|LETTER)*?	{printf("IDENT %s\n", yytext); currPos += yyleng;}
[ \t]+						{/* Ignore spaces and tabs on current line */ currPos += yyleng;}
"\n"						{++currLine; currPos = 1;}

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

	return 0;
}
