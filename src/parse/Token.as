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

package parse {
//
	/**
	 * @author dayu
	 * 是作为解释器而写的，不同于编译器。。。。
	 */
	public class Token {
		public var type:int;//
		public var value:*;//当类型为常量，则为其值
					//当类型为ident和操作符或界符，则为其单词
					//当类型为关键字，则为其单词，
		public var word:String;
		public var line:int=0;
		internal var linestr:String="";
		public function getLine():String{
			return linestr;
		}
		public var index:int;
		//
		public static var wordpatten:String="|as|is|instanceof|extends|in|package|for|var|new|class|function|if|else|while|return|import|public|private|protected|switch|case|break|continue|default|try|catch|finally|each|";
		public function Token(){
		}
		static public function iskeyword(str:String):Boolean{
			if(Token.wordpatten.indexOf("|"+str+"|")>=0){
				return true;
			}
			return false;
		}
		static public function getTypeName(str:String):String{
			if(iskeyword(str)){
				return "TokenType.key"+str;
			}
			return "TokenType."+getDec(str);
		}
		//获取分隔符
		static public function getDec(str:String):String{
			if(str=="("){
				return "LParent";
			}else if(str==")"){
				return "RParent";
			}else if(str=="{"){
				return "LBRACE";
			}else if(str=="}"){
				return "RBRACE";
			}else if(str=="["){
				return "LBRACKET";
			}else if(str=="]"){
				return "RBRACKET";
			}else if(str=="."){
				return "DOT";
			}else if(str==","){
				return "COMMA";
			}else if(str==";"){
				return "Semicolon";
			}else if(str==":"){
				return "Colon";
			}
			return str;
		}
	}
}
