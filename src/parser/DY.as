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
	import flash.utils.Proxy;
	import flash.utils.flash_proxy;
	
	import parse.ProxyFunc;
	
	//注意事项，如果要用那个_super，仅限_super的类为动态的。
	dynamic public class DY extends Proxy{
		//
		protected var __rootnode:GenTree;
		private var _classname:String;
		protected var __vars:Object;//local_vars的堆栈顶
		private var local_vars:Array;//局部变量堆栈
		protected var __API:Object;
		protected var __super:Object;
		function DY(clname:String="__DY",explist:Array=null){
			_classname=clname;
			__rootnode=GenTree.Branch[clname];
			local_vars=[];
			__API=GenTree.Branch[clname].API;
			
			__API._root=Script._root;
			//__API.stage=Script._root.stage;
			for(var o:String in Script.defaults){
				
				__API[o]=Script.defaults[o];
			}
			__super={};
			init(explist||[]);//初始化字段，调用构造函数
		}
		//
		[inline]
		public function get _super():Object
		{
			return __super;
		}
		/**
		 * _super必须指向一个动态类的实例，否则脚本定义的变量将失去作用 
		 * @param value
		 * 
		 */
		public function set _super(value:Object):void
		{
			
			for(var o:String in __super){
				value[o]=__super[o];
			}
			__super = value;
		}
		
		public function toString():String{
			return this._classname;
		}
		override flash_proxy function callProperty(methodName:*, ... args):* {
			if(methodName is QName){
				methodName=(methodName as QName).localName;
			}
			if(__rootnode.motheds[methodName]){
				return this.call(methodName,args);
				/*
				var f:Function=ProxyFunc.getAFunc(this,methodName);
				if(f){
				return f.apply(this,args);
				}*/
			}
			if(__super[methodName] is Function){
				return callLocalFunc(__super,methodName,args);
			}
			
			executeError(_classname+">SUPER "+__super+">不存在此方法="+methodName);
			return null;
		}
		[inline]
		override flash_proxy function getProperty(name:*):* {
			return __super[name];
		}
		[inline]
		override flash_proxy function setProperty(name:*, value:*):void {
			__super[name] = value;
		}
		[inline]
		public function get _rootnode():GenTree{
			return __rootnode;
		}
		//以下是对所有的有语意的语法进行翻译
		private function init(explist:Array):void{
			for each(var o:GNode in _rootnode.fields){
				if(o.nodeType!=GNodeType.FunDecl){
					executeFiledDec(o);
				}
			}
			if(__rootnode.motheds[_classname]){
				call(_classname,explist);
			}
			//return null;
		}
		private function executeFiledDec(node:GNode):void{
			if(node.nodeType==GNodeType.AssignStm){
				//assign的第一个节点为vardecal?
				this[node.childs[0].token.word]=getValue(node.childs[1]);
			}else if(node.nodeType==GNodeType.VarDecl){
				this[node.word]=0;//默认为0
			}
		}
		protected var isret:Boolean=false;//函数调用是否返回
		protected var jumpstates:Array=[0];//循环的当前状态
		//0.不跳出，1，跳出，2跳到下一次
		[inline]
		private function get  jumpstate():int{
			return jumpstates[jumpstates.length-1];
		}
		[inline]
		private function set  jumpstate(v:int):void{
			jumpstates[jumpstates.length-1]=v;
		}
		[inline]
		public function pushstate():void{
			jumpstates.push(0);
		}
		[inline]
		public function popstate():void{
			jumpstates.pop();
		}
		public function call(funcname:String,explist:Array):*{
			var re:*=null;
			try{
				var node:GNode=__rootnode.motheds[funcname];
				if(node && node.nodeType==GNodeType.FunDecl){
					if(funcname=="init"){
						trace(1);
					}
					var tisret:Boolean=isret;
					isret=false;
					local_vars.push({});
					__vars=local_vars[local_vars.length-1];
					//node=_rootnode.motheds[funcname];
					re=FunCall(node,explist);
					
					local_vars.pop();
					if(local_vars.length>0){
						__vars=local_vars[local_vars.length-1];
					}else{
						__vars=null;
					}
					isret=tisret;
				}else if(__super[funcname] is Function){
					re=callLocalFunc(__super,funcname,explist);
				}else {
					executeError(_classname+"的方法:"+funcname+" 未定义");
				}
			}catch(e:Error){
				executeError("调用>"+this._classname+"类的"+funcname+explist+"出错>\r"+e.getStackTrace());//e.message+"\r"+
			}
			return re;
		}
		[inline]
		private function FunCall(node:GNode,explist:Array):* {
			//trace(classname+">stlist="+tok.word);
			if(node.nodeType==GNodeType.FunDecl){
				var param:GNode=node.childs[0];
				for(var i:int=0;i<param.childs.length;i++){
					__vars[param.childs[i].word]=explist[i];//处理局部变量
				}
				var stms:GNode=node.childs[1];
				return executeST(node.childs[1]);//复合语句
			}
		}
		public function executeST(node:GNode):*{
			/*static public var AssignStm=7;//语句
			static public var IfElseStm=8;//语句
			static public var WhileStm=9;//语句
			static public var ForStm=10;//语句
			static public var ReturnStm=11;//语句
			VarDecl//
			*/
			var i:int;
			var re:*;
			var arr:Array;
			var obj:Object;
			if(node.nodeType==GNodeType.Stms){
				for(i=0;i<node.childs.length;i++){
					re=executeST(node.childs[i]);
					if(isret){
						return re;
					}
					if(jumpstate>0){
						return;
					}
				}
			}else if(node.nodeType==GNodeType.AssignStm){
				var lnode:GNode=node.childs[0];//左侧节点
				var tlvalue:LValue=new LValue();
				if(lnode.nodeType==GNodeType.VarDecl){
					//变量声明
					if(__vars){
						tlvalue.scope=__vars;
						tlvalue.key=node.childs[0].word;
					}else{
						tlvalue.scope=this;
						tlvalue.key=node.childs[0].word;
					}
				}else{
					getLValue(lnode);
					tlvalue.scope=lvalue.scope;
					tlvalue.key=lvalue.key;
					if(tlvalue.key==null){
						throw new Error("左值取值失败="+lnode.toString());
					}
				}
				var rvalue:*=getValue(node.childs[1]);//右侧取值
				//var lv:*=lvarr[0];
				switch(node.word){
					case "=":
						tlvalue.scope[tlvalue.key]=rvalue;
						break;
					case "+=":
						tlvalue.scope[tlvalue.key]+=rvalue;
						break;
					case "-=":
						tlvalue.scope[tlvalue.key]-=rvalue;
						break;
					case "*=":
						tlvalue.scope[tlvalue.key]*=rvalue;
						break;
					case "/=":
						tlvalue.scope[tlvalue.key]/=rvalue;
						break;
					case "%=":
						tlvalue.scope[tlvalue.key]%=rvalue;
						break;
				}
			}else if(node.nodeType==GNodeType.FunCall){
				getValue(node);
			}else if(node.nodeType==GNodeType.IfElseStm){
				for(i=0;i<node.childs.length;i++){
					var cn:GNode=node.childs[i];
					if(cn.nodeType==GNodeType.ELSEIF){
						exp=getValue(cn.childs[0]);
						if(exp){
							re=executeST(cn.childs[1]);
							if(isret){
								return re;
							}
							if(jumpstate>0){
								return;
							}
							break;
						}
					}else{
						re=executeST(cn);
						if(isret){
							return re;
						}
						if(jumpstate>0){
							return;
						}
					}
				}
			}else if(node.nodeType==GNodeType.SWITCH){
				var exp:*=getValue(node.childs[0]);
				var jump:Boolean=false;
				var isbreak:Boolean=true;
				for(i=1;i<node.childs.length;i++){
					if(jump){
						break;
					}
					cn=node.childs[i];
					
					if(cn.nodeType==GNodeType.CASE){
						//trace(cn.childs[0].toString());
						if(isbreak==false ||(isbreak && exp==getValue(cn.childs[0]))){
							//
							isbreak=false;
							//
							for(var j:int=1;j<cn.childs.length;j++){
								if((cn.childs[j] as GNode).nodeType==GNodeType.BREAK){
									jump=true;
									isbreak=true;
									break;
								}else{
									
									re=executeST(cn.childs[j]);
									if(isret){
										return re;
									}
								}
							}
						}
					}else if(cn.nodeType==GNodeType.DEFAULT){
						//stlist
						for(j=0;j<cn.childs.length;j++){
							if((cn.childs[j] as GNode).nodeType==GNodeType.BREAK){
								jump=true;
								break;
							}else{
								re=executeST(cn.childs[j]);
								if(isret){
									return re;
								}
							}
						}
					}
				}
			}else if(node.nodeType==GNodeType.INCREMENT){
				return onINCREMENT(node);
			}else if(node.nodeType==GNodeType.PREINCREMENT){
				return onPREINCREMENT(node);
			}else if(node.nodeType==GNodeType.VarDecl){
				//除了全局初始化声明，其他的都是局部变量
				var scope:*=__vars || this;
				scope[node.word]=0;//默认为0
			}else if(node.nodeType==GNodeType.ReturnStm){
				if(node.childs.length>0){
					
					re=getValue(node.childs[0]);
					isret=true;
					return re;
				}else{
					isret=true;
					return undefined;
				}
			}else if(node.nodeType==GNodeType.CONTINUE){
				//应该跳过下面的执行。
				jumpstate=2;
			}else if(node.nodeType==GNodeType.BREAK){
				//应该跳出循环
				jumpstate=1;
			}else if(node.nodeType==GNodeType.WhileStm){
				pushstate();
				try{
					while(getValue(node.childs[0])){
						re=executeST(node.childs[1]);
						if(isret){
							return re;
						}
						if(jumpstate==1){
							break;//否则继续执行
						}
						jumpstate=0;//恢复为0
					}
				}finally{
					popstate();
				}
			}else if(node.nodeType==GNodeType.ForStm){
				//var exp1=
				executeST(node.childs[0]);
				//var exp2;
				pushstate();
				try{
					while(getValue(node.childs[1])){
						re=executeST(node.childs[3]);//进行for内部的处理
						if(isret){
							return re;
						}
						if(jumpstate==1){
							break;//否则继续执行
						}
						jumpstate=0;//恢复为0
						executeST(node.childs[2]);//
					}
				}finally{
					popstate();
				}
			}else if(node.nodeType==GNodeType.ForInStm){
				var varname:String=node.childs[0].word;
				
				obj=getValue(node.childs[1]);
				//
				pushstate();
				try{
					for(var o:String in obj){
						__vars[varname]=o;
						re=executeST(node.childs[2]);//
						if(isret){
							return re;
						}
						if(jumpstate==1){
							break;//否则继续执行
						}
						jumpstate=0;//恢复为0
					}
				}finally{
					popstate();
				}
			}else if(node.nodeType==GNodeType.ForEACHStm){
				varname=node.childs[0].word;
				obj=getValue(node.childs[1]);
				pushstate();
				try{
					for each(var oo:* in obj){
						__vars[varname]=oo;
						re=executeST(node.childs[2]);//
						if(isret){
							return re;
						}
						if(jumpstate==1){
							break;//否则继续执行
						}
						jumpstate=0;//恢复为0
					}
				}finally{
					popstate();
				}
			}
			else if(node.nodeType==GNodeType.importStm){
				//
				arr=node.word.split(".");
				__API[arr[arr.length-1]]=Script.getDef(node.word);
			}
		}
		[inline]
		protected function onINCREMENT(node:GNode):Number{
			getLValue(node.childs[0]);
			if(lvalue.key!=null){
				var re:Number;
				if(node.word=="++"){
					re=lvalue.scope[lvalue.key];
					lvalue.scope[lvalue.key]+=1;
					return re;
				}else if(node.word=="--"){
					re=lvalue.scope[lvalue.key];
					lvalue.scope[lvalue.key]-=1;
					return re;
				}else{
					executeError("解释出错=递增操作符未设置值");
				}
			}
			return 0;	
		}
		[inline]
		protected function onPREINCREMENT(node:GNode):Number{
			getLValue(node.childs[0]);
			if(lvalue.key!=null){
				if(node.word=="++"){
					lvalue.scope[lvalue.key]+=1;
					return lvalue.scope[lvalue.key];
				}else if(node.word=="--"){
					lvalue.scope[lvalue.key]-=1;
					return lvalue.scope[lvalue.key];
				}else{
					executeError("解释出错=递增操作符未设置值");
				}
				return lvalue.scope[lvalue.key];
			}
			return 0;
		}
		protected function getLValue(node:GNode):void{
			lvalue.scope=null;
			lvalue.key=null;
			if(node.gtype== GNodeType.IDENT){
				//取得左值，其实就是取得scope,vname
				var var_arr:Array=[];
				
				for(var i:int=0;i<node.childs.length;i++){
					if(node.childs[i].nodeType==GNodeType.Index){//索引
						var_arr.push(getValue(node.childs[i].childs[0]));
					}else{//varID
						var_arr.push(node.childs[i].word);
					}
				}
				var vname:String=var_arr[0];
				
				//
				var scope:*=null;
				var bottem:int=0;
				if(vname=="this"){
					scope=this;
					bottem=1;
				}else if(vname=="_super"){
					scope=this;
				}else{
					if(__vars && __vars[vname]!=undefined){
						scope=__vars;
					}else if(__super.hasOwnProperty(vname) || __super[vname]!=undefined){
						scope=__super;
					}else if(_rootnode.motheds[vname]){
						scope=this;
					}else if(__API[vname]){
						scope=__API;
					}else if(Script._root && Script._root.loaderInfo.applicationDomain.hasDefinition(vname)){
						scope=Script.getDef(vname);// as Class;
						bottem=1;
					}else{
						scope=Script.__globaldy[vname];
					}
				}
				if(!scope){
					scope=__vars;
				}
				//作用域有效
				var v:*=scope;
				
				if(v){
					if(var_arr.length<bottem){
						lvalue.scope=v;
					}
					for(i=bottem;i<var_arr.length-1;i++){
						if(v){
							v=v[var_arr[i]];
						}
					}
					if(v!=undefined){
						var lastv:String=var_arr[var_arr.length-1];
						//v[lastv]==undefined && 
						lvalue.scope=v;
						lvalue.key=lastv;
					}
				}
			}
		}
		protected var lvalue:LValue=new LValue;
		public function getValue(node:GNode):*{
			switch(node.nodeType){
				case GNodeType.IDENT:
					//自身是
					if(node.childs.length==1){
						//快速通道,优化目的
						var vname:String=node.childs[0].word;
						if(__vars && __vars[vname]!=undefined){
							return __vars[vname];
						}else if(this[vname]!=undefined){
							return this[vname];
						}else if(this._rootnode.motheds[vname]!=undefined){
							return ProxyFunc.getAFunc(this,vname);
						}else if(__API[vname]!=undefined){
							return __API[vname];
						}else if(vname=="this"){
							return this;
						}else{
							return Script.__globaldy[vname];
						}
					}
					getLValue(node);
					
					if(lvalue.key!=null){
						//没有属性
						if(lvalue.scope[lvalue.key]!=undefined){
							return lvalue.scope[lvalue.key];
						}
						//可能是脚本方法
						if(lvalue.scope is DY && lvalue.scope._rootnode.motheds[lvalue.key]){
							return ProxyFunc.getAFunc(lvalue.scope as DY,lvalue.key);
						}
					}else if(lvalue.scope){
						return lvalue.scope;
					}
					return undefined;//不存在这个变量啊
					break;
				case GNodeType.VarID:
					return node.word;
				case GNodeType.ConstID:
					return node.value;
					break;
				case GNodeType.MOP:
					return onMOP(node);
					break;
				case GNodeType.LOP:
					var v1=getValue(node.childs[0]);
					if(node.word=="||" || node.word=="or"){
						//var v2=;
						if(v1){
							return true;//如果已经为true，不需要进行后面的计算
						}
						return v1 || getValue(node.childs[1]);
					}else if(node.word=="&&"|| node.word=="and"){
						if(!v1){
							return false;
						}
						return v1 && getValue(node.childs[1]);
					}
					break;
				case GNodeType.LOPNot:
					//逻辑非
					v1=getValue(node.childs[0]);
					return !v1;
					break;
				case GNodeType.Nagtive:
					//-
					v1=getValue(node.childs[0]);
					return -v1;
					break;
				case GNodeType.INCREMENT:
					return onINCREMENT(node);
					break
				case GNodeType.PREINCREMENT:
					//----------------------
					return onPREINCREMENT(node);
					break;
				case GNodeType.COP:
					return onCOP(node);
					break;
				case GNodeType.newArray:
					//新数组
					if(node.childs.length>0){
						var exps:GNode=node.childs[0];
						var explist:Array=[];
						for(i=0;i<exps.childs.length;i++){
							explist[i]=getValue(exps.childs[i]);
						}
						return explist;
					}
					return [];
				case GNodeType.newObject:
					//新数组
					if(node.childs.length>0){
						var newobj:Object={};
						for(i=0;i<node.childs.length;i+=2){
							newobj[node.childs[i].word]=getValue(node.childs[i+1]);
						}
						return newobj;
					}
					return {};
				case GNodeType.newClass:
					var c:Class;
					var identnode:GNode=node.childs[0];
					//
					var arrr:Array=identnode.word.split(".");
					if(__API[arrr[arrr.length-1]]){
						c=__API[arrr[arrr.length-1]];
					}else if(Script._root.loaderInfo.applicationDomain.hasDefinition(identnode.word)){
						c=Script.getDef(identnode.word) as Class;
					}
					
					explist=[];
					if(node.childs.length==2){
						var param:GNode=node.childs[1];
						for(var i:int=0;i<param.childs.length;i++){
							explist[i]=getValue(param.childs[i]);
						}
					}
					var re:*;
					if(c){
						return newLocalClass(c,explist);
					}else{
						if(GenTree.hasScript(identnode.word)){
							re=new DY(identnode.word,explist);
							trace("成功创建脚本类="+identnode.word+"的实例");
							return re;
						}else{
							trace("脚本类="+identnode.word+"尚未定义");
							return null;
						}
					}
					break;
				case GNodeType.FunCall:
					//函数调用
					//2个子节点，一个是函数名，一个是参数
					var ident:GNode=node.childs[0];//
					var vname_arr:Array=[];
					for(i=0;i<ident.childs.length;i++){
						if(ident.childs[i].nodeType==GNodeType.Index){
							vname_arr[i]=getValue(ident.childs[i].childs[0]);
						}else{
							vname_arr[i]=ident.childs[i].word;
						}
					}
					explist=[];
					if(node.childs.length==2){
						param=node.childs[1];
						for(i=0;i<param.childs.length;i++){
							explist[i]=getValue(param.childs[i]);
						}
						
					}
					vname=vname_arr[0];
					if(vname_arr.length==1){
						//API部分
						if(vname=="trace" || vname=="output"){//API
							if(Script.output){
								Script.output(explist.join(","));
							}else{
								trace(explist.join(","));
							}
						}else{
							
							if(__super[vname] is Function){
								return callLocalFunc(__super,vname,explist);
							}else if(__API[vname] is Function){
								return (__API[vname] as Function).apply(null,explist);
								//
							}else if(__rootnode.motheds[vname]==undefined && Script.__globaldy){
								
								if(Script.__globaldy._rootnode.motheds[vname]==undefined){
									//自身不存在该方法
									if(__API[vname]){
										return callLocalFunc(__API,vname,explist);
									}
									for each(var o:* in __API){
										if(o.hasOwnProperty(vname)){//本地方法
											return callLocalFunc(o,vname,explist);
										}
									}
									trace("类和全局都不存在该脚本方法="+vname+",是否缺少imoprt?");
								}else{
									return Script.__globaldy.call(vname,explist);
								}
							}else{
								return call(vname,explist);
							}
						}
						return;
					}
					/**/
					var scope:*=__vars;
					var bottom:int=0;
					if(vname=="this"){
						scope=this;
						bottom=1;
					}else{
						if(scope==null || scope[vname]==undefined){
							//字段变量
							scope=this;
							if(scope[vname]==undefined){
								//看看API是否存在相关的方法
								var loadstatic:Boolean=true;
								if(__API[vname]!=undefined){
									scope=__API[vname];
									bottom=1;
									loadstatic=false;
								}
								if(loadstatic){
									//静态类，或者全局变量
									if(Script._root.loaderInfo.applicationDomain.hasDefinition(vname)){
										scope=Script.getDef(vname);
										bottom=1;
									}else if(Script.__globaldy[vname]){
										scope=Script.__globaldy;
										bottom=0;
									}
								}
							}
						}
					}
					if(scope==null){
						executeError("未定义方法="+vname);
					}
					for(i=bottom;i<vname_arr.length-1;i++){
						scope=scope[vname_arr[i]];
					}
					/*if(scope==null){
					executeError("未定义方法="+vname);
					}*/
					var lastvname:String=vname_arr[vname_arr.length-1];
					//trace(scope,scope is Iterpret);
					if(scope is DY){
						re=scope.call(lastvname,explist);
						return re;
					}else{
						re=callLocalFunc(scope,lastvname,explist);
					}
					return re;
					break;
				default:
					executeError("解析出错=未知的语句");
			}
		}
		[inline]
		protected function onMOP(node:GNode):*{
			var v1:*=getValue(node.childs[0]);
			var v2:*=getValue(node.childs[1]);
			switch(node.word){
				case "+":
					return v1+v2;
				case "-":
					return v1-v2;
				case "*":
					return v1*v2;
				case "/":
					return v1/v2;
				case "%":
					return v1%v2;
				case "|":
					return v1|v2;
				case "&":
					return v1&v2;
				case "<<":
					return v1<<v2;
				case ">>":
					return v1>>v2;
			}
		}
		[inline]
		protected function onCOP(node:GNode):*{
			var v1:*=getValue(node.childs[0]);
			var v2:*=getValue(node.childs[1]);
			switch(node.word){
				case ">":
					return v1>v2;
				case "<":
					return v1<v2;
				case "<=":
					return v1<=v2;
				case ">=":
					return v1>=v2;
				case "==":
					return v1==v2;
				case "!=":
					return v1!=v2;
				case "is":
				case "instanceof":
					return v1 is v2;
				case "as":
					if(v1 is v2){
						return v1;
					}else{
						return null;
					}
				case "in":
					return v1 in v2;
			}
		}
		protected function callLocalFunc(scope:Object,vname:String,explist:Array):*{
			if(scope[vname] is Function){
				return (scope[vname] as Function).apply(scope,explist);
			}
			throw new Error(scope+"不存在"+vname+"方法");
		}
		protected function newLocalClass(c:Class,explist:Array):*{//vname,
			var re:*;
			
			switch (explist.length){
				case 0:
					re=new c();
					break;
				case 1:
					re=new c(explist[0]);
					break;
				case 2:
					re=new c(explist[0],explist[1]);
					break;
				case 3:
					re=new c(explist[0],explist[1],explist[2]);
					break;
				case 4:
					re=new c(explist[0],explist[1],explist[2],explist[3]);
					break;
				case 5:
					re=new c(explist[0],explist[1],explist[2],explist[3],explist[4]);
					break;
				case 6:
					re=new c(explist[0],explist[1],explist[2],explist[3],explist[4],explist[5]);
					break;
				case 7:
					re=new c(explist[0],explist[1],explist[2],explist[3],explist[4],explist[5],explist[6]);
					break;
				case 8:
					re=new c(explist[0],explist[1],explist[2],explist[3],explist[4],explist[5],explist[6],explist[7]);
					break;
				default:
					executeError("解析出错=未知的语句"+c+">"+explist);
			}
			return re;
		}
		protected function executeError(str:String):void{
			
			Script.Debug.log("executeError="+str);
		}
	}
}