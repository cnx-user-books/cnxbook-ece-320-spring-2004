	.copy "core.asm"

; THRU6.ASM
;
; Copies Channel 1 input to Channel 1-3 output
; Copies Channel 2 input to Channel 4-6 output
; Also echos serial data back.

	.sect ".data"
hold	.word 0

	.sect ".text"
main
	; initialize here

loop
	; wait for next block of data to arrive	
	WAITDATA
	
    	stm 	#(BlockLen-1),BRC
    	rptb 	copy-1			; 

    	ld      *AR6,16, A
    	mar 	*+AR6(2)                 ; Rcv data is in every other channel
    	ld      *AR6,16, B
    	mar 	*+AR6(2)                 ; Rcv data is in every other channel
    	
    	sth 	A, *AR7+
    	sth 	A, *AR7+
    	sth 	A, *AR7+
  
    	sth 	B, *AR7+
    	sth 	B, *AR7+
    	sth 	B, *AR7+
    
copy:
	; here we attempt to echo serial data        
	 
_serial_loop
	stm 	#hold,AR3      		; Read to hold location
	 
	READSER 1			; Read one byte from serial port
	 
	cmpm 	AR1,#1			; Did we get a character?
	bc 	loop,NTC		; if not, branch back to start
	 
	stm 	#hold,AR3		; Write from hold location
	WRITSER 1			; ... one byte
	 
	b 	_serial_loop
  
