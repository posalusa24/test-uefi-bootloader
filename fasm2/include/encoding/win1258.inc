
; Windows 1258

macro define
	local encoding
	virtual at 0
		encoding::
		repeat 80h
			dw %-1
		end repeat
		dw 20ACh,?,201Ah,192h,201Eh,2026h,2020h,2021h,2C6h,2030h,?,2039h,152h,?,?,?
		dw ?,2018h,2019h,201Ch,201Dh,2022h,2013h,2014h,2DCh,2122h,?,203Ah,153h,?,?,178h
		dw 0A0h,0A1h,0A2h,0A3h,0A4h,0A5h,0A6h,0A7h,0A8h,0A9h,0AAh,0ABh,0ACh,0ADh,0AEh,0AFh
		dw 0B0h,0B1h,0B2h,0B3h,0B4h,0B5h,0B6h,0B7h,0B8h,0B9h,0BAh,0BBh,0BCh,0BDh,0BEh,0BFh
		dw 0C0h,0C1h,0C2h,102h,0C4h,0C5h,0C6h,0C7h,0C8h,0C9h,0CAh,0CBh,300h,0CDh,0CEh,0CFh
		dw 110h,0D1h,309h,0D3h,0D4h,1A0h,0D6h,0D7h,0D8h,0D9h,0DAh,0DBh,0DCh,1AFh,303h,0DFh
		dw 0E0h,0E1h,0E2h,103h,0E4h,0E5h,0E6h,0E7h,0E8h,0E9h,0EAh,0EBh,301h,0EDh,0EEh,0EFh
		dw 111h,0F1h,323h,0F3h,0F4h,1A1h,0F6h,0F7h,0F8h,0F9h,0FAh,0FBh,0FCh,1B0h,20ABh,0FFh
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
