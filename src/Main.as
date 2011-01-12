package 
{
	import ecpu.assembler.Assembler;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.KeyboardEvent;
	import flash.events.TextEvent;
	import flash.text.StyleSheet;
	import flash.text.TextField;
	import flash.text.TextFieldType;
	import flash.text.TextFormat;
	import net.flashpunk.utils.Key;

	/**
	 * ...
	 * @author Richard Marks
	 */
	[Frame(factoryClass="Preloader")]
	public class Main extends Sprite 
	{
		private var assembler:Assembler = new Assembler;
		private var inputPanel:TextField = new TextField;
		private var outputPanel:TextField = new TextField;
		
		public function Main():void 
		{
			if (stage) init();
			else addEventListener(Event.ADDED_TO_STAGE, init);
		}

		private function OnKeyDown(e:KeyboardEvent):void
		{
			if (e.keyCode == Key.F5)
			{
				trace(inputPanel.text.split("\r").length);
				assembler.Assemble(inputPanel.text);
			}
		}
		
		private function init(e:Event = null):void 
		{
			removeEventListener(Event.ADDED_TO_STAGE, init);
			
			addEventListener(KeyboardEvent.KEY_DOWN, OnKeyDown);
			
			// entry point
			
			// build interface
			
			
			
			
			
			inputPanel.type = TextFieldType.INPUT;
			inputPanel.defaultTextFormat = new TextFormat("courier", 16, 0xFFFFFF, true);
			inputPanel.width = (stage.stageWidth / 2) - 2;
			inputPanel.x = 1;
			inputPanel.y = 1;
			inputPanel.height = (stage.stageHeight - 2);
			inputPanel.border = true;
			inputPanel.borderColor = 0xFFFFFF;
			inputPanel.multiline = true;
			inputPanel.wordWrap = false;
			
			outputPanel.defaultTextFormat = new TextFormat("courier", 16, 0xFFFFFF, true);
			outputPanel.width = (stage.stageWidth / 2) - 2;
			outputPanel.x = 1 + inputPanel.x + inputPanel.width;
			outputPanel.y = 1;
			outputPanel.height = (stage.stageHeight - 2);
			outputPanel.border = true;
			outputPanel.borderColor = 0xFFFFFF;
			outputPanel.multiline = true;
			
			addChild(inputPanel);
			addChild(outputPanel);
			
		}	
	}
}