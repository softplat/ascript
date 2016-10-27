package parse
{
   public class TokenType
   {
      
      public static var ident:int = 1;
      
      public static var constant:int = 2;
      
      public static var Assign:int = 3;
      
      public static var MOP:int = 4;
      
      public static var LOP:int = 5;
      
      public static var COP:int = 6;
      
      public static var INCREMENT:int = 7;
      
      public static var LOPNot:int = 40;
      
      public static var keyclass:int = 10;
      
      public static var keyimport:int = 11;
      
      public static var keyfunction:int = 12;
      
	  public static var keystatic:int = 57;
	  
      public static var keyif:int = 13;
      
      public static var keyelse:int = 14;
      
      public static var keyfor:int = 15;
      
      public static var keywhile:int = 16;
      
      public static var keyvar:int = 17;
      
      public static var keyreturn:int = 18;
      
      public static var keynew:int = 19;
      
      public static var keyextends:int = 20;
	  
      public static var keypackage:int = 42;
      
      public static var keypublic:int = 44;
      
      public static var keyprivate:int = 45;
      
      public static var keyprotected:int = 46;
      
      public static var keyswitch:int = 47;
      
      public static var keycase:int = 48;
      
      public static var keybreak:int = 49;
      
      public static var keydefault:int = 50;
      
      public static var keycontinue:int = 51;
      
      public static var keytry:int = 52;
      
      public static var keycatch:int = 53;
      
      public static var keyfinally:int = 54;
      
      public static var keyeach:int = 55;
      
      public static var LBRACE:int = 21;
      
      public static var RBRACE:int = 22;
      
      public static var LParent:int = 23;
      
      public static var RParent:int = 24;
      
      public static var DOT:int = 25;
      
      public static var COMMA:int = 26;
      
      public static var Semicolon:int = 27;
      
      public static var NULL:int = 29;
      
      public static var LBRACKET:int = 30;
      
      public static var RBRACKET:int = 31;
      
      public static var Colon:int = 32;
       
      public var id:int;
      
      public function TokenType(_id:int = 0)
      {
         super();
         this.id = _id;
      }
   }
}
