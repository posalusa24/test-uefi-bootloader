
; Windows 1252

macro define
	local encoding
	virtual at 0
		encoding::
		repeat 80h
			dw %-1
		end repeat
		dw 20ACh,?,201Ah,192h,201Eh,2026h,2020h,2021h,2C6h,2030h,160h,2039h,152h,?,17D,?
		dw ?,2018h,2019h,201Ch,201Dh,2022h,2013h,2014h,2DCh,2122h,161h,203Ah,153h,?,17Eh,178h
		repeat 60h
			dw 0A0h+%-1
		end repeat
	end virtual
	macro WCHAR arg
		if arg eqtype ''
			local data,char
			data db arg
			rb ($-data)
			repeat ($-data)/2
				load char:byte from data+%%-%
				load char:word from encoding:char*2
				store char:word at data+(%%-%)*2
			end repeat
		else
			dw arg
		end if
	end macro
end macro

define
purge define
