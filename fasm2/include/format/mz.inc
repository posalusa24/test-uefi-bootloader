
MZ::
.signature			dw "MZ"
.bytes_in_last_page		dw .LENGTH and 1FFh
.number_of_pages		dw (.LENGTH-1) shr 9 + 1
.number_of_relocations		dw .NUMBER_OF_RELOCATIONS
.number_of_header_paragraphs	dw .HEADER_LENGTH shr 4
.minimum_heap			dw (.LENGTH+.RESERVED_LENGTH-1) shr 4 - (.LENGTH-1) shr 4
.maximum_heap			dw 0FFFFh
.initial_ss			dw 0
.initial_sp			dw 0
.checksum			dw 0
.initial_ip			dw 0
.initial_cs			dw 0
.relocations_offset		dw .relocations
.overlay_number 		dw 0
.relocations			dw .NUMBER_OF_RELOCATIONS dup (?,?)
				rb 0Fh - ($%+0Fh) and 0Fh
.HEADER_LENGTH = $
.RELOCATION_INDEX = 0

.ENTRY_DEFINED = 0
.HEAP_DEFINED = 0
.STACK_DEFINED = 0
.STACK_LENGTH = 1000h

org 0

macro entry? definition
    local v
    if MZ.ENTRY_DEFINED
	err 'setting already specified'
    else match seg:offs, definition
	v = seg
	if v relativeto MZ.segment
	    store v - MZ.segment : word at MZ : MZ.initial_cs
	else
	    err 'incorrect segment'
	end if
	v = offs
	if v >= 0 & v < 10000h
	    store v : word at MZ : MZ.initial_ip
	else
	    err 'value out of range'
	end if
	MZ.ENTRY_DEFINED = 1
    else
	err 'invalid argument'
    end match
end macro

macro heap? definition
    local v,min
    if MZ.HEAP_DEFINED
	err 'setting already specified'
    else
	v = definition
	if v >= 0 & v < 10000h
	    load min : word from MZ : MZ.minimum_heap
	    v = v + min
	    if v > 0FFFFh
		v = 0FFFFh
	    end if
	    store v : word at MZ : MZ.maximum_heap
	else
	    err 'value out of range'
	end if
	MZ.HEAP_DEFINED = 1
    end if
end macro

macro stack? definition
    local v
    if MZ.STACK_DEFINED
	err 'setting already specified'
    else match seg:offs, definition
	v = seg
	if v relativeto MZ.segment
	    store v - MZ.segment : word at MZ : MZ.initial_ss
	else
	    err 'incorrect segment'
	end if
	v = offs
	if v >= 0 & v < 10000h
	    store v : word at MZ : MZ.initial_sp
	else
	    err 'value out of range'
	end if
	MZ.STACK_DEFINED = 1
	MZ.STACK_LENGTH = 0
    else
	MZ.STACK_DEFINED = 1
	MZ.STACK_LENGTH = definition
    end match
end macro

element MZ.segment

macro segment? definition
    rb 0Fh - ($%+0Fh) and 0Fh
    match name =use16?, definition
	name := MZ.segment + ($%-MZ.HEADER_LENGTH) shr 4
	use16
    else match name =use32?, definition
	name := MZ.segment + ($%-MZ.HEADER_LENGTH) shr 4
	use32
    else match name, definition
	name := MZ.segment + ($%-MZ.HEADER_LENGTH) shr 4
    end match
    org 0
end macro

iterate word, word,dword

	calminstruction word? value
		compute value, value
		check	value relativeto MZ.segment
		jno	plain
		local	offset
		compute offset, $%
		emit	word, value - MZ.segment
		check	$% > offset
		jno	done
		compute offset, offset - MZ.HEADER_LENGTH
		compute offset, offset and 0FFFFh + (offset and not 0FFFFh) shl 12
		asm	store offset:4 at MZ : MZ.relocations + MZ.RELOCATION_INDEX shl 2
		compute MZ.RELOCATION_INDEX, MZ.RELOCATION_INDEX + 1
	    done:
		exit
	    plain:
		emit	word, value
	end calminstruction

end iterate

postpone
    if MZ.STACK_LENGTH
	rb 0Fh - ($%+0Fh) and 0Fh
	store ($%-MZ.HEADER_LENGTH) shr 4 : word at MZ : MZ.initial_ss
	rb MZ.STACK_LENGTH
	store MZ.STACK_LENGTH : word at MZ : MZ.initial_sp
    end if
    MZ.LENGTH = $%%
    MZ.RESERVED_LENGTH = $%-$%%
    MZ.NUMBER_OF_RELOCATIONS = MZ.RELOCATION_INDEX
end postpone
