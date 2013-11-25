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
	
	import flash.utils.getDefinitionByName;
	
	import parse.Lex;
	import parse.Token;
	import parse.TokenType;
	
	//有语法树，直接就可以执行很多东西了。
	public class GenTree
	{
		private var tok:Token;
		public var lex:Lex;
		private var index:int=0;
		public var name:String;
		//public var superclass:String="Object";//父类的定义
		public var API:Object={};
		static public var Branch:Object={};
		public var imports:Object={};
		//函数节点
		public var motheds:Object={};
		//变量节点
		public var fields:Object={};
		
		public var Package:String="";
		//
		
		static public function hasScript(scname:String):Boolean{
			if(Script.app.hasDefinition("flash.filesystem.FileStream")){
				if(!Branch[scname]){
                    var File:Class=getDefinitionByName("flash.filesystem.File") as Class;
                    var FileStream:Class=getDefinitionByName("flash.filesystem.FileStream") as Class;
                    var FileMode:Class=getDefinitionByName("flash.filesystem.FileMode") as Class;
					var f:Object=File.applicationDirectory.resolvePath(Script.scriptdir+scname+".as");
					if(f.exists){
						//解析
						var fs:Object=new FileStream();
						fs.open(f,FileMode.READ);
						var str:String=fs.readUTFBytes(f.size);
						fs.close();
						trace("load=="+scname);
						Script.LoadFromString(str);
					}else{
						trace(scname+"不存在");
					}
				}
			}
			if(Branch[scname]){
				
				return true;
			}
			return false;
		}
		function GenTree(code:String=null)
		{
			if(code){
				lex=new Lex(code);
				index=0;
				nextToken();
				PACKAGE();
				Branch[name]=this;
				if(name!="____globalclass"){
					trace("脚本类:"+name+"解析完成,可以创建其实例了");
				}
			}
		}
		public function toString():String{
			var str:String="";
			str+="package"+Package+"{\r";
			var o:String;
			var c:String;
			//
			for(o in imports){
				str+="import "+o+";\r"
			}
			str+="class "+name+"{\r";
			for(o in fields){
				c=(fields[o] as GNode).toString();
			}
			for(o in motheds){
				c=(motheds[o] as GNode).toString();
				str+=c+"\r";
			}	
			str+="}\r"	
			str+="}";
			return str.replace(/protected/g,"");
		}
		//
		public function declares(_lex:Lex):GNode{
			lex=_lex;
			index=0;
			nextToken();
			var cnode:GNode=new GNode(GNodeType.Stms);
			var tnode:GNode;
			while(tok){
				if(tok.type==TokenType.keyvar){
					tnode=varst();
					fields[tnode.name]=tnode;
					cnode.addChild(tnode);
				}else if(tok.type==TokenType.keyfunction){
					tnode=func();
					motheds[tnode.name]=tnode;
				}else{
					tnode=st();
					if(tnode.name){
						fields[tnode.name]=tnode;
					}
					cnode.addChild(tnode);
				}
			}
			return cnode;
		}
		public function declare(_lex:Lex):GNode{
			lex=_lex;
			index=0;
			nextToken();
			
			var cnode:GNode;
			if(tok.type==TokenType.keyvar){
				cnode=varst();
				fields[cnode.name]=cnode;
			}else if(tok.type==TokenType.keyfunction){
				cnode=func();
				motheds[cnode.name]=cnode;
			}else if(tok.type==TokenType.LBRACE){
				cnode=stlist();
			}else{
				cnode=st();
			}
			return cnode;
		}
		private function doimport():GNode{
			match(TokenType.keyimport);
			var vname_arr:Array=[];
			vname_arr[0]=tok.word;
			match(TokenType.ident);
			//
			while(tok.type==TokenType.DOT){
				match(TokenType.DOT);
				vname_arr.push(tok.word);	
				match(TokenType.ident);
			}
			var cnode:GNode=new GNode(GNodeType.importStm);
			cnode.word=vname_arr.join(".");
			API[vname_arr[vname_arr.length-1]]=Script.getDef(cnode.word);
			
			imports[cnode.word]=true;
			if(tok.type==TokenType.Semicolon){
				match(TokenType.Semicolon);
			}
			return cnode;
		}
		
		private function PACKAGE():void{
			if(tok.type==TokenType.keypackage){
				match(TokenType.keypackage);
				if(tok.type==TokenType.ident){
					var vname_arr:Array=[];
					vname_arr[0]=tok.word;
					match(TokenType.ident);
					//
					while(tok.type==TokenType.DOT){
						match(TokenType.DOT);
						vname_arr.push(tok.word);	
						match(TokenType.ident);
					}
					Package=vname_arr.join(".");
				}
				match(TokenType.LBRACE);
				CLASS();
				match(TokenType.RBRACE);
			}else{
				CLASS();
			}
		}
		private function CLASS():void{
			while(tok.type==TokenType.keyimport){
				doimport();
			}
			switch (tok.type){
				case TokenType.keyclass:
					match(TokenType.keyclass);
					name=tok.word;
					match(TokenType.ident);
					if(tok.type==TokenType.keyextends){
						match(TokenType.keyextends);
						match(TokenType.ident);
					}
					match(TokenType.LBRACE);
					DecList();
					match(TokenType.RBRACE);
					break;
				default:
					error();
			}
		
		}
		private function DecList():void{
			var cnode:GNode;
			while(tok.type==TokenType.keyimport || tok.type==TokenType.keyvar || tok.type==TokenType.keyfunction || tok.type==TokenType.keypublic || tok.type==TokenType.keyprivate || tok.type==TokenType.keyprotected){
				
				if(tok.type==TokenType.keyimport){
					doimport();
				} else if(tok.type==TokenType.keyvar){
					cnode=varst();
					fields[cnode.name]=cnode;
				}else if(tok.type==TokenType.keyfunction){
					cnode=func();
					motheds[cnode.name]=cnode;
				}else{
					var vis:String=tok.word;
					nextToken();
					if(tok.type==TokenType.keyvar){
						cnode=varst();
						fields[cnode.name]=cnode;
					}else if(tok.type==TokenType.keyfunction){
						cnode=func();
						motheds[cnode.name]=cnode;
					}
					cnode.vis=vis;//可见性设置
				}
			}
		}
		private function func():GNode{
			switch (tok.type){
				case TokenType.keyfunction:
					match(TokenType.keyfunction);
					var cnode:GNode=new GNode(GNodeType.FunDecl,tok);
					cnode.vartype="void";//函数默认的为无返回类型
					//
					match(TokenType.ident);
					match(TokenType.LParent);
					cnode.addChild(ParamList());
					match(TokenType.RParent);
					//------------
					if(tok.type==TokenType.Colon){
						//如果考虑语法解析的话。。。
						match(TokenType.Colon);
						cnode.vartype=tok.word;//变量类型
						match(tok.type);//可能为*或者ident
						//match(TokenType.ident);
					}
					cnode.addChild(stlist());
					return cnode;
					break;
				default:
					error();
			}
			return null;
		}
		private function ParamList():GNode{
			var cnode:GNode=new GNode(GNodeType.Params);
			switch (tok.type){
				case TokenType.ident:
					cnode.addChild(new GNode(GNodeType.VarID,tok));
					match(TokenType.ident);
					if(tok.type==TokenType.Colon){
						//如果考虑语法解析的话。。。
						match(TokenType.Colon);
						cnode.vartype=tok.word;
						match(tok.type);
						//match(TokenType.ident);
					}
					while(tok.type==TokenType.COMMA){
						match(TokenType.COMMA);
						cnode.addChild(new GNode(GNodeType.VarID,tok));
						match(TokenType.ident);
						if(tok.type==TokenType.Colon){
							//如果考虑语法解析的话。。。
							match(TokenType.Colon);
							cnode.vartype=tok.word;
							match(tok.type);	
							//match(TokenType.ident);
						}
					}
					break;
				case TokenType.RParent:
					break;
				default:
					error();
			}
			return cnode;
		}
		private function stlist():GNode{
			var cnode:GNode=new GNode(GNodeType.Stms);
			switch (tok.type){
				case TokenType.LBRACE:
					match(TokenType.LBRACE);
					while(tok.type!=TokenType.RBRACE){
						cnode.addChild(st());
					}
					match(TokenType.RBRACE);
					break;
				default:
					error();
			}
			return cnode;
		}
		private function st():GNode{
			var cnode:GNode;
			var tnode:GNode;
			switch (tok.type){
				case TokenType.keyif:
					//总的，
					cnode=new GNode(GNodeType.IfElseStm);
					tnode=new GNode(GNodeType.ELSEIF);
					match(TokenType.keyif);
					match(TokenType.LParent);
					tnode.addChild(EXP());
					match(TokenType.RParent);
					tnode.addChild(stlist());
					cnode.addChild(tnode);
					
					while(tok.type==TokenType.keyelse){
						match(TokenType.keyelse);
						if(tok.type==TokenType.keyif){
							//else if
							match(TokenType.keyif);
							
							tnode=new GNode(GNodeType.ELSEIF);
							match(TokenType.LParent);
							tnode.addChild(EXP());
							match(TokenType.RParent);
							tnode.addChild(stlist());
							cnode.addChild(tnode);
						}else{
							//else
							cnode.addChild(stlist());
						}
					}
					return cnode;
					break;
				case TokenType.keyfor:
					match(TokenType.keyfor);
					//for each
					if(tok.type==TokenType.keyeach){
						match(TokenType.keyeach);
						match(TokenType.LParent);
						cnode=new GNode(GNodeType.ForEACHStm);
						if(tok.type==TokenType.keyvar){
							match(TokenType.keyvar);
						}
						if(tok.type==TokenType.ident){
							cnode.addChild(new GNode(GNodeType.VarDecl,tok));
							match(TokenType.ident);
							if(tok.type==TokenType.Colon){
								match(TokenType.Colon);
								cnode.childs[0].vartype=tok.word;
								match(tok.type);
								//match(TokenType.ident);
							}
							match(TokenType.COP,"in");
							
							cnode.addChild(EXP());
							match(TokenType.RParent);
							cnode.addChild(stlist());
						}else{
							throw Error("for each 匹配失败");
						}
					}else{
						//2种情况，一种是for in
						//一种是数组循环
						match(TokenType.LParent);
						if(lex.words[index+1].type==TokenType.COP || lex.words[index+2].type==TokenType.COP){
							cnode=new GNode(GNodeType.ForInStm);
							if(tok.type==TokenType.keyvar){
								match(TokenType.keyvar);
							}
							if(tok.type==TokenType.ident){
								cnode.addChild(new GNode(GNodeType.VarDecl,tok));
								match(TokenType.ident);
								//
								match(TokenType.COP,"in");
								
								cnode.addChild(EXP());
								match(TokenType.RParent);
								cnode.addChild(stlist());
							}else{
								throw Error("for in 匹配失败");
							}
						}else{
							cnode=new GNode(GNodeType.ForStm);
							cnode.addChild(st());
							cnode.addChild(EXP());
							match(TokenType.Semicolon);
							cnode.addChild(st());
							match(TokenType.RParent);
							cnode.addChild(stlist());
						}
					}
					return cnode;
					break;
				case TokenType.keywhile:
					cnode=new GNode(GNodeType.WhileStm);
					match(TokenType.keywhile);
					match(TokenType.LParent);
					cnode.addChild(EXP());
					match(TokenType.RParent);
					cnode.addChild(stlist());
					return cnode;
					break;
				case TokenType.keytry:
					cnode=new GNode(GNodeType.TRY);
					match(TokenType.keytry);
					cnode.addChild(stlist());//第一节点为执行部分
					if(tok.type==TokenType.keycatch){
						tnode=new GNode(GNodeType.CATCH);
						match(TokenType.keycatch);//捕获错误
						match(TokenType.LParent);
						if(tok.type==TokenType.ident){
							var tempnode:GNode=new GNode(GNodeType.VarID,tok);
							tnode.addChild(tempnode);
							match(TokenType.ident);
							if(tok.type==TokenType.Colon){//如果考虑语法解析的话。。。
								match(TokenType.Colon);
								tempnode.vartype=tok.word;
								//match(TokenType.ident);
								match(tok.type);
							}
						}else{
							error();
						}
						match(TokenType.RParent);
						tnode.addChild(stlist());
						cnode.addChild(tnode);//第2节点为捕获部分
						if(tok.type==TokenType.keyfinally){
							match(TokenType.keyfinally);//无论如何也要执行的
							cnode.addChild(stlist());//第2节点为捕获部分
						}
					}else{
						error();
					}
					return cnode;
					break;
				case TokenType.keyswitch:
					cnode=new GNode(GNodeType.SWITCH);
					match(TokenType.keyswitch);
					match(TokenType.LParent);
					cnode.addChild(EXP());//第一个节点为所需要判断的表达式
					match(TokenType.RParent);
					match(TokenType.LBRACE);
					//
					var ccc:int=0;//计数器，避免脚本分析陷入死循环
					while(tok.type==TokenType.keycase){
						tnode=new GNode(GNodeType.CASE);
						match(TokenType.keycase);
						tnode.addChild(EXP());//第一个节点为所需要判断的表达式
						match(TokenType.Colon);
						//tnode.addChild(new GNode(GNodeType.Stms));
						ccc=0;
						while(tok.type!=TokenType.keycase && tok.type!=TokenType.keydefault && tok.type!=TokenType.RBRACE){
							ccc++;
							if(tnode==null){
								trace("分析case出现严重错误");
							}
							tnode.addChild(st());
							
							if(ccc>200){
								trace("分析case结构陷入死循环，请查看case部分代码");
								break;
							}
						}
						cnode.addChild(tnode);
					}
					if(tok.type==TokenType.keydefault){
						tnode=new GNode(GNodeType.DEFAULT);
						match(TokenType.keydefault);
						match(TokenType.Colon);
						while(tok.type!=TokenType.RBRACE){
							tnode.addChild(st());
						}
						cnode.addChild(tnode);
					}
					match(TokenType.RBRACE);
					return cnode;
					break;
				case TokenType.keyvar:
					
					return varst();
					break;
				case TokenType.ident:
					//2种情况需要分别处理,赋值语句和EXP
					var tindex:int=index;
					tnode=IDENT();
					if(tok.type==TokenType.Assign){
						cnode=new GNode(GNodeType.AssignStm,tok);
						cnode.addChild(tnode);
						match(TokenType.Assign);
						cnode.addChild(EXP());
						if(tok.type==TokenType.Semicolon){
							match(TokenType.Semicolon);
						}
					}else{
						//就是个表达式
						index=tindex-1;
						nextToken();
						cnode=EXP();
						if(tok && tok.type==TokenType.Semicolon){
							match(TokenType.Semicolon);
						}
					}
					return cnode;
					break;
				case TokenType.constant:
				case TokenType.LParent:
				case TokenType.keynew:
				case TokenType.LOPNot:
				case TokenType.INCREMENT:
					cnode=EXP();
					if(tok.type==TokenType.Semicolon){
						match(TokenType.Semicolon);
					}
					return cnode;
					break;
				case TokenType.MOP:
					if(tok.word=="-"){
						cnode=EXP();
						if(tok.type==TokenType.Semicolon){
							match(TokenType.Semicolon);
						}
						return cnode;
					}
					break;
				case TokenType.keyreturn:
					cnode=new GNode(GNodeType.ReturnStm,tok);
					match(TokenType.keyreturn);
					if(tok.type!=TokenType.Semicolon){
						cnode.addChild(EXP());
					}
					match(TokenType.Semicolon);
					return cnode;
					break;
				case TokenType.keyimport:
					return doimport();
					break;
				case TokenType.keycontinue:
					cnode=new GNode(GNodeType.CONTINUE);
					cnode.word=tok.word;
					match(TokenType.keycontinue);
					if(tok.type==TokenType.Semicolon){
						match(TokenType.Semicolon);
					}
					return cnode;
					break;
				case TokenType.keybreak:
					cnode=new GNode(GNodeType.BREAK);
					cnode.word=tok.word;
					match(TokenType.keybreak);
					if(tok.type==TokenType.Semicolon){
						match(TokenType.Semicolon);
					}
					return cnode;
					break;
				default:
					
					error();
			}
			return null;
		}
		private function varst():GNode{
			switch (tok.type){
				case TokenType.keyvar:
					match(TokenType.keyvar);
					var tnode:GNode=new GNode(GNodeType.VarDecl,tok);
					match(TokenType.ident);
					if(tok.type==TokenType.Colon){
						//如果考虑语法解析的话。。。
						match(TokenType.Colon);
						tnode.vartype=tok.word;//变量类型
						match(tok.type);
						//match(TokenType.ident);
					}
					if(tok.type==TokenType.Assign){
						var cnode:GNode=new GNode(GNodeType.AssignStm,tok);
						match(TokenType.Assign);
						cnode.addChild(tnode);
						cnode.addChild(EXP());
						if(tok.type==TokenType.Semicolon){
							match(TokenType.Semicolon);
						}
						return cnode;
					}
					if(tok && tok.type==TokenType.Semicolon){
						match(TokenType.Semicolon);
					}
					return tnode;
					break;
				default:
					error();
			}
			return null;
		}
		private function EXP():GNode{
			var tnode:GNode;
			var cnode:GNode;
			switch (tok.type){
				case TokenType.ident:
				case TokenType.constant:
				case TokenType.LParent:
				case TokenType.keynew:
				case TokenType.LOPNot:
				case TokenType.INCREMENT:
					tnode=Term();
					if(tok && tok.type==TokenType.LOP){
						cnode=new GNode(GNodeType.LOP,tok);	
						match(TokenType.LOP);
						cnode.addChild(tnode);
						cnode.addChild(EXP());
						return cnode;
					}else{
						return tnode;
					}
					break;
				case TokenType.MOP:
					if(tok.word=="-"){
						tnode=Term();
						if(tok.type==TokenType.LOP){
							cnode=new GNode(GNodeType.LOP,tok);	
							match(TokenType.LOP);
							cnode.addChild(tnode);
							cnode.addChild(EXP());
							return cnode;
						}else{
							return tnode;
						}
					}
					break;
				case TokenType.LBRACKET:
					match(TokenType.LBRACKET);
					tnode=new GNode(GNodeType.newArray);
					if(tok.type!=TokenType.RBRACKET){
						tnode.addChild(EXPList());
					}
					match(TokenType.RBRACKET);
					return tnode;
				case TokenType.LBRACE:
					match(TokenType.LBRACE);
					tnode=new GNode(GNodeType.newObject);
					if(tok.type==TokenType.RBRACE){
						match(TokenType.RBRACE);
						return tnode;
					}
					do{
						if(tok.type==TokenType.COMMA){
							match(TokenType.COMMA);
						}
						var cn:GNode=new GNode(GNodeType.VarID,tok);
						cn.word=tok.word;
						tnode.addChild(cn);
						match(TokenType.ident);
						match(TokenType.Colon);
						//
						if(tok.type==TokenType.COMMA || tok.type==TokenType.RBRACE){
							var tk:Token=new Token();
							tk.value="";
							tnode.addChild(new GNode(GNodeType.ConstID,tk));
						}else{
							tnode.addChild(EXP());
						}
					}while(tok.type==TokenType.COMMA)
					match(TokenType.RBRACE);
					return tnode;
					break;
				default:
					error();
			}
			return null;
		}
		private function EXPList():GNode{
			var cnode:GNode=new GNode(GNodeType.EXPS);	
			switch (tok.type){
				case TokenType.ident:
				case TokenType.constant:
				case TokenType.LParent:
				case TokenType.keynew:
				case TokenType.LOPNot:
				case TokenType.INCREMENT:
				case TokenType.LBRACKET:
				case TokenType.LBRACE:
					
					cnode.addChild(EXP());
					while(tok.type==TokenType.COMMA){
						match(TokenType.COMMA);
						cnode.addChild(EXP());
					}
					return cnode;
					break;
				case TokenType.MOP:
					if(tok.word=="-"){
						cnode.addChild(EXP());
						while(tok.type==TokenType.COMMA){
							match(TokenType.COMMA);
							cnode.addChild(EXP());
						}
						return cnode;
					}
					break;
				default:
					error();
			}
			return null;
		}
		
		private function Term():GNode{
			var tnode:GNode;
			var cnode:GNode;
			switch (tok.type){
				case TokenType.ident:
				case TokenType.constant:
				case TokenType.LParent:
				case TokenType.keynew:
				case TokenType.LOPNot:
				case TokenType.INCREMENT:
					tnode=facter();
					if(tok && tok.type==TokenType.COP){
						cnode=new GNode(GNodeType.COP,tok);	
						match(TokenType.COP);
						cnode.addChild(tnode);
						cnode.addChild(Term());
						return cnode;
					}else{
						return tnode;
					}
					break;
				case TokenType.MOP:
					if(tok.word=="-"){
						tnode=facter();
						if(tok && tok.type==TokenType.COP){
							cnode=new GNode(GNodeType.COP,tok);	
							match(TokenType.COP);
							cnode.addChild(tnode);
							cnode.addChild(Term());
							return cnode;
						}else{
							return tnode;
						}
					}
					break;
				default:
					error();
			}
			return null;
		}
		private function priority(s:GNode):int{
			if(s.nodeType==GNodeType.MOP){
				if(s.word=="+" || s.word=="-"){
					return 1;
				}
				return 2;
			}
			return 3;
		}
		private function MopFactor():GNode{
			var tnode:GNode;
			var cnode:GNode;
			var nodearr:Array=[];//输出后缀表达式
			var stack:Array=[];//符号堆栈
			nodearr.push(gene());
			var i:int;
			if(tok && tok.type==TokenType.MOP){
				while(tok.type==TokenType.MOP){
					cnode=new GNode(GNodeType.MOP,tok);
					var pri:int=priority(cnode);
					if(stack.length==0){
						//stack.push(cnode);
					}else{
						var len:int=stack.length-1;
						for(i=len;i>=0;i--){
							if(priority(stack[i] as GNode)>=pri){//压入到输出
								nodearr.push(stack.pop());
							}else{
								break;
							}
						}
					}
					stack.push(cnode);//符号入栈
					match(TokenType.MOP);
					nodearr.push(gene());
				}
				//5+10*(100-3);
				while(stack.length>0){
					nodearr.push(stack.pop());//压入到输出
				}
				
				//通过以上2步，已经做到了后缀表达式
				var ccc:String="";
				for(i=0;i<nodearr.length;i++){
					ccc+=(nodearr[i] as GNode).word+".";
				}
				//trace(ccc);
				//转为语法树返回
				
				for(i=0;i<nodearr.length;i++){
					if((nodearr[i] as GNode).childs.length==0 && (nodearr[i] as GNode).nodeType==GNodeType.MOP){//
						tnode=(nodearr[i] as GNode);
						var right:GNode=stack.pop();
						var left:GNode=stack.pop();
						tnode.addChild(left);
						tnode.addChild(right);
						stack.push(tnode);
					}else{
						stack.push(nodearr[i]);
					}
				}
				if(stack.length==1){
					//trace((stack[0] as GNode).toString());
					return stack[0];
				}else{
					error();//"错误的表达式"
				}
				
			}
			return nodearr[0];
		}
		private function facter():GNode{
			
			switch (tok.type){
				case TokenType.ident:
				case TokenType.constant:
				case TokenType.LParent:
				case TokenType.keynew:
				case TokenType.LOPNot:
				case TokenType.INCREMENT:
					return MopFactor();
					//
					break;
				case TokenType.MOP:
					if(tok.word=="-"){
						return MopFactor();
					}
					break;
				default:
					error();
			}
			return null;
		}
		private function IDENT():GNode{
			var tnode:GNode;
			switch (tok.type){
				case TokenType.ident:
					var cnode:GNode=new GNode(GNodeType.IDENT);
					//
					tnode=new GNode(GNodeType.VarID,tok);
					cnode.addChild(tnode);
					match(TokenType.ident);
					while(tok.type==TokenType.LBRACKET || tok.type==TokenType.DOT){
						if(tok.type==TokenType.LBRACKET){
							match(TokenType.LBRACKET);
							tnode=new GNode(GNodeType.Index);
							tnode.addChild(EXP());
							cnode.addChild(tnode);
							match(TokenType.RBRACKET);
						}else {
							//if(tok.type==TokenType.DOT)
							match(TokenType.DOT);
							tnode=new GNode(GNodeType.VarID,tok);
							cnode.addChild(tnode);
							match(TokenType.ident);
						}
					}
					//---------------------------------------------
					return cnode;
					break;
				default:
					error();
			}
			return null;
		}
		private function gene():GNode{
			var cnode:GNode;
			var tnode:GNode;
			switch (tok.type){
				case TokenType.constant:
					cnode=new GNode(GNodeType.ConstID,tok);
					cnode.word=tok.word;
					match(TokenType.constant);
					return cnode;
					break;
				case TokenType.LParent:
					match(TokenType.LParent);
					cnode=EXP();
					match(TokenType.RParent);
					return cnode;
					break;
				case TokenType.keynew:
					cnode=new GNode(GNodeType.newClass,tok);
					match(TokenType.keynew);
					var id:GNode=new GNode(GNodeType.VarID,tok);
					//
					cnode.addChild(id);
					match(TokenType.ident);
					while(tok.type==TokenType.DOT){
						match(TokenType.DOT);
						id.word+="."+tok.word;
						match(TokenType.ident);
					}
					match(TokenType.LParent);
					if(tok.type!=TokenType.RParent){
						cnode.addChild(EXPList());
					}
					match(TokenType.RParent);
					return cnode;
					break;
				case TokenType.ident:
					tnode=IDENT();
					if(tok.type==TokenType.LParent){
						cnode=new GNode(GNodeType.FunCall);
						cnode.addChild(tnode);
						match(TokenType.LParent);
						if(tok.type!=TokenType.RParent){
							cnode.addChild(EXPList());
						}
						match(TokenType.RParent);
						return cnode;
					}else if(tok.type==TokenType.INCREMENT){
						cnode=new GNode(GNodeType.INCREMENT);
						cnode.word=tok.word;
						cnode.addChild(tnode);
						match(TokenType.INCREMENT);
						return cnode;
					}else{
						return tnode;
					}
					break;
				
				case TokenType.LOPNot:
					match(TokenType.LOPNot);
					tnode=gene();
					cnode=new GNode(GNodeType.LOPNot);
					cnode.word="!";
					cnode.addChild(tnode);
					return cnode;
				case TokenType.MOP:
					if(tok.word=="-"){
						match(TokenType.MOP);
						tnode=gene();
						cnode=new GNode(GNodeType.Nagtive);
						cnode.word="-";
						cnode.addChild(tnode);
						return cnode;
					}
					break;
				case TokenType.INCREMENT:
					cnode=new GNode(GNodeType.PREINCREMENT);
					cnode.word=tok.word;
					match(TokenType.INCREMENT);
					cnode.addChild(gene());
					return cnode;
				default:
					error();
			}
			return null;
		}
		
		
		private function nextToken():void{
			tok=this.lex.words[index++] as Token;
			//index++;
		}
		private function match(type:int,word=null):void{
			//trace("try eat ",tok.word);
			if(type==tok.type && (word==null ||  tok.word==word)){
					nextToken();
			}else{//匹配失败
				error();
			}
		}
		private function error():void{
			throw new Error(this.name+"语法错误>行号:"+tok.line+","+tok.getLine()+"，单词："+tok.word);
		}
	}
}