
; Windows 1255

macro define
	local encoding
	virtual at 0
		encoding::
		repeat 80h
			dw %-1
		end repeat
		dw 20ACh,?,201Ah,192h,201Eh,2026h,2020h,2021h,2C6h,2030h,?,2039h,?,?,?,?
		dw ?,2018h,2019h,201Ch,201Dh,2022h,2013h,2014h,2DCh,2122h,?,203Ah,?,?,?,?
		dw 0A0h,0A1h,0A2h,0A3h,20AAh,0A5h,0A6h,0A7h,0A8h,0A9h,0D7h,0ABh,0ACh,0ADh,0AEh,0AFh
		dw 0B0h,0B1h,0B2h,0B3h,0B4h,0B5h,0B6h,0B7h,0B8h,0B9h,0F7h,0BBh,0BCh,0BDh,0BEh,0BFh
		dw 5B0h,5B1h,5B2h,5B3h,5B4h,5B5h,5B6h,5B7h,5B8h,5B9h,?,5BBh,5BCh,5BDh,5BEh,5BFh
		dw 5C0h,5C1h,5C2h,5C3h,5F0h,5F1h,5F2h,5F3h,5F4h,?,?,?,?,?,?,?
		dw 5D0h,5D1h,5D2h,5D3h,5D4h,5D5h,5D6h,5D7h,5D8h,5D9h,5DAh,5DBh,5DCh,5DDh,5DEh,5DFh
		dw 5E0h,5E1h,5E2h,5E3h,5E4h,5E5h,5E6h,5E7h,5E8h,5E9h,5EAh,?,?,200Eh,200Fh,?
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
