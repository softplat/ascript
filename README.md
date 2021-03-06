AScript是什么
=======

Ascript是一种解释型脚本语言，用ActionScript3.0实现，并且能和ActionScript3.0无缝结合，无需编译，即可执行大部分as3内置类和自定义类。   

AScript能做什么
=======   
    
Ascript并不想帮你编写大量的代码，Ascript让你用少量的代码解决动态数据和动态逻辑配置等问题。一个很好的例子是当你采用as3来开发ios项目，就可以用AScript动态配置逻辑和数据，这样就做到可以动态更新逻辑和数据而不需要重新提交客户端。
    
Ascript是一个小巧而嵌入式的语言，语法和as3基本相同，会方便任何熟悉此类语言的人轻易使用，实际上，这个语言能直接运行大部分as3类。
    
Ascript不致力于做as3语言已经做得很好的领域，比如：UI库，游戏底层渲染，物理系统，以及与第三方软件的接口。 Ascript依赖于as3去做完成这些任务。Ascript所提供的机制是as3不善于的：动态数据和逻辑等。 
    
AScript的特点
======= 

Ascript支持基于组件的，我们可以将一些已经存在的高级组件整合在一起实现一个应用软件。

一般情况下，组件使用像as3等静态的语言编写。但Ascript是我们整合各个组件的粘合剂。通常情况下，组件（或对象）表现为具体在程序开发过程中很少变化的、占用大量CPU时间的决定性的程序，例如窗口部件和数据结构。
    
对于在产品的生命周期内变化比较多的应用程序，使用Ascript可以更方便的适应变化。
    
除了作为整合语言外，Ascript自身也是一个功能强大的语言。Ascript不仅可以整合组件，还可以编辑组件甚至完全使用Ascript创建组件。   

除了Ascript外，还有很多类似的脚本语言，例如：Lua，Perl，Tcl，Ruby，Forth，Python等。AScript和这些语言在某些方面有相同的特点，但下面这些特征是Ascript特有的： 


  * 支持类。可以创建自定义的脚本类，这是个嵌入式脚本语言，和lua等语言比较，最大的优势是支持类。

  * 简单。Ascript本身简单，小巧，内容少但功能强大，这使得Ascript易于学习，很容易实现一些小的应用。

  * 体积小。他的完全发布版swc库不足30K。用flashcs系列发布只会增加不足20k的体积。

  * Ascript的接口极其简单，目前的接口只有6个函数,方便学习使用。

  * 易用。其语法和as3相似，可以用as3的语法进行程序编写。

  * 与as3无缝集成，就是说可以在脚本中调用和创建任意的as3编写的类库和内置API。 

下载及版本说明
=======
如果您想对Ascript进行二次开发，以便Ascript更加适应您的项目，建议您通过<font color="#ff0000">**Fork**</font>的方式，fork操作会把Ascript项目克隆一份到您的代码仓库，您可以对您代码仓库里的Ascript项目随意修改。

如果您不熟悉git的操作形式，也可以点击首页右侧的<font color="#ff0000">**Download Zip**</font>按钮，下载一份代码压缩包，代码的版本与您所选择的分支版本有关。

![](https://raw.github.com/wiki/softplat/ascript/imgs/2.png)

github的使用者可以在不同的版本分支之间自由切换。切换版本分支可以参考下图：

![](https://raw.github.com/wiki/softplat/ascript/imgs/1.png)

- tags下为稳定版本，以版本号作为分支名。

- release以及dev为前缀的版本为开发版本，不能保证程序的正常运行，不建议您直接检出使用。

- master分支为最新版本，可能是alhpa版或beta版，也可能和稳定版一样。

下表是一个简单的对各个版本的推荐：


<table border="0">
<tr  align="center">
<td><b>版本</b></td>
<td><b>稳定版</b></td>
<td><b>开发版</b></td>
<td><b>master分支</b></td>
</tr>
<tr  align="center">
<td>开发者</td>
<td>推荐</td>
<td>推荐</td>
<td>推荐</td>
</tr>
<tr  align="center">
<td>使用者</td>
<td>推荐</td>
<td>不推荐</td>
<td>不推荐</td>
</tr>
<tr  align="center">
<td>学习者</td>
<td>推荐</td>
<td>不推荐</td>
<td>推荐</td>
</tr>
</table>

不同版本的说明请参考[ChangeLog](https://github.com/softplat/ascript/wiki/changelog)
        
Ascript示例
=======

[Ascript控制台（用于通过Ascript动态执行主程序内的代码）](https://github.com/gt2005/GameUtilities/tree/master/GDebug)    
      
ios项目的热更新（马上推出）     

Ascript交流QQ群
=======
QQ群：264282406
       
与我们联系请发送邮件到[ascript@softplat.com](mailto:ascript@softplat.com)

Wiki
=======		
https://github.com/softplat/ascript/wiki

