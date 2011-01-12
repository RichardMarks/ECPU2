package ecpu.common 
{
	/**
	 * ...
	 * @author Richard Marks
	 */
	public class ErrorID 
	{
		static public const NONE:String = "NONE";
		static public const INVALID_INSTRUCTION:String = "INVALID INSTRUCTION";
		static public const INSTRUCTION_POINTER_IS_PAST_END_OF_MEMORY:String = "INSTRUCTION POINTER REACHED END OF MEMORY";
		static public const INSTRUCTION_STREAM_ENDED_PREMATURELY:String = "INSTRUCTION STREAM ENDED PREMATURELY";
		static public const OUT_OF_MEMORY:String = "ADDRESS IS PAST THE END OF MEMORY";
		static public const BAD_PRINT_MODE:String = "BAD STDOUT PRINTER MODE SELECTED";
		static public const DIVIDE_BY_ZERO:String = "ILLEGAL DIVISION BY ZERO";
		static public const OUT_OF_STACK_SPACE:String = "OUT OF STACK SPACE";
		static public const STACK_EMPTY:String = "STACK IS EMPTY";
		static public const BIOS_ROUTINE_NOT_FOUND:String = "BIOS ROUTINE NOT FOUND";
		static public const BIOS_ROUTINE_PARAMETER_MISSING:String = "BIOS ROUTINE PARAMETER MISSING";
		static public const FILE_HANDLE_INVALID:String = "INVALID FILE HANDLE";
	}
}