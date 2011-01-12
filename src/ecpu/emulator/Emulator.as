package ecpu.emulator 
{
	import ecpu.common.CmpResult;
	import ecpu.common.ErrorID;
	import ecpu.common.InstructionSet;
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
		private var lastCmp:Number;

		/// the result of the last tst operation
		private var lastTst:Number;

		/// what mode is the stdout printer in
		private var printerMode:Number;

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
			
			processing = true;
			
			var instructions:Number = 0;
			
			while((VRAM_SIZE > (VRAM_USER + ip)) && processing)
			{
				if (processing)
				{
					if (!ProcessInstruction())
					{
						processing = false;
					}
					instructions++;
				}
			}
			
			if (!processingError)
			{
				trace("FINISHED: [", instructions, " instructions processed]");
			}
			else
			{
				trace("FINISHED WITH ERRORS: [", instructions, " instructions processed]");
				trace("Last Error: ", lastError);
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
			stdout = "";
		}
		
		/// processes the current instruction - returns false on error
		private function ProcessInstruction():Boolean 
		{
			if (VRAM_USER + ip >= VRAM_SIZE)
			{
				lastError = ErrorID.INSTRUCTION_POINTER_IS_PAST_END_OF_MEMORY;
				processingError = true;
				return false;
			}
			
			var instruction:Number = vram[VRAM_USER + ip];
			
			if (instruction >= InstructionSet.INS_INVALID)
			{
				lastError = ErrorID.INVALID_INSTRUCTION;
				processingError = true;
				return false;
			}
			
			switch(instruction)
			{
				// misc
				case InstructionSet.INS_NOP: 	{ Nop(); } break;
				case InstructionSet.INS_RESET: 	{ Reset(); } break;
				case InstructionSet.INS_RAND: 	{ Rand(); Skip(2); } break;
				
				// data manip
				case InstructionSet.INS_INC: 		{ Inc(); Skip(); } break;
				case InstructionSet.INS_DEC: 		{ Dec(); Skip(); } break;
				case InstructionSet.INS_VAR: 		{ Var(); Skip(); } break;
				case InstructionSet.INS_SET: 		{ Set(); Skip(); } break;
				case InstructionSet.INS_COPY: 		{ Copy();Skip(2); } break;
				case InstructionSet.INS_ADV:		{ Adv(); Skip(); } break;
				
				// math
				case InstructionSet.INS_ADD: 		{ Add(); Skip(2); } break;
				case InstructionSet.INS_SUB: 		{ Sub(); Skip(2); } break;
				case InstructionSet.INS_MUL: 		{ Mul(); Skip(2); } break;
				case InstructionSet.INS_DIV: 		{ Div(); Skip(2); } break;
				case InstructionSet.INS_SHL: 		{ Shl(); Skip(); } break;
				case InstructionSet.INS_SHR: 		{ Shr(); Skip(); } break;
				case InstructionSet.INS_MOD: 		{ Mod(); Skip(); } break;
				case InstructionSet.INS_SQRT: 		{ Sqrt(); Skip(); } break;
				case InstructionSet.INS_SIN: 		{ Sin(); Skip(); } break;
				case InstructionSet.INS_COS: 		{ Cos(); Skip(); } break;
				case InstructionSet.INS_TAN: 		{ Tan(); Skip(); } break;
				case InstructionSet.INS_ACOS: 		{ Acos(); Skip(); } break;
				case InstructionSet.INS_ASIN: 		{ Asin(); Skip(); } break;
				case InstructionSet.INS_ATAN: 		{ Atan(); Skip(); } break;
				case InstructionSet.INS_POW: 		{ Pow(); Skip(); } break;
				
				// output
				case InstructionSet.INS_PRINT:		{ Print(); } break;
				case InstructionSet.INS_SETPRINT:	{ SetPrint(); Skip(); } break;
				
				// logic
				case InstructionSet.INS_JMP: 		{ Jmp(); 		if (!jumped) { Skip(); } jumped = false; } break;
				case InstructionSet.INS_END: 		{ End(); 		} break;
				case InstructionSet.INS_CMP: 		{ Cmp(); 		Skip(2); } break;
				case InstructionSet.INS_TST: 		{ Tst(); 		Skip(); } break;
				case InstructionSet.INS_JE: 		{ Je(); 		if (!jumped) { Skip(); } jumped = false; } break;
				case InstructionSet.INS_JNE: 		{ Jne(); 		if (!jumped) { Skip(); } jumped = false; } break;
				case InstructionSet.INS_JL: 		{ Jl(); 		if (!jumped) { Skip(); } jumped = false; } break;
				case InstructionSet.INS_JG: 		{ Jg(); 		if (!jumped) { Skip(); } jumped = false; } break;
				case InstructionSet.INS_JLE: 		{ Jle(); 		if (!jumped) { Skip(); } jumped = false; } break;
				case InstructionSet.INS_JGE: 		{ Jge(); 		if (!jumped) { Skip(); } jumped = false; } break;
				case InstructionSet.INS_JZ: 		{ Jz(); 		if (!jumped) { Skip(); } jumped = false; } break;
				case InstructionSet.INS_JNZ: 		{ Jnz(); 		if (!jumped) { Skip(); } jumped = false; } break;
				
				default: break;
			}
			
			++ip;
			if (VRAM_USER + ip >= VRAM_SIZE)
			{
				lastError = ErrorID.INSTRUCTION_STREAM_ENDED_PREMATURELY;
				processingError = true;
				return false;
			}
			
			return true;
		}

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

		private function Cmp():void 
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
			
			operandA = vram[operandA];
			operandB = vram[operandB];
			
			lastCmp = CmpResult.INVALID;
			
			if (operandA == operandB)
			{
				lastCmp = CmpResult.EQUAL;
			}
			else
			{
				lastCmp = CmpResult.NOTEQUAL;
			}
			
			if (operandA < operandB)
			{
				lastCmp |= CmpResult.LESS;
			}
			else if (operandA > operandB)
			{
				lastCmp |= CmpResult.GREATER;
			}
		}
		
		private function Tst():void 
		{
			var addressForOperandA:Number = VRAM_USER + 1 + ip;
			
			if (addressForOperandA >= VRAM_SIZE)
			{
				lastError = ErrorID.OUT_OF_MEMORY;
				processingError = true;
				return;
			}
			
			var operandA:Number = vram[addressForOperandA];
			
			lastTst = (operandA == 0)? TstResult.ZERO : TstResult.NOTZERO;
		}
		
		private function Je():void 
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
			
			if (lastCmp & CmpResult.EQUAL)
			{
				ip = operandA;
				jumped = true;
			}
		}
		
		private function Jne():void 
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
			
			if (lastCmp & CmpResult.NOTEQUAL)
			{
				ip = operandA;
				jumped = true;
			}
		}
		
		private function Jl():void 
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
			
			if (lastCmp & CmpResult.LESS)
			{
				ip = operandA;
				jumped = true;
			}
		}
		
		private function Jg():void 
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
			
			if (lastCmp & CmpResult.GREATER)
			{
				ip = operandA;
				jumped = true;
			}
		}
		
		private function Jle():void 
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
			
			if ((lastCmp & CmpResult.LESS) || (lastCmp & CmpResult.EQUAL))
			{
				ip = operandA;
				jumped = true;
			}
		}
		
		private function Jge():void 
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
			
			if ((lastCmp & CmpResult.GREATER) || (lastCmp & CmpResult.EQUAL))
			{
				ip = operandA;
				jumped = true;
			}
		}
		
		private function Jz():void 
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
			
			if (lastTst == TstResult.ZERO)
			{
				ip = operandA;
				jumped = true;
			}
		}
		
		private function Jnz():void 
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
			
			if (lastTst == TstResult.NOTZERO)
			{
				ip = operandA;
				jumped = true;
			}
		}

		private function Push():void 
		{
			// check if we have space to grow the stack
			// the stack grows in reverse from the end of free memory to the start of vram
			// the stack will overwrite anything you have stored in memory if
			// it happens to grow that large!
			
			if (sp - 1 < 0)
			{
				processingError = true;
				lastError = ErrorID.OUT_OF_STACK_SPACE;
				return;
			}
			
			// get the value to be pushed (operand)
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
			
			// copy the value to vram and reduce the stack pointer (grow the stack)
			vram[sp] = vram[operandA];
			sp--;
		}
		
		private function Pop():void 
		{
			// check if there is anything to pop
			if (VRAM_STACK == sp)
			{
				lastError = ErrorID.STACK_EMPTY;
				processingError = true;
				return;
			}
			
			// get the address to pop into
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
			
			// copy the value from stack to vram at the desired address
			// and increase the stack pointer (shrink the stack)
			vram[operandA] = vram[sp];
			sp++;
		}
		
		private function Popall():void 
		{
			// check if there is anything to pop
			if (VRAM_STACK == sp)
			{
				lastError = ErrorID.STACK_EMPTY;
				processingError = true;
				return;
			}

			// get the address to pop into
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
			
			var stackSize:Number = Math.abs(VRAM_STACK - sp);
			
			if (operandA + stackSize >= VRAM_SIZE)
			{
				lastError = ErrorID.OUT_OF_MEMORY;
				processingError = true;
				return;
			}
			
			// loop over the stack
			var offset:Number = 0;
			for (var address:Number = sp; address < VRAM_STACK; address++)
			{
				// copy the value from stack to vram at the desired address
				// and increase the stack pointer (shrink the stack)
				vram[operandA + offset] = vram[address];
				offset++;
				sp++;
			}
		}

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