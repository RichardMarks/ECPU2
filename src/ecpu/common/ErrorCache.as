package ecpu.common 
{
	/**
	 * ...
	 * @author Richard Marks
	 */
	public class ErrorCache
	{
		private var errors:Vector.<String>;
		private var errorPointer:Number;
		
		public function ErrorCache() 
		{
			errors = new Vector.<String>();
			errorPointer = 0;
		}
		
		public function Clear():void 
		{
			errors.length = 0;
		}
		
		public function Write(message:String):void 
		{
			errors.push(message);
		}
		
		public function Rewind():Number 
		{
			errorPointer = 0;
			return errors.length;
		}
		
		public function Next():String 
		{
			if (errorPointer >= errors.length)
			{
				errorPointer = 0;
			}
			
			return errors[errorPointer++];
		}
	}
}