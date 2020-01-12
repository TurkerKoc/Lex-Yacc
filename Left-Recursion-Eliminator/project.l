digit   [0-9]
letter  [A-Za-z]
lowerLetter [a-z]
upperLetter [A-Z]
%{
#include <stdio.h>
#include <string.h>
#include "y.tab.h"
int linenum;
%}

%%
"epsilon" {yylval.str = strdup(yytext);return EPSILON;}
\<{upperLetter}{letter}*\> {yylval.str = strdup(yytext);return NONTERMINAL;}
\-\> {yylval.str = strdup(yytext);return ASSIGN;}
{lowerLetter}{letter}* {yylval.str = strdup(yytext);return TERMINAL;}
\n {linenum++; return NEWLINE;}
[ \t]+
%%

