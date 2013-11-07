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

请访问https://github.com/softplat/ascript获取最新的Ascript
http://code.google.com/p/ascript-as3/ 此地址只更新swc和wiki，源码不再更新

*/       

package parser
{
	import flash.display.DisplayObjectContainer;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	import flash.system.ApplicationDomain;
	import flash.utils.getDefinitionByName;
	import flash.utils.getTimer;
	
	import parse.Lex;
	import parse.ProxyFunc;

	public class Script
	{
		static var ____globalclass:GenTree;
		internal static var __globaldy:DY;
		public static var vm:DY;
		internal static var output:Function;
		//
		static var classes:Object={};
		static var errores:Object={};
		//
		static internal var Debug:*;
		static var app:ApplicationDomain;
		//
		internal static var defaults:Object={};
		static public function addAPI(Aname:String,api:*):void{
			defaults[Aname]=api;
		}
		//
		static public function getDef(clname:String):*{
			if(!classes[clname]){
				if(!errores[clname]){
					try{
						var c=getDefinitionByName(clname);
						if(c){
							classes[clname]=c;
						}
						return c;
					}catch(e){
						errores[clname]=true;
					}
				}
				if(app.hasDefinition(clname)){
					classes[clname]=app.getDefinition(clname);
				}
			}
			return classes[clname];
		}
		static internal var _root:Sprite;
		//
		static public function set root(r:Sprite):void{
			_root=r;
			app=r.loaderInfo.applicationDomain;
		}
		static public var scriptdir:String="script/";
		static public function init(__root:Sprite,code:String=null):void{
			root=__root;
			//
			DY.prototype.toString=function():String{
				return "这是一个脚本类";
			}
			Script.addAPI("Number",Number);
			Script.addAPI("int",int);
			Script.addAPI("String",String);
			//
			Script.addAPI("parseInt",parseInt);
			Script.addAPI("parseFloat",parseFloat);
			//
			//
			if(code){
				____globalclass=LoadFromString(code);
				GenTree.Branch["____globalclass"]=____globalclass;
			}else{
				____globalclass=newScript("____globalclass");
			}
			__globaldy=New(____globalclass.name);
			vm=__globaldy;
			//再初始化一个基本类
			newScript("__DY");//基本类
			//
			/*if(!code){
				trace(<![CDATA[
					欢迎您体验Ascript1.0,这个脚本语言专门为as3打造。
					开发者:dayu,如果遇到任何bug以及疑问请联系我
					email:zuwuneng@yahoo.com.cn
					qq:32932813
					]]>);
			}*/
		}
		/**
		 *加载一个脚本类的代码 
		 * @param code
		 * @return 
		 * 
		 */		
		static public function LoadFromString(code:String):*{
			code=code.replace(/public /g,"");
			code=code.replace(/private /g,"");
			code=code.replace(/protected /g,"");
			return new GenTree(code);
		}
		/**
		 *获得一个脚本函数的引用 
		 * @param funcname
		 * @return 
		 * 
		 */
		static public function getFunc(funcname:String):Function{
			return ProxyFunc.getAFunc(__globaldy,funcname);
		}
		static private function LoadFromFile(code:String):void{
			//code=code.replace(/\r/,"");
			var ld:URLLoader=new URLLoader();
			ld.addEventListener(Event.COMPLETE,onloadFile);
			ld.load(new URLRequest(code));
		}
		static private function onloadFile(e:Event):void{
			LoadFromString((e.target as URLLoader).data);
		}
		static private function newScript(_name:String):*{
			var mycode:String="class "+_name+"{}";
			return new GenTree(mycode);
		}
		/**
		 *第一个参数为脚本类名，如果不传递，会创建一个默认的脚本对象，无任何属性，
		 * 后面是构造函数的参数 
		 * @param args
		 * @return 
		 * 
		 **/
		static public function New(...args):*{
			if(args.length==0){
				var _name:String="__DY";//匿名类
			}else{
				var _name:String=args.shift();
			}
			if(GenTree.hasScript(_name)){
				return new DY(_name,args);
			}
			return new DY(_name,args);
		}
		
		/**
		 *为某个脚本类声明一个脚本函数 
		 * @param code
		 * @param clname
		 * @return 
		 * 
		 */		
		static public function declare(code:String,clname:String="____globalclass"):*{
			//trace(code);
			if(GenTree.hasScript(clname)){
				var lex:Lex=new Lex(code);
				var cnode:GNode=(GenTree.Branch[clname] as GenTree).declares(lex);
				//trace(cnode.toString());
				return __globaldy.executeST(cnode);
				/*
				if(cnode.nodeType==GNodeType.AssignStm){
					__globaldy[cnode.childs[0].word]=__globaldy.getValue(cnode.childs[1]);
				}else if(cnode.nodeType==GNodeType.VarDecl){
					__globaldy[cnode.childs[0].word]=__globaldy.getValue(cnode.childs[1]);
				}*/
			}
		}
		//----------
		static public function eval(code:String,...args):*{
			var cnode:GNode;
			if(args && args.length>0){
				var code:String="function __niming(args){return "+code+";}";
				if(Lex.treecach[code]){
					cnode=Lex.treecach[code];
					____globalclass.motheds[cnode.name]=cnode;
				}else{
					var lex:Lex=new Lex(code);
					cnode=____globalclass.declare(lex);
					Lex.treecach[code]=cnode;
				}
				return __globaldy.call("__niming",[args]);
			}else{
				code="return "+code+";";
				if(Lex.treecach[code]){
					cnode=Lex.treecach[code];
				}else{
					var lex:Lex=new Lex(code);
					cnode=____globalclass.declare(lex);
					Lex.treecach[code]=cnode;
				}
				return __globaldy.executeST(cnode);
			}
		}
		static public function execute(code:String,...args):*{
			//trace(code);
			if(args && args.length>0){
				var code:String="function __niming(args){"+code+"}";
				var cnode:GNode;
				if(Lex.treecach[code]){
					cnode=Lex.treecach[code];
					____globalclass.motheds[cnode.name]=cnode;
				}else{
					var lex:Lex=new Lex(code);
					cnode=____globalclass.declare(lex);
					Lex.treecach[code]=cnode;
				}
				return __globaldy.call("__niming",[args]);
			}else{
				var cnode:GNode;
				if(Lex.treecach[code]){
					cnode=Lex.treecach[code];
				}else{
					var lex:Lex=new Lex(code);
					cnode=____globalclass.declares(lex);
					Lex.treecach[code]=cnode;
				}
				return __globaldy.executeST(cnode);
			}
		}
		//
		static public function decode(str:String):*{
			var cnode:GNode;
			var code="return "+str+";";
			var lex:Lex=new Lex(code,true);
			cnode=____globalclass.declare(lex);
			return __globaldy.executeST(cnode);
		}
		static private function encodeObj(ob:Object):String{
			if(ob==null){
				//throw new Error("无法对空对象进行编码");
				return "null";
			}
			if(ob is String){
				return escapeString(ob as String);
			}
			if(ob is Number){
				return ob+"";
			}
			if(ob is Boolean){
				return ob.toString();
			}
			var str:String="{";
			for(var o:String in ob){
				str+=o+":"+encode(ob[o])+",";
			}
			if(str.charAt(str.length-1)==","){
				return str.substr(0,str.length-1)+"}"
			}
			return "{}";
		}
		static private function escapeString( str:String ):String {
			// create a string to store the string's jsonstring value
			var s:String = "";
			// current character in the string we're processing
			var ch:String;
			// store the length in a local variable to reduce lookups
			var len:Number = str.length;
			// loop over all of the characters in the string
			for ( var i:int = 0; i < len; i++ ) {
				// examine the character to determine if we have to escape it
				ch = str.charAt( i );
				switch ( ch ) {
					case '"':	// quotation mark
						s += "\\\"";
						break;
					//case '/':	// solidus
					//	s += "\\/";
					//	break;
					case '\\':	// reverse solidus
						s += "\\\\";
						break;
					case '\b':	// bell
						s += "\\b";
						break;
					case '\f':	// form feed
						s += "\\f";
						break;
					case '\n':	// newline
						s += "\\n";
						break;
					case '\r':	// carriage return
						s += "\\r";
						break;
					case '\t':	// horizontal tab
						s += "\\t";
						break;
					default:	// everything else
						s += ch;
						/*
						//对汉字或者特殊字符进行unicode编码
						// check for a control character and escape as unicode
						if ( ch < ' ' ) {
							// get the hex digit(s) of the character (either 1 or 2 digits)
							var hexCode:String = ch.charCodeAt( 0 ).toString( 16 );
							// ensure that there are 4 digits by adjusting
							// the # of zeros accordingly.
							var zeroPad:String = hexCode.length == 2 ? "00" : "000";
							// create the unicode escape sequence with 4 hex digits
							s += "\\u" + zeroPad + hexCode;
						} else {
							// no need to do any special encoding, just pass-through
							s += ch;
						}*/
				}	// end switch
				
			}	// end for loop
			
			return "\"" + s + "\"";
		}
		static private function encodeArr(ar:Array):String{
			var str:String="[";
			for(var i:int=0;i<ar.length;i++){
				if(ar[i]==null){
					str+=",";
				}
				else if(ar[i] is Array){
					str+=encodeArr(ar[i])+",";
				}else{
					str+=encodeObj(ar[i])+",";
				}
			}
			if(str.charAt(str.length-1)==","){
				return str.substr(0,str.length-1)+"]"
			}
			return "[]";
		}
		static public function encode(ob:Object):*{
			var str:String="";
			if(ob is Array){
				return encodeArr(ob as Array);
			}
			return encodeObj(ob);
		}
	}
}