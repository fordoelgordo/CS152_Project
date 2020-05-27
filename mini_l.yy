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
	#include <stack>
	#include <queue>
	yy::parser::symbol_type yylex();
	/* Define symbol table, global variables, list of keywords or functions that are needed here */
	bool semantic_error = false; /* If semantic error is encountered, no intermediate code should be created and an error should print */
	int tempIndex = 0; /* to index temporary variables */
	string tempVar; /* To name temporary variables */
	int tempLabIndex = 0; /* to index labels */
	string tempLabel; /* To name temporary labels */
	string newTemp(); /* Function to create a new temporary variable and return it */
	string newLabel(); /* Function to create a new label and return it */
	string temp; /* Return newTemp() to this global variable */
	string label; /* Return newLabel() to this global variable */
	vector<string> sym_table;
	map<string, int> sym_type; /* 0 = integer, 1 = 1-D array, 2 = 2-D array, 3 = function */
	vector<string> label_table;
	vector<string> ident_list;
	vector<string> var_list;
	bool in_sym_table(string symbol); /* Check if the passed symbol is in the symbol table */
	int find_symbol(string symbol);  /* Return the location of the passed symbol in the symbol table */
	bool in_label_table(string label);
	struct exp_struct {
		int place; /* Location in the symbol table of the name of the variable that holds the expression's value */
		string code; /* The code that generates the expression */
	}
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
%type <string> identifier identifiers functions function declarations declaration statements statement vars var
%type <exp_struct> expression

%%

%start program_start;

program_start: functions {
			//FIXME: if (!semantic_error) {
				std::cout << $1 << std::endl;
				cout << endl;
				cout << "Printing the variables in the symbol table" << endl;
				for (int i = 0; i < sym_table.size(); ++i) {
					cout << "Variable: " << sym_table.at(i) << ", type: " << sym_type.find(sym_table.at(i))->second << endl;
				}			
			//}
		}
functions: function functions {
		$$ = $1;
		if ($2 != "") {
			$$ += "\n" + $2;
		}
	   }
           | /* epsilon */ {$$ = "";}
           ;
function: FUNCTION identifier SEMICOLON BEGINPARAMS declarations ENDPARAMS BEGINLOCALS declarations ENDLOCALS BEGINBODY statements ENDBODY {
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
identifiers: identifier COMMA identifiers {
		ident_list.push_back($1);
	     }
	     | identifier {
	     	ident_list.push_back($1);
	     }
	     ;
declarations: /* epsilon */ {$$ = "";}
	      | declaration SEMICOLON declarations {
	      	$$ = $1;
		if ($3 != "") {
			$$ += "\n" + $3;
		}
	      }
	      ;
declaration: identifiers COLON INTEGER {
		/* Variable declaration of type integer */
		for (int i = 0; i < ident_list.size(); ++i) {	
			if (!in_sym_table(ident_list.at(i))) {
				sym_table.push_back(ident_list.at(i));
				sym_type.insert(pair<string, int>(ident_list.at(i), 0));
				$$ = ". " + $1; // Code for an integer declaration
			}
			else {
				std::cerr << "Error: redeclaration of variable " << ident_list.at(i) << std::endl;
				semantic_error = true;	
			}
		}
		ident_list.clear(); 
	     }
	     | identifiers COLON ARRAY L_SQUARE_BRACKET NUMBER R_SQUARE_BRACKET OF INTEGER {
		/* Variable declaration of a 1-D array */
		if (!in_sym_table($1)) {
			sym_table.push_back($1);
			sym_type.insert(pair<string, int>($1, 1));
			$$ = ".[] " + $1 + "," + to_string($5);
		}
		else {
			std::cerr << "Error: redeclaration of variable " << $1 << std::endl;
			semantic_error = true;
		}
	     }
             | identifiers COLON ARRAY L_SQUARE_BRACKET NUMBER R_SQUARE_BRACKET L_SQUARE_BRACKET NUMBER R_SQUARE_BRACKET OF INTEGER {
		/* Variable declaration of a 2-D array */
		if (!in_sym_table($1)) {
			sym_table.push_back($1);
			sym_type.insert(pair<string, int>($1, 2));
		}
		else {
			std::cerr << "Error: redeclaration of variable " << $1 << std::endl;
			semantic_error = true;
		}	
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
vars: var {
	var_list.push_back($1);
      }
      | var COMMA vars {
	var_list.push_back($1);
      }
      ;
term: SUB var {
      	temp = newTemp();
	if (!in_sym_table($2)) {
		std::cerr << "Semantic error: " << $2 << " not declared" << std::endl;
		semantic_error = true;
	}
	$$ = $2 + "\n";
	$$ += "* " + temp + ", " + $2 + ", -1";      		
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
statements: statement SEMICOLON statements {
		if ($3 != "") {
			$$ += $1 + "\n" + $3;
		}
		else {
			$$ = $1;
		}
	    }
	    | /* epsilon */ {$$ = "";}
	    ;
statement: var ASSIGN expression {std::cout << "statement -> var ASSIGN expression\n";}
	   | IF bool_expression THEN statements ENDIF {std::cout << "statement -> IF bool_expression THEN statements ENDIF\n";}
	   | IF bool_expression THEN statements ELSE statements ENDIF {std::cout << "statement -> IF bool_expression THEN statements ELSE statements ENDIF\n";}
	   | WHILE bool_expression BEGINLOOP statements ENDLOOP {std::cout << "statement -> WHILE bool_expression BEGINLOOP statements ENDLOOP\n";}
	   | DO BEGINLOOP statements ENDLOOP WHILE bool_expression {std::cout << "statement -> DO BEGINLOOP statements ENDLOOP WHILE bool_expression\n";}
	   | FOR var ASSIGN NUMBER SEMICOLON bool_expression SEMICOLON var ASSIGN expression BEGINLOOP statements ENDLOOP {std::cout << "FOR var ASSIGN NUMBER SEMICOLON bool_expression SEMICOLON var ASSIGN expression BEGINLOOP statements ENDLOOP\n";}
	   | READ vars {
		for (int i = 0; i < var_list.size(); ++i) {
			if (in_sym_table(var_list.at(i))) {
				if (sym_type.find(var_list.at(i))->second == 0) {
					if (i < var_list.size() - 1) {
						$$ += ".< " + var_list.at(i) + "\n";
					}
					else {
						$$ += ".< " + var_list.at(i);
					}
				}
				else if (sym_type.find(var_list.at(i))->second == 1) {
					if (i < var_list.size() - 1) {
						$$ += ".[]< " + var_list.at(i) + "\n";
					}
					else {
						$$ += ".[]< " + var_list.at(i);
					}
				}
			}	
			else {
				std::cerr << "Error: variable " << $2 << " not declared" << std::endl;
				semantic_error = true;
			}	
		}
		var_list.clear();	
	   }
	   | WRITE vars {
		/* Do nothing for now */		
	   }
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
int find_symbol(string symbol) {
	for (int i = 0; i < sym_table.size(); ++i) {
		if (sym_table.at(i) == symbol) {
			return i;
		}
	}
	return -1;
}
bool in_label_table(string label) {
	for (int i = 0; i < label_table.size(); ++i) {
		if (label_table.at(i) == label) {
			return true;
		}
	}
	return false;
}
string newTemp() {
	/* Ensure temporary variable not already in symbol table */
	tempVar = "_temp_" + to_string(tempIndex);
	if (in_sym_table(tempVar)) {
		++tempIndex;
		tempVar = "_temp_" + to_string(tempIndex);
		// Insert the temporary variable into the symbol table
		sym_table.push_back(tempVar);
		// Return the temporary variable
		return tempVar;
	}
	tempVar = "_temp_" + to_string(tempIndex);
	++tempIndex;
	sym_table.push_back(tempVar);
	return tempVar;
}
string newLabel() {
	/* Ensure label hasn't already been used */
	tempLabel = "_label_" + to_string(tempLabIndex);
	if (in_label_table(tempLabel)) {
		++tempLabIndex;
		tempLabel = "_label_" + to_string(tempLabIndex);
		label_table.push_back(tempLabel);
		return tempLabel;
	}
	tempLabel = "_temp_" + to_string(tempLabIndex);
	++tempLabIndex;
	label_table.push_back(tempLabel);
	return tempLabel;
}
	
