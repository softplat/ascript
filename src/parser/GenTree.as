package parser
{
   import air.update.descriptors.ConfigurationDescriptor;
   import flash.utils.getDefinitionByName;
   import parse.Token;
   import parse.Lex;
   import parse.TokenType;
   
   public class GenTree
   {
      
      public static var Branch:Object = { };
	  public static var staticBranch:Object = {};
       
      private var tok:Token;
      
      public var lex:Lex;
      
      private var index:int = 0;
      
      public var name:String;
      
      public var API:Object;
      
      public var imports:Object;
      
      public var motheds:Object;
      
      public var fields:Object;
      
      public var Package:String = "";
	  //构造函数里面存在super么。。。
	  public var baseClass:Token;
	  public var callSuper:Boolean=false;
      
	  public var instance:DY;
	  static public function create(code:String = null):GenTree 
	  {
		  var A:GenTree = new GenTree();
		  A.parse(code);
		  //移除所有静态的字段到B里面
		  var B:GenTree = new GenTree();
		  B.name = A.name;
		  var arr:Array = [];
		  for(var n in A.motheds){
			  if(A.motheds[n].istatic){
				  B.motheds[n] = A.motheds[n];
				  arr.push(n);
			  }
		  }
		  for each (var n in arr) {
			  delete A.motheds[n];
		  }
		  //
		  arr = [];
		  for(var n in A.fields){
			  if(A.fields[n].istatic){
				  B.fields[n] = A.fields[n];
				  arr.push(n);
			  }
		  }
		  for each (var n in arr) {
			  delete A.fields[n];
		  }
		  
		  B.instance = new DY(B);//创建一个静态类的实例
		  staticBranch[B.name] = B;//静态类
		  return A;
	  }
      public function GenTree()
      {
         this.API = {};//这个对象作为静态方法的代理
         this.imports = {};
         this.motheds = {};
         this.fields = {};
         super();
	  }
	  private function parse(code:String):void 
	  {
         if(code)
         {
            this.lex = new Lex(code);
            this.index = 0;
            this.nextToken();
            this.PACKAGE();
            Branch[this.name] = this;
            if(this.name != "____globalclass")
            {
               trace("脚本类:" + this.name + "解析完成,可以创建其实例了");
            }
         }
      }
      
      public static function hasScript(scname:String) : Boolean
      {
         var File:Class = null;
         var FileStream:Class = null;
         var FileMode:Class = null;
         var f:Object = null;
         var fs:Object = null;
         var str:String = null;
         if(Script.app.hasDefinition("flash.filesystem.FileStream"))
         {
            if(!Branch[scname])
            {
               File = getDefinitionByName("flash.filesystem.File") as Class;
               FileStream = getDefinitionByName("flash.filesystem.FileStream") as Class;
               FileMode = getDefinitionByName("flash.filesystem.FileMode") as Class;
               f = File.applicationDirectory.resolvePath(Script.scriptdir + scname + ".as");
               if(f.exists)
               {
                  fs = new FileStream();
                  fs.open(f,FileMode.READ);
                  str = fs.readUTFBytes(f.size);
                  fs.close();
                  trace("load==" + scname);
                  Script.LoadFromString(str);
               }
               else
               {
                  trace(scname + "不存在");
               }
            }
         }
         if(Branch[scname])
         {
            return true;
         }
         return false;
      }
      
      public function toString() : String
      {
         var o:* = null;
         var c:String = null;
         var str:String = "";
         str = str + ("package" + this.Package + "{\r");
         for(o in this.imports)
         {
            str = str + ("import " + o + ";\r");
         }
         str = str + ("class " + this.name + "{\r");
         for(o in this.fields)
         {
            c = (this.fields[o] as GNode).toString();
         }
         for(o in this.motheds)
         {
            c = (this.motheds[o] as GNode).toString();
            str = str + (c + "\r");
         }
         str = str + "}\r";
         str = str + "}";
		 
         return str;//.replace(/protected/g,"");
      }
      
      public function declares(_lex:Lex) : GNode
      {
         var tnode:GNode = null;
         this.lex = _lex;
         this.index = 0;
         this.nextToken();
         var cnode:GNode = new GNode(GNodeType.Stms);
         while(this.tok)
         {
            if(this.tok.type == TokenType.keyvar)
            {
               tnode = this.varst();
               this.fields[tnode.name] = tnode;
               cnode.addChild(tnode);
            }
            else if(this.tok.type == TokenType.keyfunction)
            {
               tnode = this.func();
               this.motheds[tnode.name] = tnode;
            }
            else
            {
               tnode = this.st();
               if(tnode.name)
               {
                  this.fields[tnode.name] = tnode;
               }
               cnode.addChild(tnode);
            }
         }
         return cnode;
      }
      
      public function declare(_lex:Lex) : GNode
      {
         var cnode:GNode = null;
         this.lex = _lex;
         this.index = 0;
         this.nextToken();
         if(this.tok.type == TokenType.keyvar)
         {
            cnode = this.varst();
            this.fields[cnode.name] = cnode;
         }
         else if(this.tok.type == TokenType.keyfunction)
         {
            cnode = this.func();
            this.motheds[cnode.name] = cnode;
         }
         else if(this.tok.type == TokenType.LBRACE)
         {
            cnode = this.stlist();
         }
         else
         {
            cnode = this.st();
         }
         return cnode;
      }
      
      private function doimport() : GNode
      {
         this.match(TokenType.keyimport);
         var vname_arr:Array = [];
         vname_arr[0] = this.tok.word;
         this.match(TokenType.ident);
         while(this.tok.type == TokenType.DOT)
         {
            this.match(TokenType.DOT);
            vname_arr.push(this.tok.word);
            this.match(TokenType.ident);
         }
         var cnode:GNode = new GNode(GNodeType.importStm);
         cnode.word = vname_arr.join(".");
         this.API[vname_arr[vname_arr.length - 1]] = Script.getDef(cnode.word);
         this.imports[cnode.word] = true;
         if(this.tok.type == TokenType.Semicolon)
         {
            this.match(TokenType.Semicolon);
         }
         return cnode;
      }
      
      private function PACKAGE() : void
      {
         var vname_arr:Array = null;
         if(this.tok.type == TokenType.keypackage)
         {
            this.match(TokenType.keypackage);
            if(this.tok.type == TokenType.ident)
            {
               vname_arr = [];
               vname_arr[0] = this.tok.word;
               this.match(TokenType.ident);
               while(this.tok.type == TokenType.DOT)
               {
                  this.match(TokenType.DOT);
                  vname_arr.push(this.tok.word);
                  this.match(TokenType.ident);
               }
               this.Package = vname_arr.join(".");
            }
            this.match(TokenType.LBRACE);
            this.CLASS();
            this.match(TokenType.RBRACE);
         }
         else
         {
            this.CLASS();
         }
      }
      
      private function CLASS() : void
      {
         while(this.tok.type == TokenType.keyimport)
         {
            this.doimport();
         }
         switch(this.tok.type)
         {
            case TokenType.keyclass:
               this.match(TokenType.keyclass);
               this.name = this.tok.word;
               this.match(TokenType.ident);
               if(this.tok.type == TokenType.keyextends)
               {
                  this.match(TokenType.keyextends);
				  this.baseClass = this.tok;
                  this.match(TokenType.ident);
               }
               this.match(TokenType.LBRACE);
               this.DecList();
               this.match(TokenType.RBRACE);
               break;
            default:
               this.error();
         }
      }
      
      private function DecList() : void
      {
         var cnode:GNode = null;
         var vis:String = null;
         while (this.tok.type == TokenType.keyimport || this.tok.type == TokenType.keyvar ||
		 this.tok.type == TokenType.keyfunction || this.tok.type == TokenType.keystatic)
         {
			 if(this.tok.type == TokenType.keystatic)
            {//静态 =======
				var istatic:Boolean = true;
               this.nextToken();
			   if(this.tok.type == TokenType.keyvar)
               {
                  cnode = this.varst();
                  this.fields[cnode.name] = cnode;
               }
               else if(this.tok.type == TokenType.keyfunction)
               {
                  cnode = this.func();
                  this.motheds[cnode.name] = cnode;
               }
			   cnode.istatic = istatic;
            }else {				
				if(this.tok.type == TokenType.keyimport)
				{
				   this.doimport();
				}
				else if(this.tok.type == TokenType.keyvar)
				{
				   cnode = this.varst();
				   this.fields[cnode.name] = cnode;
				}
				else if(this.tok.type == TokenType.keyfunction)
				{
				   cnode = this.func();
				   this.motheds[cnode.name] = cnode;
				}
			}
         }
      }
      
      private function func() : GNode
      {
         var cnode:GNode = null;
         switch(this.tok.type)
         {
            case TokenType.keyfunction:
               this.match(TokenType.keyfunction);
               cnode = new GNode(GNodeType.FunDecl, this.tok);
			   var funcname = this.tok.word;
               cnode.vartype = "void";
			   __callsuper = false;
               this.match(TokenType.ident);
			   
               this.match(TokenType.LParent);
               cnode.addChild(this.ParamList());
               this.match(TokenType.RParent);
               if(this.tok.type == TokenType.Colon)
               {
                  this.match(TokenType.Colon);
                  cnode.vartype = this.tok.word;
                  this.match(this.tok.type);
               }
               cnode.addChild(this.stlist());
			   
			   if(funcname==this.name &&　__callsuper){//构造函数内有调用super
				   callSuper = true;
			   }
               return cnode;
            default:
               this.error();
               return null;
         }
      }
      
      private function ParamList() : GNode
      {
         var cnode:GNode = new GNode(GNodeType.Params);
         switch(this.tok.type)
         {
            case TokenType.ident:
               cnode.addChild(new GNode(GNodeType.VarID,this.tok));
               this.match(TokenType.ident);
               if(this.tok.type == TokenType.Colon)
               {
                  this.match(TokenType.Colon);
                  cnode.vartype = this.tok.word;
                  this.match(this.tok.type);
               }
               while(this.tok.type == TokenType.COMMA)
               {
                  this.match(TokenType.COMMA);
                  cnode.addChild(new GNode(GNodeType.VarID,this.tok));
                  this.match(TokenType.ident);
                  if(this.tok.type == TokenType.Colon)
                  {
                     this.match(TokenType.Colon);
                     cnode.vartype = this.tok.word;
                     this.match(this.tok.type);
                  }
               }
               break;
            case TokenType.RParent:
               break;
            default:
               this.error();
         }
         return cnode;
      }
      
      private function stlist() : GNode
      {
         var cnode:GNode = new GNode(GNodeType.Stms);
         switch(this.tok.type)
         {
            case TokenType.LBRACE:
               this.match(TokenType.LBRACE);
               while(this.tok.type != TokenType.RBRACE)
               {
                  cnode.addChild(this.st());
               }
               this.match(TokenType.RBRACE);
               break;
            default:
               this.error();
         }
         return cnode;
      }
      
      private function st() : GNode
      {
         var cnode:GNode = null;
         var tnode:GNode = null;
         var ccc:int = 0;
         var tindex:int = 0;
         var tempnode:GNode = null;
         switch(this.tok.type)
         {
            case TokenType.keyif:
               cnode = new GNode(GNodeType.IfElseStm);
			   //============////============
               tnode = new GNode(GNodeType.ELSEIF);
               this.match(TokenType.keyif);
               this.match(TokenType.LParent);
               tnode.addChild(this.EXP());
               this.match(TokenType.RParent);
			   //
               tnode.addChild(this.stlist());
               cnode.addChild(tnode);
               while(this.tok && this.tok.type == TokenType.keyelse)
               {
                  this.match(TokenType.keyelse);
                  if(this.tok.type == TokenType.keyif)
                  {
                     this.match(TokenType.keyif);
                     tnode = new GNode(GNodeType.ELSEIF);
                     this.match(TokenType.LParent);
                     tnode.addChild(this.EXP());
                     this.match(TokenType.RParent);
                     tnode.addChild(this.stlist());
                     cnode.addChild(tnode);
                  }
                  else
                  {
                     cnode.addChild(this.stlist());
                  }
               }
               return cnode;
            case TokenType.keyfor:
               this.match(TokenType.keyfor);
               if(this.tok.type == TokenType.keyeach)
               {
                  this.match(TokenType.keyeach);
                  this.match(TokenType.LParent);
                  cnode = new GNode(GNodeType.ForEACHStm);
                  if(this.tok.type == TokenType.keyvar)
                  {
                     this.match(TokenType.keyvar);
                  }
                  if(this.tok.type == TokenType.ident)
                  {
                     cnode.addChild(new GNode(GNodeType.VarDecl,this.tok));
                     this.match(TokenType.ident);
                     if(this.tok.type == TokenType.Colon)
                     {
                        this.match(TokenType.Colon);
                        cnode.childs[0].vartype = this.tok.word;
                        this.match(this.tok.type);
                     }
                     this.match(TokenType.COP,"in");
                     cnode.addChild(this.EXP());
                     this.match(TokenType.RParent);
                     cnode.addChild(this.stlist());
                  }
                  else
                  {
                     throw Error("for each 匹配失败");
                  }
               }
               else
               {
                  this.match(TokenType.LParent);
                  if(this.lex.words[this.index + 1].type == TokenType.COP || this.lex.words[this.index + 2].type == TokenType.COP)
                  {
                     cnode = new GNode(GNodeType.ForInStm);
                     if(this.tok.type == TokenType.keyvar)
                     {
                        this.match(TokenType.keyvar);
                     }
                     if(this.tok.type == TokenType.ident)
                     {
                        cnode.addChild(new GNode(GNodeType.VarDecl,this.tok));
                        this.match(TokenType.ident);
                        this.match(TokenType.COP,"in");
                        cnode.addChild(this.EXP());
                        this.match(TokenType.RParent);
                        cnode.addChild(this.stlist());
                     }
                     else
                     {
                        throw Error("for in 匹配失败");
                     }
                  }
                  else
                  {
                     cnode = new GNode(GNodeType.ForStm);
                     cnode.addChild(this.st());
                     cnode.addChild(this.EXP());
                     this.match(TokenType.Semicolon);
                     cnode.addChild(this.st());
                     this.match(TokenType.RParent);
                     cnode.addChild(this.stlist());
                  }
               }
               return cnode;
            case TokenType.keywhile:
               cnode = new GNode(GNodeType.WhileStm);
               this.match(TokenType.keywhile);
               this.match(TokenType.LParent);
               cnode.addChild(this.EXP());
               this.match(TokenType.RParent);
               cnode.addChild(this.stlist());
               return cnode;
            case TokenType.keytry:
               cnode = new GNode(GNodeType.TRY);
               this.match(TokenType.keytry);
               cnode.addChild(this.stlist());
               if(this.tok.type == TokenType.keycatch)
               {
                  tnode = new GNode(GNodeType.CATCH);
                  this.match(TokenType.keycatch);
                  this.match(TokenType.LParent);
                  if(this.tok.type == TokenType.ident)
                  {
                     tempnode = new GNode(GNodeType.VarID,this.tok);
                     tnode.addChild(tempnode);
                     this.match(TokenType.ident);
                     if(this.tok.type == TokenType.Colon)
                     {
                        this.match(TokenType.Colon);
                        tempnode.vartype = this.tok.word;
                        this.match(this.tok.type);
                     }
                  }
                  else
                  {
                     this.error();
                  }
                  this.match(TokenType.RParent);
                  tnode.addChild(this.stlist());
                  cnode.addChild(tnode);
                  if(this.tok.type == TokenType.keyfinally)
                  {
                     this.match(TokenType.keyfinally);
                     cnode.addChild(this.stlist());
                  }
               }
               else
               {
                  this.error();
               }
               return cnode;
            case TokenType.keyswitch:
               cnode = new GNode(GNodeType.SWITCH);
               this.match(TokenType.keyswitch);
               this.match(TokenType.LParent);
               cnode.addChild(this.EXP());
               this.match(TokenType.RParent);
               this.match(TokenType.LBRACE);
               ccc = 0;
               while(this.tok.type == TokenType.keycase)
               {
                  tnode = new GNode(GNodeType.CASE);
                  this.match(TokenType.keycase);
                  tnode.addChild(this.EXP());
                  this.match(TokenType.Colon);
                  ccc = 0;
                  while(this.tok.type != TokenType.keycase && this.tok.type != TokenType.keydefault && this.tok.type != TokenType.RBRACE)
                  {
                     ccc++;
                     if(tnode == null)
                     {
                        trace("分析case出现严重错误");
                     }
                     tnode.addChild(this.st());
                     if(ccc > 200)
                     {
                        trace("分析case结构陷入死循环，请查看case部分代码");
                        break;
                     }
                  }
                  cnode.addChild(tnode);
               }
               if(this.tok.type == TokenType.keydefault)
               {
                  tnode = new GNode(GNodeType.DEFAULT);
                  this.match(TokenType.keydefault);
                  this.match(TokenType.Colon);
                  while(this.tok.type != TokenType.RBRACE)
                  {
                     tnode.addChild(this.st());
                  }
                  cnode.addChild(tnode);
               }
               this.match(TokenType.RBRACE);
               return cnode;
            case TokenType.keyvar:
               return this.varst();
            case TokenType.ident:
               tindex = this.index;
               tnode = this.IDENT();
               if(this.tok.type == TokenType.Assign)
               {
                  cnode = new GNode(GNodeType.AssignStm,this.tok);
                  cnode.addChild(tnode);
                  this.match(TokenType.Assign);
                  cnode.addChild(this.EXP());
                  if(this.tok.type == TokenType.Semicolon)
                  {
                     this.match(TokenType.Semicolon);
                  }
               }
               else
               {
                  this.index = tindex - 1;
                  this.nextToken();
                  cnode = this.EXP();
                  if(Boolean(this.tok) && this.tok.type == TokenType.Semicolon)
                  {
                     this.match(TokenType.Semicolon);
                  }
               }
               return cnode;
            case TokenType.constant:
            case TokenType.LParent:
            case TokenType.keynew:
            case TokenType.LOPNot:
            case TokenType.INCREMENT:
               cnode = this.EXP();
               if(this.tok.type == TokenType.Semicolon)
               {
                  this.match(TokenType.Semicolon);
               }
               return cnode;
            case TokenType.MOP:
               if(this.tok.word == "-")
               {
                  cnode = this.EXP();
                  if(this.tok.type == TokenType.Semicolon)
                  {
                     this.match(TokenType.Semicolon);
                  }
                  return cnode;
               }
               break;
            case TokenType.keyreturn:
               cnode = new GNode(GNodeType.ReturnStm,this.tok);
               this.match(TokenType.keyreturn);
               if(this.tok.type != TokenType.Semicolon)
               {
                  cnode.addChild(this.EXP());
               }
               this.match(TokenType.Semicolon);
               return cnode;
            case TokenType.keyimport:
               return this.doimport();
            case TokenType.keycontinue:
               cnode = new GNode(GNodeType.CONTINUE);
               cnode.word = this.tok.word;
               this.match(TokenType.keycontinue);
               if(this.tok.type == TokenType.Semicolon)
               {
                  this.match(TokenType.Semicolon);
               }
               return cnode;
            case TokenType.keybreak:
               cnode = new GNode(GNodeType.BREAK);
               cnode.word = this.tok.word;
               this.match(TokenType.keybreak);
               if(this.tok.type == TokenType.Semicolon)
               {
                  this.match(TokenType.Semicolon);
               }
               return cnode;
            default:
               this.error();
         }
         return null;
      }
      
      private function varst() : GNode
      {
         var tnode:GNode = null;
         var cnode:GNode = null;
         switch(this.tok.type)
         {
            case TokenType.keyvar:
               this.match(TokenType.keyvar);
               tnode = new GNode(GNodeType.VarDecl,this.tok);
               this.match(TokenType.ident);
               if(this.tok.type == TokenType.Colon)
               {
                  this.match(TokenType.Colon);
                  tnode.vartype = this.tok.word;
                  this.match(this.tok.type);
               }
               if(this.tok.type == TokenType.Assign)
               {
                  cnode = new GNode(GNodeType.AssignStm,this.tok);
                  this.match(TokenType.Assign);
                  cnode.addChild(tnode);
                  cnode.addChild(this.EXP());
                  if(this.tok.type == TokenType.Semicolon)
                  {
                     this.match(TokenType.Semicolon);
                  }
                  return cnode;
               }
               if(Boolean(this.tok) && this.tok.type == TokenType.Semicolon)
               {
                  this.match(TokenType.Semicolon);
               }
               return tnode;
            default:
               this.error();
               return null;
         }
      }
      
      private function EXP() : GNode
      {
         var tnode:GNode = null;
         var cnode:GNode = null;
         var cn:GNode = null;
         var tk:Token = null;
         switch(this.tok.type)
         {
            case TokenType.ident:
            case TokenType.constant:
            case TokenType.LParent:
            case TokenType.keynew:
            case TokenType.LOPNot:
            case TokenType.INCREMENT:
               tnode = this.Term();
               if(Boolean(this.tok) && this.tok.type == TokenType.LOP)
               {
                  cnode = new GNode(GNodeType.LOP,this.tok);
                  this.match(TokenType.LOP);
                  cnode.addChild(tnode);
                  cnode.addChild(this.EXP());
                  return cnode;
               }
               return tnode;
            case TokenType.MOP:
               if(this.tok.word == "-")
               {
                  tnode = this.Term();
                  if(this.tok.type == TokenType.LOP)
                  {
                     cnode = new GNode(GNodeType.LOP,this.tok);
                     this.match(TokenType.LOP);
                     cnode.addChild(tnode);
                     cnode.addChild(this.EXP());
                     return cnode;
                  }
                  return tnode;
               }
               break;
            case TokenType.LBRACKET:
               this.match(TokenType.LBRACKET);
               tnode = new GNode(GNodeType.newArray);
               if(this.tok.type != TokenType.RBRACKET)
               {
                  tnode.addChild(this.EXPList());
               }
               this.match(TokenType.RBRACKET);
               return tnode;
            case TokenType.LBRACE:
               this.match(TokenType.LBRACE);
               tnode = new GNode(GNodeType.newObject);
               if(this.tok.type == TokenType.RBRACE)
               {
                  this.match(TokenType.RBRACE);
                  return tnode;
               }
               do
               {
                  if(this.tok.type == TokenType.COMMA)
                  {
                     this.match(TokenType.COMMA);
                  }
                  cn = new GNode(GNodeType.VarID,this.tok);
                  cn.word = this.tok.word;
                  tnode.addChild(cn);
                  this.match(TokenType.ident);
                  this.match(TokenType.Colon);
                  if(this.tok.type == TokenType.COMMA || this.tok.type == TokenType.RBRACE)
                  {
                     tk = new Token();
                     tk.value = "";
                     tnode.addChild(new GNode(GNodeType.ConstID,tk));
                  }
                  else
                  {
                     tnode.addChild(this.EXP());
                  }
               }
               while(this.tok.type == TokenType.COMMA);
               
               this.match(TokenType.RBRACE);
               return tnode;
            default:
               this.error();
         }
         return null;
      }
      
      private function EXPList() : GNode
      {
         var cnode:GNode = new GNode(GNodeType.EXPS);
         switch(this.tok.type)
         {
            case TokenType.ident:
            case TokenType.constant:
            case TokenType.LParent:
            case TokenType.keynew:
            case TokenType.LOPNot:
            case TokenType.INCREMENT:
            case TokenType.LBRACKET:
            case TokenType.LBRACE:
               cnode.addChild(this.EXP());
               while(this.tok.type == TokenType.COMMA)
               {
                  this.match(TokenType.COMMA);
                  cnode.addChild(this.EXP());
               }
               return cnode;
            case TokenType.MOP:
               if(this.tok.word == "-")
               {
                  cnode.addChild(this.EXP());
                  while(this.tok.type == TokenType.COMMA)
                  {
                     this.match(TokenType.COMMA);
                     cnode.addChild(this.EXP());
                  }
                  return cnode;
               }
               break;
            default:
               this.error();
         }
         return null;
      }
      
      private function Term() : GNode
      {
         var tnode:GNode = null;
         var cnode:GNode = null;
         switch(this.tok.type)
         {
            case TokenType.ident:
            case TokenType.constant:
            case TokenType.LParent:
            case TokenType.keynew:
            case TokenType.LOPNot:
            case TokenType.INCREMENT:
               tnode = this.facter();
               if(Boolean(this.tok) && this.tok.type == TokenType.COP)
               {
                  cnode = new GNode(GNodeType.COP,this.tok);
                  this.match(TokenType.COP);
                  cnode.addChild(tnode);
                  cnode.addChild(this.Term());
                  return cnode;
               }
               return tnode;
            case TokenType.MOP:
               if(this.tok.word == "-")
               {
                  tnode = this.facter();
                  if(Boolean(this.tok) && this.tok.type == TokenType.COP)
                  {
                     cnode = new GNode(GNodeType.COP,this.tok);
                     this.match(TokenType.COP);
                     cnode.addChild(tnode);
                     cnode.addChild(this.Term());
                     return cnode;
                  }
                  return tnode;
               }
               break;
            default:
               this.error();
         }
         return null;
      }
      
      private function priority(s:GNode) : int
      {
         if(s.nodeType == GNodeType.MOP)
         {
            if(s.word == "+" || s.word == "-")
            {
               return 1;
            }
            return 2;
         }
         return 3;
      }
      
      private function MopFactor() : GNode
      {
         var tnode:GNode = null;
         var cnode:GNode = null;
         var i:int = 0;
         var ccc:String = null;
         var pri:int = 0;
         var len:int = 0;
         var right:GNode = null;
         var left:GNode = null;
         var nodearr:Array = [];
         var stack:Array = [];
         nodearr.push(this.gene());
         if(Boolean(this.tok) && this.tok.type == TokenType.MOP)
         {
            while(this.tok.type == TokenType.MOP)
            {
               cnode = new GNode(GNodeType.MOP,this.tok);
               pri = this.priority(cnode);
               if(stack.length != 0)
               {
                  len = stack.length - 1;
                  for(i = len; i >= 0; )
                  {
                     if(this.priority(stack[i] as GNode) >= pri)
                     {
                        nodearr.push(stack.pop());
                        i--;
                        continue;
                     }
                     break;
                  }
               }
               stack.push(cnode);
               this.match(TokenType.MOP);
               nodearr.push(this.gene());
            }
            while(stack.length > 0)
            {
               nodearr.push(stack.pop());
            }
            ccc = "";
            for(i = 0; i < nodearr.length; i++)
            {
               ccc = ccc + ((nodearr[i] as GNode).word + ".");
            }
            for(i = 0; i < nodearr.length; i++)
            {
               if((nodearr[i] as GNode).childs.length == 0 && (nodearr[i] as GNode).nodeType == GNodeType.MOP)
               {
                  tnode = nodearr[i] as GNode;
                  right = stack.pop();
                  left = stack.pop();
                  tnode.addChild(left);
                  tnode.addChild(right);
                  stack.push(tnode);
               }
               else
               {
                  stack.push(nodearr[i]);
               }
            }
            if(stack.length == 1)
            {
               return stack[0];
            }
            this.error();
         }
         return nodearr[0];
      }
      
      private function facter() : GNode
      {
         switch(this.tok.type)
         {
            case TokenType.ident:
            case TokenType.constant:
            case TokenType.LParent:
            case TokenType.keynew:
            case TokenType.LOPNot:
            case TokenType.INCREMENT:
               return this.MopFactor();
            case TokenType.MOP:
               if(this.tok.word == "-")
               {
                  return this.MopFactor();
               }
               break;
            default:
               this.error();
         }
         return null;
      }
      private var __callsuper:Boolean = false;
      private function IDENT() : GNode
      {
         var tnode:GNode = null;
         var cnode:GNode = null;
         switch(this.tok.type)
         {
            case TokenType.ident:
               cnode = new GNode(GNodeType.IDENT);
               tnode = new GNode(GNodeType.VarID,this.tok);
               cnode.addChild(tnode);
			   var first = this.tok.word;
			   //
               this.match(TokenType.ident);
			   if(tnode.word=="super" && this.tok.type ==TokenType.LParent){
				   __callsuper = true;
			   }
               while(true)//this.tok.type == TokenType.LBRACKET || this.tok.type == TokenType.DOT || this.tok.type ==TokenType.LParent
               {
				  if(this.tok.type == TokenType.LParent)
				  {
					  tnode = new GNode(GNodeType.FunCall);
					  cnode.addChild(tnode);
					  this.match(TokenType.LParent);
					  if(this.tok.type != TokenType.RParent)
					  {
						 tnode.addChild(this.EXPList());
					  }
					  this.match(TokenType.RParent);
				  }
                  else if(this.tok.type == TokenType.LBRACKET)
                  {
                     this.match(TokenType.LBRACKET);
                     tnode = new GNode(GNodeType.Index);
                     tnode.addChild(this.EXP());
					 //
                     cnode.addChild(tnode);
                     this.match(TokenType.RBRACKET);
                  }
                  else if(this.tok.type == TokenType.DOT)
                  {
                     this.match(TokenType.DOT);
                     tnode = new GNode(GNodeType.VarID, this.tok);
                     cnode.addChild(tnode);
                     this.match(TokenType.ident);
                  }else {
					 break; 
				  }
               }
               return cnode;
            default:
               this.error();
               return null;
         }
      }
      
      private function gene() : GNode
      {
         var cnode:GNode = null;
         var tnode:GNode = null;
         var id:GNode = null;
         switch(this.tok.type)
         {
            case TokenType.constant:
               cnode = new GNode(GNodeType.ConstID,this.tok);
               cnode.word = this.tok.word;
               this.match(TokenType.constant);
               return cnode;
            case TokenType.LParent:
               this.match(TokenType.LParent);
               cnode = this.EXP();
               this.match(TokenType.RParent);
               return cnode;
            case TokenType.keynew:
               cnode = new GNode(GNodeType.newClass,this.tok);
               this.match(TokenType.keynew);
               id = new GNode(GNodeType.VarID,this.tok);
               cnode.addChild(id);
               this.match(TokenType.ident);
               while(this.tok.type == TokenType.DOT)
               {
                  this.match(TokenType.DOT);
                  id.word = id.word + ("." + this.tok.word);
                  this.match(TokenType.ident);
               }
               this.match(TokenType.LParent);
               if(this.tok.type != TokenType.RParent)
               {
                  cnode.addChild(this.EXPList());
               }
               this.match(TokenType.RParent);
			   //后面可能还有代码。。包括后续的属性访问等。。。
			   //以后有时间再加。。。。。。。。。。。。
               return cnode;
            case TokenType.ident:
               tnode = this.IDENT();
               
               if(this.tok.type == TokenType.INCREMENT)
               {
                  cnode = new GNode(GNodeType.INCREMENT);
                  cnode.word = this.tok.word;
                  cnode.addChild(tnode);
                  this.match(TokenType.INCREMENT);
                  return cnode;
               }
               return tnode;
            case TokenType.LOPNot:
               this.match(TokenType.LOPNot);
               tnode = this.gene();
               cnode = new GNode(GNodeType.LOPNot);
               cnode.word = "!";
               cnode.addChild(tnode);
               return cnode;
            case TokenType.MOP:
               if(this.tok.word == "-")
               {
                  this.match(TokenType.MOP);
                  tnode = this.gene();
                  cnode = new GNode(GNodeType.Nagtive);
                  cnode.word = "-";
                  cnode.addChild(tnode);
                  return cnode;
               }
               break;
            case TokenType.INCREMENT:
               cnode = new GNode(GNodeType.PREINCREMENT);
               cnode.word = this.tok.word;
               this.match(TokenType.INCREMENT);
               cnode.addChild(this.gene());
               return cnode;
            default:
               this.error();
         }
         return null;
      }
      
      private function nextToken() : void
      {
         this.tok = this.lex.words[this.index++] as Token;
      }
      
      private function match(type:int, word:* = null) : void
      {
         if(type == this.tok.type && (word == null || this.tok.word == word))
         {
            this.nextToken();
         }
         else
         {
            this.error();
         }
      }
      
      private function error() : void
      {
         throw new Error(this.name + "语法错误>行号:" + this.tok.line + "," + this.tok.getLine() + "，单词：" + this.tok.word);
      }
   }
}
