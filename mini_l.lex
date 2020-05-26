/*
 * Flex scanner specification file for MINI-L language using Abbas' template
*/

/* Variable declarations */
%{
	#include <iostream>
	#define YY_DECL yy::parser::symbol_type yylex()
	#include "parser.tab.hh"
	static yy::location loc;
%}

%option noyywrap 

%{
	#define YY_USER_ACTION loc.columns(yyleng);
%}

/* Definitions */
DIGIT [0-9]
LETTER [a-zA-Z]
IDENTIFIER ({LETTER}({LETTER}|{DIGIT}|"_")*({LETTER}|{DIGIT}))|{LETTER}
ERROR_IDENTIFIER_DIGIT_UNDERSCORE_START ({DIGIT}|"_")+{IDENTIFIER}
ERROR_IDENTIFIER_UNDERSCORE_END {IDENTIFIER}"_"+

%%

%{
loc.step(); 
%}

	/* your rules here */

	/* use this structure to pass the Token :
	 * return yy::parser::make_TokenName(loc)
	 * if the token has a type you can pass it's value
	 * as the first argument. as an example we put
	 * the rule to return token function.
	 */

"function"       	{return yy::parser::make_FUNCTION(loc);}
"beginparams"	 	{return yy::parser::make_BEGINPARAMS(loc);}
"endparams"		{return yy::parser::make_ENDPARAMS(loc);}
"beginbody"		{return yy::parser::make_BEGINBODY(loc);}
"endbody"		{return yy::parser::make_ENDBODY(loc);}
"beginlocals"	 	{return yy::parser::make_BEGINLOCALS(loc);}
"endlocals"		{return yy::parser::make_ENDLOCALS(loc);}
"integer"		{return yy::parser::make_INTEGER(loc);}
"if"			{return yy::parser::make_IF(loc);}
"then"			{return yy::parser::make_THEN(loc);}
"else"		     	{return yy::parser::make_ELSE(loc);}
"endif"			{return yy::parser::make_ENDIF(loc);}
"return"		{return yy::parser::make_RETURN(loc);}
"read"		     	{return yy::parser::make_READ(loc);}
"write"			{return yy::parser::make_WRITE(loc);}
"do"			{return yy::parser::make_DO(loc);}
"beginloop"		{return yy::parser::make_BEGINLOOP(loc);}
"while"			{return yy::parser::make_WHILE(loc);}
"and"			{return yy::parser::make_AND(loc);}
"or"			{return yy::parser::make_OR(loc);}
"not"			{return yy::parser::make_NOT(loc);}
"continue"		{return yy::parser::make_CONTINUE(loc);}
"endloop"		{return yy::parser::make_ENDLOOP(loc);}
"array"			{return yy::parser::make_ARRAY(loc);}
"of"			{return yy::parser::make_OF(loc);}
"true"			{return yy::parser::make_TRUE(loc);}
"false"			{return yy::parser::make_FALSE(loc);}
"for"			{return yy::parser::make_FOR(loc);}
";"			{return yy::parser::make_SEMICOLON(loc);}
":"			{return yy::parser::make_COLON(loc);}
"("			{return yy::parser::make_L_PAREN(loc);}
")"			{return yy::parser::make_R_PAREN(loc);}
"-"			{return yy::parser::make_SUB(loc);}
"+"			{return yy::parser::make_ADD(loc);}
"*"			{return yy::parser::make_MULT(loc);}
"/"			{return yy::parser::make_DIV(loc);}
"<="			{return yy::parser::make_LTE(loc);}
"<"			{return yy::parser::make_LT(loc);}
">="			{return yy::parser::make_GTE(loc);}
">"		  	{return yy::parser::make_GT(loc);}
":="			{return yy::parser::make_ASSIGN(loc);}
"=="			{return yy::parser::make_EQ(loc);}
"<>"			{return yy::parser::make_NEQ(loc);}
"["			{return yy::parser::make_L_SQUARE_BRACKET(loc);}
"]"			{return yy::parser::make_R_SQUARE_BRACKET(loc);}
"%"			{return yy::parser::make_MOD(loc);}
","			{return yy::parser::make_COMMA(loc);}
##[^\n]*		{/* Ignore comments and tabs on the current line */} 
{IDENTIFIER}	 	{return yy::parser::make_IDENT(yytext, loc);}
{DIGIT}+		{return yy::parser::make_NUMBER(std::stoi(yytext), loc);}
[ \t]+			{/* Ignore spaces and tabs on current line */ }
"\n"			{/* Don't have a purpose in the programming language */}
"\r"			{/* Don't have a purpose in the programming language */}
{ERROR_IDENTIFIER_DIGIT_UNDERSCORE_START}  {std::cerr << loc << ": identifier \"" << yytext << "\" must begin with a letter" << std::endl; exit(1);}
{ERROR_IDENTIFIER_UNDERSCORE_END} 	   {std::cerr << loc << ": identifier \"" << yytext << "\" cannot end with an underscore " << std::endl; exit(1);}
"="					   {/* = not technically a valid token */} 
.              		                   {std::cerr << loc << ": unrecognized symbol \"" << yytext << "\"" << std::endl; exit(1);}
 <<EOF>>	{return yy::parser::make_END(loc);}
	/* your rules end */

%%
