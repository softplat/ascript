package parser
{
   public class LValue
   {
       
      public var scope:Object;
      
      public var key:String;
      public var params:Array;
      public function LValue()
      {
         super();
      }
	  public function get Value():*{
		  var vl = key!=null?scope[key]:scope;
		  if (vl is Function) {
			 if (params != null) {
				return vl.apply(scope, params); 
			 }
			 return vl;
		  }else{
			  return vl;
		  }
	  }
   }
}
