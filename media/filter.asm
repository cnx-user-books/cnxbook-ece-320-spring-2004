	.copy "core.asm"		; Copy in core code
	
FIR_len	.set	8			; This is an 8-tap filter.
	
    	.sect ".data"			; Flag following as data declarations
    
    	.align 16				; Align to a multiple of 16
coef						; assign label "coeff"
	.copy "coef.asm"		; Copy in coefficients

	.align 16				; Align to a multiple of 16
firstate
	.space 16*8				; Allocate 8 words of storage for
							; filter state.
	.sect ".text"
main
	; Initialize address registers 
	stm 	#FIR_len,BK		; initialize circular buffer length
	stm 	#coef,AR2    		; initialize coefficient pointer
	stm	#firstate,AR3		; initialize state pointer
	stm 	#1,AR0			; initialize AR0 for pointer increment
	
loop
	; Wait for a new block of 64 samples to come in
	WAITDATA
	
    	; BlockLen = the number of samples that come from WAITDATA (64)
    	stm 	#BlockLen-1, BRC	; Save repeat count into block repeat counter
    	rptb 	endblock-1		; Repeat between here and 'endblock' label

    	ld      *AR6,16, A		; Receive ch1 into A accumulator
    	mar 	*+AR6(2)                ; Rcv data is in every other channel
    	ld      *AR6,16, B		; Receive ch2 into B accumulator
    	mar 	*+AR6(2)                ; Rcv data is in every other channel
    
    	ld	A,B			; Transfer A into B for safekeeping

	; The following code executes a single FIR filter.
	
    	sth   	A,*AR3+%		; store current input into state buffer
    	rptz  	A,(FIR_len-1)		; clear A and repeat
    	mac   	*AR2+0%,*AR3+0%,A	; multiply coefficient by state & accumulate
    
    	rnd	A				; Round off value in 'a' to 16 bits                            
    
    	; end of FIR filter code. Output is in the high part of 'A.'

    	sth 	A, *AR7+	; Store filter output (from a) into ch1
    	sth 	B, *AR7+	; Store saved input (from b) into ch2
   
    	sth 	B, *AR7+	; Store saved input (from b) into ch3...ch6 also.
    	sth 	B, *AR7+	; ch4
    	sth 	B, *AR7+	; ch5 
    	sth 	B, *AR7+	; ch6
   
endblock:
    	b 	loop

