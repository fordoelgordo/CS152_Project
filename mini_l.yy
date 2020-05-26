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
	#include <cstdio> /* To write from stdout to file */
	#include <vector>
	#include <string>
	/* Define other data structures for non-terminals */
}

%code
{
	#include "parser.tab.hh"
	#include <map>
	#include <vector>
	#include <string>
	yy::parser::symbol_type yylex();
	/* Define symbol table, global variables, list of keywords or functions that are needed here */
	bool semantic_error = false; /* If semantic error is encountered, no intermediate code should be created and an error should print */
	int tempIndex = 0; /* to index temporary variables */
	string tempVar;
	vector<string> sym_table;
	vector<string> sym_type;
	bool in_sym_table(string symbol);
}

%token END 0 "end of file";

	/* Specification of tokens, type of non-terminals and terminals */
%token FUNCTION BEGINPARAMS ENDPARAMS BEGINBODY ENDBODY BEGINLOCALS ENDLOCALS INTEGER IF THEN ELSE ENDIF RETURN READ WRITE DO BEGINLOOP WHILE AND OR NOT CONTINUE ENDLOOP ARRAY OF TRUE FALSE
%token SEMICOLON L_PAREN R_PAREN SUB ADD MULT DIV LTE LT GTE GT EQ NEQ ASSIGN L_SQUARE_BRACKET R_SQUARE_BRACKET MOD FOR
%token COLON ":"
%token COMMA ","
%token <int> NUMBER
%token <string> IDENT
%left MULT DIV MOD /* Precedence = 3 */
%left ADD SUB /* Precedence = 4 */
%left LTE LT GTE GT EQ NEQ /* Precedence = 5 */
%right NOT /* Precedence = 6 */
%left AND /* Precedence = 7 */
%left OR /* Precedence = 8 */
%right ASSIGN /* Precedence = 9 */
%type <string> identifier identifiers functions function declarations declaration statements var

%%

%start program_start;

program_start: functions {
			if (!semantic_error) {
				std::cout << $1 << std::endl;
			}
		}
functions: function functions {
		$$ = $1;
		if ($2 != "") {
			$$ += "\n" + $2;
		}
	   }
           | /* epsilon */ {$$ = "";}
           ;
function: FUNCTION identifiers SEMICOLON BEGINPARAMS declarations ENDPARAMS BEGINLOCALS declarations ENDLOCALS BEGINBODY statements ENDBODY {
		$$ = "func " + $2 + "\n";
		if ($5 != "") {
			$$ += $5 + "\n";
		}
		if ($8 != "") {
			$$ += $8 + "\n";
		}
		if ($11 != "") {
			$$ += $11 + "\n";
		}
		$$ += "endfunc";
	}
	;
identifier: IDENT {$$ = $1;}
	  ;
identifiers: identifier COMMA identifiers {std::cout << "identifiers -> identifier COMMA identifiers\n";}
	     | identifier {$$ = $1;}
	     ;
declarations: /* epsilon */ {$$ = "";}
	      | declaration SEMICOLON declarations {$$ = $1 + "\n" + $3;}
	      ;
declaration: identifiers COLON INTEGER {
		/* Variable declaration of type integer */
		sym_table.push_back($1);
		sym_type.push_back("integer");
		$$ = ". " + $1;
	     }
	     | identifiers COLON ARRAY L_SQUARE_BRACKET NUMBER R_SQUARE_BRACKET OF INTEGER {
		/* Variable declaration of a 1-D array */
		sym_table.push_back($1);
		sym_type.push_back("array_1_d");
		$$ = ".[] " + $1 + "," + to_string($5);
	     }
             | identifiers COLON ARRAY L_SQUARE_BRACKET NUMBER R_SQUARE_BRACKET L_SQUARE_BRACKET NUMBER R_SQUARE_BRACKET OF INTEGER {
		/* Variable declaration of a 2-D array */
		sym_table.push_back($1);
		sym_type.push_back("array_2_d");
		
	     }
	     ;
comp: EQ {std::cout << "comp -> EQ\n";}
      | NEQ {std::cout << "comp -> NEQ\n";}
      | LT {std::cout << "comp -> LT\n";}
      | GT {std::cout << "comp -> GT\n";}
      | LTE {std::cout << "comp -> LTE\n";}
      | GTE {std::cout << "comp -> LTE\n";}
      ;
var: identifier {
	if (!in_sym_table($1)) {
		std::cerr << "Semantic error: " << $1 << " not declared" << std::endl;
		semantic_error = true;	
	}
	$$ = $1;
     }
     | identifier L_SQUARE_BRACKET expression R_SQUARE_BRACKET {std::cout << "var -> identifier L_SQUARE_BRACKET expression R_SQUARE_BRACKET\n";}
     | identifier L_SQUARE_BRACKET expression R_SQUARE_BRACKET L_SQUARE_BRACKET expression R_SQUARE_BRACKET {std::cout << "var -> identifier L_SQUARE_BRACKET expression R_SQUARE_BRACKET L_SQUARE_BRACKET expression R_SQUARE_BRACKET\n";}
     ;
vars: var {std::cout << "vars -> var\n";}
      | var COMMA vars {std::cout << "vars -> var COMMA vars\n";}
      ;
term: SUB var {
		
      }
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
	freopen("mil_code.mil", "w", stdout);
	if (argc > 1) {
		fileIn.open(argv[1]);
		if (!fileIn.is_open()) {
			std::cerr << "Error opening user file" << std::endl;
			exit(1);
		}
	}	
	p.parse();

	/*
	std::cout.open("mil_code.mil");
	if (!std::cout.is_open()) {
		std::cerr << "Error opening mil code file" << std::endl;
		exit(1);
	}
	std::cout << p.parse() << std::endl;
	std::cout.close();
	*/
	
	return 0;
}
void yy::parser::error(const yy::location& l, const std::string& m) {
	std::cerr << l << ": " << m << std::endl;
}
bool in_sym_table(string symbol) {
	for (int i = 0; i < sym_table.size(); ++i) {
		if (sym_table.at(i) == symbol) {
			return true;
		}
	}
	return false;	
}
