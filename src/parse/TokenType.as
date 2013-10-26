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

package parse
{
	public class TokenType
	{
		public var id:int;
		public function TokenType(_id:int=0)
		{
			id=_id;
		}
		static public var ident:int=1;//标识符
		static public var constant:int=2;//常量
		//
		public static var Assign:int=3;//赋值运算符
		//
		static public var MOP:int=4;//数学运算符
		static public var LOP:int=5;//逻辑运算符
		
		static public var COP:int=6;//比较运算符
		static public var INCREMENT:int=7;//递增操作运算符
		//
		
		static public var LOPNot:int=40;//单元逻辑运算符
		//
		static public var keyclass:int=10;//关键字
		static public var keyimport:int=11;//关键字
		static public var keyfunction:int=12;//关键字
		static public var keyif:int=13;//关键字
		static public var keyelse:int=14;//关键字
		
		static public var keyfor:int=15;//关键字
		static public var keywhile:int=16;//关键字
		static public var keyvar:int=17;//关键字
		static public var keyreturn:int=18;//关键字
		static public var keynew:int=19;//关键字
		static public var keyextends:int=20;//关键字
		static public var keypackage:int=42;//关键字
		//static public var keyin:int=43;//关键字
		//2011.9.6,添加3个关键字
		static public var keypublic:int=44;//关键字
		static public var keyprivate:int=45;//关键字
		static public var keyprotected:int=46;//关键字
		//2011.9.7,添加7个关键字
		static public var keyswitch:int=47;//关键字
		static public var keycase:int=48;//关键字
		static public var keybreak:int=49;//关键字
		static public var keydefault:int=50;//关键字
		static public var keycontinue:int=51;//关键字
		//
		static public var keytry:int=52;//关键字
		static public var keycatch:int=53;//关键字
		static public var keyfinally:int=54;//关键字
		static public var keyeach:int=55;//关键字
		//
		
		//分割符---------
		//大括号{}
		public static var LBRACE:int=21;
		public static var RBRACE:int=22;
		//小括号()
		public static var LParent:int=23;
		public static var RParent:int=24;
		//.
		public static var DOT:int=25;
		//逗号,
		public static var COMMA:int=26;
		//分号;
		public static var Semicolon:int=27;
		
		//null
		public static var NULL:int=29;
		//方括号
		public static var LBRACKET:int=30;
		public static var RBRACKET:int=31;
		//冒号
		public static var Colon:int=32;
		
		//
		
	}
}