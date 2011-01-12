package ecpu.emulator 
{
	import ecpu.common.CmpResult;
	import ecpu.common.PrinterMode;
	import ecpu.common.TstResult;
	import flash.net.FileReference;
	/**
	 * This is an emulator for a simple non-existent computer system.
	 * There is a total of 2MB of RAM in which you may execute your own programs.
	 * 1MB of RAM is your program space, and 1MB of RAM is for your code's usage.
	 * You may be thinking "one meg? thats nothing!" well my friend,
	 * this means that you can have up to a whopping max-length of 1,048,576 instructions!
	 * The memory is mapped in 2x 1MB chunks.
	 * Your program gets loaded into virtual memory address 0x100000
	 * and may extend all the way to address 0x1FFFFF
	 * You have from 0x000000 to 0x0FFFFF in which you may write data and store variables.
	 * If you write values into virtual memory between 0x100000 and 0x1FFFFF then you will
	 * be modifying the program code. This can be a useful technique for some hardcore coders.
	 * At this time, you may only use 32-bit integers in any memory location.
	 * 
	 * @author Richard Marks
	 */
	public class Emulator 
	{
		/// total virtual memory
		static public const VRAM_SIZE:uint = 0x200000;
		
		/// start of virtual memory
		static public const VRAM_FREE:uint = 0x000000;
		
		/// start of virtual memory where program code is loaded
		static public const VRAM_USER:uint = 0x100000;
		
		/// start of stack virtual memory (end of free memory)
		static public const VRAM_STACK:uint = 0x0FFFFF;
		
		/// is the cpu processing
		private var processing:Boolean;

		/// was there an error processing
		private var processingError:Boolean;

		/// what the last error was
		private var lastError:String;

		/// data pointer
		private var dp:Number;

		/// instruction pointer
		private var ip:Number;

		/// stack pointer
		private var sp:Number;

		/// virtual memory
		private var vram:Vector.<Number>;

		/// the result of the last cmp operation
		private var lastCmp:CmpResult;

		/// the result of the last tst operation
		private var lastTst:TstResult;

		/// what mode is the stdout printer in
		private var printerMode:PrinterMode;

		/// have we jumped
		private var jumped:Boolean;
		
		public function Emulator() 
		{
			vram = new Vector.<Number>(VRAM_SIZE);
			HardwareReset();
		}
		
		/**
		 * loads a machine code program into the virtual memory starting at VRAM_USER memory location
		 * @param	code - Vector containing the assembled ECPU machine code instructions
		 * @return true if load is successful and false if out of memory
		 */
		public function Load(code:Vector.<Number>):Boolean 
		{
			
		}
		
		/**
		 * begin executing the instructions found in virtual memory starting at VRAM_USER memory location
		 * @param	code - optional code to load
		 */
		public function Run(code:Vector.<Number> = null):void
		{
			if (code != null)
			{
				Load(code);
			}
		}
		
		/// perform a hardware reset -- all virtual memory is cleared and pointers are reset
		private function HardwareReset():void { }
		
		/// processes the current instruction - returns false on error
		private function ProcessInstruction():Boolean { }

		/// outputs a single character to stdout
		private function OutputCharacter(character:String):void { }
		
		/// outputs a single integer to stdout
		private function OutputInteger(integer:Number):void { }

		/// returns a psuedo-random number between lowerlimit and upperlimit inclusive
		private function GenerateRandomInteger(lowerlimit:Number, upperlimit:Number):Number { }

		/// advances the instruction pointer by count
		private function Skip(count:Number = 1):void { }

		/// instruction set implementations
		private function Nop():void { }
		private function Reset():void { }
		private function Rand():void { }

		private function Inc():void { }
		private function Dec():void { }
		private function Var():void { }
		private function Set():void { }
		private function Copy():void { }
		private function Adv():void { }

		private function Add():void { }
		private function Sub():void { }
		private function Mul():void { }
		private function Div():void { }
		private function Shl():void { }
		private function Shr():void { }
		private function Mod():void { }
		private function Sqrt():void { }
		private function Sin():void { }
		private function Cos():void { }
		private function Tan():void { }
		private function Acos():void { }
		private function Asin():void { }
		private function Atan():void { }
		private function Pow():void { }

		private function Print():void { }
		private function SetPrint():void { }

		private function Jmp():void { }
		private function End():void { }

		private function Cmp():void { }
		private function Tst():void { }
		private function Je():void { }
		private function Jne():void { }
		private function Jl():void { }
		private function Jg():void { }
		private function Jle():void { }
		private function Jge():void { }
		private function Jz():void { }
		private function Jnz():void { }

		private function Push():void { }
		private function Pop():void { }
		private function Popall():void { }

		private function SysCall():void { }

		// bios routine implementations
		private function BiosGetChar():void { }
		private function BiosGetString():void { }
		private function BiosGetInteger():void { }
		private function BiosFileOpen():void { }
		private function BiosFileRead():void { }
		private function BiosFileReadLine():void { }
		private function BiosFileWrite():void { }
		private function BiosFileWriteLine():void { }
		private function BiosFileClose():void { }
		private function BiosFillMemory():void { }
	}
}