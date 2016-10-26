package parser
{
   import parse.Token;
   
   public final class GNode
   {
      
      public static var lev:int = 0;
      
      private static var levs:Array = ["","-","--","---","----","-----","------","--------","--------","---------","----------","-----------","------------","-------------","--------------","---------------","----------------"];
       
      public var childs:Vector.<parser.GNode>;
      
      public var token:Token;
      
      public var gtype:int;
      
      public var vartype:String = "dynamic";
      
      public var word:String;
      
      public var istatic:Boolean;
      
      public function GNode(n:int = -1, v:Token = null)
      {
         this.childs = new Vector.<parser.GNode>();
         super();
         if(n > -1)
         {
            this.gtype = n;
            this.token = v;
            if(n != GNodeType.IDENT)
            {
               if(this.token)
               {
                  this.word = this.token.word;
               }
            }
         }
      }
      
      public function get value() : *
      {
         if(this.token)
         {
            return this.token.value;
         }
         return null;
      }
      
      public function get line() : int
      {
         return this.token.line;
      }
      
      public function get nodeType() : int
      {
         return this.gtype;
      }
      
      public function get name() : String
      {
         if(this.nodeType == GNodeType.AssignStm)
         {
            return this.childs[0].name;
         }
         if(this.token)
         {
            return this.token.word;
         }
         return null;
      }
      
      public function addChild(node:parser.GNode) : void
      {
         this.childs.push(node);
      }
      
      public function toString() : String
      {
         var o:parser.GNode = null;
         var str:String = GNodeType.getName(this.gtype);
         if(this.token)
         {
            str = str + (" " + this.token.value);
            if(this.gtype == GNodeType.VarDecl || this.gtype == GNodeType.FunDecl)
            {
               str = this.vartype + " " + str;
            }
         }
         str = levs[lev] + str + "\n";
         lev++;
         for each(o in this.childs)
         {
            if(o is parser.GNode)
            {
               str = str + (o as parser.GNode).toString();
            }
            else
            {
               str = str + ("=======>" + o.toString());
            }
         }
         lev--;
         return str;
      }
   }
}
