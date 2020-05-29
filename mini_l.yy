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
	};
	struct stmt_struct {
		string begin;
		string after;
		string code;
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
	vector<string> sym_table;
	map<string, int> sym_type; /* 0 = integer, 1 = 1-D array, 2 = 2-D array, 3 = function */
	vector<string> label_table;
	vector<string> ident_list;
	vector<string> var_list;
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
			//FIXME: if (!semantic_error) {
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
		/* Variable declaration of type integer */
		for (int i = 0; i < ident_list.size(); ++i) {	
			if (!in_sym_table(ident_list.at(i))) {
				if (!in_reserved_words(ident_list.at(i))) {
					sym_table.push_back(ident_list.at(i));
					sym_type.insert(pair<string, int>(ident_list.at(i), 0));
					$$.ids.push_back(ident_list.at(i));
					if (i < ident_list.size() - 1) {
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
		//Variable declaration of a 1-D array 
		/*
		if (!in_sym_table($1)) {
			sym_table.push_back($1);
			sym_type.insert(pair<string, int>($1, 1));
			$$ = ".[] " + $1 + "," + to_string($5);
		}
		else {
			std::cerr << "Error: redeclaration of variable " << $1 << std::endl;
			semantic_error = true;
		}
		*/
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
     | identifier L_SQUARE_BRACKET expression R_SQUARE_BRACKET {std::cout << "var -> identifier L_SQUARE_BRACKET expression R_SQUARE_BRACKET\n";}
     | identifier L_SQUARE_BRACKET expression R_SQUARE_BRACKET L_SQUARE_BRACKET expression R_SQUARE_BRACKET {std::cout << "var -> identifier L_SQUARE_BRACKET expression R_SQUARE_BRACKET L_SQUARE_BRACKET expression R_SQUARE_BRACKET\n";}
     ;
vars: var {
	var_list.push_back(sym_table.at($1.place));
      }
      | var COMMA vars {
	var_list.push_back(sym_table.at($1.place));
      }
      ;
term: SUB var {
      }
      | SUB NUMBER {std::cout << "term -> SUB NUMBER\n";}
      | SUB L_PAREN expression R_PAREN {std::cout << "term -> SUB L_PAREN expression R_PAREN\n";}
      | var {
	temp = newTemp();
	sym_type.insert(pair<string, int>(temp, sym_type.find(sym_table.at($1.place))->second));
	$$.place = find_symbol(temp);
	$$.code = ". " + temp + "\n"; // Declare the new temp
	$$.code += "= " + temp + ", " + sym_table.at($1.place);
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
		$$.code = $1.code + "\n" + $3.code;
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
			   | term MULT multiplicative_expression {std::cout << "multiplicative_expression -> term MULT multiplicative_expression\n";}
			   | term DIV multiplicative_expression {std::cout << "multiplicative_expression -> term DIV multiplicative_expression\n";}
                           | term MOD multiplicative_expression {std::cout << "multiplicative_expression -> term MOD multiplicative_expression\n";}
                           ;
relation_expression: TRUE {std::cout << "relation_expression -> TRUE\n";}
 		     | FALSE {std::cout << "relation_expression -> FALSE\n";}
		     | expression comp expression {
			temp = newTemp();
			$$.place = find_symbol(temp);
			sym_type.insert(pair<string, int>(temp, sym_type.find(sym_table.at($1.place))->second)); // Update the symbol type for the new temproary with E1 type
			$$.code = $1.code + "\n";
			$$.code += $3.code + "\n";
			$$.code += ". " + temp + "\n"; // Declare the new temp
			if ($2 == "<") {
				$$.code += "< " + temp + ", " + sym_table.at($1.place) + ", " + sym_table.at($3.place);
			}
			else if ($2 == "<=") {			
				$$.code += "<= " + temp + ", " + sym_table.at($1.place) + ", " + sym_table.at($3.place);
			}
			else if ($2 == "!=") {
				$$.code += "!= " + temp + ", " + sym_table.at($1.place) + ", " + sym_table.at($3.place);
			}
			else if ($2 == "==") {
				$$.code += "== " + temp + ", " + sym_table.at($1.place) + ", " + sym_table.at($3.place);
			}
			else if ($2 == ">=") {
				$$.code += ">= " + temp + ", " + sym_table.at($1.place) + ", " + sym_table.at($3.place);
			}
			else {
				$$.code += "> " + temp + ", " + sym_table.at($1.place) + ", " + sym_table.at($3.place);
			}
		     }
		     | L_PAREN bool_expression R_PAREN {
			$$.place = $2.place;
			$$.code = $2.code;
		     }
                     | NOT TRUE {std::cout << "relation_expression -> NOT TRUE\n";}
		     | NOT FALSE {std::cout << "relation_expression -> NOT FALSE\n";}
		     | NOT expression comp expression {std::cout << "relation_expression -> NOT expression comp expression\n";}
		     | NOT L_PAREN bool_expression R_PAREN {std::cout << "relation_expression -> NOT L_PAREN bool_expression R_PAREN\n";}
		     ;
relation_and_expression: relation_expression {$$.place = $1.place; $$.code = $1.code;}
			 | relation_expression AND relation_and_expression {
			 	temp = newTemp();
				$$.place = find_symbol(temp);
				sym_type.insert(pair<string, int>(temp, sym_type.find(sym_table.at($1.place))->second));
				$$.code = $1.code + "\n";
				$$.code += $3.code + "\n";
				$$.code += ". " + temp; // Declare the new temp
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
			$$.code += ". " + temp; // Declare the new temp
			$$.code += "|| " + temp + "," + sym_table.at($1.place) + "," + sym_table.at($3.place); // Assign the value to the new temp
		 }
		 ;
statements: statement SEMICOLON statements {
		//$$.begin = $1.begin;
		//$$.after = $3.after;
		$$.code = $1.code;
		if ($3.code != "") {
			$$.code += "\n" + $3.code;
		}
	    }
	    | /* epsilon */ {
	    	$$.begin = "";
		$$.after = "";
		$$.code = "";
	    }
	    ;
statement: var ASSIGN expression {
		//$$.code = $1.code + "\n";
		$$.code += $3.code + "\n";
		$$.code += "= " + sym_table.at($1.place) + "," + sym_table.at($3.place);
	   }
	   | IF bool_expression THEN statements ENDIF {
		$$.code = $2.code + "\n";
		$$.begin = newLabel();
		$$.after = newLabel();
		$$.code += "?:= " + $$.begin + ", " + sym_table.at($2.place) + "\n";
		$$.code += ":= " + $$.after + "\n";
		$$.code += ": " + $$.begin + "\n";
		$$.code += $4.code + "\n";
		$$.code += ": " + $$.after; 
		/*FIXME: adjust this code
		label = newLabel();
		$$.begin = label;
		$$.code = ": " + label + "\n"; // Declare the label for statement.begin
		$$.code += $2.code + "\n"; // Evaluate expression
		temp = newTemp();
		sym_type.insert(pair<string, int>(temp, sym_type.find(sym_table.at($2.place))->second));
		$$.code += ". " + temp + "\n"; // Declare the new variable
		$$.code += "= " + temp + "," + sym_table.at($2.place) + "\n"; // Copy value bool_expression to new variable
		$$.code += "! " + temp + "," + temp + "\n"; // Negate the value of bool_expression
		$$.code += "?:= " + $4.after + "," + temp + "\n"; // Go statement.after if not true
		$$.code += $4.code + "\n";
		label = newLabel();
		$$.after = label;
		$$.code += ":= " + $$.after + "\n";
		$$.code += ": " + $$.after;
		*/
	   }
	   | IF bool_expression THEN statements ELSE statements ENDIF {std::cout << "statement -> IF bool_expression THEN statements ELSE statements ENDIF\n";}
	   | WHILE bool_expression BEGINLOOP statements ENDLOOP {std::cout << "statement -> WHILE bool_expression BEGINLOOP statements ENDLOOP\n";}
	   | DO BEGINLOOP statements ENDLOOP WHILE bool_expression {std::cout << "statement -> DO BEGINLOOP statements ENDLOOP WHILE bool_expression\n";}
	   | FOR var ASSIGN NUMBER SEMICOLON bool_expression SEMICOLON var ASSIGN expression BEGINLOOP statements ENDLOOP {std::cout << "FOR var ASSIGN NUMBER SEMICOLON bool_expression SEMICOLON var ASSIGN expression BEGINLOOP statements ENDLOOP\n";}
	   | READ vars {
		for (int i = 0; i < var_list.size(); ++i) {
			if (in_sym_table(var_list.at(i))) {
				if (sym_type.find(var_list.at(i))->second == 0) {
					if (i < var_list.size() - 1) {
						$$.code += ".< " + var_list.at(i) + "\n";
					}
					else {
						$$.code += ".< " + var_list.at(i);
					}
				}
				else if (sym_type.find(var_list.at(i))->second == 1) {
					if (i < var_list.size() - 1) {
						$$.code += ".[]< " + var_list.at(i) + "\n";
					}
					else {
						$$.code += ".[]< " + var_list.at(i);
					}
				}
			}	
			else {
				yy::parser::syntax_error(@2, "variable " + ident_list.at(i) + " not declared");
				semantic_error = true;
			}	
		}
		var_list.clear();	
	   }
	   | WRITE vars {
		for (int i = 0; i < var_list.size(); ++i) {
			if (in_sym_table(var_list.at(i))) {
				if (sym_type.find(var_list.at(i))->second == 0) {
					if (i < var_list.size() - 1) {
						$$.code += ".> " + var_list.at(i) + "\n";
					}
					else {
						$$.code += ".> " + var_list.at(i);
					}
				}
				else if (sym_type.find(var_list.at(i))->second == 1) {
					if (i < var_list.size() - 1) {
						$$.code += ".[]> " + var_list.at(i) + "\n";
					}
					else {
						$$.code += ".[]> " + var_list.at(i);
					}
				}
			}	
			else {
				yy::parser::syntax_error(@2, "variable " + ident_list.at(i) + " not declared");
				semantic_error = true;
			}	
		}
		var_list.clear();	
	   }
	   | CONTINUE {std::cout << "statement -> CONTINUE\n";}
	   | RETURN expression {
		$$.code = $2.code + "\n";
		$$.code += "ret " + sym_table.at($2.place);	
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
	
