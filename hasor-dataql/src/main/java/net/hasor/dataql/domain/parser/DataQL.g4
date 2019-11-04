// Define a grammar called Hello
grammar DataQL;

/* skip spaces */
WS      : [ \t\n\r\f]+ -> skip ; // skip spaces, (空格\水平制表符\换行\回车\换页)
COMMENT1: '//' (~[\n\r])* EOL? -> skip ;
COMMENT2: '/*' ()* '*/' -> skip ;
EOL     : [\n\r\f];

/* key words */
IF      : 'if';
ELSEIF  : 'elseif';
ELSE    : 'else';
END     : 'end';
RETURN  : 'return';
THROW   : 'throw';
EXIT    : 'exit';
VAR     : 'var';
OPTION  : 'option';
IMPORT  : 'import';
TRUE    : 'true';
FALSE   : 'false';
NULL    : 'null';
AS      : 'as';

/* arithmetic operators 算数运算 */
PLUS    : '+';      // 加法
MINUS   : '-';      // 减法
MUL     : '*';      // 乘法
DIV     : '/';      // 除法
DIV2    : '\\';     // 整除
MOD     : '%';      // 取摸
LBT     : '(';      // 优先级
RBT     : ')';      // 优先级
AND     : '&';      // 按位于运算
OR      : '|';      // 按位或运算
NOT     : '!';      // 按位取反
XOR     : '^';      // 异或
LSHIFT  : '<<';     // 左位移
RSHIFT  : '>>';     // 有符号右位移
RSHIFT2 : '>>>';    // 无符号右位移

/* logic operators 逻辑运算 */
GT      : '>';      // 大于
GE      : '>=';     // 大于等于
LT      : '<';      // 小于
LE      : '<=';     // 小于等于
EQ      : '==';     // 等于
NE      : '!=';     // 不等于
SC_OR   : '||';     // 逻辑或
SC_AND  : '&&';     // 逻辑与

/* assist words 连接符在某些特定场景下使用 */
COMMA   : ',';      // 参数\分割项
COLON   : ':';      // Object 类型中使用
ASS     : '=';      // 赋值
DOT     : '.';      //
LSBT    : '[';      // 数组 or 下标
RSBT    : ']';      // 数组 or 下标
OCBR    : '{';      // 表示为一个对象
CCBR    : '}';      // 表示为一个对象
ROU     : [#$];     // 路由限定符
/* 字符串 */


STRING           : '"' (~["\r\n] | '""' | TRANS)* '"'
                 | '\'' (~['\r\n] | '\'\'' | TRANS)* '\''
                 ;
fragment TRANS   : '\\' (['"\\/bfnrt] | UNICODE);
fragment UNICODE : 'u' HEX HEX HEX HEX;
fragment HEX     : [0-9a-fA-F];

/* 数字 */
DECIMAL_NUM     : SYMBOL? [0-9]* '.' [0-9]+     // 浮点数
                  ([eE] SYMBOL? [1-9][0-9]*)?;  // 浮点数-科学计数法
INTEGER_NUM     : SYMBOL? [0-9]+;               // 十进制数：-0000234 or 123
HEX_NUM         : '0' [xX] [0-9a-fA-F]+;        // 十六进制：0x12345
OCT_NUM         : '0' [oO] [0-7]+;              // 八 进 制：0o1234567
BIT_NUM         : '0' [bB] [01]+;               // 二 进 制：0b01010101100
fragment SYMBOL : [+-];

/* 标识符 */
IDENTIFIER      : [_a-zA-Z] [_0-9a-zA-Z]*;

/* ----------------------------------------------------------------------------------- 语句 & 命令 */
/* 入口 */
rootBlockSet    : optionBlock* importBlock* blockSet+ EOF;

/* 选项指令 */
optionBlock     : OPTION IDENTIFIER ASS primitiveValue;

/* import指令 */
importBlock     : IMPORT '@'? STRING AS IDENTIFIER;

/* 语句块 */
blockSet        : OCBR (blockItem (';')?)+ CCBR // 多行语句
                | blockItem (';')?              // 单行语句
                ;


/* 语句 */
blockItem   : varBlock      // var 语句
            | ifBlock       // if 语句
            | breakBlock    // 退出语句
            ;

/* var 语句 var aaa = ... */
varBlock    : VAR IDENTIFIER ASS (polymericObject | lambdaDef);

/* if 语句 */
ifBlock     : IF LBT expr RBT blockSet (ELSEIF LBT expr RBT blockSet)* (ELSE blockSet)? END;

/* 退出 语句 */
breakBlock  : (RETURN | THROW | EXIT) (INTEGER_NUM COMMA)? (polymericObject | lambdaDef);

/* 可以作为：参数、返回值 并带有 具有结构的 */
polymericObject : functionCallConvertValue | routeConvertValue | objectValue | listValue | expr | primitiveValue;

/* lambda函数声明 */
lambdaDef   : LBT ( IDENTIFIER (COMMA IDENTIFIER)* )? RBT '->' blockSet;

/* ----------------------------------------------------------------------------------- 带有结构的 */
/* 对象结构 */
objectValue             : OCBR objectValueItem? ( COMMA objectValueItem)* CCBR;
objectValueItem         : STRING ( COLON polymericObject)?;

/* 列表结构 */
listValue               : LSBT polymericObject? (COMMA polymericObject)* RSBT;

/* 函数调用并转换成：列表 or 对象 */
functionCallConvertValue: functionCall '=>' (objectValue | listValue) ;

/* 路由并转换成：列表 or 对象 */
routeConvertValue: routeMapping '=>' (objectValue | listValue) ;

/* ----------------------------------------------------------------------------------- 函数调用和路由 */
/* 函数调用 */
functionCall    : routeMapping LBT ( polymericObject (COMMA polymericObject)* )? RBT ((DOT routeMapping) | subscriptMapping)?;

/* 路由 */
routeMapping    : ROU OCBR routeMappingItem (DOT routeMappingItem)* CCBR    // 特殊路由
                | routeMappingItem (DOT routeMappingItem)*                  // 一般路由
                ;
routeMappingItem: IDENTIFIER subscriptMapping*;                             // 路由项（可以有下标）

/* 下标 */
subscriptMapping: LSBT ( STRING | INTEGER_NUM ) RSBT;

/* ----------------------------------------------------------------------------------- 表达式 */
expr        : LBT expr RBT ( dyadicExpr | ternaryExpr )?    // 优先级(后面可以有多元运算)
            | unaryExpr                                     // 一元运算
            | atomExpr ( dyadicExpr | ternaryExpr )?        // 基本算项 or 多元运算
            ;

/* 一元运算 */
unaryExpr   : (PLUS | MINUS | NOT) atomExpr;

/* 二元运算 */
dyadicExpr  : (PLUS | MINUS | MUL | DIV | DIV2 | MOD | LBT | RBT | AND | OR | NOT | XOR | LSHIFT | RSHIFT | RSHIFT2 | GT | GE | LT | LE | EQ | NE | SC_OR | SC_AND) expr;

/* 三元运算 */
ternaryExpr : '?' expr COLON expr;

/* 可以作为表达式项的有：基本类型 or 发起函数调用 or 路由映射 */
atomExpr    : primitiveValue | functionCall | routeMapping;

/* ----------------------------------------------------------------------------------- 基本类型 */
primitiveValue  : STRING | NULL | TRUE | FALSE | DECIMAL_NUM | INTEGER_NUM | HEX_NUM | OCT_NUM | BIT_NUM;