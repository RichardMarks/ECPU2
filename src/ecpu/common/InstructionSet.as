package ecpu.common 
{
	/**
	 * ...
	 * @author Richard Marks
	 */
	public class InstructionSet 
	{
		// misc
		static public const INS_NOP:Number = 0;
		static public const INS_RESET:Number = 1;
		static public const INS_RAND:Number = 2;
		
		// data manipulation
		static public const INS_INC:Number = 3;
		static public const INS_DEC:Number = 4;
		static public const INS_VAR:Number = 5;
		static public const INS_SET:Number = 6;
		static public const INS_COPY:Number = 7;
		static public const INS_ADV:Number = 8;
		
		// mathematics
		static public const INS_ADD:Number = 9;
		static public const INS_SUB:Number = 10;
		static public const INS_MUL:Number = 11;
		static public const INS_DIV:Number = 12;
		static public const INS_SHL:Number = 13;
		static public const INS_SHR:Number = 14;
		static public const INS_MOD:Number = 15;
		static public const INS_SQRT:Number = 16;
		static public const INS_SIN:Number = 17;
		static public const INS_COS:Number = 18;
		static public const INS_TAN:Number = 19;
		static public const INS_ACOS:Number = 20;
		static public const INS_ASIN:Number = 21;
		static public const INS_ATAN:Number = 22;
		static public const INS_POW:Number = 23;
		
		// output
		static public const INS_PRINT:Number = 24;
		static public const INS_SETPRINT:Number = 25;
		
		// logic
		static public const INS_JMP:Number = 26;
		static public const INS_END:Number = 27;
		static public const INS_CMP:Number = 28;
		static public const INS_TST:Number = 29;
		static public const INS_JE:Number = 30;
		static public const INS_JNE:Number = 31;
		static public const INS_JL:Number = 32;
		static public const INS_JG:Number = 33;
		static public const INS_JLE:Number = 34;
		static public const INS_JGE:Number = 35;
		static public const INS_JZ:Number = 36;
		static public const INS_JNZ:Number = 37;
		
		// stack
		static public const INS_PUSH:Number = 38;
		static public const INS_POP:Number = 39;
		static public const INS_POPALL:Number = 40;
		
		// bios
		// SYSCALL N - call a bios routine (see BIOS routine table for valid values of N)
		static public const INS_SYSCALL:Number = 41;
		
		// not an instruction - used for handling unsupported opcodes
		static public const INS_INVALID:Number = 9999;
	}
}