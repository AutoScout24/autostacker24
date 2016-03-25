grammar interpolation;


fragment
ID    : [a-zA-Z0-9]+;
//AT    : '@';
LEFT  : '[';
RIGHT : ']';
COMMA : ',' ' '*;
DOT   : '.';
FILE  : '@file://';

//ESC : '@' '@'| '[' | ']' | '.' | ':' ;
//RAW: ~['@']+ ;

expr: NAME (ATTR | mapping)?;

mapping: LEFT key (COMMA key)?  RIGHT;

key: ID | expr;

string: RAW expr RAW;

NAME : '@' ID ('::' ID)+;
ATTR : (DOT ID)+;
