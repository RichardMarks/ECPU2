package ecpu.assembler 
{
	import ecpu.common.ErrorCache;
	import ecpu.common.InstructionSet;
	import flash.utils.ByteArray;
	import net.flashpunk.FP;
	/**
	 * ...
	 * @author Richard Marks
	 */
	public class Assembler 
	{
		private var code:Vector.<Number>;
		private var codeSize:Number;
		private var assembling:Boolean;
		private var assemblingError:Boolean;
		private var assemblingErrors:ErrorCache;
		
		public function get MachineCode():Vector.<Number> { return code; }
		public function get CodeSize():Number { if (code == null) { return 0; } return code.length; }
		
		public function Assembler() {}
		
		static private function LTrim(s:String):String
		{
			var size:Number = s.length;
			for (var i:Number = 0; i < size; i++)
			{
				if (s.charCodeAt(i) > 32)
				{
					return s.substring(i);
				}
			}
			return "";
		}
		
		private function StripCommentsAndEmptyLines(lines:Vector.<String>):Vector.<String>
		{
			var temp:Vector.<String> = new Vector.<String>();
			for (var i:Number = 0; i < lines.length; i++)
			{
				var line:String = LTrim(lines[i]);
				
				if (line.length > 0)
				{
					if (line.substring(0, 1) != ";")
					{
						var commentPos:Number = line.indexOf(";", 2);
						if (commentPos > 0)
						{
							line = line.substring(0, commentPos);
						}
						temp.push(line);
					}
				}
			}
			return temp;
		}
		
		public function Assemble(source:String):void
		{
			code = new Vector.<Number>();
			codeSize = 0;
			assembling = true;
			assemblingError = false;
			assemblingErrors = new ErrorCache;
			
			var splitSource:Array = source.split("\r");
			trace(splitSource.length);
			var lines:Vector.<String> = Vector.<String>(splitSource);
			lines = StripCommentsAndEmptyLines(lines);
			
			var assembled:Number = 0;
			var sourceSize:Number = Number(lines.length);
			var line:Number = 0;
			
			var codeStream:Vector.<Number> = new Vector.<Number>();
			
			while (assembling)
			{
				if (assembling)
				{
					if (line >= sourceSize)
					{
						assembling = false;
					}
					else
					{
						var lineRead:Number = line + 1;
						trace("Assembling:#0x", lineRead.toString(16).toUpperCase(), ":", lines[line]);
						
						var tokens:Vector.<String> = Vector.<String>(lines[line].split(" "));
						var numTokens:Number = tokens.length;
						var instruction:String = tokens[0].toLowerCase();
						
						if ("nop" == instruction)
						{
							codeStream.push(InstructionSet.INS_NOP);
							assembled++;
						}
						else if ("inc" == instruction)
						{
							if (numTokens < 2)
							{
								assemblingErrors.Write("Missing required argument.");
								assemblingError = true;
							}
							codeStream.push(InstructionSet.INS_INC);
							codeStream.push(Number(tokens[1]));
							//fprintf(stderr, "{INC 0x%04X}", operanda);
							assembled++;
						}
						else if ("dec" == instruction)
						{
							if (numTokens < 2)
							{
								assemblingErrors.Write("Missing required argument.");
								assemblingError = true;
							}
							codeStream.push(InstructionSet.INS_DEC);
							codeStream.push(Number(tokens[1]));
							assembled++;
						}
						else if ("adv" == instruction)
						{
							if (numTokens < 2)
							{
								assemblingErrors.Write("Missing required argument.");
								assemblingError = true;
							}
							codeStream.push(InstructionSet.INS_ADV);
							codeStream.push(Number(tokens[1]));
							assembled++;
						}
						else if ("print" == instruction)
						{
							codeStream.push(InstructionSet.INS_PRINT);
							assembled++;
						}
						else if ("setprint" == instruction)
						{
							if (numTokens < 2)
							{
								assemblingErrors.Write("Missing required argument.");
								assemblingError = true;
							}
							codeStream.push(InstructionSet.INS_SETPRINT);
							codeStream.push(Number(tokens[1]));
							assembled++;
						}
						else if ("jmp" == instruction)
						{
							if (numTokens < 2)
							{
								assemblingErrors.Write("Missing required argument.");
								assemblingError = true;
							}
							codeStream.push(InstructionSet.INS_JMP);
							codeStream.push(Number(tokens[1]));
							assembled++;
						}
						else if ("end" == instruction)
						{
							codeStream.push(InstructionSet.INS_END);
							assembled++;
						}
						else if ("reset" == instruction)
						{
							codeStream.push(InstructionSet.INS_RESET);
							assembled++;
						}
						else if ("cmp" == instruction)
						{
							if (numTokens < 3)
							{
								assemblingErrors.Write("Missing required argument.");
								assemblingError = true;
							}
							codeStream.push(InstructionSet.INS_CMP);
							codeStream.push(Number(tokens[1]));
							codeStream.push(Number(tokens[2]));
							assembled++;
						}
						else if ("rand" == instruction)
						{
							if (numTokens < 3)
							{
								assemblingErrors.Write("Missing required argument.");
								assemblingError = true;
							}
							codeStream.push(InstructionSet.INS_RAND);
							codeStream.push(Number(tokens[1]));
							codeStream.push(Number(tokens[2]));
							assembled++;
						}

						// math
						else if ("add" == instruction)
						{
							if (numTokens < 3)
							{
								assemblingErrors.Write("Missing required argument.");
								assemblingError = true;
							}
							codeStream.push(InstructionSet.INS_ADD);
							codeStream.push(Number(tokens[1]));
							codeStream.push(Number(tokens[2]));
							assembled++;
						}
						else if ("sub" == instruction)
						{
							if (numTokens < 3)
							{
								assemblingErrors.Write("Missing required argument.");
								assemblingError = true;
							}
							codeStream.push(InstructionSet.INS_SUB);
							codeStream.push(Number(tokens[1]));
							codeStream.push(Number(tokens[2]));
							assembled++;
						}
						else if ("mul" == instruction)
						{
							if (numTokens < 3)
							{
								assemblingErrors.Write("Missing required argument.");
								assemblingError = true;
							}
							codeStream.push(InstructionSet.INS_MUL);
							codeStream.push(Number(tokens[1]));
							codeStream.push(Number(tokens[2]));
							assembled++;
						}
						else if ("div" == instruction)
						{
							if (numTokens < 3)
							{
								assemblingErrors.Write("Missing required argument.");
								assemblingError = true;
							}
							codeStream.push(InstructionSet.INS_DIV);
							codeStream.push(Number(tokens[1]));
							codeStream.push(Number(tokens[2]));
							assembled++;
						}

						else if ("shl" == instruction)
						{
							if (numTokens < 2)
							{
								assemblingErrors.Write("Missing required argument.");
								assemblingError = true;
							}
							codeStream.push(InstructionSet.INS_SHL);
							codeStream.push(Number(tokens[1]));
							assembled++;
						}
						else if ("shr" == instruction)
						{
							if (numTokens < 2)
							{
								assemblingErrors.Write("Missing required argument.");
								assemblingError = true;
							}
							codeStream.push(InstructionSet.INS_SHR);
							codeStream.push(Number(tokens[1]));
							assembled++;
						}
						else if ("mod" == instruction)
						{
							if (numTokens < 2)
							{
								assemblingErrors.Write("Missing required argument.");
								assemblingError = true;
							}
							codeStream.push(InstructionSet.INS_MOD);
							codeStream.push(Number(tokens[1]));
							assembled++;
						}
						else if ("sqrt" == instruction)
						{
							if (numTokens < 2)
							{
								assemblingErrors.Write("Missing required argument.");
								assemblingError = true;
							}
							codeStream.push(InstructionSet.INS_SQRT);
							codeStream.push(Number(tokens[1]));
							assembled++;
						}
						else if ("sin" == instruction)
						{
							if (numTokens < 2)
							{
								assemblingErrors.Write("Missing required argument.");
								assemblingError = true;
							}
							codeStream.push(InstructionSet.INS_SIN);
							codeStream.push(Number(tokens[1]));
							assembled++;
						}
						else if ("cos" == instruction)
						{
							if (numTokens < 2)
							{
								assemblingErrors.Write("Missing required argument.");
								assemblingError = true;
							}
							codeStream.push(InstructionSet.INS_COS);
							codeStream.push(Number(tokens[1]));
							assembled++;
						}
						else if ("tan" == instruction)
						{
							if (numTokens < 2)
							{
								assemblingErrors.Write("Missing required argument.");
								assemblingError = true;
							}
							codeStream.push(InstructionSet.INS_TAN);
							codeStream.push(Number(tokens[1]));
							assembled++;
						}
						else if ("acos" == instruction)
						{
							if (numTokens < 2)
							{
								assemblingErrors.Write("Missing required argument.");
								assemblingError = true;
							}
							codeStream.push(InstructionSet.INS_ACOS);
							codeStream.push(Number(tokens[1]));
							assembled++;
						}
						else if ("asin" == instruction)
						{
							if (numTokens < 2)
							{
								assemblingErrors.Write("Missing required argument.");
								assemblingError = true;
							}
							codeStream.push(InstructionSet.INS_ASIN);
							codeStream.push(Number(tokens[1]));
							assembled++;
						}
						else if ("atan" == instruction)
						{
							if (numTokens < 2)
							{
								assemblingErrors.Write("Missing required argument.");
								assemblingError = true;
							}
							codeStream.push(InstructionSet.INS_ATAN);
							codeStream.push(Number(tokens[1]));
							assembled++;
						}
						else if ("pow" == instruction)
						{
							if (numTokens < 2)
							{
								assemblingErrors.Write("Missing required argument.");
								assemblingError = true;
							}
							codeStream.push(InstructionSet.INS_POW);
							codeStream.push(Number(tokens[1]));
							assembled++;
						}
						//

						else if ("tst" == instruction)
						{
							if (numTokens < 2)
							{
								assemblingErrors.Write("Missing required argument.");
								assemblingError = true;
							}
							codeStream.push(InstructionSet.INS_TST);
							codeStream.push(Number(tokens[1]));
							assembled++;
						}
						else if ("je" == instruction)
						{
							if (numTokens < 2)
							{
								assemblingErrors.Write("Missing required argument.");
								assemblingError = true;
							}
							codeStream.push(InstructionSet.INS_JE);
							codeStream.push(Number(tokens[1]));
							assembled++;
						}
						else if ("jne" == instruction)
						{
							if (numTokens < 2)
							{
								assemblingErrors.Write("Missing required argument.");
								assemblingError = true;
							}
							codeStream.push(InstructionSet.INS_JNE);
							codeStream.push(Number(tokens[1]));
							assembled++;
						}
						else if ("jl" == instruction)
						{
							if (numTokens < 2)
							{
								assemblingErrors.Write("Missing required argument.");
								assemblingError = true;
							}
							codeStream.push(InstructionSet.INS_JL);
							codeStream.push(Number(tokens[1]));
							assembled++;
						}
						else if ("jg" == instruction)
						{
							if (numTokens < 2)
							{
								assemblingErrors.Write("Missing required argument.");
								assemblingError = true;
							}
							codeStream.push(InstructionSet.INS_JG);
							codeStream.push(Number(tokens[1]));
							assembled++;
						}
						else if ("jle" == instruction)
						{
							if (numTokens < 2)
							{
								assemblingErrors.Write("Missing required argument.");
								assemblingError = true;
							}
							codeStream.push(InstructionSet.INS_JLE);
							codeStream.push(Number(tokens[1]));
							assembled++;
						}
						else if ("jge" == instruction)
						{
							if (numTokens < 2)
							{
								assemblingErrors.Write("Missing required argument.");
								assemblingError = true;
							}
							codeStream.push(InstructionSet.INS_JGE);
							codeStream.push(Number(tokens[1]));
							assembled++;
						}
						else if ("jz" == instruction)
						{
							if (numTokens < 2)
							{
								assemblingErrors.Write("Missing required argument.");
								assemblingError = true;
							}
							codeStream.push(InstructionSet.INS_JZ);
							codeStream.push(Number(tokens[1]));
							assembled++;
						}
						else if ("jnz" == instruction)
						{
							if (numTokens < 2)
							{
								assemblingErrors.Write("Missing required argument.");
								assemblingError = true;
							}
							codeStream.push(InstructionSet.INS_JNZ);
							codeStream.push(Number(tokens[1]));
							assembled++;
						}
						else if ("var" == instruction)
						{
							if (numTokens < 2)
							{
								assemblingErrors.Write("Missing required argument.");
								assemblingError = true;
							}
							codeStream.push(InstructionSet.INS_VAR);
							codeStream.push(Number(tokens[1]));
							assembled++;
						}
						else if ("set" == instruction)
						{
							if (numTokens < 2)
							{
								assemblingErrors.Write("Missing required argument.");
								assemblingError = true;
							}
							codeStream.push(InstructionSet.INS_SET);
							codeStream.push(Number(tokens[1]));
							assembled++;
						}
						else if ("copy" == instruction)
						{
							if (numTokens < 3)
							{
								assemblingErrors.Write("Missing required argument.");
								assemblingError = true;
							}
							codeStream.push(InstructionSet.INS_COPY);
							codeStream.push(Number(tokens[1]));
							codeStream.push(Number(tokens[2]));
							assembled++;
						}
						else if ("push" == instruction)
						{
							if (numTokens < 2)
							{
								assemblingErrors.Write("Missing required argument.");
								assemblingError = true;
							}
							codeStream.push(InstructionSet.INS_PUSH);
							codeStream.push(Number(tokens[1]));
							assembled++;
						}
						else if ("pop" == instruction)
						{
							if (numTokens < 2)
							{
								assemblingErrors.Write("Missing required argument.");
								assemblingError = true;
							}
							codeStream.push(InstructionSet.INS_POP);
							codeStream.push(Number(tokens[1]));
							assembled++;
						}
						else if ("popall" == instruction)
						{
							if (numTokens < 2)
							{
								assemblingErrors.Write("Missing required argument.");
								assemblingError = true;
							}
							codeStream.push(InstructionSet.INS_POPALL);
							codeStream.push(Number(tokens[1]));
							assembled++;
						}
						else if ("sys" == instruction)
						{
							if (numTokens < 2)
							{
								assemblingErrors.Write("Missing required argument.");
								assemblingError = true;
							}
							codeStream.push(InstructionSet.INS_SYSCALL);
							codeStream.push(Number(tokens[1]));
							assembled++;
						}
						else
						{
							assemblingErrors.Write("Unknown Token: " + instruction);
							//fprintf(stderr, "\nUnknown Token: %s\n", instruction.c_str());
							assemblingError = true;
							codeStream.push(InstructionSet.INS_INVALID);
							assembled++;
						}
						line++;
					}
				}
			}
			
			if (assemblingError)
			{
				var errorCount:Number = assemblingErrors.Rewind();
				trace("There were", errorCount, "Errors: ");
				for (var errorNum:Number = 0; errorNum < errorCount; errorNum++)
				{
					trace(assemblingErrors.Next());
				}
			}
			
			codeSize = Number(codeStream.length);
			code = new Vector.<Number>(codeSize);
			for (var i:Number = 0; i < codeSize; i++)
			{
				code[i] = Number(codeStream[i]);
			}
			
			trace("Assembled", sourceSize, "lines into", assembled, "instructions and", codeSize, "bytes.");
			//trace(code);
		}
		
		public function WriteBinary(filename:String):Boolean 
		{ 
			return false;
		}
		
		public function InfoBinary(filename:String):Boolean 
		{ 
			return false;
		}
		
	}
}