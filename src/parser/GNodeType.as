/*
The MIT License

Copyright (c) 2009 dayu qq:32932813

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.

http://code.google.com/p/ascript-as3/
http://ascript.softplat.com/
*/       

package parser
{
	//语法树节点
	public class GNodeType
	{
		static public var CLASS:int=20;//类
		static public var FunDecl:int=0;//函数声明
		static public var VarDecl:int=1;//变量声明//语句
		static public var Params:int=2;//参数;
		
		static public var MOP:int=3;//值类型
		static public var LOP:int=4;//值类型
		static public var LOPNot:int=22;//单元逻辑非节点
		static public var Nagtive:int=23;//单元逻辑非节点
		
		static public var COP:int=5;//值类型
		static public var Stms:int=6;//语句
		static public var AssignStm:int=7;//语句
		static public var IfElseStm:int=8;//语句
		static public var WhileStm:int=9;//语句
		static public var ForStm:int=10;//语句
		
		static public var ForInStm:int=25;//语句
		static public var ForEACHStm:int=40;//语句
		//
		static public var ReturnStm:int=11;//语句
		
		static public var FunCall:int=12;//值类型
		
		//
		static public var VarID:int=13;//值类型
		static public var IDENT:int=24;//值类型
		//2011.9.6增加
		static public var Index:int=28;//[]下标语句
		static public var SWITCH:int=29;//[]下标语句
		static public var CASE:int=30;//[]下标语句
		static public var DEFAULT:int=31;//[]下标语句
		static public var TRY:int=32;//try语句
		static public var CATCH:int=33;//try语句
		static public var FINALLY:int=34;//try语句
		
		static public var BREAK:int=35;//break语句
		static public var CONTINUE:int=36;//continue语句
		
		static public var ELSEIF:int=37;//ELSS IF语句
		static public var PREINCREMENT:int=38;//++idient语句
		static public var INCREMENT:int=39;//idient++ --语句
		
		//
		static public var newArray:int=26;//值类型
		static public var newObject:int=27;//值类型
		//
		static public var ConstID:int=14;//值类型
		static public var EXPS:int=15;
		static public var newClass:int=17;//值类型
		static public var ERROR:int=18;
		static public var importStm:int=19;//语句
		
		
		
		
		static public var names:Array=["FunDecl","VarDecl","Params","MOP","LOP","COP","Stms","AssignStm","IfElseStm","WhileStm","ForStm","ReturnStm",
			"FunCall","VarID","ConstID","EXPS","","newClass","ERROR","importStm","CLASS","","LOPNot","Nagtive","IDENT","ForInStm",
			"newArray","newObject","Index","SWITCH","CASE","DEFAULT","TRY","CATCH","FINALLY","BREAK","CONTINUE","ELSEIF","PREINCREMENT","INCREMENT"];
		static public function getName(i:int):String{
			return names[i];
		}
	}
}