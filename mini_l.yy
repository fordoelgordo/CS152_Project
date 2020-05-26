/* 
 * MINI-L Bison Specification File
*/

%{
%}

%skeleton "lalr1.cc"
%require "3.0.4"
%defines
%define api.token.constructor
%define api.value.type variant
%define parse.error verbose
%locations

%code requires
{
	using namespace std;
	#include <iostream>
	#include <fstream> /* To write the generated mil code to a file */
	#include <vector>
	#include <string>
	/* Define other data structures for non-terminals */
}

%code
{
	#include "parser.tab.hh"
	#include <map>
	#include <vector>
	yy::parser::symbol_type yylex();
	/* Define symbol table, global variables, list of keywords or functions that are needed here */
}

%token END 0 "end of file";

	/* Specification of tokens, type of non-terminals and terminals */
%token FUNCTION BEGINPARAMS ENDPARAMS BEGINBODY ENDBODY BEGINLOCALS ENDLOCALS INTEGER IF THEN ELSE ENDIF RETURN READ WRITE DO BEGINLOOP WHILE AND OR NOT CONTINUE ENDLOOP ARRAY OF TRUE FALSE
%token SEMICOLON L_PAREN R_PAREN SUB ADD MULT DIV LTE LT GTE GT EQ NEQ ASSIGN L_SQUARE_BRACKET R_SQUARE_BRACKET MOD FOR
%token COLON ":"
%token COMMA ","
%token <int> NUMBER
%token <string> IDENT
%type <string> identifier


%%

%start program_start;

program_start: functions {std::cout << "prog_start -> functions\n";}
functions: function functions {std::cout << "functions -> function functions\n";}
           | /* epsilon */ {std::cout << "functions -> epsilon\n";}
           ;
function: FUNCTION identifiers SEMICOLON BEGINPARAMS declarations ENDPARAMS BEGINLOCALS declarations ENDLOCALS BEGINBODY statements ENDBODY {std::cout << "function -> FUNCTION identifiers SEMICOLON BEGINPARAMS declarations ENDPARAMS BEGINLOCALS declarations ENDLOCALS BEGINBODY statements ENDBODY\n";}
	;
identifier: IDENT {std::cout << "identifier -> IDENT " << $1 << "\n";}
	  ;
identifiers: identifier COMMA identifiers {std::cout << "identifiers -> identifier COMMA identifiers\n";}
	     | identifier {std::cout << "identifiers -> identifier\n";}
	     ;
declarations: /* epsilon */ {std::cout << "declarations -> epsilon\n";}
	      | declaration SEMICOLON declarations {std::cout << "declarations -> declaration SEMICOLON declarations\n";}
	      ;
declaration: identifiers COLON INTEGER {std::cout << "declaration -> identifiers COLON INTEGER\n";}
	     | identifiers COLON ARRAY L_SQUARE_BRACKET NUMBER R_SQUARE_BRACKET OF INTEGER {std::cout << "declaration -> identifiers COLON ARRAY L_SQUARE_BRACKET NUMBER R_SQUARE_BRACKET OF INTEGER\n";}
             | identifiers COLON ARRAY L_SQUARE_BRACKET NUMBER R_SQUARE_BRACKET L_SQUARE_BRACKET NUMBER R_SQUARE_BRACKET OF INTEGER {std::cout << "declaration -> identifiers COLON ARRAY L_SQUARE_BRACKET NUMBER R_SQUARE_BRACKET L_SQUARE_BRACKET NUMBER R_SQUARE_BRACKET OF INTEGER\n";}
	     ;
comp: EQ {std::cout << "comp -> EQ\n";}
      | NEQ {std::cout << "comp -> NEQ\n";}
      | LT {std::cout << "comp -> LT\n";}
      | GT {std::cout << "comp -> GT\n";}
      | LTE {std::cout << "comp -> LTE\n";}
      | GTE {std::cout << "comp -> LTE\n";}
      ;
var: identifier {std::cout << "var -> indentifier\n";}
     | identifier L_SQUARE_BRACKET expression R_SQUARE_BRACKET {std::cout << "var -> identifier L_SQUARE_BRACKET expression R_SQUARE_BRACKET\n";}
     | identifier L_SQUARE_BRACKET expression R_SQUARE_BRACKET L_SQUARE_BRACKET expression R_SQUARE_BRACKET {std::cout << "var -> identifier L_SQUARE_BRACKET expression R_SQUARE_BRACKET L_SQUARE_BRACKET expression R_SQUARE_BRACKET\n";}
     ;
vars: var {std::cout << "vars -> var\n";}
      | var COMMA vars {std::cout << "vars -> var COMMA vars\n";}
      ;
term: SUB var {std::cout << "term -> SUB var\n";}
      | SUB NUMBER {std::cout << "term -> SUB NUMBER\n";}
      | SUB L_PAREN expression R_PAREN {std::cout << "term -> SUB L_PAREN expression R_PAREN\n";}
      | var {std::cout << "term -> var\n";}
      | NUMBER {std::cout << "term -> NUMBER \n";}
      | L_PAREN expression R_PAREN {std::cout << "term -> L_PAREN expression R_PAREN\n";}
      | identifier L_PAREN expressions R_PAREN {std::cout << "term -> indentifier L_PAREN expression R_PAREN\n";}
      ;
expressions: expression COMMA expressions {std::cout << "expressions -> expression COMMA expressions\n";}
	     | expression {std::cout << "expressions -> expression\n";}
	     ;
expression: multiplicative_expression {std::cout << "expression -> multiplicative_expression\n";}
            | multiplicative_expression ADD expression {std::cout << "expression -> multiplicative_expression ADD expression\n";}
	    | multiplicative_expression SUB expression {std::cout << "expression -> multiplicative_expression SUB expression\n";}
	    ;
multiplicative_expression: term {std::cout << "multiplicative_expression -> term\n";}
			   | term MULT multiplicative_expression {std::cout << "multiplicative_expression -> term MULT multiplicative_expression\n";}
			   | term DIV multiplicative_expression {std::cout << "multiplicative_expression -> term DIV multiplicative_expression\n";}
                           | term MOD multiplicative_expression {std::cout << "multiplicative_expression -> term MOD multiplicative_expression\n";}
                           ;
relation_expression: TRUE {std::cout << "relation_expression -> TRUE\n";}
 		     | FALSE {std::cout << "relation_expression -> FALSE\n";}
		     | expression comp expression {std::cout << "relation_expression -> expression comp expresssion\n";}
		     | L_PAREN bool_expression R_PAREN {std::cout << "relation_expression -> L_PAREN bool_expression R_PAREN\n";}
                     | NOT TRUE {std::cout << "relation_expression -> NOT TRUE\n";}
		     | NOT FALSE {std::cout << "relation_expression -> NOT FALSE\n";}
		     | NOT expression comp expression {std::cout << "relation_expression -> NOT expression comp expression\n";}
		     | NOT L_PAREN bool_expression R_PAREN {std::cout << "relation_expression -> NOT L_PAREN bool_expression R_PAREN\n";}
		     ;
relation_and_expression: relation_expression {std::cout << "relation_and_expression -> relation_expression\n";}
			 | relation_expression AND relation_and_expression {std::cout << "relation_and_expression -> relation_expression AND relation_and_expression\n";}
			 ;
bool_expression: relation_and_expression {std::cout << "bool_expression -> relation_and_expression\n";}
	    	 | relation_and_expression OR relation_and_expression {std::cout << "bool_expression -> relation_and_expression OR relation_and_expression\n";}
		 ;
statements: statement SEMICOLON statements {std::cout << "statements -> statement SEMICOLON statements\n";}
	    | /* epsilon */ {std::cout << "statements -> epsilon\n";}
	    ;
statement: var ASSIGN expression {std::cout << "statement -> var ASSIGN expression\n";}
	   | IF bool_expression THEN statements ENDIF {std::cout << "statement -> IF bool_expression THEN statements ENDIF\n";}
	   | IF bool_expression THEN statements ELSE statements ENDIF {std::cout << "statement -> IF bool_expression THEN statements ELSE statements ENDIF\n";}
	   | WHILE bool_expression BEGINLOOP statements ENDLOOP {std::cout << "statement -> WHILE bool_expression BEGINLOOP statements ENDLOOP\n";}
	   | DO BEGINLOOP statements ENDLOOP WHILE bool_expression {std::cout << "statement -> DO BEGINLOOP statements ENDLOOP WHILE bool_expression\n";}
	   | FOR var ASSIGN NUMBER SEMICOLON bool_expression SEMICOLON var ASSIGN expression BEGINLOOP statements ENDLOOP {std::cout << "FOR var ASSIGN NUMBER SEMICOLON bool_expression SEMICOLON var ASSIGN expression BEGINLOOP statements ENDLOOP\n";}
	   | READ vars {std::cout << "statement -> READ vars\n";}
	   | WRITE vars {std::cout << "statement -> WRITE vars\n";}
	   | CONTINUE {std::cout << "statement -> CONTINUE\n";}
	   | RETURN expression {std::cout << "statement -> RETURN expression\n";}
	   ;

%%
int main(int argc, char* argv[]) {
	yy::parser p;
	ifstream fileIn;
	ofstream fileOut;
	if (argc > 1) {
		fileIn.open(argv[1]);
		if (!fileIn.is_open()) {
			std::cerr << "Error opening user file" << std::endl;
			exit(1);
		}
	}
	p.parse();

	/*
	fileOut.open("mil_code.mil");
	if (!fileOut.is_open()) {
		std::cerr << "Error opening mil code file" << std::endl;
		exit(1);
	}
	fileOut << p.parse() << std::endl;
	fileOut.close();
	*/
	
	return 0;
}
void yy::parser::error(const yy::location& l, const std::string& m) {
	std::cerr << l << ": " << m << std::endl;
}
