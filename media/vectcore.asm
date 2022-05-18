; Core file for Spectrum Digital Surround Sound daughterboard on
; a TI TMS320C549 DSP evaluation module

; Surround sound daughterboard includes

		.include "v:\ece320\54x\dsplib\globals.inc"
		.include "v:\ece320\54x\dsplib\misc.inc"
		.include "v:\ece320\54x\dsplib\ioregs.inc"

	.global	RESET

; Required definitions
;	tv_count: number of input/output samples
;	tv_inptr: Start of input data
;	tv_outptr: Start of output data
                                    
; Definitions

ser_txlen	.set	7Fh		; 127 byte transmit buffer
ser_rxlen 	.set	7Fh		; 127 byte receive buffer

SER_RBR		.set 010h		; read buffer
SER_THR		.set 010h		; transmit holding register
SER_DLL		.set 010h		; divisor latch (low)
SER_DLM		.set 011h		; divisor latch (upper)
SER_IER		.set 011h		; interrupt enable register
SER_FCR		.set 012h		; FIFO control register
SER_IIR		.set 012h		; Interrupt status register
SER_LCR		.set 013h		; Line control register
SER_MCR		.set 014h		; Modem control register
SER_LSR		.set 015h		; Line status register
SER_MSR		.set 016h		; Modem status register
SER_SCR		.set 017h		; Scratchpad register
                                                     

	.asg    AR6,pINBUF           ; Input data pointer
        .asg    AR7,pOUTBUF          ; Output data pointer


K_FRAME_SIZE  	.set 128	; Size of I/O frames (sample times)

XmitBufLen		.set 400h
RcvBufLen		.set 3F0h

XmitLen			.set (K_FRAME_SIZE)*6    ; 100 6 channel samples
RcvLen			.set (K_FRAME_SIZE)*4    ; 100 4 channel samples
XmitLen2		.set XmitLen/2
RcvLen2			.set RcvLen/2
RcvLen3			.set (K_FRAME_SIZE)/2-1

BlockLen		.set (K_FRAME_SIZE/2)
                                                     
;*************************************************************************
;*   Define macros for talking to the CODEC :
;*************************************************************************
	
WAITDATA .macro
	call wait_fill
	.endm  
	
SAVEREG	.macro   
	pshm ST0
	pshm AR0
	pshm AR1
	pshm AR2
	pshm AR3
	pshm BK
	pshm AL
	pshm AH
	pshm AG
	.endm
	
LOADREG .macro
	popm AG
	popm AH
	popm AL
	popm BK
	popm AR3
	popm AR2
	popm AR1
	popm AR0
	popm ST0
	.endm	
	
PULLBUFF .macro buf,fail
	mvdm buf,AR0  		; head pointer
	mvdm buf+1,AR2	 	; tail pointer
	nop
	cmpr eq,AR2     	; Is buffer empty?
	stm #1,AR0	    	; Load 1 into AR0 for increment
	bc 	fail,tc		; If so, branch to fail
	mvdd *AR2+0%,*AR3+	; Transfer from buffer to AR2
					; bk assumed to be set to block size
	mvmd AR2,buf+1		; Put back modified tail pointer	
	.endm
	
WRPORT .macro immed,dest
	stm	immed,AL
	portw AL,dest
	.endm
	
; Serial port access macros

; USAGE: WRITSER rpt
; Effect: Transfer rpt characters from *AR3+ to serial buffer

WRITSER	.macro rpt
	stm	#rpt-1,rep_count
	call ser_transmit
	.endm


; USAGE: READSER rpt
; Effect: Transfer up to rpt characters from serial buffer to *AR3+
;         Returns number read in AR1

READSER	.macro rpt   
	stm #rpt-1,rep_count
	call ser_receive
	.endm
	
; Program RAM access macros

; Usage: READPROG rpt
; Effect: Transfer PMEM(*A) to DMEM(*AR1+)
;         rpt is the number of consecutive words to transfer
READPROG .macro rpt
	stm	#rpt-1,rep_count
	intr 	2
	.endm

; Usage: WRITPROG rpt
; Efect: Transfer DMEM(*AR1+) to PMEM(*A)
;         rpt is the number of consecutive words to transfer
WRITPROG .macro rpt
	stm	#rpt-1,rep_count
	intr	3
	.endm

;Scratchpad RAM definitions

	.sect   ".scratch"

rep_count	.word 	0		; Default to 1 word transfers
buf_filled	.word	0		; I/O buffer filled?
                      
srx_head	.word ser_rxbuf		; Start of receive queue
srx_tail 	.word ser_rxbuf		; End of receive queue

stx_head	.word ser_txbuf		; Start of transmit queue
stx_tail	.word ser_txbuf		; End of transmit queue

; Serial data buffers

	.sect	".sdata"
	
	.align	(ser_txlen+1)
ser_txbuf						
	.space	ser_txlen*16        ; Space for serial transmit buffer
	
	.align (ser_rxlen+1)
ser_rxbuf
	.space	ser_rxlen*16		; Space for serial receive buffer
	
; Automatic buffering / CODEC data

	.sect ".abdata"
XmitBuf
	.space XmitBufLen*16
	
RcvBuf
	.space RcvBufLen*16               

; Pointers for test vector stuff
tv_inptr	.word	0
tv_outptr	.word 	0
tv_counter	.word	0

;*************************************************************************
;*   Start section containing executable code 
;*************************************************************************	
	.sect	".text"	
	.mmregs		; defines symbolic names for memory-mapped registers 

SYSTEM_STACK	.set 06000h

	;* Specify reset and receive interrupt vector: 
	.sect     ".vectors"	; label section 

RESET	
	bd	start	; branch to main program
	stm	#SYSTEM_STACK, SP
	
	.space	4*16		; skip 0x04 words (start of vectors + 0x08h)

SINT0	bd 	reada_int
	stm	#0ffc0h,PMST

SINT1	bd	writa_int
	stm	#0ffc0h,PMST

	.space	48*16		; skip 0x34 words (start of vectors + 0x44h)

INT0	bd 	SERIAL_IFC
	nop
	nop
	
	.space	12*16		; skip 0x08 words (start of vectors + 0x50h ) 

BRINT0	
	rete
	nop
	nop		
	nop
	.space	44*16	   	; 0x80 locations with interrupt vectors

	.sect   ".hightext"
reada_int

	rpt 	rep_count
	reada	*AR1+
	stm	#0ffe0h,PMST
	rete

writa_int
	rpt	rep_count
	writa	*AR1+
	stm	#0ffe0h,PMST
	rete

	.sect	".text"			; new section
start
	ld	#0, DP         	; load 0 into data-page pointer
	ssbx	INTM	        ; set status register bits
	ssbx	SXM	        ; set sign extension mode

	call 	CPU_INIT		; call DSP initialization routine     
	call	SER_INIT		; call serial initialization routine
	call	TEST_INIT		; call test initialization

	stm	#3B40h,ST1	; set fractional bit (FRCT) in ST1

	b	main
	
; Initialization of 320C549 DSP state			
CPU_INIT
	st   #0ffe0h, PMST	; OVLY = 0, MP/MC = 0, IPTR = 1ff  

; 	st   #07492h, SWWSR	; 2 wait offchip, 7 I/O
 	st   #07FFFh, SWWSR	; 7 wait offchip, 7 I/O  *fixes test vectors*

	; Disable PLL
	stm	#0h,CLKMD

	; Wait for PLL to turn off
	rpt 	#0ffffh
	nop

	; Program PLL for 80MHz clock
; 	stm   #71ffh,CLKMD	; 80MHz clock
	stm   #11ffh,CLKMD	; 20MHz clock

 	rete
 	
ser_transmit
	pshm AR2				; save AR2
	pshm BK			; save BK
	stm #1,AR0					; Set AR0 to 1
	
	stm	#ser_txlen,BK 			; Transmit buffer length
	ssbx INTM					; Mask interrupts
	
	mvdm stx_head,AR2			; Head of transmit buffer
	                
	rpt rep_count				
	mvdd *AR3,*AR2+0%           ; Transfer data to be transmitted into buffer
	
	mvmd AR2,stx_head			; Save new head pointer 
	
	stm	#03h,BK
	portw BK,SER_IER
	popm BK			;  restore BK
	popm AR2				; restore AR2
	
	rete						; Return
	
ser_receive
	pshm AR2				; save AR2
	pshm BK			; save BK
	stm #ser_rxlen,BK			; Set receive buffer length
	stm #0,AR1					; Zero count of received characters
	
	ssbx INTM					; Mask interrupts
	
_ser_rec_loop
	PULLBUFF srx_head,_ser_rec_done	; Pull a datum out of the buffer
	
	mvdm rep_count,AR0				; Load repeat count
	nop
	cmpr EQ,AR1						; Collected the right number yet?
	bcd _ser_rec_done,TC			; If so, then we're done
	mar *AR1+ 						; Don't forget to increment count
	nop
	
	b _ser_rec_loop
		          
_ser_rec_done
	popm BK			; restore BK
	popm AR2				; restore AR2
	rete		          
         
; Serial Interrupt Handler       
SERIAL_IFC
	SAVEREG 					; Save registers that will be modified
	
_get_next_int
	portr	SER_IIR,AL
	and #0ffh,A
	
	stl a,ar2
	sub	#4,a
	
	bc _rx_intr,aeq
	
	ld	 AR2,A
	sub #2,a
	
	bc _tx_intr,aeq
	
	LOADREG 					; Restore registers
	rete
	
_rx_intr
	stm	#ser_rxlen,BK 			; Transmit buffer length
	mvdm srx_head,AR2			; Head of transmit buffer

	portr SER_RBR,AL	    	; Get new word
	and #0ffh,A
	stl A,*AR2+%
	
	bd _get_next_int			; Process next interrupt
	mvmd AR2,srx_head			; Save new head pointer
	nop
	
_tx_intr    
	stm #ser_txlen,BK
	stm #AL,AR3					; Store into AL
	PULLBUFF stx_head,_tx_done	; Grab an byte from transmit buffer
	bd _get_next_int
	portw AL, SER_THR				; Store byte
	
_tx_done	        
	bd _get_next_int
	wrport #1h,SER_IER
	
; 16550 Initialization Routine    
SER_INIT                 
	; Disable serial interrupts
	andm #0fffeh,IMR
	
	; Initialize buffer pointers
	stm	#ser_rxbuf,srx_head
	stm #ser_rxbuf,srx_tail
	
	stm #ser_txbuf,stx_head
	stm	#ser_txbuf,stx_tail
	
	; Init serial controller
	wrport	#080h,SER_LCR		; Access divisor latch
	
	wrport	#000h,SER_DLM		; Program divisor for 38,400 bps
	wrport	#006h,SER_DLL
	
	wrport  #000h,SER_FCR		; Disable serial FIFO
	
	wrport	#003h,SER_LCR		; Program LCR for 8bits, no parity, 1 stop bit

	wrport	#001h,SER_IER		; Enable receive interrupt
	wrport	#000h,SER_MCR		; Enable interrupts, RTS, DTR
	
	;Enable serial interrupts
	orm	#00001h,IMR     
	rsbx INTM
	
	rete

TEST_INIT
	; Load start locations into test vector pointers

	ld #tv_inbuf,A
	stl A,*(tv_inptr)

	ld #tv_outbuf,A
	stl A,*(tv_outptr)

	ld #0h,A
	stl A,*(tv_counter)

	st #1,*(buf_filled)		; we can always get more

	ret


; Wait for buffer to fill
; Clobbers: B, DP, TC
; Returns: AR6 (pointer to input buffer)
;          AR7 (Pointser to output buffer)

wait_fill
	pshm AR0
	pshm AR1
	pshm AR2
	pshm AL
	pshm AH
	pshm AG
	pshm ST1

	rsbx 	sxm		; Clear sign-extension bit
 
	; Make sure to clobber the same registers as
	; wait_fill normally does

	ld #0,DP		; Clobber DP
	ld #1234h,16,B		; Clobber B

	; Check if we're done

	stm	#tv_count,AR0	
	mvdm 	*(tv_counter),ar1
	nop			; Pipeline stall
	cmpr	lt,AR1		; Any more to do?
	bc	_quit,NTC	; If not, quit

	stm	#2,AR0		; Increment by two

	st	#1,*(buf_filled)	

	stm	#RcvBuf,AR2
	ld 	*(tv_inptr),a		
	rpt	#(2*BlockLen)-1	; Copy input data
	  reada	*AR2+0
	add 	#2*BlockLen,a
	stl	a,*(tv_inptr)

	; Is this the first block? IF so, we don't save any data

	stm	#0,AR0
	nop
	cmpr	eq,AR1		; First block?
	bc	_nosave,TC	; If so, skip this part


	stm	#XmitBuf,AR2
	ld 	*(tv_outptr),a
	rpt	#(6*BlockLen)-1	; Copy output data
	  writa	*AR2+
	add	#6*BlockLen,a
	stl	a,*(tv_outptr)

_nosave
	mar	*+ar1(BlockLen)
	mvmd	AR1,*(tv_counter)

	popm 	ST1
	popm 	AG
	popm 	AH
	popm	AL
	popm	AR2
	popm	AR1
	popm 	AR0

	stm 	#RcvBuf,AR6
	stm 	#XmitBuf,AR7

	ret

_quit
	; Save the last block of output data

	stm	#XmitBuf,AR2
	ld 	*(tv_outptr),a
	rpt	#(6*BlockLen)-1	; Copy output data
	  writa	*AR2+
	add	#6*BlockLen,a
	stl	a,*(tv_outptr)

_spin	b	_spin			; Infinite loop when done

