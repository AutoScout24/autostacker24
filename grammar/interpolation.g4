grammar interpolation;

ID    : [a-zA-Z0-9]+;
FILE  : '@file://';
WS : ' '*;

//ESC : '@' '@'| '[' | ']' | '.' | ':' ;
//RAW: ~['@']+ ;
//string: RAW expr RAW;

expr: '@' name (attr+ | map)?;
name: ID ('::' ID)?;
attr: ('.' ID)+;
map: '[' key (',' WS key)? ']';
key: ID | expr;




