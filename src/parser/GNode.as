
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
	import parse.Token;

	final public class GNode
	{
		public var childs:Vector.<GNode> = new Vector.<GNode>;
		public var token:Token;
		//
		public var gtype:int;	//GNodeType 
		public var vartype:String="dynamic";//用于标明变量类型int char float//dynamic
		public var word:String;
		public var vis:String="protected";//可见性
		public function GNode(n:int=-1,v:Token=null)
		{
			if(n>-1){
				gtype=n;
				token=v;
				if(n!=GNodeType.IDENT){
					if(token){
						//throw new Error("语法分析错误");
						word=token.word;
					}
				}
			}
		}
			
		//常量会有
		[inline]
		public function get value():*{
			if(token){
				return token.value;
			}
			return null;
		}
		//第几行
		public function get line():int{
			return token.line;
		}
		//
		[inline]
		public function get nodeType():int{
			return gtype;
		}
		//只有class,varst和func存在name,varID,constID是否需要存在，目前还没想好
		public function get name():String{
			if(nodeType==GNodeType.AssignStm){
				return childs[0].name;
			}
			if(token){
				return token.word;
			}
			return null;
		}
		public function addChild(node:GNode):void{
			childs.push(node);
		}
		static public var lev:int=0;
		static private var levs:Array=["","-","--","---","----","-----","------","--------","--------","---------","----------","-----------","------------","-------------","--------------","---------------","----------------"];
		public function toString():String{
			var str:String=GNodeType.getName(this.gtype);
			if(this.token){
				str+=" "+this.token.value;
				if(gtype==GNodeType.VarDecl || gtype==GNodeType.FunDecl){
					str=this.vis+" "+this.vartype+" "+str;
				}
			}
			str=levs[lev]+str+"\n";
			lev++;
			for each(var o:GNode in this.childs){
				if(o is GNode){
					str+=(o as GNode).toString();
				}else{
					str+="=======>"+o.toString();
				}
			}
			lev--;
			return str;
		}
	}
}