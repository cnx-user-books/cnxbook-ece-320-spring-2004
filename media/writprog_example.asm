	stm	#64h,AR1	; load 64h into AR1
	ld	#02h,16,A	; load 02h in high part of A
	adds	#3456h,A	; fill in low part of A
				; A contains 023456h
	writprog	1	; write from *AR1 in Data RAM to
				; 023456h in Program RAM
