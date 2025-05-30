
element SSE.reg

repeat 16, i:0
	element xmm#i? : SSE.reg + i
end repeat

iterate context, @dest,@src,@src2,@aux

	namespace context

		calminstruction SSE.parse_operand#context operand

			call	x86.parse_operand#context, operand

			check	type = 'imm' & size = 0
			jno	done
			check	imm eq 1 elementof imm & 1 metadataof imm relativeto MMX.reg
			jyes	mm_register
			check	imm eq 1 elementof imm & 1 metadataof imm relativeto SSE.reg
			jyes	xmm_register
			exit

		    mm_register:

			compute rm, 1 metadataof imm - MMX.reg
			compute size, 8

			jump	export_mmreg

		    xmm_register:

			compute rm, 1 metadataof imm - SSE.reg
			compute size, 16

		    export_mmreg:

			compute type, 'mmreg'
			compute mod, 11b

		    done:

		end calminstruction

	end namespace

end iterate

calminstruction SSE.basic_instruction pre,ext,msize,dest,src
	call	x86.require.SSE
	call	SSE.parse_operand@dest, dest
	call	SSE.parse_operand@src,	src
	check	@dest.type = 'mmreg' & (@src.type = 'mem' | @src.type = 'mmreg')
	jno	invalid_combination_of_operands
	check	@dest.size <> 16 | (@src.type = 'mem' & @src.size and not msize) | (@src.type = 'mmreg' & @src.size <> 16)
	jno	size_ok
	err	'invalid operand size'
    size_ok:
	compute @src.opcode_prefix, pre
	xcall	x86.store_instruction@src, <0Fh,ext>,@dest.rm
	exit
    invalid_combination_of_operands:
	err	'invalid combination of operands'
end calminstruction

calminstruction SSE.basic_instruction_imm8 pre,ext,msize,dest,src,aux
	call	x86.require.SSE
	call	SSE.parse_operand@dest, dest
	call	SSE.parse_operand@src,	src
	call	x86.parse_operand@aux, aux
	check	@dest.type = 'mmreg' & (@src.type = 'mem' | @src.type = 'mmreg') & @aux.type = 'imm'
	jno	invalid_combination_of_operands
	check	@dest.size <> 16 | (@src.type = 'mem' & @src.size and not msize) | (@src.type = 'mmreg' & @src.size <> 16) | @aux.size and not 1
	jno	size_ok
	err	'invalid operand size'
    size_ok:
	compute @src.opcode_prefix, pre
	xcall	x86.store_instruction@src, <0Fh,ext>,@dest.rm,byte,@aux.imm
	exit
    invalid_combination_of_operands:
	err	'invalid combination of operands'
end calminstruction

iterate <instr,ext>, sqrt,51h, rsqrt,52h, rcp,53h, add,58h, mul,59h, sub,5Ch, min,5Dh, div,5Eh, max,5Fh
	macro instr#ps? dest*,src*
		SSE.basic_instruction 0,ext,16,dest,src
	end macro
	macro instr#ss? dest*,src*
		SSE.basic_instruction 0F3h,ext,4,dest,src
	end macro
end iterate

iterate <instr,ext>, and,54h, andn,55h, or,56h, xor,57h, unpckl,14h, unpckh,15h
	macro instr#ps? dest*,src*
		SSE.basic_instruction 0,ext,16,dest,src
	end macro
end iterate

macro cmpps? dest*,src*,code*
	SSE.basic_instruction_imm8 0,0C2h,16,dest,src,code
end macro

macro cmpss? dest*,src*,code*
	SSE.basic_instruction_imm8 0F3h,0C2h,4,dest,src,code
end macro

iterate <cond,code>, eq,0, lt,1, le,2, unord,3, neq,4, nlt,5, nle,6, ord,7
	macro cmp#cond#ps? dest*,src*
		cmpps dest,src,code
	end macro
	macro cmp#cond#ss? dest*,src*
		cmpss dest,src,code
	end macro
end iterate

macro shufps? dest*,src*,imm*
	SSE.basic_instruction_imm8 0,0C6h,16,dest,src,imm
end macro

iterate <instr,ext>, movaps,28h, movups,10h
	macro instr? dest*,src*
		require SSE+
		SSE.parse_operand@dest dest
		SSE.parse_operand@src src
		if (@dest.size or @src.size) and not 16
			err 'invalid operand size'
		end if
		if @dest.type = 'mmreg' & (@src.type = 'mem' | @src.type = 'mmreg')
			x86.store_instruction@src <0Fh,ext>,@dest.rm
		else if @dest.type = 'mem' & @src.type = 'mmreg'
			x86.store_instruction@dest <0Fh,ext+1>,@src.rm
		else
			err 'invalid combination of operands'
		end if
	end macro
end iterate

iterate <instr,ext>, movlps,12h, movhps,16h
	macro instr? dest*,src*
		require SSE+
		SSE.parse_operand@dest dest
		SSE.parse_operand@src src
		if @dest.type = 'mmreg' & @src.type = 'mem'
			if @dest.size <> 16 | @src.size and not 8
				err 'invalid operand size'
			end if
			x86.store_instruction@src <0Fh,ext>,@dest.rm
		else if @dest.type = 'mem' & @src.type = 'mmreg'
			if @dest.size and not 8 | @src.size <> 16
				err 'invalid operand size'
			end if
			x86.store_instruction@dest <0Fh,ext+1>,@src.rm
		else
			err 'invalid combination of operands'
		end if
	end macro
end iterate

iterate <instr,ext>, movhlps,12h, movlhps,16h
	macro instr? dest*,src*
		require SSE+
		SSE.parse_operand@dest dest
		SSE.parse_operand@src src
		if (@dest.size or @src.size) and not 16
			err 'invalid operand size'
		end if
		if @dest.type = 'mmreg' & @src.type = 'mmreg'
			x86.store_instruction@src <0Fh,ext>,@dest.rm
		else
			err 'invalid combination of operands'
		end if
	end macro
end iterate

macro movss? dest*,src*
	require SSE+
	SSE.parse_operand@dest dest
	SSE.parse_operand@src src
	if @dest.type = 'mmreg' & (@src.type = 'mem' | @src.type = 'mmreg')
		if @dest.size <> 16 | (@src.type = 'mem' & @src.size and not 4) | (@src.type = 'mmreg' & @src.size <> 16)
			err 'invalid operand size'
		end if
		@src.opcode_prefix = 0F3h
		x86.store_instruction@src <0Fh,10h>,@dest.rm
	else if @dest.type = 'mem' & @src.type = 'mmreg'
		if @dest.size and not 4 | @src.size <> 16
			err 'invalid operand size'
		end if
		@dest.opcode_prefix = 0F3h
		x86.store_instruction@dest <0Fh,11h>,@src.rm
	else
		err 'invalid combination of operands'
	end if
end macro

macro movntps? dest*,src*
	require SSE+
	SSE.parse_operand@dest dest
	SSE.parse_operand@src src
	if @dest.type = 'mem' & @src.type = 'mmreg'
		if (@dest.size or @src.size) and not 16
			err 'invalid operand size'
		end if
		x86.store_instruction@dest <0Fh,2Bh>,@src.rm
	else
		err 'invalid combination of operands'
	end if
end macro

macro movmskps? dest*,src*
	require SSE+
	x86.parse_operand@dest dest
	SSE.parse_operand@src src
	if @dest.type = 'reg' & @src.type = 'mmreg'
		if (@dest.size <> 4 & (x86.mode < 64 | @dest.size <> 8)) | @src.size <> 16
			err 'invalid operand size'
		end if
		x86.store_instruction@src <0Fh,50h>,@dest.rm
	else
		err 'invalid combination of operands'
	end if
end macro

iterate <instr,ext>, ucomiss,2Eh, comiss,2Fh
	macro instr? dest*,src*
		require SSE+
		SSE.parse_operand@dest dest
		SSE.parse_operand@src src
		if @dest.type = 'mmreg' & (@src.type = 'mem' | @src.type = 'mmreg')
			if @dest.size <> 16 | (@src.type = 'mem' & @src.size and not 4) | (@src.type = 'mmreg' & @src.size <> 16)
				err 'invalid operand size'
			end if
			x86.store_instruction@src <0Fh,ext>,@dest.rm
		else
			err 'invalid combination of operands'
		end if
	end macro
end iterate

macro cvtpi2ps? dest*,src*
	require SSE+
	SSE.parse_operand@dest dest
	SSE.parse_operand@src src
	if @dest.type = 'mmreg' & (@src.type = 'mem' | @src.type = 'mmreg')
		if @dest.size <> 16 | @src.size and not 8
			err 'invalid operand size'
		end if
		x86.store_instruction@src <0Fh,2Ah>,@dest.rm
	else
		err 'invalid combination of operands'
	end if
end macro

macro cvtsi2ss? dest*,src*
	require SSE+
	SSE.parse_operand@dest dest
	x86.parse_operand@src src
	if @dest.type = 'mmreg' & (@src.type = 'mem' | @src.type = 'reg')
		if @src.size = 0
			err 'operand size not specified'
		else if @dest.size <> 16 | @src.size < 4
			err 'invalid operand size'
		end if
		x86.select_operand_prefix@src @src.size
		@src.opcode_prefix = 0F3h
		x86.store_instruction@src <0Fh,2Ah>,@dest.rm
	else
		err 'invalid combination of operands'
	end if
end macro

iterate <instr,ext>, cvttps2pi,2Ch, cvtps2pi,2Dh
	macro instr? dest*,src*
		require SSE+
		SSE.parse_operand@dest dest
		SSE.parse_operand@src src
		if @dest.type = 'mmreg' & (@src.type = 'mem' | @src.type = 'mmreg')
			if @dest.size <> 8 | (@src.size = 'mem' & @src.size and not 8) | (@src.size = 'mmreg' & @src.size <> 16)
				err 'invalid operand size'
			end if
			x86.store_instruction@src <0Fh,ext>,@dest.rm
		else
			err 'invalid combination of operands'
		end if
	end macro
end iterate

iterate <instr,ext>, cvttss2si,2Ch, cvtss2si,2Dh
	macro instr? dest*,src*
		require SSE+
		SSE.parse_operand@dest dest
		SSE.parse_operand@src src
		if @dest.type = 'reg' & (@src.type = 'mem' | @src.type = 'mmreg')
			if @dest.size < 4 | (@src.size = 'mem' & @src.size and not 4) | (@src.size = 'mmreg' & @src.size <> 16)
				err 'invalid operand size'
			end if
			x86.select_operand_prefix@src @dest.size
			@src.opcode_prefix = 0F3h
			x86.store_instruction@src <0Fh,ext>,@dest.rm
		else
			err 'invalid combination of operands'
		end if
	end macro
end iterate

iterate <instr,ext>, pminub,0DAh, pmaxub,0DEh, pavgb,0E0h, pavgw,0E3h, pmulhuw,0E4h, pminsw,0EAh, pmaxsw,0EEh, psadbw,0F6h
	macro instr? dest*,src*
		require SSE+
		MMX.basic_instruction ext,dest,src
	end macro
end iterate

macro pinsrw? dest*,src*,sel*
	require SSE+
	MMX.parse_operand@dest dest
	x86.parse_operand@src src
	x86.parse_operand@aux sel
	if @dest.type = 'mmreg' & (@src.type = 'reg' | @src.type = 'mem') & @aux.type = 'imm'
		if (@src.type = 'reg' & @src.size <> 4) | (@src.type = 'mem' & @src.size and not 2) | @aux.size and not 1
			err 'invalid operand size'
		end if
		x86.store_instruction@src <0Fh,0C4h>,@dest.rm,1,@aux.imm
	else
		err 'invalid combination of operands'
	end if
end macro

macro pextrw? dest*,src*,sel*
	require SSE+
	x86.parse_operand@dest dest
	MMX.parse_operand@src src
	x86.parse_operand@aux sel
	if @dest.type = 'reg' & @src.type = 'mmreg' & @aux.type = 'imm'
		if @dest.size <> 4 | @aux.size and not 1
			err 'invalid operand size'
		end if
		x86.store_instruction@src <0Fh,0C5h>,@dest.rm,1,@aux.imm
	else
		err 'invalid combination of operands'
	end if
end macro

macro pshufw? dest*,src*,sel*
	require SSE+
	MMX.parse_operand@dest dest
	MMX.parse_operand@src src
	x86.parse_operand@aux sel
	if @dest.type = 'mmreg' & (@src.type = 'mem' | @src.type = 'mmreg') & @aux.type = 'imm'
		if @src.size and not 8 | @aux.size and not 1
			err 'invalid operand size'
		end if
		x86.store_instruction@src <0Fh,70h>,@dest.rm,1,@aux.imm
	else
		err 'invalid combination of operands'
	end if
end macro

macro pmovmskb? dest*,src*
	require SSE+
	x86.parse_operand@dest dest
	MMX.parse_operand@src src
	if @dest.type = 'reg' & @src.type = 'mmreg'
		if @dest.size <> 4
			err 'invalid operand size'
		end if
		x86.store_instruction@src <0Fh,0D7h>,@dest.rm
	else
		err 'invalid combination of operands'
	end if
end macro

macro movntq? dest*,src*
	require SSE+
	MMX.parse_operand@dest dest
	MMX.parse_operand@src src
	if @dest.type = 'mem' & @src.type = 'mmreg'
		if @dest.size and not 8
			err 'invalid operand size'
		end if
		x86.store_instruction@dest <0Fh,0E7h>,@src.rm
	else
		err 'invalid combination of operands'
	end if
end macro

macro maskmovq? src*,sel*
	require SSE+
	MMX.parse_operand@src src
	MMX.parse_operand@aux sel
	if @src.type = 'mmreg' & @aux.type = 'mmreg'
		x86.store_instruction@aux <0Fh,0F7h>,@src.rm
	else
		err 'invalid combination of operands'
	end if
end macro

iterate <instr,postbyte>, prefetchnta,0, prefetcht0,1, prefetcht1,2, prefetcht2,3
	macro instr? src*
		require SSE+
		x86.parse_operand@src src
		if @src.type = 'mem'
			if @src.size and not 1
				err 'invalid operand size'
			end if
			x86.store_instruction@src <0Fh,18h>,postbyte
		else
			err 'invalid operand'
		end if
	end macro
end iterate

macro sfence?
	db 0Fh,0AEh,0F8h
end macro

iterate <instr,postbyte>, fxsave,0, fxrstor,1
	macro instr? src*
		require SSE+
		x86.parse_operand@src src
		if @src.type = 'mem'
			if @src.size and not 512
				err 'invalid operand size'
			end if
			x86.store_instruction@src <0Fh,0AEh>,postbyte
		else
			err 'invalid operand'
		end if
	end macro
end iterate

iterate <instr,postbyte>, ldmxcsr,2, stmxcsr,3
	macro instr? src*
		require SSE+
		x86.parse_operand@src src
		if @src.type = 'mem'
			if @src.size and not 4
				err 'invalid operand size'
			end if
			x86.store_instruction@src <0Fh,0AEh>,postbyte
		else
			err 'invalid operand'
		end if
	end macro
end iterate
