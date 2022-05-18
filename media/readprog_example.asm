	stm	#64h,AR1	; load 64h into AR1
	ld	#02h,16,A	; load 02h in high part of A
	adds	#3456h,A	; fill in low part of A
				; A contains 023456h
	readprog 1 		; read from 023456h in Program RAM
				; into *AR1 in Data RAM
