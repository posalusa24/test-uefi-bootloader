
iterate <instr,prefix,ext,postbyte>, vmxon,0F3h,0C7h,6, vmclear,66h,0C7h,6,  \
				 vmptrld,0,0C7h,6, vmptrst,0,0C7h,7

	macro instr? src*
		require VMX
		x86.parse_operand@src src
		if @src.type = 'mem'
			if @src.size and not 8
				err 'invalid operand size'
			else
				@src.opcode_prefix = prefix
				x86.store_instruction@src <0Fh,ext>,postbyte
			end if
		else
			err 'invalid operand'
		end if
	end macro

end iterate

macro vmxoff?
	require VMX
	db 0Fh,1,0C4h
end macro

macro vmcall?
	require VMX
	db 0Fh,1,0C1h
end macro

macro vmlaunch?
	require VMX
	db 0Fh,1,0C2h
end macro

macro vmresume?
	require VMX
	db 0Fh,1,0C3h
end macro

macro vmread? dest*,src*
	require VMX
	x86.parse_operand@dest dest
	x86.parse_operand@src src
	if @src.type = 'reg' & (@dest.type = 'mem' | @dest.type = 'reg')
		if (x86.mode < 64 & @src.size <> 4) | (x86.mode = 64 & @src.size <> 8)
			err 'invalid operand size'
		else if @dest.size and not @src.size
			err 'operand sizes do not match'
		end if
		x86.store_instruction@dest <0Fh,78h>,@src.rm
	else
		err 'invalid combination of operands'
	end if
end macro

macro vmwrite? dest*,src*
	require VMX
	x86.parse_operand@dest dest
	x86.parse_operand@src src
	if @dest.type = 'reg' & (@src.type = 'mem' | @src.type = 'reg')
		if (x86.mode < 64 & @dest.size <> 4) | (x86.mode = 64 & @dest.size <> 8)
			err 'invalid operand size'
		else if @src.size and not @dest.size
			err 'operand sizes do not match'
		end if
		x86.store_instruction@src <0Fh,79h>,@dest.rm
	else
		err 'invalid combination of operands'
	end if
end macro
