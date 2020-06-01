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
	struct dec_struct {
		vector<string> ids;
		string code;
	};
	struct exp_struct {
		int place; /* Location in the symbol table of the name of the variable that holds the expression's value */
		string code; /* The code that generates the expression */
		string index; /* If referencing an array element, store the index of the requested access */
	};
	struct stmt_struct {
		string begin;
		string after;
		string code;
		bool has_continue = false;
	};
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
	string texp1;
	string texp2;
	vector<string> sym_table;
	map<string, int> sym_type; /* 0 = integer, 1 = 1-D array, 2 = 2-D array, 3 = function */
	vector<string> label_table;
	vector<string> ident_list;
	vector<exp_struct> var_list;
	queue<string> loop_labels;
	vector<string> reserved_words{"function","beginparams","endparams","beginbody","endbody","beginlocals","endlocals","integer","if","then","else","endif","return","read","write","do","beginloop","while","and","or","not","continue","endloop","array","of","true","false"};
	bool in_sym_table(string symbol); /* Check if the passed symbol is in the symbol table */
	int find_symbol(string symbol);  /* Return the location of the passed symbol in the symbol table */
	bool in_label_table(string label);
	bool in_reserved_words(string word);
}

%token END 0 "end of file";

	/* Specification of tokens, type of non-terminals and terminals */
%token FUNCTION BEGINPARAMS ENDPARAMS BEGINBODY ENDBODY BEGINLOCALS ENDLOCALS INTEGER IF THEN ELSE ENDIF RETURN READ WRITE DO BEGINLOOP WHILE AND OR NOT CONTINUE ENDLOOP ARRAY OF TRUE FALSE
%token SEMICOLON L_PAREN R_PAREN SUB ADD MULT DIV ASSIGN L_SQUARE_BRACKET R_SQUARE_BRACKET MOD FOR
%token COLON ":"
%token COMMA ","
%token <int> NUMBER
%token <string> IDENT LTE LT GTE GT EQ NEQ
%left MULT DIV MOD /* Precedence = 3 */
%left ADD SUB /* Precedence = 4 */
%left LTE LT GTE GT EQ NEQ /* Precedence = 5 */
%right NOT /* Precedence = 6 */
%left AND /* Precedence = 7 */
%left OR /* Precedence = 8 */
%right ASSIGN /* Precedence = 9 */
%type <string> identifier identifiers functions function vars comp
%type <dec_struct> declarations declaration
%type <exp_struct> expression expressions term var bool_expression relation_expression relation_and_expression multiplicative_expression
%type <stmt_struct> statements statement

%%

%start program_start;

program_start: functions {
			//FIXME
			//if (!semantic_error) {
				std::cout << $1 << std::endl;
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
		if (!in_sym_table($2)) {
			if (!in_reserved_words($2)) {
				sym_table.push_back($2);
				sym_type.insert(pair<string, int>($2, 3));
			}
			else {
				yy::parser::syntax_error(@2, "Declaration of function using reserved word");
				semantic_error = true;
			}
		}
		else {
			yy::parser::syntax_error(@2, "Redeclaration of identifier " + $2 + " as a function");
			semantic_error = true;
		}
		$$ = "func " + $2 + "\n";
		if ($5.code != "") {
			$$ += $5.code + "\n";
			if ($2 != "main") {
				for (int i = 0; i < $5.ids.size(); ++i) {
					if (i < $5.ids.size() - 1) {
						$$ += "= " + $5.ids.at(i) + ", $" + to_string(i) + "\n";
					}
					else {
						$$ += "= " + $5.ids.at(i) + ", $" + to_string(i);
					}
				}
			}
			$$ += "\n";
		}
		if ($8.code != "") {
			$$ += $8.code + "\n";
		}
		if ($11.code != "") {
			$$ += $11.code + "\n";
		}
		$$ += "endfunc";
		$$ += "\n";
		sym_table.clear(); // Clear the symbol table after evaulating all declarations within each function 
		sym_type.clear(); // Clear the associated symbol type table as well
		label_table.clear();
		ident_list.clear();
		var_list.clear();
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
declarations: /* epsilon */ {$$.code = "";}
	      | declaration SEMICOLON declarations {
	      	for (int i = 0; i < $1.ids.size(); ++i) {
			$$.ids.push_back($1.ids.at(i));
		}
		for (int i = 0; i < $3.ids.size(); ++i) {
			$$.ids.push_back($3.ids.at(i));
		}
		$$.code = $1.code;
		if ($3.code != "") {
			$$.code += "\n" + $3.code;
		}
	      }
	      ;
declaration: identifiers COLON INTEGER {
		// Variable declaration of type integer
		for (int i = ident_list.size() - 1; i >= 0; --i) {	
			if (!in_sym_table(ident_list.at(i))) {
				if (!in_reserved_words(ident_list.at(i))) {
					sym_table.push_back(ident_list.at(i));
					sym_type.insert(pair<string, int>(ident_list.at(i), 0));
					$$.ids.push_back(ident_list.at(i));
					if (i > 0) {
						$$.code += ". " + ident_list.at(i) + "\n"; // Code for an integer declaration
					}
					else {
						$$.code += ". " + ident_list.at(i);
					}
				}
				else {
					yy::parser::syntax_error(@1, "Declaration of variable with same name as a reserved word");
					semantic_error = true;
				}
			}
			else {
				yy::parser::syntax_error(@1, "Redeclaration of variable " + ident_list.at(i));
				semantic_error = true;	
			}
		}
		ident_list.clear(); 
	     }
	     | identifiers COLON ARRAY L_SQUARE_BRACKET NUMBER R_SQUARE_BRACKET OF INTEGER {
		// Variable declaration of a 1-D array 
		for (int i = ident_list.size() - 1; i >= 0; --i) {	
			if (!in_sym_table(ident_list.at(i))) {
				if (!in_reserved_words(ident_list.at(i))) {
					sym_table.push_back(ident_list.at(i));
					sym_type.insert(pair<string, int>(ident_list.at(i), 1));
					$$.ids.push_back(ident_list.at(i));
					if (i > 0) {
						$$.code += ".[] " + ident_list.at(i) + ", " + to_string($5) + "\n"; // Code for an integer declaration
					}
					else {
						$$.code += ".[] " + ident_list.at(i) + ", " + to_string($5);
					}
				}
				else {
					yy::parser::syntax_error(@1, "Declaration of variable with same name as a reserved word");
					semantic_error = true;
				}
			}
			else {
				yy::parser::syntax_error(@1, "Redeclaration of variable " + ident_list.at(i));
				semantic_error = true;	
			}
		}
		ident_list.clear(); 
	     }
             | identifiers COLON ARRAY L_SQUARE_BRACKET NUMBER R_SQUARE_BRACKET L_SQUARE_BRACKET NUMBER R_SQUARE_BRACKET OF INTEGER {
		//Variable declaration of a 2-D array
		/*
		if (!in_sym_table($1)) {
			sym_table.push_back($1);
			sym_type.insert(pair<string, int>($1, 2));
		}
		else {
			std::cerr << "Error: redeclaration of variable " << $1 << std::endl;
			semantic_error = true;
		}	
		*/
	     }
	     ;
comp: EQ {$$ = $1;}
      | NEQ {$$ = $1;}
      | LT {$$ = $1;}
      | GT {$$ = $1;}
      | LTE {$$ = $1;}
      | GTE {$$ = $1;}
      ;
var: identifier {
	if (!in_sym_table($1)) {
		yy::parser::syntax_error(@1, "Variable " + $1 + " not declared");
		semantic_error = true;	
	}
	$$.place = find_symbol($1);
	$$.code = "";
     }
     | identifier L_SQUARE_BRACKET expression R_SQUARE_BRACKET {
	// Ensure the identifier is in the symbol table
	if (!in_sym_table($1)) {
		yy::parser::syntax_error(@1, "Variable " + $1 + " not declared");
		semantic_error = true;
	}
	// Ensure the identifier has been declared as an array
	if (sym_type.find($1)->second != 1 || sym_type.find($1)->second != 2) {
		yy::parser::syntax_error(@1, "Attempting to access variable not declared as an array");
		semantic_error = true;
	}
	$$.place = find_symbol($1);
	$$.code += $3.code;
	$$.index = sym_table.at($3.place);
     }
     | identifier L_SQUARE_BRACKET expression R_SQUARE_BRACKET L_SQUARE_BRACKET expression R_SQUARE_BRACKET {std::cout << "var -> identifier L_SQUARE_BRACKET expression R_SQUARE_BRACKET L_SQUARE_BRACKET expression R_SQUARE_BRACKET\n";}
     ;
vars: var {
	//var_list.push_back(sym_table.at($1.place));
      	var_list.push_back($1);
      }
      | var COMMA vars {
	//var_list.push_back(sym_table.at($1.place));
      	var_list.push_back($1);
      }
      ;
term: SUB var {
	temp = newTemp();
	sym_type.insert(pair<string, int>(temp, sym_type.find(sym_table.at($2.place))->second));
	$$.place = find_symbol(temp);
	$$.code = ". " + temp + "\n";
	$$.code += "* " + sym_table.at($2.place) + ", " + sym_table.at($2.place) + ", " + "-" + to_string(1) + "\n";
	$$.code += "= " + temp + ", " + sym_table.at($2.place);
      }
      | SUB NUMBER {
	temp = newTemp();
	sym_type.insert(pair<string, int>(temp, 0));
	$$.place = find_symbol(temp);
	$$.code = ". " + temp + "\n";
	$$.code += "= " + temp + ", " + "-" + to_string($2);
      }
      | SUB L_PAREN expression R_PAREN {
	temp = newTemp();
	sym_type.insert(pair<string, int>(temp, sym_type.find(sym_table.at($3.place))->second));
	$$.place = find_symbol(temp);
	$$.code = $3.code + "\n";
	$$.code += ". " + temp + "\n";
	$$.code += "* " + sym_table.at($3.place) + ", " + sym_table.at($3.place) + ", " + "-" + to_string(1) + "\n";
	$$.code += "= " + temp + ", " + sym_table.at($3.place);	
      }
      | var {
	temp = newTemp();
	sym_type.insert(pair<string, int>(temp, 0));
	$$.place = find_symbol(temp);
	if ($1.code != "") {
		$$.code = $1.code + "\n";
	}
	$$.code += ". " + temp + "\n";
	if (sym_type.find(sym_table.at($1.place))->second == 0) {
		$$.code += "= " + temp + ", " + sym_table.at($1.place);
	}
	else {
		$$.code += "=[] " + temp + ", " + sym_table.at($1.place) + ", " + $1.index;
	}
      }
      | NUMBER {
	temp = newTemp();
	sym_type.insert(pair<string, int>(temp, 0));
	$$.place = find_symbol(temp);
	$$.code = ". " + temp + "\n";
	$$.code += "= " + temp + ", " + to_string($1);
      }
      | L_PAREN expression R_PAREN {
	$$.place = $2.place;
	$$.code = $2.code;
      }
      | identifier L_PAREN expressions R_PAREN { // This indicates a function call
	$$.code = $3.code + "\n";
	$$.code += "param " + sym_table.at($3.place) + "\n";
	temp = newTemp();
	sym_type.insert(pair<string, int>(temp, sym_type.find(sym_table.at($3.place))->second));
	$$.place = find_symbol(temp);
	$$.code += ". " + temp + "\n";
	$$.code += "call " + $1 + ", " + temp;
      }
      ;
expressions: expression COMMA expressions {
		temp = newTemp();
		sym_type.insert(pair<string, int>(temp, sym_type.find(sym_table.at($1.place))->second));
		$$.place = find_symbol(temp);
		$$.code = $1.code + "\n" + $3.code + "\n";
		$$.code += ". " + temp;
	     }
	     | expression {$$.place = $1.place; $$.code = $1.code;}
	     ;
expression: multiplicative_expression {
		$$.place = $1.place;
		$$.code = $1.code;
	    }
            | multiplicative_expression ADD expression {
		temp = newTemp();
		sym_type.insert(pair<string, int>(temp, sym_type.find(sym_table.at($3.place))->second));
		$$.place = find_symbol(temp);
		$$.code = $1.code + "\n" + $3.code + "\n";
		$$.code += ". " + temp + "\n";
		$$.code += "+ " + temp + ", " + sym_table.at($1.place) + ", " + sym_table.at($3.place);
	    }
	    | multiplicative_expression SUB expression {
		temp = newTemp();
		sym_type.insert(pair<string, int>(temp, sym_type.find(sym_table.at($3.place))->second));
		$$.place = find_symbol(temp);
		$$.code = $1.code + "\n" + $3.code + "\n";
		$$.code += ". " + temp + "\n";
		$$.code += "- " + temp + ", " + sym_table.at($1.place) + ", " + sym_table.at($3.place);
	    }
	    ;
multiplicative_expression: term {$$.place = $1.place; $$.code = $1.code;}
			   | term MULT multiplicative_expression {
				temp = newTemp();
				sym_type.insert(pair<string, int>(temp, sym_type.find(sym_table.at($1.place))->second));
				$$.place = find_symbol(temp);
				$$.code = $1.code + "\n" + $3.code + "\n";
				$$.code += ". " + temp + "\n";
				$$.code += "* " + temp + ", " + sym_table.at($1.place) + ", " + sym_table.at($3.place);
			   }
			   | term DIV multiplicative_expression {
				temp = newTemp();
				sym_type.insert(pair<string, int>(temp, sym_type.find(sym_table.at($1.place))->second));
				$$.place = find_symbol(temp);
				$$.code = $1.code + "\n" + $3.code + "\n";
				$$.code += ". " + temp + "\n";
				$$.code += "/ " + temp + ", " + sym_table.at($1.place) + ", " + sym_table.at($3.place);
			   }
                           | term MOD multiplicative_expression {
				temp = newTemp();
				sym_type.insert(pair<string, int>(temp, sym_type.find(sym_table.at($1.place))->second));
				$$.place = find_symbol(temp);
				$$.code = $1.code + "\n" + $3.code + "\n";
				$$.code += ". " + temp + "\n";
				$$.code += "% " + temp + ", " + sym_table.at($1.place) + ", " + sym_table.at($3.place);
			   }
                           ;
relation_expression: TRUE {
			temp = newTemp();
			sym_type.insert(pair<string, int>(temp, 0));
			$$.place = find_symbol(temp);
			$$.code = ". " + temp + "\n";
			$$.code += "= " + temp + ", " + to_string(1);
		     }
 		     | FALSE {
			temp = newTemp();
			sym_type.insert(pair<string, int>(temp, 0));
			$$.place = find_symbol(temp);
			$$.code = ". " + temp + "\n";
			$$.code += "= " + temp + ", " + to_string(0);
		     }
		     | expression comp expression {
			$$.code = $1.code + "\n";
			$$.code += $3.code + "\n";
			texp1 = newTemp();
			sym_type.insert(pair<string, int>(texp1, 0));
			$$.code += ". " + texp1 + "\n";
			if (sym_type.find(sym_table.at($1.place))->second == 1 || sym_type.find(sym_table.at($1.place))->second == 2) {
				$$.code += "=[] " + texp1 + ", " + sym_table.at($1.place) + ", " + $1.index + "\n";
			}
			else {
				$$.code += "= " + texp1 + ", " + sym_table.at($1.place) + "\n";
			}
			texp2 = newTemp();
			sym_type.insert(pair<string, int>(texp2, 0));				
			$$.code += ". " + texp2 + "\n";
			if (sym_type.find(sym_table.at($3.place))->second == 1 || sym_type.find(sym_table.at($3.place))->second == 2) {
				$$.code += "=[] " + texp2 + ", " + sym_table.at($3.place) + ", " + $3.index + "\n";
			}
			else {
				$$.code += "= " + texp2 + ", " + sym_table.at($3.place) + "\n";
			}
			temp = newTemp();
			sym_type.insert(pair<string, int>(temp, 0));
			$$.place = find_symbol(temp);
			$$.code += ". " + temp + "\n";
			if ($2 == "<") {
				$$.code += "< " + temp + ", " + texp1 + ", " + texp2;
			}
			else if ($2 == "<=") {			
				$$.code += "<= " + temp + ", " + texp1 + ", " + texp2;
			}
			else if ($2 == "!=") {
				$$.code += "!= " + temp + ", " + texp1 + ", " + texp2;
			}
			else if ($2 == "==") {
				$$.code += "== " + temp + ", " + texp1 + ", " + texp2;
			}
			else if ($2 == ">=") {
				$$.code += ">= " + temp + ", " + texp1 + ", " + texp2;
			}
			else {
				$$.code += "> " + temp + ", " + texp1 + ", " + texp2;
			}
		     }
		     | L_PAREN bool_expression R_PAREN {
			$$.place = $2.place;
			$$.code = $2.code;
		     }
                     | NOT TRUE {
			temp = newTemp();
			sym_type.insert(pair<string, int>(temp, 0));
			$$.place = find_symbol(temp);
			$$.code = ". " + temp + "\n";
			$$.code = "= " + temp + ", " + to_string(0);
		     }
		     | NOT FALSE {
			temp = newTemp();
			sym_type.insert(pair<string, int>(temp, 0));
			$$.place = find_symbol(temp);
			$$.code = ". " + temp + "\n";
			$$.code += "= " + temp + ", " + to_string(1);
		     }
		     | NOT expression comp expression {
			$$.code = $2.code + "\n";
			$$.code += $4.code + "\n";
			texp1 = newTemp();
			sym_type.insert(pair<string, int>(texp1, 0));
			$$.code += ". " + texp1 + "\n";
			if (sym_type.find(sym_table.at($2.place))->second == 1 || sym_type.find(sym_table.at($2.place))->second == 2) {
				$$.code += "=[] " + texp1 + ", " + sym_table.at($2.place) + ", " + $2.index + "\n";
			}
			else {
				$$.code += "= " + texp1 + ", " + sym_table.at($2.place) + "\n";
			}
			texp2 = newTemp();
			sym_type.insert(pair<string, int>(texp2, 0));				
			$$.code += ". " + texp2 + "\n";
			if (sym_type.find(sym_table.at($4.place))->second == 1 || sym_type.find(sym_table.at($4.place))->second == 2) {
				$$.code += "=[] " + texp2 + ", " + sym_table.at($4.place) + ", " + $4.index + "\n";
			}
			else {
				$$.code += "= " + texp2 + ", " + sym_table.at($4.place) + "\n";
			}
			temp = newTemp();
			sym_type.insert(pair<string, int>(temp, 0));
			$$.place = find_symbol(temp);
			$$.code += ". " + temp + "\n";
			if ($3 == "<") {
				$$.code += "< " + temp + ", " + texp1 + ", " + texp2;
			}
			else if ($3 == "<=") {			
				$$.code += "<= " + temp + ", " + texp1 + ", " + texp2;
			}
			else if ($3 == "!=") {
				$$.code += "!= " + temp + ", " + texp1 + ", " + texp2;
			}
			else if ($3 == "==") {
				$$.code += "== " + temp + ", " + texp1 + ", " + texp2;
			}
			else if ($3 == ">=") {
				$$.code += ">= " + temp + ", " + texp1 + ", " + texp2;
			}
			else {
				$$.code += "> " + temp + ", " + texp1 + ", " + texp2;
			}
			temp = newTemp();
			sym_type.insert(pair<string, int>(temp, sym_type.find(sym_table.at($$.place))->second));
			$$.code += ". " + temp + "\n";
			$$.code += "! " + temp + ", " + sym_table.at($$.place);
			$$.place = find_symbol(temp);
		     }
		     | NOT L_PAREN bool_expression R_PAREN {
			temp = newTemp();
			sym_type.insert(pair<string, int>(temp, sym_type.find(sym_table.at($3.place))->second));
			$$.place = find_symbol(temp);
			$$.code = $3.code + "\n";
			$$.code += ". " + temp + "\n";
			$$.code += "! " + temp + ", " + sym_table.at($3.place);
		     }
		     ;
relation_and_expression: relation_expression {$$.place = $1.place; $$.code = $1.code;}
			 | relation_expression AND relation_and_expression {
			 	temp = newTemp();
				$$.place = find_symbol(temp);
				sym_type.insert(pair<string, int>(temp, sym_type.find(sym_table.at($1.place))->second));
				$$.code = $1.code + "\n";
				$$.code += $3.code + "\n";
				$$.code += ". " + temp + "\n"; // Declare the new temp
				$$.code += "&& " + temp + "," + sym_table.at($1.place) + "," + sym_table.at($3.place); // Assign the value to the new temp
			 }
			 ;
bool_expression: relation_and_expression {$$.place = $1.place; $$.code = $1.code;}
	    	 | relation_and_expression OR relation_and_expression {
		 	temp = newTemp();
			$$.place = find_symbol(temp);
			sym_type.insert(pair<string, int>(temp, sym_type.find(sym_table.at($1.place))->second));
			$$.code = $1.code + "\n";
			$$.code += $3.code + "\n";
			$$.code += ". " + temp + "\n"; // Declare the new temp
			$$.code += "|| " + temp + "," + sym_table.at($1.place) + "," + sym_table.at($3.place); // Assign the value to the new temp
		 }
		 ;
statements: statement SEMICOLON statements {
		//$$.begin = $1.begin;
		//$$.after = $3.after;
		$$.begin = $1.begin;
		$$.code = $1.code;
		if ($1.has_continue) {
			if ($3.after != "") {
				$$.code += "\n";
				$$.code += ":= " + $3.after + "\n";
			}
		}
		if ($3.code != "") {
			if (!$1.has_continue) {
				$$.code += "\n" + $3.code;
			}		
			else {
				$$.code += $3.code;
			}
			$$.after = $3.after;
			if ($3.has_continue) {
				$$.code += "\n";
				$$.code += ":= " + $$.after;
			}
		}
		else {
			$$.after = $1.after;
		}
	    }
	    | /* epsilon */ {
	    }
	    ;
statement: var ASSIGN expression {
		$$.begin = newLabel();
		$$.after = newLabel();
		$$.code = ": " + $$.begin + "\n";
		if($1.code != "") {
			$$.code += $1.code + "\n";
		}
		$$.code += $3.code + "\n";
		if (sym_type.find(sym_table.at($1.place))->second == 0) {	
			if (sym_type.find(sym_table.at($3.place))->second == 1 || sym_type.find(sym_table.at($3.place))->second == 2) {
				// Assigning something of the form x = a[i]
				$$.code = "=[] " + sym_table.at($1.place) + ", " + sym_table.at($3.place) + ", " + $3.index + "\n";
			}
			else {
				// Assigning somethng of the form x = y
				$$.code += "= " + sym_table.at($1.place) + "," + sym_table.at($3.place) + "\n";
			}
		}
		else if (sym_type.find(sym_table.at($1.place))->second == 1 || sym_type.find(sym_table.at($1.place))->second == 2) {
			// Assigning something of the form a[i] = x	
			$$.code += "[]= " + sym_table.at($1.place) + ", " + $1.index + ", " + sym_table.at($3.place) + "\n";
		}
		else {
			yy::parser::syntax_error(@1, "Invalid assignment statement");
			semantic_error = true;
		}
		$$.code += ": " + $$.after;
	   }
	   | IF bool_expression THEN statements ENDIF {
		$$.begin = newLabel();
		$$.after = newLabel();
		$$.code = ": " + $$.begin + "\n";
		$$.code += $2.code + "\n";
		$$.code += "?:= " + $4.begin + ", " + sym_table.at($2.place) + "\n";
		$$.code += ":= " + $4.after + "\n";
		$$.code += $4.code + "\n";
	   	$$.code += ": " + $$.after;
	   }
	   | IF bool_expression THEN statements ELSE statements ENDIF {
	   	$$.begin = newLabel();
		$$.after = newLabel();
		$$.code = ": " + $$.begin + "\n";
		$$.code += $2.code + "\n";
		$$.code += "?:= " + $4.begin + ", " + sym_table.at($2.place) + "\n";
		$$.code += $6.code + "\n"; // Execute the ELSE statements if above is false
		$$.code += ":= " + $$.after + "\n";
		$$.code += $4.code + "\n"; // Goto THEN statements
		$$.code += ": " + $$.after;
	   }
	   | WHILE bool_expression BEGINLOOP statements ENDLOOP {
	   	$$.begin = newLabel();
		$$.after = newLabel();
		$$.code = ": " + $$.begin + "\n";
		$$.code += $2.code + "\n";
		$$.code += "?:= " + $4.begin + ", " + sym_table.at($2.place) + "\n";
		$$.code += ":= " + $$.after + "\n";
		$$.code += $4.code + "\n";
		$$.code += ":= " + $$.begin + "\n";
		$$.code += ": " + $$.after;
	   }
	   | DO BEGINLOOP statements ENDLOOP WHILE bool_expression {
		$$.begin = newLabel();
		$$.after = newLabel();
		$$.code = ": " + $$.begin + "\n";
		$$.code += $3.code + "\n";
		$$.code += $6.code + "\n";
		$$.code += "?:= " + $$.begin + ", " + sym_table.at($6.place) + "\n";
		$$.code += ": " + $$.after;
	   }
	   | FOR var ASSIGN NUMBER SEMICOLON bool_expression SEMICOLON var ASSIGN expression BEGINLOOP statements ENDLOOP {
		$$.begin = newLabel();
		$$.after = newLabel();
		$$.code = ": " + $$.begin + "\n";
		// var ASSIGN NUMBER code
		if($2.code != "") {
			$$.code += $2.code + "\n";
		}
		if (sym_type.find(sym_table.at($2.place))->second == 0) {	
			// Assigning somethng of the form x = y
			$$.code += "= " + sym_table.at($2.place) + "," + to_string($4) + "\n";
		}
		else if (sym_type.find(sym_table.at($2.place))->second == 1 || sym_type.find(sym_table.at($2.place))->second == 2) {
			// Assigning something of the form a[i] = x	
			$$.code += "[]= " + sym_table.at($2.place) + ", " + $2.index + ", " + to_string($4) + "\n";
		}
		else {
			yy::parser::syntax_error(@1, "Invalid assignment statement");
			semantic_error = true;
		}
		// code for bool expression
		$$.code += $6.code + "\n";
		$$.code += "?:= " + $12.begin + ", " + sym_table.at($6.place) + "\n";
		$$.code += ":= " + $$.after + "\n";
		// code for var ASSIGN expression
		if($8.code != "") {
			$$.code += $8.code + "\n";
		}
		$$.code += $10.code + "\n";
		if (sym_type.find(sym_table.at($8.place))->second == 0) {	
			if (sym_type.find(sym_table.at($10.place))->second == 1 || sym_type.find(sym_table.at($10.place))->second == 2) {
				// Assigning something of the form x = a[i]
				$$.code = "=[] " + sym_table.at($8.place) + ", " + sym_table.at($10.place) + ", " + $10.index + "\n";
			}
			else {
				// Assigning somethng of the form x = y
				$$.code += "= " + sym_table.at($8.place) + "," + sym_table.at($10.place) + "\n";
			}
		}
		else if (sym_type.find(sym_table.at($8.place))->second == 1 || sym_type.find(sym_table.at($8.place))->second == 2) {
			// Assigning something of the form a[i] = x	
			$$.code += "[]= " + sym_table.at($8.place) + ", " + $8.index + ", " + sym_table.at($10.place) + "\n";
		}
		else {
			yy::parser::syntax_error(@1, "Invalid assignment statement");
			semantic_error = true;
		}
		$$.code += ": " + $$.after;
	   }
	   | READ vars {
		$$.begin = newLabel();
		$$.after = newLabel();
		$$.code = ": " + $$.begin + "\n";
		for (int i = var_list.size() - 1; i >= 0; --i) {
			if (in_sym_table(sym_table.at(var_list.at(i).place))) {
				if (var_list.at(i).code != "") {
					$$.code += var_list.at(i).code + "\n";
				}
				if (sym_type.find(sym_table.at(var_list.at(i).place))->second == 0) {
					$$.code += ".< " + sym_table.at(var_list.at(i).place) + "\n";
				}
				else if (sym_type.find(sym_table.at(var_list.at(i).place))->second == 1) {
					$$.code += ".[]< " + sym_table.at(var_list.at(i).place) + ", " + var_list.at(i).index + "\n";
				}
			}	
			else {
				yy::parser::syntax_error(@2, "variable " + sym_table.at(var_list.at(i).place) + " not declared");
				semantic_error = true;
			}	
		}
		$$.code += ": " + $$.after;
		var_list.clear();	
	   }
	   | WRITE vars {
		$$.begin = newLabel();
		$$.after = newLabel();
		$$.code = ": " + $$.begin + "\n";
		for (int i = var_list.size() - 1; i>= 0; --i) {
			if (in_sym_table(sym_table.at(var_list.at(i).place))) {
				if (var_list.at(i).code != "") {
					$$.code += var_list.at(i).code + "\n";
				}
				if (sym_type.find(sym_table.at(var_list.at(i).place))->second == 0) {
					$$.code += ".> " + sym_table.at(var_list.at(i).place) + "\n";
				}
				else if (sym_type.find(sym_table.at(var_list.at(i).place))->second == 1) {
					$$.code += ".[]> " + sym_table.at(var_list.at(i).place) + ", " + var_list.at(i).index + "\n";
				}
			}	
			else {
				yy::parser::syntax_error(@2, "variable " + ident_list.at(i) + " not declared");
				semantic_error = true;
			}	
		}
		$$.code += ": " + $$.after;
		var_list.clear();	
	   }
	   | CONTINUE {
		$$.begin = newLabel();
		$$.after = newLabel();
		$$.code = ": " + $$.begin + "\n";
		$$.has_continue = true;
		$$.code += ": " + $$.after;
	   }
	   | RETURN expression {
		$$.begin = newLabel();
		$$.after = newLabel();
		$$.code = ": " + $$.begin + "\n";
		$$.code += $2.code + "\n";
		$$.code += "ret " + sym_table.at($2.place) + "\n";
		$$.code += ": " + $$.after;	
	   }
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
bool in_reserved_words(string word) {
	for (int i = 0; i < reserved_words.size(); ++i) {
		if (reserved_words.at(i) == word) {
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
	tempLabel = "_label_" + to_string(tempLabIndex);
	++tempLabIndex;
	label_table.push_back(tempLabel);
	return tempLabel;
}
	
