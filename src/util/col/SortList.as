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

package util.col
{
	
	/**
	 * @author dayu
	 */
	public class SortList {
		public var arr : Array;//保存位置
		public var element : Array;//实际元素
		public var obj : Object;
		
		function SortList() {
			arr = [];
			obj = {};
			element=[];
		}
		public function clear():void{
			arr=[];
			obj={};
			element=[];
		}
		public function add(s:String,object):void{
			if (obj[s] == null) {
				obj[s] = arr.length;
				arr.push(s);
				element.push(object);		
			}
		}
		public function setobj(s:String,Value:Object):void{
			if(exist(s)){
				element[obj[s]]=Value;
			}
		}
		public function getobj(s:String):Object{
			if(exist(s)){
				return element[obj[s]];
			}
			return null;
		}
		public function exist(s:String):Boolean{
			return obj[s] != null;
		}
		
		public function remove(s:String):void{
			if (obj[s] != null) {
				//if(obj[s])
				arr.splice(obj[s], 1);
				element.splice(obj[s], 1);
				for (var i:int = obj[s];i < arr.length; i++) {
					obj[arr[i]] -= 1;
				}
				delete obj[s];
			}
		}
		public function get length():int{
			return arr.length;
		}
		
		public function getbyindex(i:int):Object {
			return arr[i];
		}
		public function toString():String{
			return arr.toString();
		}
	}
	
}