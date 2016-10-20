package parse
{
   import flash.utils.Dictionary;
   import parser.DY;
   import parser.GNode;
   
   public class ProxyFunc
   {
      
      private static var dics:Dictionary = new Dictionary();
       
      private var it:DY;
      
      private var funcname:String;
      
      private var Func:Function;
      
      public function ProxyFunc(_it:DY, fn:String)
      {
         super();
         this.it = _it;
         this.funcname = fn;
         if((_it._rootnode.motheds[fn] as GNode).childs[0].childs.length == 1)
         {
            this.Func = this.Func1;
         }
         else
         {
            this.Func = this.FuncN;
         }
      }
      
      public static function getAFunc(_it:DY, fn:String) : Function
      {
         if(!dics[_it])
         {
            dics[_it] = new Dictionary();
         }
         if(!dics[_it][fn])
         {
            dics[_it][fn] = new ProxyFunc(_it,fn);
         }
         return dics[_it][fn].Func;
      }
      
      public function Func1(arg1:*) : *
      {
         try
         {
            return this.it.call(this.funcname,[arg1]);
         }
         catch(e:Error)
         {
            trace(e.getStackTrace());
         }
      }
      
      public function FuncN(... args) : *
      {
         try
         {
            return this.it.call(this.funcname,args);
         }
         catch(e:Error)
         {
            trace(e.getStackTrace());
         }
      }
   }
}
