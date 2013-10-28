/*
The MIT License

Copyright (c) 2009 作者:dayu qq:32932813

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
	import flash.events.Event;
	import flash.utils.Dictionary;
	
	import parser.DY;
	import parser.GNode;
	import parser.GenTree;
	
	public class ProxyFunc
	{
		static private var dics:Dictionary=new Dictionary();
		static public function getAFunc(_it:DY,fn:String):Function{
			if(!dics[_it]){
				dics[_it]=new Dictionary();
			}
			if(!dics[_it][fn]){
				dics[_it][fn]=new ProxyFunc(_it,fn);
			}
			return dics[_it][fn].Func;
		}
		//
		private var it:DY;//首先明确是哪个脚本类的哪个方法
		private var funcname:String;//这是it监听函数名。
		private var Func:Function;
		
		public function ProxyFunc(_it:DY,fn:String)
		{
			it=_it;
			funcname=fn;
			//为了兼容starling,修改了一下返回函数...分为带1参数和其他，2013.9.14
			if((_it._rootnode.motheds[fn] as GNode).childs[0].childs.length==1){
				Func=this.Func1;
			}else{
				Func=this.FuncN;
			}
		}
		//=================
		public function Func1(arg1):*{
			try{
				//trace(it._rootnode.name+" call "+funcname+"("+args+")")
				return it.call(funcname,[arg1]);
			}catch(e:Error){
				trace(e.getStackTrace());
			}
		};
		public function FuncN(...args):*{
			try{
				//trace(it._rootnode.name+" call "+funcname+"("+args+")")
				return it.call(funcname,args);
			}catch(e:Error){
				trace(e.getStackTrace());
			}
		};
	}
}