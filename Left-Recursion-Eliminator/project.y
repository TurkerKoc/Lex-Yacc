%{
    #include <stdio.h>
	#include <string.h>
	#include <stdlib.h>
	#include "y.tab.h"
    void yyerror(char *);
    int yylex(void);
    extern FILE *yyin;
    extern int linenum;


	#include <vector>
	#include <string>
	#include <iostream>
	#include <fstream>
	using namespace std;

	class leftRecursion //class for creating left recursion objects 
	{
	public:
		string ident; //name of nonterminal which has left recursion
		string rhsAfter; //terminals and nonterminals on the rhs after left recursion
		vector<string> otherLines; //rhs of the other lines that has the same nonterminal ident on the LHS
		vector<string> otherLRrhsAfter; //other lines that has the same nonterminal on the LHS with left recursion again(record their rhs for elimination)
	};

	vector<leftRecursion> leftRecursions; //vector of leftRecursions
	void addLR(string); //create an object of nonterminal with left recursion an put it in leftRecursions vector
	int isLRExist(string); //is left recursion of current nonterminal is exist(if not directly write to output file) return index in leftRecursions array
	string curLRNT=""; //ident of the curren lr
	void eliminateLR(); //eliminating left recursion and writing into output file
	void addExistLR(int i); //add left recursion to exist LR's otherLRrhsAfter vector 
	void writeDirectly(string); //if there is no left recursion write directly into output file

	vector<string> RHS; //assigned terminals and nonterminals on the rhs of any line
	//int RHSSize=0;	

	ofstream outputFile; //for writing output
	void openFile(string);
	void writeLinetoFile(string);
	void closeFile();



	

%}
%union
{
char *str;
}
%token <str> EPSILON NONTERMINAL ASSIGN TERMINAL
%type <str> righths
%token NEWLINE

%%
program:
		statement
		|
		statement program
		;
statement:
		NONTERMINAL ASSIGN righths NEWLINE
		{
			printf("%s %s ",$1,$2);
			for(int i=0;i<RHS.size();i++)
			{
				cout<<RHS[i]<<" ";
			}
			cout<<endl;
			if(RHS[0]!=$1) //if there is no left recursion
			{
				cout<<"checking isLRExist\n";
				int res=isLRExist(string($1));//if lr of current nonterminal is already exist it will return index in leftRecursions
				if(res!=-1) //means lr of current nt is already exist so put rhs in otherLines of lr
				{
					cout<<"exist\n";
					string temp;
					for(int i=0;i<RHS.size();i++) //putting terminals and nonterminals of rhs into a string
					{
						temp += RHS[i]+" ";
					}
					leftRecursions[res].otherLines.push_back(temp); //put that string into lr.otherlines
				}
				else //Left recursion of current nonterminal is not exist so directly write into output file
				{
					if(curLRNT!="") //is previous lr is not eliminated
					{
						eliminateLR(); //eliminate it and write into output file
						curLRNT=""; //current LR elimination is done
					}
					writeDirectly(string($1)); //write current nt directly to the output file
				}
			}
			else //if current nonterminal is leftRecursion
			{
				cout<<"adding LR\n";
				int res=isLRExist(string($1));//if lr is already exist it will return index in leftRecursions
				if(res!=-1) //this left recursion found before
					addExistLR(res); //put rhs of nonterminal into otherLRrhsAfter
				else //new left Recursion
				{
					if(curLRNT!="") //is previous lr is not eliminated
					{
						eliminateLR(); //eliminate it and write into output file
						cout<<"elimination done!\n";
						curLRNT=""; //current LR elimination is done
					}
					addLR(string($1)); //add new lr into leftRecursions vector
				}
				curLRNT = leftRecursions.back().ident; //curLR
			}
			RHS.clear(); //done with current line clear RHS vector
		}
		|
		NONTERMINAL ASSIGN EPSILON NEWLINE
		{
			printf("%s %s %s\n",$1,$2,$3);
			if(curLRNT!="") //is previous lr is not eliminated
			{
				eliminateLR(); //eliminate it and write into output file
				curLRNT=""; //current LR elimination is done
			}
			writeLinetoFile(string($1)+" -> epsilon"); //write line directly to the output file
			
		}
		;
righths:
		NONTERMINAL righths {
			RHS.insert(RHS.begin(),string($1)); //push current lines rhs nonterminals and terminal into RHS vector
		}
		|
		TERMINAL righths {
			RHS.insert(RHS.begin(),string($1));//push current lines rhs nonterminals and terminal into RHS vector
		}
		|
		NONTERMINAL {
			RHS.insert(RHS.begin(),string($1));//push current lines rhs nonterminals and terminal into RHS vector
		}
		|
		TERMINAL {
			RHS.insert(RHS.begin(),string($1));//push current lines rhs nonterminals and terminal into RHS vector
		}
		;
%%
void addExistLR(int i) //add left recursion to exist LR's otherLRrhsAfter vector 
{
	string temp;
	for(int i=1;i<RHS.size();i++) //write rhs after first nonterminal into a string
	{
		 temp += RHS[i]+" ";
	}
	cout<<"Adding already exist LR: "<<leftRecursions[i].ident<<": "<<temp<<endl;
	leftRecursions[i].otherLRrhsAfter.push_back(temp); //push that string into otherLRrhsAfter of curren left Recursion
}
void eliminateLR() //eliminate last LR in leftRecursions vector
{
	leftRecursion curLR = leftRecursions.back(); //current left recursion
	string newNT = "<"+curLR.ident.substr(1,curLR.ident.size()-2)+"2"+">"; //creating new nonterminals name (by adding 2 into end) 
	for(int i=0;i<curLR.otherLines.size();i++) //first output lines that has no lr but same nonterminal ident by adding newNT into end
		writeLinetoFile(curLR.ident + " -> "+curLR.otherLines[i]+newNT);
	writeLinetoFile(newNT+" -> epsilon"); //write epsilon line
	writeLinetoFile(newNT+" -> "+curLR.rhsAfter+newNT); //write eliminated lr
	if(!curLR.otherLRrhsAfter.empty()) //if there are multiple leftRecursion with same ident
	{
		for(int i=0;i<curLR.otherLRrhsAfter.size();i++) //eliminate other leftRecursions
			writeLinetoFile(newNT+" -> "+curLR.otherLRrhsAfter[i]+newNT);
	}

}
void addLR(string nt) //nt(NONTERMINAL)
{
	leftRecursion newLR; //create object of new leftRecursion
	newLR.ident = nt;
	for(int i=1;i<RHS.size();i++)
	{
		newLR.rhsAfter += RHS[i]+" ";
	}
	leftRecursions.push_back(newLR); //put it into leftRecursions vector

	
}
int isLRExist(string nt) //nt(NONTERMINAL)
{
	cout<<"here: "<<nt<<endl;
	for(int i=0;i<leftRecursions.size();i++)
	{
		if(leftRecursions[i].ident==nt)
		{
			return i; //exist return index in vector
		}
	}
	return -1; //not exist return -1;
}
void writeDirectly(string d1) //$1(NONTERMINAL)
{
	string temp = d1+" -> ";
	for(int i=0;i<RHS.size();i++)
	{
		temp += RHS[i]+" ";
	}
	writeLinetoFile(temp); //write current line directly
}
void openFile(string fileName){
	outputFile.open(fileName);
}

void writeLinetoFile(string str){
	outputFile<<str<<endl;
}

void closeFile(){
	outputFile.close();
}
void yyerror(char *s) 
{
    printf("Syntax error in line %d!! Parser stopped now.\n",linenum+1);
	exit(0);
}
int yywrap(){
	return 1;
}
int main(int argc, char *argv[])
{
    yyin=fopen(argv[1],"r");
	openFile("output.txt");
	
    yyparse();
	//for(int i=0;i<RHS.size();i++)
		//cout<<RHS[i];
	
	if(curLRNT!="") //if last lines has leftRecursion eliminate it too
	{
		eliminateLR();
		curLRNT=""; //current LR elimination is done
	}
	cout<<"LeftRecursions:\n";
	for(int i=0;i<leftRecursions.size();i++)
	{
		cout<<leftRecursions[i].ident<<" ";
		cout<<leftRecursions[i].rhsAfter<<endl;
		cout<<leftRecursions[i].otherLines[0]<<endl;
	}
	closeFile();

	printf("No violation !! Parser finished without error !!!\n");
    fclose(yyin);
    return 0;
}
