package parser
{
   public class GNodeType
   {
      
      public static var CLASS:int = 20;
      
      public static var FunDecl:int = 0;
      
      public static var VarDecl:int = 1;
      
      public static var Params:int = 2;
      
      public static var MOP:int = 3;
      
      public static var LOP:int = 4;
      
      public static var LOPNot:int = 22;
      
      public static var Nagtive:int = 23;
      
      public static var COP:int = 5;
      
      public static var Stms:int = 6;
      
      public static var AssignStm:int = 7;
      
      public static var IfElseStm:int = 8;
      
      public static var WhileStm:int = 9;
      
      public static var ForStm:int = 10;
      
      public static var ForInStm:int = 25;
      
      public static var ForEACHStm:int = 40;
      
      public static var ReturnStm:int = 11;
      
      public static var FunCall:int = 12;
      
      public static var VarID:int = 13;
      
      public static var IDENT:int = 24;
      
      public static var Index:int = 28;
      
      public static var SWITCH:int = 29;
      
      public static var CASE:int = 30;
      
      public static var DEFAULT:int = 31;
      
      public static var TRY:int = 32;
      
      public static var CATCH:int = 33;
      
      public static var FINALLY:int = 34;
      
      public static var BREAK:int = 35;
      
      public static var CONTINUE:int = 36;
      
      public static var ELSEIF:int = 37;
      
      public static var PREINCREMENT:int = 38;
      
      public static var INCREMENT:int = 39;
      
      public static var newArray:int = 26;
      
      public static var newObject:int = 27;
      
      public static var ConstID:int = 14;
      
      public static var EXPS:int = 15;
      
      public static var newClass:int = 17;
      
      public static var ERROR:int = 18;
      
      public static var importStm:int = 19;
      
      public static var names:Array = ["FunDecl","VarDecl","Params","MOP","LOP","COP","Stms","AssignStm","IfElseStm","WhileStm","ForStm","ReturnStm","FunCall","VarID","ConstID","EXPS","","newClass","ERROR","importStm","CLASS","","LOPNot","Nagtive","IDENT","ForInStm","newArray","newObject","Index","SWITCH","CASE","DEFAULT","TRY","CATCH","FINALLY","BREAK","CONTINUE","ELSEIF","PREINCREMENT","INCREMENT"];
       
      public function GNodeType()
      {
         super();
      }
      
      public static function getName(i:int) : String
      {
         return names[i];
      }
   }
}
