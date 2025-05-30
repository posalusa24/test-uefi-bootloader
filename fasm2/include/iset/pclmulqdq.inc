
macro pclmulqdq? dest*,src*,imm*
	require PCLMULQDQ
	SSE.basic_instruction_imm8 66h,<3Ah,44h>,16,dest,src,imm
end macro

macro vpclmulqdq? dest*,src*,src2*,aux*
	require VPCLMULQDQ
	AVX_512.parse_operand@dest dest
	AVX_512.parse_operand@src src
	AVX_512.parse_operand@src2 src2
	x86.parse_operand@aux aux
	if @dest.type = 'mmreg' & @src.type = 'mmreg' & (@src2.type = 'mem' | @src2.type = 'mmreg') & @aux.type = 'imm'
		if @aux.size and not 1
			err 'invalid operand size'
		else if @dest.size <> @src.size | @src2.size and not @dest.size
			err 'operand sizes do not match'
		end if
		@src2.memsize = 0
		AVX_512.store_instruction@src2 @dest.size,VEX_66_0F3A_W0,EVEX_AS_VEX+EVEX_VL,44h,@dest.mask,@dest.rm,@src.rm,1,@aux.imm
	else
		err 'invalid combination of operands'
	end if
end macro
