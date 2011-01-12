package ecpu.emulator 
{
	import ecpu.common.CmpResult;
	import ecpu.common.ErrorID;
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
		
		
		public var stdout:String;
		
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
			var codeSize:Number = code.length;
			if ((codeSize + VRAM_USER) >= VRAM_SIZE)
			{
				lastError = ErrorID.OUT_OF_MEMORY;
				return false;
			}
			
			for (var offset:Number = 0; offset < codeSize; offset++)
			{
				vram[VRAM_USER + offset] = code[offset];
			}
			
			dp = 0;
			ip = 0;
			
			return true;
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
		private function HardwareReset():void 
		{ 
			for (var location:Number = 0; location < VRAM_SIZE; location++)
			{
				vram[location] = 0;
			}
			
			ip = 0;
			dp = 0;
			sp = VRAM_STACK;
			
			lastCmp = CmpResult.INVALID;
			lastTst = TstResult.INVALID;
			lastError = ErrorID.NONE;
			jumped = false;
			printerMode = PrinterMode.CHARACTER;
			processingError = false;
		}
		
		/// processes the current instruction - returns false on error
		private function ProcessInstruction():Boolean { }

		/// outputs a single character to stdout
		private function OutputCharacter(character:String):void 
		{
			stdout += character;
		}
		
		/// outputs a single integer to stdout
		private function OutputInteger(integer:Number):void 
		{
			stdout += integer.toString();
		}

		/// returns a psuedo-random number between lowerlimit and upperlimit inclusive
		private function GenerateRandomInteger(lowerLimit:Number, upperLimit:Number):Number 
		{
			var r:Number = 0;
			var range:Number = (upperLimit - lowerLimit);
			
			if (range <= 0)
			{
				range = 1;
			}
			
			r = lowerLimit + Math.random() % range;
			return r;
		}

		/// advances the instruction pointer by count
		private function Skip(count:Number = 1):void 
		{
			ip += count;
		}

		/// instruction set implementations
		
		private function Nop():void 
		{
			// waste CPU cycles
		}
		
		private function Reset():void 
		{ 
			HardwareReset(); 
		}
		
		private function Rand():void 
		{ 
			var addressForOperandA:Number = VRAM_USER + 1 + ip;
			var addressForOperandB:Number = VRAM_USER + 2 + ip;
			
			if (addressForOperandB >= VRAM_SIZE)
			{
				lastError = ErrorID.OUT_OF_MEMORY;
				processingError = true;
				return;
			}
			
			var operandA:Number = vram[addressForOperandA];
			var operandB:Number = vram[addressForOperandB];
			vram[dp] = GenerateRandomInteger(operandA, operandB);
		}

		private function Inc():void 
		{
			var addressForOperandA:Number = VRAM_USER + 1 + ip;
			
			if (addressForOperandA >= VRAM_SIZE)
			{
				lastError = ErrorID.OUT_OF_MEMORY;
				processingError = true;
				return;
			}
			
			var operandA:Number = vram[addressForOperandA];
			
			vram[dp] += operandA;
		}
		
		private function Dec():void 
		{
			var addressForOperandA:Number = VRAM_USER + 1 + ip;
			
			if (addressForOperandA >= VRAM_SIZE)
			{
				lastError = ErrorID.OUT_OF_MEMORY;
				processingError = true;
				return;
			}
			
			var operandA:Number = vram[addressForOperandA];
			
			vram[dp] -= operandA;
		}
		
		private function Var():void 
		{
			var addressForOperandA:Number = VRAM_USER + 1 + ip;
			
			if (addressForOperandA >= VRAM_SIZE)
			{
				lastError = ErrorID.OUT_OF_MEMORY;
				processingError = true;
				return;
			}
			
			var operandA:Number = vram[addressForOperandA];
			
			dp = operandA;
		}
		
		private function Set():void 
		{
			var addressForOperandA:Number = VRAM_USER + 1 + ip;
			
			if (addressForOperandA >= VRAM_SIZE)
			{
				lastError = ErrorID.OUT_OF_MEMORY;
				processingError = true;
				return;
			}
			
			var operandA:Number = vram[addressForOperandA];
			
			vram[dp] = operandA;
		}
		
		private function Copy():void 
		{
			var addressForOperandA:Number = VRAM_USER + 1 + ip;
			var addressForOperandB:Number = VRAM_USER + 2 + ip;
			
			if (addressForOperandB >= VRAM_SIZE)
			{
				lastError = ErrorID.OUT_OF_MEMORY;
				processingError = true;
				return;
			}
			
			var operandA:Number = vram[addressForOperandA];
			var operandB:Number = vram[addressForOperandB];
			
			if (operandA >= VRAM_SIZE || operandB >= VRAM_SIZE)
			{
				lastError = ErrorID.OUT_OF_MEMORY;
				processingError = true;
				return;
			}
			
			vram[operandB] = operandA;
		}
		
		private function Adv():void 
		{
			var addressForOperandA:Number = VRAM_USER + 1 + ip;
			
			if (addressForOperandA >= VRAM_SIZE)
			{
				lastError = ErrorID.OUT_OF_MEMORY;
				processingError = true;
				return;
			}
			
			var operandA:Number = vram[addressForOperandA];
			
			if (operandA >= VRAM_SIZE)
			{
				lastError = ErrorID.OUT_OF_MEMORY;
				processingError = true;
				return;
			}
			
			operandA = vram[operandA];
			
			if (dp + operandA >= VRAM_SIZE)
			{
				lastError = ErrorID.OUT_OF_MEMORY;
				processingError = true;
				return;
			}
			
			dp += operandA;
		}

		private function Add():void 
		{
			var addressForOperandA:Number = VRAM_USER + 1 + ip;
			var addressForOperandB:Number = VRAM_USER + 2 + ip;
			
			if (addressForOperandB >= VRAM_SIZE)
			{
				lastError = ErrorID.OUT_OF_MEMORY;
				processingError = true;
				return;
			}
			
			var operandA:Number = vram[addressForOperandA];
			var operandB:Number = vram[addressForOperandB];
			
			if (operandA >= VRAM_SIZE || operandB >= VRAM_SIZE)
			{
				lastError = ErrorID.OUT_OF_MEMORY;
				processingError = true;
				return;
			}
			
			vram[dp] = vram[operandA] + vram[operandB];
		}
		
		private function Sub():void 
		{
			var addressForOperandA:Number = VRAM_USER + 1 + ip;
			var addressForOperandB:Number = VRAM_USER + 2 + ip;
			
			if (addressForOperandB >= VRAM_SIZE)
			{
				lastError = ErrorID.OUT_OF_MEMORY;
				processingError = true;
				return;
			}
			
			var operandA:Number = vram[addressForOperandA];
			var operandB:Number = vram[addressForOperandB];
			
			if (operandA >= VRAM_SIZE || operandB >= VRAM_SIZE)
			{
				lastError = ErrorID.OUT_OF_MEMORY;
				processingError = true;
				return;
			}
			
			vram[dp] = vram[operandA] - vram[operandB];
		}
		
		private function Mul():void 
		{
			var addressForOperandA:Number = VRAM_USER + 1 + ip;
			var addressForOperandB:Number = VRAM_USER + 2 + ip;
			
			if (addressForOperandB >= VRAM_SIZE)
			{
				lastError = ErrorID.OUT_OF_MEMORY;
				processingError = true;
				return;
			}
			
			var operandA:Number = vram[addressForOperandA];
			var operandB:Number = vram[addressForOperandB];
			
			if (operandA >= VRAM_SIZE || operandB >= VRAM_SIZE)
			{
				lastError = ErrorID.OUT_OF_MEMORY;
				processingError = true;
				return;
			}
			
			vram[dp] = vram[operandA] * vram[operandB];
		}
		
		private function Div():void 
		{
			var addressForOperandA:Number = VRAM_USER + 1 + ip;
			var addressForOperandB:Number = VRAM_USER + 2 + ip;
			
			if (addressForOperandB >= VRAM_SIZE)
			{
				lastError = ErrorID.OUT_OF_MEMORY;
				processingError = true;
				return;
			}
			
			var operandA:Number = vram[addressForOperandA];
			var operandB:Number = vram[addressForOperandB];
			
			if (operandA >= VRAM_SIZE || operandB >= VRAM_SIZE)
			{
				lastError = ErrorID.OUT_OF_MEMORY;
				processingError = true;
				return;
			}
			
			if (operandB <= 0) 
			{
				lastError = ErrorID.DIVIDE_BY_ZERO;
				processingError = true;
				return;
			}
			
			vram[dp] = vram[operandA] / vram[operandB];
		}
		
		private function Shl():void 
		{
			var addressForOperandA:Number = VRAM_USER + 1 + ip;
			
			if (addressForOperandA >= VRAM_SIZE)
			{
				lastError = ErrorID.OUT_OF_MEMORY;
				processingError = true;
				return;
			}
			
			var operandA:Number = vram[addressForOperandA];
			
			vram[dp] = (vram[dp] << operandA);
		}
		
		private function Shr():void 
		{
			var addressForOperandA:Number = VRAM_USER + 1 + ip;
			
			if (addressForOperandA >= VRAM_SIZE)
			{
				lastError = ErrorID.OUT_OF_MEMORY;
				processingError = true;
				return;
			}
			
			var operandA:Number = vram[addressForOperandA];
			
			vram[dp] = (vram[dp] >> operandA);
		}
		
		private function Mod():void 
		{
			var addressForOperandA:Number = VRAM_USER + 1 + ip;
			
			if (addressForOperandA >= VRAM_SIZE)
			{
				lastError = ErrorID.OUT_OF_MEMORY;
				processingError = true;
				return;
			}
			
			var operandA:Number = vram[addressForOperandA];
			
			if (operandA <= 0)
			{
				lastError = ErrorID.DIVIDE_BY_ZERO;
				processingError = true;
				return;
			}
			
			vram[dp] = (vram[dp] % operandA);
		}
		
		private function Sqrt():void 
		{
			var addressForOperandA:Number = VRAM_USER + 1 + ip;
			
			if (addressForOperandA >= VRAM_SIZE)
			{
				lastError = ErrorID.OUT_OF_MEMORY;
				processingError = true;
				return;
			}
			
			var operandA:Number = vram[addressForOperandA];
			
			vram[dp] = Math.sqrt(operandA);
		}
		
		private function Sin():void 
		{
			var addressForOperandA:Number = VRAM_USER + 1 + ip;
			
			if (addressForOperandA >= VRAM_SIZE)
			{
				lastError = ErrorID.OUT_OF_MEMORY;
				processingError = true;
				return;
			}
			
			var operandA:Number = vram[addressForOperandA];
			
			vram[dp] = Math.sin(operandA);
		}
		
		private function Cos():void 
		{
			var addressForOperandA:Number = VRAM_USER + 1 + ip;
			
			if (addressForOperandA >= VRAM_SIZE)
			{
				lastError = ErrorID.OUT_OF_MEMORY;
				processingError = true;
				return;
			}
			
			var operandA:Number = vram[addressForOperandA];
			
			vram[dp] = Math.cos(operandA);
		}
		
		private function Tan():void 
		{
			var addressForOperandA:Number = VRAM_USER + 1 + ip;
			
			if (addressForOperandA >= VRAM_SIZE)
			{
				lastError = ErrorID.OUT_OF_MEMORY;
				processingError = true;
				return;
			}
			
			var operandA:Number = vram[addressForOperandA];
			
			vram[dp] = Math.tan(operandA);
		}
		
		private function Acos():void 
		{
			var addressForOperandA:Number = VRAM_USER + 1 + ip;
			
			if (addressForOperandA >= VRAM_SIZE)
			{
				lastError = ErrorID.OUT_OF_MEMORY;
				processingError = true;
				return;
			}
			
			var operandA:Number = vram[addressForOperandA];
			
			vram[dp] = Math.acos(operandA);
		}
		
		private function Asin():void 
		{
			var addressForOperandA:Number = VRAM_USER + 1 + ip;
			
			if (addressForOperandA >= VRAM_SIZE)
			{
				lastError = ErrorID.OUT_OF_MEMORY;
				processingError = true;
				return;
			}
			
			var operandA:Number = vram[addressForOperandA];
			
			vram[dp] = Math.asin(operandA);
		}
		
		private function Atan():void 
		{
			var addressForOperandA:Number = VRAM_USER + 1 + ip;
			
			if (addressForOperandA >= VRAM_SIZE)
			{
				lastError = ErrorID.OUT_OF_MEMORY;
				processingError = true;
				return;
			}
			
			var operandA:Number = vram[addressForOperandA];
			
			vram[dp] = Math.atan(operandA);
		}
		
		private function Pow():void 
		{
			var addressForOperandA:Number = VRAM_USER + 1 + ip;
			
			if (addressForOperandA >= VRAM_SIZE)
			{
				lastError = ErrorID.OUT_OF_MEMORY;
				processingError = true;
				return;
			}
			
			var operandA:Number = vram[addressForOperandA];
			
			vram[dp] = Math.pow(vram[dp], operandA);
		}

		private function Print():void 
		{
			if (printerMode == PrinterMode.CHARACTER)
			{
				OutputCharacter(String.fromCharCode(vram[dp]));
			}
			else
			{
				OutputInteger(vram[dp]);
			}
		}
		
		private function SetPrint():void 
		{
			var addressForOperandA:Number = VRAM_USER + 1 + ip;
			
			if (addressForOperandA >= VRAM_SIZE)
			{
				lastError = ErrorID.OUT_OF_MEMORY;
				processingError = true;
				return;
			}
			
			var operandA:Number = vram[addressForOperandA];
			
			if (operandA >= PrinterMode.INVALID)
			{
				lastError = ErrorID.BAD_PRINT_MODE;
				processingError = true;
				return;
			}
			
			printerMode = operandA;
		}

		private function Jmp():void 
		{
			var addressForOperandA:Number = VRAM_USER + 1 + ip;
			
			if (addressForOperandA >= VRAM_SIZE)
			{
				lastError = ErrorID.OUT_OF_MEMORY;
				processingError = true;
				return;
			}
			
			var operandA:Number = vram[addressForOperandA];
			
			if (operandA >= VRAM_SIZE)
			{
				lastError = ErrorID.OUT_OF_MEMORY;
				processingError = true;
				return;
			}
			
			ip = operandA;
			jumped = true;
		}
		
		private function End():void 
		{
			processing = false;
		}

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

		private function SysCall():void 
		{
			
		}

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