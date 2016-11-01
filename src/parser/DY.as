package parser
{
   import flash.utils.getQualifiedClassName;
   import flash.utils.Proxy;
   import flash.utils.flash_proxy;
   import parse.ProxyFunc;
   import parse.Token;
   
   public dynamic class DY extends Proxy
   {
       
      protected var __rootnode:parser.GenTree;
	  protected var __static_rootnode:parser.GenTree;
      
      private var _classname:String;
      
      protected var __vars:Object;
      
      private var local_vars:Array;
      
      protected var __API:Object;
      
      protected var __object:Object;
	  protected var __super:Object;
	  
      protected var isret:Boolean = false;
      
      protected var jumpstates:Array;
      
      protected var lvalue:parser.LValue;
      
	  public function get base():*{
		  return __super;
	  }
      public function DY(rootTree:GenTree, explist:Array = null)
      {
         var o:* = null;
         this.jumpstates = [0];
         this.lvalue = new parser.LValue();
         super();
         this._classname = rootTree.name;
         this.__rootnode = rootTree;
		 __static_rootnode = parser.GenTree.staticBranch[_classname];
		 
         this.local_vars = [];
         this.__API = __rootnode.API;
         this.__API._root = Script._root;
		 
         this.__object = { };
         this.init(explist || []);
      }
      
      public function toString() : String
      {
         return this._classname;
      }
      
      override flash_proxy function callProperty(methodName:*, ... args) : *
      {
         if(methodName is QName)
         {
            methodName = (methodName as QName).localName;
         }
		 
         if(this.__rootnode.motheds[methodName])
         {
            return this.call(methodName,args);
         }
         if(this.__object[methodName] is Function)
         {
            return this.callLocalFunc(this.__object,methodName,args);
         }
		 //hasOwnProperty
		 if(this.__super && this.__super[methodName] is Function)
         {
            return this.callLocalFunc(this.__super,methodName,args);
         }
         this.executeError(this._classname + ">SUPER " + this.__object + ">不存在此方法=" + methodName);
         return null;
      }
      
      override flash_proxy function getProperty(vname:*) : *
      {
		  var na = vname.localName;
		  if(this._rootnode.motheds[na] != undefined)
		  {
			 return ProxyFunc.getAFunc(this,na);//返回函数
		  }
		  var re = this.__object[na];
		  if(re==undefined){
			  if(this.__super){
				  if(this.__super is DY){
					  re = __super[na];
					  
				  }else if(__super.hasOwnProperty(na)){
					  re= __super[na];
				  }
			  }
		  }
		  
         return re;
      }
      
      override flash_proxy function setProperty(name:*, value:*) : void
      {
         this.__object[name] = value;
      }
      
      public function get _rootnode() : parser.GenTree
      {
         return this.__rootnode;
      }
      
      private function init(explist:Array) : void
      {
         var o:GNode = null;
		 
		 if (__rootnode.baseClass) {//存在父类
			if (!__rootnode.callSuper) {
				var identnode:Token = __rootnode.baseClass;// GenTree.Branch[__rootnode.baseClass.word].motheds[__rootnode.baseClass];
				//
			   var arrr = identnode.word.split(".");
			   var c = null;
			   if(this.__API[arrr[arrr.length - 1]])
			   {
				  c = this.__API[arrr[arrr.length - 1]];
			   }
			   else if(Script._root.loaderInfo.applicationDomain.hasDefinition(identnode.word))
			   {
				  c = Script.getDef(identnode.word) as Class;
			   }
			   if(c)
			   {
				  __super= this.newLocalClass(c,[]);
			   }
			   if(parser.GenTree.hasScript(identnode.word))
			   {
				  __super = new DY(GenTree.Branch[identnode.word],[]);
				  trace("成功创建脚本类=" + identnode.word + "的实例");
			   }
			}
		 }
         for each(o in this._rootnode.fields)
         {
            if(o.nodeType != GNodeType.FunDecl)
            {
               this.executeFiledDec(o);
            }
         }
		 
		 
         if(this.__rootnode.motheds[this._classname])
         {
            this.call(this._classname,explist);
         }
      }
      
      private function executeFiledDec(node:GNode) : void
      {
         if(node.nodeType == GNodeType.AssignStm)
         {
            this[node.childs[0].token.word] = this.getValue(node.childs[1]);
         }
         else if(node.nodeType == GNodeType.VarDecl)
         {
            this[node.word] = 0;
         }
      }
      
      private function get jumpstate() : int
      {
         return this.jumpstates[this.jumpstates.length - 1];
      }
      
      private function set jumpstate(v:int) : void
      {
         this.jumpstates[this.jumpstates.length - 1] = v;
      }
      
      public function pushstate() : void
      {
         this.jumpstates.push(0);
      }
      
      public function popstate() : void
      {
         this.jumpstates.pop();
      }
      
      public function call(funcname:String, explist:Array) : *
      {
         var node:GNode = null;
         var tisret:Boolean = false;
         var re:* = null;
         try
         {
            node = this.__rootnode.motheds[funcname];
            if(Boolean(node) && node.nodeType == GNodeType.FunDecl)
            {
               tisret = this.isret;
               this.isret = false;
               this.local_vars.push({});
               this.__vars = this.local_vars[this.local_vars.length - 1];
			   //
               re = this.FunCall(node,explist);
               this.local_vars.pop();
               if(this.local_vars.length > 0)
               {
                  this.__vars = this.local_vars[this.local_vars.length - 1];
               }
               else
               {
                  this.__vars = null;
               }
               this.isret = tisret;
            }
            else if(this.__object[funcname] is Function)
            {
               re = this.callLocalFunc(this.__object,funcname,explist);
            }
            else
            {
               this.executeError(this._classname + "的方法:" + funcname + " 未定义");
            }
         }
         catch(e:Error)
         {
            executeError("调用>" + this._classname + "类的" + funcname + explist + "出错>\r" + e.getStackTrace());
         }
         return re;
      }
      
      private function FunCall(node:GNode, explist:Array) : *
      {
         var param:GNode = null;
         var i:int = 0;
         var stms:GNode = null;
         if(node.nodeType == GNodeType.FunDecl)
         {
            param = node.childs[0];
            for(i = 0; i < param.childs.length; i++)
            {
               this.__vars[param.childs[i].word] = explist[i];
            }
            stms = node.childs[1];
            return this.executeST(node.childs[1]);
         }
      }
      
      public function executeST(node:GNode) : *
      {
         var i:int = 0;
         var re:* = undefined;
         var arr:Array = null;
         var obj:Object = null;
         var lnode:GNode = null;
         var tlvalue:parser.LValue = null;
         var rvalue:* = undefined;
         var cn:GNode = null;
         var exp:* = undefined;
         var jump:Boolean = false;
         var isbreak:Boolean = false;
         var j:int = 0;
         var scope:* = undefined;
         var varname:String = null;
         var o:String = null;
         var oo:* = undefined;
         if(node.nodeType == GNodeType.Stms)
         {
            for(i = 0; i < node.childs.length; i++)
            {
               re = this.executeST(node.childs[i]);
               if(this.isret)
               {
                  return re;
               }
               if(this.jumpstate > 0)
               {
                  return;
               }
            }
         }
		 else if(node.nodeType == GNodeType.IDENT)
         {
			 //表达式。
			 getValue(node);
		 }
         else if(node.nodeType == GNodeType.AssignStm)
         {
            lnode = node.childs[0];
            tlvalue = new parser.LValue();
            if(lnode.nodeType == GNodeType.VarDecl)
            {
               if(this.__vars)
               {
                  tlvalue.scope = this.__vars;
                  tlvalue.key = node.childs[0].word;
               }
               else
               {
                  tlvalue.scope = this;
                  tlvalue.key = node.childs[0].word;
               }
            }
            else
            {
               this.getLValue(lnode);
               tlvalue.scope = this.lvalue.scope;
               tlvalue.key = this.lvalue.key;
               if(tlvalue.key == null)
               {
                  throw new Error("左值取值失败=" + lnode.toString());
               }
            }
            rvalue = this.getValue(node.childs[1]);
            switch(node.word)
            {
               case "=":
                  tlvalue.scope[tlvalue.key] = rvalue;
                  break;
               case "+=":
                  tlvalue.scope[tlvalue.key] = tlvalue.scope[tlvalue.key] + rvalue;
                  break;
               case "-=":
                  tlvalue.scope[tlvalue.key] = tlvalue.scope[tlvalue.key] - rvalue;
                  break;
               case "*=":
                  tlvalue.scope[tlvalue.key] = tlvalue.scope[tlvalue.key] * rvalue;
                  break;
               case "/=":
                  tlvalue.scope[tlvalue.key] = tlvalue.scope[tlvalue.key] / rvalue;
                  break;
               case "%=":
                  tlvalue.scope[tlvalue.key] = tlvalue.scope[tlvalue.key] % rvalue;
            }
         }
         else
         {
            if(node.nodeType == GNodeType.IfElseStm)
            {
               i = 0;
               while(true)
               {
                  if(i < node.childs.length)
                  {
                     cn = node.childs[i];
                     if(cn.nodeType == GNodeType.ELSEIF)
                     {
                        exp = this.getValue(cn.childs[0]);
                        if(exp)
                        {
                           re = this.executeST(cn.childs[1]);
                           if(this.isret)
                           {
                              return re;
                           }
                           if(this.jumpstate > 0)
                           {
                              return;
                           }
						   return;
                        }
                     }
                     else
                     {
                        re = this.executeST(cn);
                        if(this.isret)
                        {
                           break;
                        }
                        if(this.jumpstate > 0)
                        {
                           return;
                        }
                     }
                     i++;
                     continue;
                  }else {
					 break
				  }
               }
               return re;
            }
            if(node.nodeType == GNodeType.SWITCH)
            {
               this.pushstate();
               try
               {
                  exp = this.getValue(node.childs[0]);
                  jump = false;
                  isbreak = true;
                  for(i = 1; i < node.childs.length; i++)
                  {
                     if(jump)
                     {
                        break;
                     }
                     cn = node.childs[i];
                     if(cn.nodeType == GNodeType.CASE)
                     {
                        if(isbreak == false || Boolean(isbreak) && exp == this.getValue(cn.childs[0]))
                        {
                           isbreak = false;
                           for(j = 1; j < cn.childs.length; j++)
                           {
                              if((cn.childs[j] as GNode).nodeType == GNodeType.BREAK)
                              {
                                 jump = true;
                                 isbreak = true;
                                 break;
                              }
                              re = this.executeST(cn.childs[j]);
                              if(this.isret)
                              {
                                 return re;
                              }
                           }
                        }
                     }
                     else if(cn.nodeType == GNodeType.DEFAULT)
                     {
                        for(j = 0; j < cn.childs.length; j++)
                        {
                           if((cn.childs[j] as GNode).nodeType == GNodeType.BREAK)
                           {
                              jump = true;
                              break;
                           }
                           re = this.executeST(cn.childs[j]);
                           if(this.isret)
                           {
                              return re;
                           }
                        }
                     }
                  }
               }
               finally
               {
                  this.popstate();
               }
            }
            else
            {
               if(node.nodeType == GNodeType.INCREMENT)
               {
                  return this.onINCREMENT(node);
               }
               if(node.nodeType == GNodeType.PREINCREMENT)
               {
                  return this.onPREINCREMENT(node);
               }
               if(node.nodeType == GNodeType.VarDecl)
               {
                  scope = this.__vars || this;
                  scope[node.word] = 0;
               }
               else
               {
                  if(node.nodeType == GNodeType.ReturnStm)
                  {
                     if(node.childs.length > 0)
                     {
                        re = this.getValue(node.childs[0]);
                        this.isret = true;
                        return re;
                     }
                     this.isret = true;
                     return undefined;
                  }
                  if(node.nodeType == GNodeType.CONTINUE)
                  {
                     this.jumpstate = 2;
                  }
                  else if(node.nodeType == GNodeType.BREAK)
                  {
                     this.jumpstate = 1;
                  }
                  else if(node.nodeType == GNodeType.WhileStm)
                  {
                     this.pushstate();
                     try
                     {
                        while(this.getValue(node.childs[0]))
                        {
                           re = this.executeST(node.childs[1]);
                           if(this.isret)
                           {
                              return re;
                           }
                           if(this.jumpstate == 1)
                           {
                              break;
                           }
                           this.jumpstate = 0;
                        }
                     }
                     finally
                     {
                        this.popstate();
                     }
                  }
                  else if(node.nodeType == GNodeType.ForStm)
                  {
                     this.executeST(node.childs[0]);
                     this.pushstate();
                     try
                     {
                        while(this.getValue(node.childs[1]))
                        {
                           re = this.executeST(node.childs[3]);
                           if(this.isret)
                           {
                              return re;
                           }
                           if(this.jumpstate == 1)
                           {
                              break;
                           }
                           this.jumpstate = 0;
                           this.executeST(node.childs[2]);
                        }
                     }
                     finally
                     {
                        this.popstate();
                     }
                  }
                  else if(node.nodeType == GNodeType.ForInStm)
                  {
                     varname = node.childs[0].word;
                     obj = this.getValue(node.childs[1]);
                     this.pushstate();
                     try
                     {
                        for(o in obj)
                        {
                           this.__vars[varname] = o;
                           re = this.executeST(node.childs[2]);
                           if(this.isret)
                           {
                              return re;
                           }
                           if(this.jumpstate == 1)
                           {
                              break;
                           }
                           this.jumpstate = 0;
                        }
                     }
                     finally
                     {
                        this.popstate();
                     }
                  }
                  else if(node.nodeType == GNodeType.ForEACHStm)
                  {
                     varname = node.childs[0].word;
                     obj = this.getValue(node.childs[1]);
                     this.pushstate();
                     try
                     {
                        for each(oo in obj)
                        {
                           this.__vars[varname] = oo;
                           re = this.executeST(node.childs[2]);
                           if(this.isret)
                           {
                              return re;
                           }
                           if(this.jumpstate == 1)
                           {
                              break;
                           }
                           this.jumpstate = 0;
                        }
                     }
                     finally
                     {
                        this.popstate();
                     }
                  }
                  else if(node.nodeType == GNodeType.importStm)
                  {
                     arr = node.word.split(".");
                     this.__API[arr[arr.length - 1]] = Script.getDef(node.word);
                  }
               }
            }
         }
      }
      
      protected function onINCREMENT(node:GNode) : Number
      {
         var re:Number = NaN;
         this.getLValue(node.childs[0]);
         if(this.lvalue.key != null)
         {
            if(node.word == "++")
            {
               re = this.lvalue.scope[this.lvalue.key];
               this.lvalue.scope[this.lvalue.key] = this.lvalue.scope[this.lvalue.key] + 1;
               return re;
            }
            if(node.word == "--")
            {
               re = this.lvalue.scope[this.lvalue.key];
               this.lvalue.scope[this.lvalue.key] = this.lvalue.scope[this.lvalue.key] - 1;
               return re;
            }
            this.executeError("解释出错=递增操作符未设置值");
         }
         return 0;
      }
      
      protected function onPREINCREMENT(node:GNode) : Number
      {
         this.getLValue(node.childs[0]);
         if(this.lvalue.key != null)
         {
            if(node.word == "++")
            {
               this.lvalue.scope[this.lvalue.key] = this.lvalue.scope[this.lvalue.key] + 1;
               return this.lvalue.scope[this.lvalue.key];
            }
            if(node.word == "--")
            {
               this.lvalue.scope[this.lvalue.key] = this.lvalue.scope[this.lvalue.key] - 1;
               return this.lvalue.scope[this.lvalue.key];
            }
            this.executeError("解释出错=递增操作符未设置值");
            return this.lvalue.scope[this.lvalue.key];
         }
         return 0;
      }
      
      protected function getLValue(node:GNode) : void
      {
         var var_arr:Array = null;
         var i:int = 0;
         var vname:String = null;
         var scope:* = undefined;
         var bottem:int = 0;
         var v:* = undefined;
         var lastv:String = null;
         this.lvalue.scope = null;
         this.lvalue.key = null;
		 this.lvalue.params = null;
		 
         if(node.gtype == GNodeType.IDENT)
         {
            var_arr = [];
            for(i = 0; i < node.childs.length; i++)
            {
               if(node.childs[i].nodeType == GNodeType.Index)
               {
                  var_arr.push(this.getValue(node.childs[i].childs[0]));
				  
               }else if(node.childs[i].nodeType == GNodeType.FunCall)
               {
				   //表达式列表
				   var explist:Array = [];
				   if(node.childs[i].childs.length>0){
						var exps:GNode = node.childs[i].childs[0];
					   //
					   for (var z:int = 0; z < exps.childs.length;z++){
							explist.push(this.getValue(exps.childs[z]));
					   }   
				   }				   
                  var_arr.push(explist);
               }
               else
               {
                  var_arr.push(node.childs[i].word);
               }
            }
            vname = var_arr[0];
            scope = null;
            bottem = 0;
			//
			
            if(vname == "this")
            {
               scope = this;
               bottem = 1;
            }
            else if(vname == "super")
            {
               scope = this.__super;//有2种情况,一种是调用构造函数
			   if (var_arr.length == 2 && node.childs[1].nodeType == GNodeType.FunCall) {
				   var identnode:Token = __rootnode.baseClass;// GenTree.Branch[__rootnode.baseClass.word].motheds[__rootnode.baseClass];
					//
				   var arrr = identnode.word.split(".");
				   var c = null;
				   if(this.__API[arrr[arrr.length - 1]])
				   {
					  c = this.__API[arrr[arrr.length - 1]];
				   }
				   else if(Script._root.loaderInfo.applicationDomain.hasDefinition(identnode.word))
				   {
					  c = Script.getDef(identnode.word) as Class;
				   }
				   if(c)
				   {
					  __super= this.newLocalClass(c,var_arr[1]);
				   }
				   if(parser.GenTree.hasScript(identnode.word))
				   {
					  __super = new DY(GenTree.Branch[identnode.word],var_arr[1]);
					  trace("成功创建脚本类=" + identnode.word + "的实例");
				   }
				   return;//特殊情况，直接赋值
			   } 
				   
			   bottem = 1;
            }
            else if(Boolean(this.__vars) && this.__vars[vname] != undefined)
            {
               scope = this.__vars;
            }
            else if(this.__object.hasOwnProperty(vname) || (getQualifiedClassName(this.__object)=="Object" && this.__object[vname] != undefined))
            {
               scope = this;
            }
			else if(this.__super!=null && (__super.hasOwnProperty(vname) || (this.__super is DY && (this.__super as DY)._rootnode.motheds[vname])))
            {
               scope = this.__super;
            }
            else if(this._rootnode.motheds[vname])
            {
               scope = this;
            }else if(this.__static_rootnode && (this.__static_rootnode.motheds[vname] || this.__static_rootnode.fields[vname]))
            {
				//本类的静态方法,指向本类的静态实例
               scope = __static_rootnode.instance;
            }
            else if(this.__API[vname])
            {
               scope = this.__API;
            }
            else if(Script.__globaldy[vname])
            {
               scope = Script.__globaldy;
            }else if (parser.GenTree.staticBranch[vname]) {
				//指向其他静态类
				scope = parser.GenTree.staticBranch[vname].instance;
				bottem = 1;
			}
			else if(Script._root && Boolean(Script._root.loaderInfo.applicationDomain.hasDefinition(vname)))
            {
               scope = Script.getDef(vname);
               bottem = 1;
            }
            if(!scope)
            {
               scope = this.__vars;
            }
            v = scope;
			
            if(v)
            {
               if(var_arr.length < bottem)
               {
                  this.lvalue.scope = v;
               }
               for(i = bottem; i < var_arr.length - 1; i++)
               {
                  if(v)
                  {
					  if (v is Function) {
						 if ( var_arr[i] is Array) {
							if (scope is DY) {
								v = (v as Function).apply(null, var_arr[i]);
							}else{
								v=(v as Function).apply(scope,var_arr[i])		
							}
							
						 }
					  }else {
						scope = v;
						v = v[var_arr[i]];
					  }
                  }
               }
               if(v != undefined)
               {
				  if (v is Function) {
					  //倒数一层为函数，最后可能为调用，也可能
					this.lvalue.scope = scope;
					this.lvalue.key = var_arr[var_arr.length - 2];
					this.lvalue.params = var_arr[var_arr.length - 1];  
					 
				  }else {
					lastv = var_arr[var_arr.length - 1];
					this.lvalue.scope = v;
					this.lvalue.key = lastv;
					this.lvalue.params = null;
				  }
               }
            }
         }
      }
      
      public function getValue(node:GNode) : *
      {
         var v1:* = undefined;
         var c:Class = null;
         var identnode:GNode = null;
         var arrr:Array = null;
         var re:* = undefined;
         var ident:GNode = null;
         var vname_arr:Array = null;
         var scope:* = undefined;
         var bottom:int = 0;
         var lastvname:String = null;
         var vname:String = null;
         var exps:GNode = null;
         var explist:Array = null;
         var newobj:Object = null;
         var param:GNode = null;
         var i:int = 0;
         var o:* = undefined;
         var loadstatic:Boolean = false;
         switch(node.nodeType)
         {
            case GNodeType.IDENT:
               
               this.getLValue(node);
               if(this.lvalue.key != null)
               {
				  return this.lvalue.Value;
               }
               else if(this.lvalue.scope)
               {
                  return this.lvalue.scope;
               }
               return undefined;
            case GNodeType.VarID:
               return node.word;
            case GNodeType.ConstID:
               return node.value;
            case GNodeType.MOP:
               return this.onMOP(node);
            case GNodeType.LOP:
               v1 = this.getValue(node.childs[0]);
               if(node.word == "||" || node.word == "or")
               {
                  if(v1)
                  {
                     return true;
                  }
                  return v1 || this.getValue(node.childs[1]);
               }
               if(node.word == "&&" || node.word == "and")
               {
                  if(!v1)
                  {
                     return false;
                  }
                  return v1 && this.getValue(node.childs[1]);
               }
               break;
            case GNodeType.LOPNot:
               v1 = this.getValue(node.childs[0]);
               return !v1;
            case GNodeType.Nagtive:
               v1 = this.getValue(node.childs[0]);
               return -v1;
            case GNodeType.INCREMENT:
               return this.onINCREMENT(node);
            case GNodeType.PREINCREMENT:
               return this.onPREINCREMENT(node);
            case GNodeType.COP:
               return this.onCOP(node);
            case GNodeType.newArray:
               if(node.childs.length > 0)
               {
                  exps = node.childs[0];
                  explist = [];
                  for(i = 0; i < exps.childs.length; i++)
                  {
                     explist[i] = this.getValue(exps.childs[i]);
                  }
                  return explist;
               }
               return [];
            case GNodeType.newObject:
               if(node.childs.length > 0)
               {
                  newobj = {};
                  for(i = 0; i < node.childs.length; i = i + 2)
                  {
                     newobj[node.childs[i].word] = this.getValue(node.childs[i + 1]);
                  }
                  return newobj;
               }
               return {};
            case GNodeType.newClass:
               identnode = node.childs[0];
               arrr = identnode.word.split(".");
               if(this.__API[arrr[arrr.length - 1]])
               {
                  c = this.__API[arrr[arrr.length - 1]];
               }
               else if(Script._root.loaderInfo.applicationDomain.hasDefinition(identnode.word))
               {
                  c = Script.getDef(identnode.word) as Class;
               }
               explist = [];
               if(node.childs.length == 2)
               {
                  param = node.childs[1];
                  for(i = 0; i < param.childs.length; i++)
                  {
                     explist[i] = this.getValue(param.childs[i]);
                  }
               }
               if(c)
               {
                  return this.newLocalClass(c,explist);
               }
               if(parser.GenTree.hasScript(identnode.word))
               {
                  re = new DY(GenTree.Branch[identnode.word],explist);
                  trace("成功创建脚本类=" + identnode.word + "的实例");
                  return re;
               }
               trace("脚本类=" + identnode.word + "尚未定义");
               return null;
		 }
      }
      
      protected function onMOP(node:GNode) : *
      {
         var v1:* = this.getValue(node.childs[0]);
         var v2:* = this.getValue(node.childs[1]);
         switch(node.word)
         {
            case "+":
               return v1 + v2;
            case "-":
               return v1 - v2;
            case "*":
               return v1 * v2;
            case "/":
               return v1 / v2;
            case "%":
               return v1 % v2;
            case "|":
               return v1 | v2;
            case "&":
               return v1 & v2;
            case "<<":
               return v1 << v2;
            case ">>":
               return v1 >> v2;
            default:
               return;
         }
      }
      
      protected function onCOP(node:GNode) : *
      {
         var v1:* = this.getValue(node.childs[0]);
         var v2:* = this.getValue(node.childs[1]);
         switch(node.word)
         {
            case ">":
               return v1 > v2;
            case "<":
               return v1 < v2;
            case "<=":
               return v1 <= v2;
            case ">=":
               return v1 >= v2;
            case "==":
               return v1 == v2;
            case "!=":
               return v1 != v2;
            case "is":
            case "instanceof":
				if(v1 is DY && v2 is DY){
					//这里有一些脚本类的判断可以做=======
				}
               return v1 is v2;
            case "as":
               if(v1 is v2)
               {
                  return v1;
               }
               return null;
            case "in":
               return v1 in v2;
            default:
               return;
         }
      }
      
      protected function callLocalFunc(scope:Object, vname:String, explist:Array) : *
      {
         if(scope[vname] is Function)
         {
            return (scope[vname] as Function).apply(scope,explist);
         }
         throw new Error(scope + "不存在" + vname + "方法");
      }
      
      protected function newLocalClass(c:Class, explist:Array) : *
      {
         var re:* = undefined;
         switch(explist.length)
         {
            case 0:
               re = new c();
               break;
            case 1:
               re = new c(explist[0]);
               break;
            case 2:
               re = new c(explist[0],explist[1]);
               break;
            case 3:
               re = new c(explist[0],explist[1],explist[2]);
               break;
            case 4:
               re = new c(explist[0],explist[1],explist[2],explist[3]);
               break;
            case 5:
               re = new c(explist[0],explist[1],explist[2],explist[3],explist[4]);
               break;
            case 6:
               re = new c(explist[0],explist[1],explist[2],explist[3],explist[4],explist[5]);
               break;
            case 7:
               re = new c(explist[0],explist[1],explist[2],explist[3],explist[4],explist[5],explist[6]);
               break;
            case 8:
               re = new c(explist[0],explist[1],explist[2],explist[3],explist[4],explist[5],explist[6],explist[7]);
               break;
            default:
               this.executeError("解析出错=未知的语句" + c + ">" + explist);
         }
         return re;
      }
      
      protected function executeError(str:String) : void
      {
         trace("executeError=" + str);
      }
   }
}
