package parser
{
	import parse.ProxyFunc;

	public class DY2 extends DY
	{
		private var funcs:Vector.<Function>;
		public  function DY2(clname:String="__DY",explist:Array=null){
			funcs=new Vector.<Function>(50,true);
			funcs[GNodeType.IDENT]=onIDENT;
			funcs[GNodeType.VarID]=onVarID;
			funcs[GNodeType.ConstID]=onConstID;
			funcs[GNodeType.MOP]=onMOP;
			funcs[GNodeType.LOP]=onLOP;
			funcs[GNodeType.LOPNot]=onLOPNot;
			funcs[GNodeType.Nagtive]=onNagtive;
			funcs[GNodeType.INCREMENT]=onINCREMENT;
			funcs[GNodeType.PREINCREMENT]=onPREINCREMENT;
			funcs[GNodeType.COP]=onCOP;
			funcs[GNodeType.newArray]=onnewArray;
			funcs[GNodeType.newClass]=onnewClass;
			funcs[GNodeType.newObject]=onnewObject;
			funcs[GNodeType.FunCall]=onFunCall;
			super(clname,explist);
			
		}
		//
		private function onIDENT(node:GNode):*{
			if(node.childs.length==1){
				//快速通道,优化目的
				var vname:String=node.childs[0].word;
				if(__vars && __vars[vname]!=undefined){
					return __vars[vname];
				}else if(__super[vname]!=undefined){
					return __super[vname];
				}else if(this._rootnode.motheds[vname]!=undefined){
					return ProxyFunc.getAFunc(this,vname);
				}else if(__API[vname]!=undefined){
					return __API[vname];
				}else if(vname=="this"){
					return this;
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
		}
		[inline]
		private function onVarID(node:GNode):String{
			return node.word;
		}
		[inline]
		private function onConstID(node:GNode):*{
			return node.value;
		}
		[inline]
		private function onLOP(node:GNode):*{
			var v1:*=getValue(node.childs[0]);
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
		}
		[inline]
		private function onLOPNot(node:GNode):Boolean{
			return !getValue(node.childs[0]);
			
		}
		[inline]
		private function onNagtive(node:GNode):Number{
			return -getValue(node.childs[0]);
		}
		[inline]
		private function onnewArray(node:GNode):Array{
			if(node.childs.length>0){
				var exps:GNode=node.childs[0];
				var explist:Array=[];
				for(var i:int=0;i<exps.childs.length;i++){
					explist[i]=getValue(exps.childs[i]);
				}
				return explist;
			}
			return [];
		}
		[inline]
		private function onnewObject(node:GNode):Object{
			if(node.childs.length>0){
				var newobj:Object={};
				for(var i:int=0;i<node.childs.length;i+=2){
					newobj[node.childs[i].word]=getValue(node.childs[i+1]);
				}
				return newobj;
			}
			return {};
		}
		[inline]
		private function onnewClass(node:GNode):*{
			var c:Class;
			var identnode:GNode=node.childs[0];
			//
			var arrr:Array=identnode.word.split(".");
			if(__API[arrr[arrr.length-1]]){
				c=__API[arrr[arrr.length-1]];
			}else if(Script._root.loaderInfo.applicationDomain.hasDefinition(identnode.word)){
				c=Script.getDef(identnode.word) as Class;
			}
			
			var explist:Array=[];
			if(node.childs.length==2){
				var param:GNode=node.childs[1];
				for(var i:int=0;i<param.childs.length;i++){
					explist[i]=getValue(param.childs[i]);
				}
			}
			if(c){
				var re:*;
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
		}
		private function onFunCall(node:GNode):*{
			//2个子节点，一个是函数名，一个是参数
			var ident:GNode=node.childs[0];//
			var vname_arr:Array=[];
			var i:int;
			for(i=0;i<ident.childs.length;i++){
				if(ident.childs[i].nodeType==GNodeType.Index){
					vname_arr[i]=getValue(ident.childs[i].childs[0]);
				}else{
					vname_arr[i]=ident.childs[i].word;
				}
			}
			var explist:Array=[];
			if(node.childs.length==2){
				var param:GNode=node.childs[1];
				for(i=0;i<param.childs.length;i++){
					explist[i]=getValue(param.childs[i]);
				}
			}
			var vname:String=vname_arr[0];
			if(vname_arr.length==1){
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
			var re:*;
			if(scope is DY){
				re=scope.call(lastvname,explist);
				return re;
			}else{
				re=callLocalFunc(scope,lastvname,explist);
			}
			return re;
		}
		[inline]
		override public function getValue(node:GNode):*{
			return funcs[node.nodeType](node);
		}
	}
}