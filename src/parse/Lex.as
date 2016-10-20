package parse
{
   import flash.events.EventDispatcher;
   import flash.utils.Dictionary;
   
   public class Lex extends EventDispatcher
   {
      
      public static var treecach:Dictionary = new Dictionary();
       
      private var str:String;
      
      private var line:int;
      
      private var lines:Array;
      
      private var ptr:uint;
      
      public var words:Array;
      
      private var word:String;
      
      private var ch:String;
      
      private var loadnew:Boolean = false;
      
      private var undot:Boolean = false;
      
      public function Lex(_str:String = null, _undot:* = false)
      {
         var tk:Token = null;
         super();
         if(_str)
         {
            this.ptr = 0;
            this.undot = _undot;
            this.line = 0;
            this.lines = [];
            _str = _str.replace(/\r\n/g,"\n");
            _str = _str.replace(/\r/g,"\n");
            this.lines = _str.split("\n");
            this.words = [];
            this.str = _str;
            this.nextChar();
            while(this.ptr < this.str.length + 1)
            {
               try
               {
                  tk = this.getNextWord();
                  tk.line = this.line;
                  tk.index = this.words.length;
                  tk.linestr = this.lines[this.line];
               }
               catch(e:*)
               {
                  trace("词法分析" + e);
               }
               if(tk)
               {
                  this.words.push(tk);
               }
            }
         }
      }
      
      private function skipIgnored() : void
      {
         this.skipWhite();
         var c:int = 0;
         while(Boolean(this.skipComments()) && c < 40)
         {
            c++;
            this.skipWhite();
         }
      }
      
      private function skipComments() : Boolean
      {
         var zhushi:String = null;
         var ttt:String = null;
         var re:Boolean = false;
         var br:Boolean = false;
         while(this.ch == "/")
         {
            if(br)
            {
               break;
            }
            this.nextChar();
            switch(this.ch)
            {
               case "/":
                  zhushi = "";
                  this.nextChar();
                  while(this.ch != "\n" && this.ch != "\r")
                  {
                     zhushi = zhushi + this.ch;
                     this.nextChar();
                  }
                  if(this.ch == "\n")
                  {
                     re = true;
                  }
                  continue;
               case "*":
                  this.nextChar();
                  while(true)
                  {
                     if(this.ch == "*")
                     {
                        this.nextChar();
                        re = true;
                        if(this.ch == "/")
                        {
                           break;
                        }
                     }
                     else
                     {
                        if(this.ch == "\n")
                        {
                           this.line++;
                        }
                        this.nextChar();
                     }
                     if(this.ch == "")
                     {
                        this.parseError("Multi-line comment not closed");
                     }
                  }
                  this.nextChar();
                  continue;
               default:
                  this.ptr = this.ptr - 2;
                  this.nextChar();
                  ttt = this.str.substr(this.ptr,20);
                  br = true;
                  continue;
            }
         }
         return re;
      }
      
      private function skipWhite() : void
      {
         while(this.isWhiteSpace(this.ch))
         {
            if(this.ch == "\n")
            {
               this.line++;
            }
            this.nextChar();
         }
      }
      
      private function isWhiteSpace(ch:String) : Boolean
      {
         return ch == " " || ch == "　" || ch == " " || ch == "\t" || ch == "\r" || ch == "\n";
      }
      
      private function getNextWord() : Token
      {
         var cc:String = null;
         var nc:String = null;
         var ischar:Boolean = false;
         this.skipIgnored();
         var token:Token = new Token();
         switch(this.ch)
         {
            case "{":
               token.type = TokenType.LBRACE;
               token.word = "{";
               token.value = token.word;
               this.nextChar();
               break;
            case "}":
               token.type = TokenType.RBRACE;
               token.word = "}";
               token.value = token.word;
               this.nextChar();
               break;
            case "(":
               token.type = TokenType.LParent;
               token.word = "(";
               token.value = token.word;
               this.nextChar();
               break;
            case ")":
               token.type = TokenType.RParent;
               token.word = ")";
               token.value = token.word;
               this.nextChar();
               break;
            case ".":
               token.type = TokenType.DOT;
               token.word = ".";
               token.value = token.word;
               this.nextChar();
               break;
            case ";":
               token.type = TokenType.Semicolon;
               token.word = ";";
               token.value = token.word;
               this.nextChar();
               break;
            case ",":
               token.type = TokenType.COMMA;
               token.word = ",";
               token.value = token.word;
               this.nextChar();
               break;
            case "-":
            case "+":
               cc = this.ch;
               nc = this.str.charAt(this.ptr);
               if(nc == "=")
               {
                  token.type = TokenType.Assign;
                  token.word = this.ch + "=";
                  token.value = token.word;
                  this.nextChar();
                  this.nextChar();
               }
               else if(cc == nc)
               {
                  token.type = TokenType.INCREMENT;
                  token.word = this.ch + this.ch;
                  token.value = token.word;
                  this.nextChar();
                  this.nextChar();
               }
               else
               {
                  token.type = TokenType.MOP;
                  token.word = this.ch;
                  token.value = token.word;
                  this.nextChar();
               }
               break;
            case "*":
            case "/":
            case "%":
               cc = this.ch;
               nc = this.str.charAt(this.ptr);
               if(nc == "=")
               {
                  token.type = TokenType.Assign;
                  token.word = this.ch + "=";
                  token.value = token.word;
                  this.nextChar();
                  this.nextChar();
               }
               else
               {
                  token.type = TokenType.MOP;
                  token.word = this.ch;
                  token.value = token.word;
                  this.nextChar();
               }
               break;
            case "&":
               nc = this.str.charAt(this.ptr);
               if(nc == "&")
               {
                  this.nextChar();
                  token.type = TokenType.LOP;
                  token.word = "&&";
                  token.value = token.word;
                  this.nextChar();
               }
               else
               {
                  token.type = TokenType.MOP;
                  token.word = this.ch;
                  token.value = token.word;
                  this.nextChar();
               }
               break;
            case "|":
               nc = this.str.charAt(this.ptr);
               if(nc == "|")
               {
                  this.nextChar();
                  token.type = TokenType.LOP;
                  token.word = "||";
                  token.value = token.word;
                  this.nextChar();
               }
               else
               {
                  token.type = TokenType.MOP;
                  token.word = this.ch;
                  token.value = token.word;
                  this.nextChar();
               }
               break;
            case "[":
               token.type = TokenType.LBRACKET;
               token.word = "[";
               token.value = token.word;
               this.nextChar();
               break;
            case "]":
               token.type = TokenType.RBRACKET;
               token.word = "]";
               token.value = token.word;
               this.nextChar();
               break;
            case ":":
               token.type = TokenType.Colon;
               token.word = ":";
               token.value = token.word;
               this.nextChar();
               break;
            case "!":
               this.nextChar();
               if(this.ch == "=")
               {
                  token.type = TokenType.COP;
                  token.word = "!=";
                  token.value = token.word;
                  this.nextChar();
               }
               else
               {
                  token.type = TokenType.LOPNot;
                  token.word = "!";
                  token.value = token.word;
               }
               break;
            case "=":
               this.nextChar();
               if(this.ch == "=")
               {
                  token.type = TokenType.COP;
                  token.word = "==";
                  token.value = token.word;
                  this.nextChar();
               }
               else
               {
                  token.type = TokenType.Assign;
                  token.word = "=";
                  token.value = token.word;
               }
               break;
            case ">":
               this.nextChar();
               if(this.ch == "=")
               {
                  token.type = TokenType.COP;
                  token.word = ">=";
                  token.value = token.word;
                  this.nextChar();
               }
               else if(this.ch == ">")
               {
                  token.type = TokenType.MOP;
                  token.word = ">>";
                  token.value = token.word;
                  this.nextChar();
               }
               else
               {
                  token.type = TokenType.COP;
                  token.word = ">";
                  token.value = token.word;
               }
               break;
            case "<":
               this.nextChar();
               if(this.ch == "=")
               {
                  token.type = TokenType.COP;
                  token.word = "<=";
                  token.value = token.word;
                  this.nextChar();
               }
               else if(this.ch == "<")
               {
                  token.type = TokenType.MOP;
                  token.word = "<<";
                  token.value = token.word;
                  this.nextChar();
               }
               else
               {
                  token.type = TokenType.COP;
                  token.word = "<";
                  token.value = token.word;
               }
               break;
            case "\"":
               token.word = this.readString();
               token.value = token.word;
               token.type = TokenType.constant;
               break;
            case "\'":
               token.word = this.readString();
               token.value = token.word;
               token.type = TokenType.constant;
               break;
            case "#":
               this.nextChar();
               this.word = "";
               while(Boolean(this.isDigit(this.ch)) || this.ch >= "a" && this.ch <= "f" || this.ch >= "A" && this.ch <= "F")
               {
                  this.word = this.word + this.ch;
                  this.nextChar();
               }
               token.word = this.word;
               token.value = uint(parseInt(this.word,16));
               token.type = TokenType.constant;
               break;
            default:
               if(Boolean(this.isDigit(this.ch)) || this.ch == "-")
               {
                  this.word = this.ch;
                  this.nextChar();
                  if(this.ch == "x" && this.word == "0")
                  {
                     this.nextChar();
                     this.word = "";
                     while(Boolean(this.isDigit(this.ch)) || this.ch >= "a" && this.ch <= "f" || this.ch >= "A" && this.ch <= "F")
                     {
                        this.word = this.word + this.ch;
                        this.nextChar();
                     }
                     token.word = this.word;
                     token.value = uint(parseInt(this.word,16));
                     token.type = TokenType.constant;
                  }
                  else
                  {
                     ischar = false;
                     while(this.ch == "_" || Boolean(this.isDigit(this.ch)) || this.ch == ".")
                     {
                        if(this.ch == "_")
                        {
                           ischar = true;
                        }
                        this.word = this.word + this.ch;
                        this.nextChar();
                     }
                     if(ischar)
                     {
                        token.word = this.word;
                        token.value = this.word;
                        token.type = TokenType.ident;
                     }
                     else
                     {
                        token.word = this.word;
                        token.value = Number(this.word);
                        token.type = TokenType.constant;
                     }
                  }
               }
               else if(this.isAlpha(this.ch))
               {
                  this.word = this.ch;
                  this.nextChar();
                  while(Boolean(this.isAlpha(this.ch)) || Boolean(this.isDigit(this.ch)) || this.ch == "_")
                  {
                     this.word = this.word + this.ch;
                     this.nextChar();
                  }
                  if(this.word.charAt(this.word.length - 1) == ".")
                  {
                     this.parseError("ID不允许后后缀");
                  }
                  token.word = this.word;
                  token.value = this.word.split(".");
                  if(Token.wordpatten.indexOf("|" + this.word + "|") >= 0)
                  {
                     if(this.word == "as" || this.word == "is" || this.word == "in" || this.word == "instanceof")
                     {
                        token.type = TokenType.COP;
                        token.word = this.word;
                     }
                     else
                     {
                        token.type = TokenType["key" + this.word];
                        if(this.word == "new")
                        {
                           this.loadnew = true;
                        }
                     }
                  }
                  else if(token.word == "false")
                  {
                     token.type = TokenType.constant;
                     token.value = false;
                     token.word = "false";
                  }
                  else if(token.word == "true")
                  {
                     token.type = TokenType.constant;
                     token.value = true;
                     token.word = "true";
                  }
                  else if(token.word == "null")
                  {
                     token.type = TokenType.constant;
                     token.value = null;
                     token.word = "null";
                  }
                  else
                  {
                     token.type = TokenType.ident;
                  }
               }
               else
               {
                  if(this.ch == "")
                  {
                     return null;
                  }
                  this.parseError(this.ptr + "Unexpected " + this.str.substr(this.ptr) + " encountered");
               }
         }
         return token;
      }
      
      private function isHexDigit(ch:String) : Boolean
      {
         var uc:String = ch.toUpperCase();
         return Boolean(this.isDigit(ch)) || uc >= "A" && uc <= "F";
      }
      
      private function readString() : String
      {
         var s:String = "";
         var mychar:String = this.ch;
         this.nextChar();
         while(this.ch != mychar && this.ch != "")
         {
            if(this.ch == "\\")
            {
               this.nextChar();
               switch(this.ch)
               {
                  case "\"":
                     s = s + "\"";
                     break;
                  case "/":
                     s = s + "/";
                     break;
                  case "\\":
                     s = s + "\\";
                     break;
                  case "b":
                     s = s + "\b";
                     break;
                  case "f":
                     s = s + "\f";
                     break;
                  case "n":
                     s = s + "\n";
                     break;
                  case "r":
                     s = s + "\r";
                     break;
                  case "t":
                     s = s + "\t";
                     break;
                  default:
                     s = s + ("\\" + this.ch);
               }
            }
            else
            {
               s = s + this.ch;
            }
            this.nextChar();
         }
         if(this.ch == "")
         {
            this.parseError("Unterminated string literal");
         }
         this.nextChar();
         return s;
      }
      
      private function nextChar() : String
      {
         this.ch = this.str.charAt(this.ptr++);
         return this.ch;
      }
      
      private function isDigit(ch:String) : Boolean
      {
         return ch >= "0" && ch <= "9";
      }
      
      private function isAlpha(c:String) : Boolean
      {
         var v:Number = c.charCodeAt(0);
         if(Boolean(this.undot) && c == ".")
         {
            return true;
         }
         if(v < 127)
         {
            if(v < 91 && v > 64 || v > 96 && v < 123 || v == 95)
            {
               return true;
            }
         }
         else if(v >= 19968 && v <= 40869)
         {
            return true;
         }
         return false;
      }
      
      private function parseError(message:String) : void
      {
         throw new Error(this.lines[this.line] + "词法分析出错:" + message + "当前位置=" + this.ptr);
      }
   }
}
