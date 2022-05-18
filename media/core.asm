; Core file for Spectrum Digital Surround Sound daughterboard on
; a TI TMS320C549 DSP evaluation module

; Surround sound daughterboard includes

		.include "v:\ece320\54x\dsplib\globals.inc"
		.include "v:\ece320\54x\dsplib\misc.inc"
		.include "v:\ece320\54x\dsplib\ioregs.inc"

		.global	RESET                                    
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
RcvBufLen		.set 400h

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
	bd	ANALOG_IFC	; AIC interrupt - CPU is interrupted 
				; by buffered serial & sent here when data ready
	nop			; room for instructions in pipeline
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
	call 	AIC_INIT    	; call AD55 initialization routine

	stm	#3B40h,ST1	; set fractional bit (FRCT) in ST1

	b	main
	
; Initialization of 320C549 DSP state			
CPU_INIT
	st   #0ffe0h, PMST	; OVLY = 0, MP/MC = 0, IPTR = 1ff  

 	st   #07492h, SWWSR	; 2 wait offchip, 7 I/O

	; Disable PLL
	stm	#0h,CLKMD

	; Wait for PLL to turn off
	rpt 	#0ffffh
	nop

	; Program PLL for 80MHz clock
 	stm   #71ffh,CLKMD	; 80MHz clock

 	rete
 	
ser_transmit
	pshm AR2				; save AR2
	pshm BK			; save BK
	stm #1,AR0					; Set AR0 to 1
	
	stm	#ser_txlen,BK 			; Transmit buffer length
	ssbx INTM					; Mask interrupts
	
	mvdm stx_head,AR2			; Head of transmit buffer
	                
	rpt rep_count				
	mvdd *AR3+,*AR2+0%           ; Transfer data to be transmitted into buffer
	
	mvmd AR2,stx_head			; Save new head pointer 
	
	stm	#03h,BK
	portw BK,SER_IER

        popm BK			;  restore BK
	popm AR2				; restore AR2 
	
	rete						; Return
	
ser_receive
	pshm AR2				; save AR2
	pshm BK					; save BK
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
	popm BK					; restore BK
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
	wrport	#0001h,SER_MCR		; Enable interrupts, RTS, DTR
	
	;Enable serial interrupts
	orm	#00001h,IMR     
	rsbx INTM
	
	rete

; AIC_INIT: Initialize Surround Sound codec
AIC_INIT:
        SSBX    INTM
        RSBX    1,0dh   ; Clear XF (put CODEC/CPLD in reset)
        RPT     #0FFFFh
        NOP
        RPT     #0FFFFh
        NOP
        RPT     #0FFFFh
        NOP
        RPT     #0FFFFh
        NOP
        RPT     #0FFFFh
        NOP
        RPT     #0FFFFh
        NOP

        STM     #00000H, TSPC 
        
;===== Set up BSP0 for data and TDM for control to DAC =====
        CALL    SerialInit
        STM     #000ECH, TSPC   ; Take Control SP out of reset
        SSBX    1,0dh           ; Set XF (take CODEC/CPLD out of reset)
        RPT     #0FFFFh
        NOP
        RPT     #0FFFFh
        NOP
        RPT     #0FFFFh
        NOP
        RPT     #0FFFFh
        NOP
        RPT     #0FFFFh
        NOP
        RPT     #0FFFFh
        NOP

;===== Initialize CS4226 =====
        CALL ControlPortInit

;===== Call test of 6-channel output =====
        call InitCS4226

	ret



;=============================================================================
; Function: SerialInit
;
; Description:  Init serial ports
;     - setup Serial Port BSP0 (data)
;     - setup Serial Port TDM (control)
;;=============================================================================
        .global SerialInit
SerialInit:
        ld      #0,DP                   ; insure that DP is 0

;=============================================
; Set up normal C54x serial port for CS 4226 data =====
;=============================================

;===== Initialize BSP XMIT
        STM     #00008H, mmBSPC0        ; set control register
                                        ; RRST = 0 (RECV is inactive)
                                        ; XRST = 0 (XMIT is inactive)
                                        ; TXM  = 0 (0=FSX is input)
                                        ; MCM  = 0 (0=CLKX is input)
                                        ; FSM  = 1 (FSX is required)
                                        ; FO   = 0 (1=8,0=16 bit data frames)
                                        ; DLB  = 0 (loopback is off)
                                        ; TDM  = 0 (operate in normal mode)
;=============================================

;==================================================
; Set up C54x buffered serial port for CS 4226 control =====
;==================================================
;===== Initialize TDM XMIT =====
        STM     #0002CH, TSPC   ; set control register
                                ; RRST = 0 (RECV is inactive)
                                ; XRST = 0 (XMIT is inactive)
                                ; TXM  = 1 (1=FSX is output)
                                ; MCM  = 0 (0=CLKX is input)
                                ; FSM  = 1 (1=FSX is required)
                                ; FO   = 1 (1=8 bit data frames)
                                ; DLB  = 0 (loopback is off)
                                ; TDM  = 0 (TDM mode bit.  0=normal)
        ret
        nop
        nop
        nop
        nop





;=============================================================================
; Function: ControlPortInit
;
; Description:  Initialize the MAP registers via the control port.
;		For each CS4226, three events must occur:
;		1) Transmit chip address & read/write:
;				0x20 for write
;				0x21 for read
;		2) Transmit MAP Address
;		3) Transmit Data
;		4) Wait 1000 cycles so that another control word can be send and
;			CPLD sends another /CS signal for the new control word.
;		The transmission of the 1, 2, and 3 must occur back to back.
;
;     The powerdown pin must be active until this routine finishes.
;
;=============================================================================
 .global ControlPortInit
ControlPortInit:

; Clock Mode control word

; This mode selects between SPDIF input and analog input:
;		SPDIF input uses control word  0x4
;       Analog input uses control word 0x0

    stm		#020H, TDXR			; store to XMIT reg  -Chip address & write
WaitCPI_01_W:
    bitf	TSPC, #0800h   		; test for bit 11 of TSPC to be set
    bc		WaitCPI_01_W, ntc	; branch if bit is not set
    stm		#001H, TDXR			; store to XMIT reg  -MAP address 1
    							;					 Clock Mode
WaitCPI_01_W1:
    bitf	TSPC, #0800h   		; test for bit 11 of TSPC to be set
    bc		WaitCPI_01_W1, ntc ; branch if bit is not set
  .if 0
    stm		#004H, TDXR			; store to XMIT reg  -Data write
                                                ;  Clock Mode: 0 Crystal, 256Fs
                                                ;              4 -> RX1 (SPDIF) PLL
  .else
    stm         #000H, TDXR                     ; store to XMIT reg  -Data write
                                                ;  Clock Mode: 0 Crystal, 256Fs
                                                ;              4 -> RX1 (SPDIF) PLL
  .endif
    rpt         #1000-1                         ; Allow zCS to get caught up - dead space to allow
                                                ;  another control word to be sent
    nop




; Output Attenuator Ch 1 control word
    stm		#020H, TDXR       ; store to XMIT reg  -Chip address & write
WaitCPI_04_W:
    bitf	TSPC, #0800h   ; test for bit 11 of TSPC to be set
    bc		WaitCPI_04_W, ntc  ; branch if bit is not set
    stm		#004H, TDXR       ; store to XMIT reg  -MAP address 4
    							;					 Output Attenuator
WaitCPI_04_W1:
    bitf	TSPC, #0800h   ; test for bit 11 of TSPC to be set
    bc		WaitCPI_04_W1, ntc ; branch if bit is not set
    stm		#000H, TDXR       ; store to XMIT reg  -Data write
    							;					No attenuation
    rpt         #1000-1            ; Allow zCS to get caught up
    nop


; Output Attenuator Ch 2  control word
    stm 	#020H, TDXR       ; store to XMIT reg  -Chip address & write
WaitCPI_05_W:
    bitf 	TSPC, #0800h   ; test for bit 11 of TSPC to be set
    bc 		WaitCPI_05_W, ntc  ; branch if bit is not set
    stm 	#005H, TDXR       ; store to XMIT reg  -MAP address 5
    							;					 Output Attenuator
WaitCPI_05_W1:
    bitf 	TSPC, #0800h   ; test for bit 11 of TSPC to be set
    bc 		WaitCPI_05_W1, ntc ; branch if bit is not set
    stm		#000H, TDXR       ; store to XMIT reg   -Data write
    							;					No attenuation
    rpt         #1000-1            ; Allow zCS to get caught up
    nop

; Output Attenuator Ch 3 control word
    stm 	#020H, TDXR       ; store to XMIT reg  -Chip address & write
WaitCPI_06_W:
    bitf 	TSPC, #0800h   ; test for bit 11 of TSPC to be set
    bc 		WaitCPI_06_W, ntc  ; branch if bit is not set
    stm 	#006H, TDXR       ; store to XMIT reg   -MAP address 6
    							;					 Output Attenuator
WaitCPI_06_W1:
    bitf 	TSPC, #0800h   ; test for bit 11 of TSPC to be set
    bc 		WaitCPI_06_W1, ntc ; branch if bit is not set
    stm 	#000H, TDXR       ; store to XMIT reg   -Data write
    							;					No attenuation
    rpt         #1000-1            ; Allow zCS to get caught up
    nop


; Output Attenuator Ch 4 control word
    stm 	#020H, TDXR       ; store to XMIT reg   -Chip address & write
WaitCPI_07_W:
    bitf 	TSPC, #0800h   ; test for bit 11 of TSPC to be set
    bc 		WaitCPI_07_W, ntc  ; branch if bit is not set
    stm 	#007H, TDXR       ; store to XMIT reg   -MAP address 7
WaitCPI_07_W1:
    bitf 	TSPC, #0800h   ; test for bit 11 of TSPC to be set
    bc 		WaitCPI_07_W1, ntc ; branch if bit is not set
    stm 	#000H, TDXR       ; store to XMIT reg   -Data write
    							;					No attenuation
    rpt         #1000-1            ; Allow zCS to get caught up
    nop

; Output Attenuator Ch 5 control word
    stm #020H, TDXR       ; store to XMIT reg      -Chip address & write
WaitCPI_08_W:
    bitf TSPC, #0800h     ; test for bit 11 of TSPC to be set
    bc WaitCPI_08_W, ntc   ; branch if bit is not set
    stm #008H, TDXR       ; store to XMIT reg      -MAP address 8
   							;					 Output Attenuator
WaitCPI_08_W1:
    bitf TSPC, #0800h     ; test for bit 11 of TSPC to be set
    bc WaitCPI_08_W1, ntc  ; branch if bit is not set
    stm #000H, TDXR       ; store to XMIT reg      -Data write
    							;					No attenuation
    rpt  #1000-1            ; Allow zCS to get caught up
    nop

; Output Attenuator Ch 6 control word
    stm #020H, TDXR       ; store to XMIT reg     -Chip address & write
WaitCPI_09_W:
    bitf TSPC, #0800h     ; test for bit 11 of TSPC to be set
    bc WaitCPI_09_W, ntc   ; branch if bit is not set
    stm #009H, TDXR       ; store to XMIT reg     -MAP address 9
   							;					 Output Attenuator
WaitCPI_09_W1:
    bitf TSPC, #0800h     ; test for bit 11 of TSPC to be set
    bc WaitCPI_09_W1, ntc  ; branch if bit is not set
    stm #000h,TDXR       ; store to XMIT reg     -Data write
    							;					No attenuation
    rpt  #1000-1            ; Allow zCS to get caught up
    nop

; DSP Port Mode control word
    stm #020H, TDXR       ; store to XMIT reg     -Chip address & write
WaitCPI_14_W:
    bitf TSPC, #0800h     ; test for bit 11 of TSPC to be set
    bc WaitCPI_14_W, ntc   ; branch if bit is not set
    stm #00EH, TDXR       ; store to XMIT reg     -MAP address E
    						;						DSP Port mode
WaitCPI_14_W1:
    bitf TSPC, #0800h     ; test for bit 11 of TSPC to be set
    bc WaitCPI_14_W1, ntc  ; branch if bit is not set
    stm #015H, TDXR       ; store to XMIT reg     -Data write
    						;	Data format One data line mode
    						;	Data clocked in on rising edge
    						;	Master burst mode
    						;   128 nit clocks/Fs
    rpt  #1000-1            ; Allow zCS to get caught up
    nop

; Converter Control Byte
    stm #020H, TDXR       ; store to XMIT reg    -Chip address & write
WaitCPI_02_W:
    bitf TSPC, #0800h     ; test for bit 11 of TSPC to be set
    bc WaitCPI_02_W, ntc   ; branch if bit is not set
    stm #002H, TDXR       ; store to XMIT reg    -MAP address 2
WaitCPI_02_W1:
    bitf TSPC, #0800h     ; test for bit 11 of TSPC to be set
    bc WaitCPI_02_W1, ntc  ; branch if bit is not set
    stm #0000H, TDXR     ;PADZ   ; store to XMIT reg    -Data write

    						;				Converter Control Byte
    						;	No reset; Normal operatioon; No AC3/MPEG
    						;	Normal flat DAC response; No CLKE errors;
    						;	Calibration done
    rpt  #1000-1            ; Allow zCS to get caught up
    nop


; ADC Control Byte
   stm #020H, TDXR        ; store to XMIT reg   -Chip address & write
WaitCPI_0B_W:
    bitf TSPC, #0800h     ; test for bit 11 of TSPC to be set
    bc WaitCPI_0B_W, ntc   ; branch if bit is not set
    stm #00BH, TDXR       ; store to XMIT reg   -MAP address 11
    						;	ADC Control Byte
WaitCPI_0B_W1:
    bitf TSPC, #0800h     ; test for bit 11 of TSPC to be set
    bc WaitCPI_0B_W1, ntc  ; branch if bit is not set
    .if 1
    stm #0080H, TDXR       ; store to XMIT reg   -Data write
    						; SPDIF to SDOUT1
    						; Stereo to SDOUT2
    .else
    stm #0000H, TDXR       ; store to XMIT reg   -Data write
    						; Stereo to SDOUT1
    						; Mono to SDOUT2
	.endif
    rpt  #1000-1            ; Allow zCS to get caught up
    nop




; DAC Control Byte
   stm #020H, TDXR        ; store to XMIT reg   -Chip address & write
WaitCPI_03_W:
    bitf TSPC, #0800h     ; test for bit 11 of TSPC to be set
    bc WaitCPI_03_W, ntc   ; branch if bit is not set
    stm #003H, TDXR       ; store to XMIT reg   -MAP address 3
    						;						DAC Control Byte
WaitCPI_03_W1:
    bitf TSPC, #0800h     ; test for bit 11 of TSPC to be set
    bc WaitCPI_03_W1, ntc  ; branch if bit is not set
    stm #0000H, TDXR       ; store to XMIT reg   -Data write
    						;  Normal output level; 512 consec zeros mutes DAC;
    						;	DAC mutes & vol control on zero corssings
    rpt  #1000-1            ; Allow zCS to get caught up
    nop

    ret



;=============================================================================
; Function: InitCS4226
;
; Description:
;     - initialize CS4226 for receive and transmit
;
;=============================================================================
InitCS4226:

;===========================
;===== Enable receive =====
;===========================
    STM  #00010H, IFR		; Clear any pending BRNT0
    ORM  #00010H, IMR		; Enable BRNT0
    STM  #02040H, mmBSPCE0	; Enable autobuffering rcv
    STM  #RcvBuf, mmARR0	; Buffer start addr
    STM  #RcvLen, BKR		; Buffer size

;===========================
;===== Enable transmit =====
;===========================
    STM  #00020H, IFR		; Clear any pending BXINT0
    STM  #XmitBuf, mmAXR0   ; Buffer start addr
    STM  #XmitLen, BKX		; Buffer size
    ORM  #0400h, mmBSPCE0	; Enable auto buffer
    STM  #000C8H, mmBSPC0	; Take SP for data out of reset
    RSBX INTM				; Enable Interrupts
    ret

; Wait for buffer to fill
; Clobbers: B, DP, TC
; Returns: AR6 (pointer to input buffer)
;          AR7 (Pointser to output buffer)
   
wait_fill
	ld 	*(buf_filled),B
	bc wait_fill,BEQ
	
	st	#0,*(buf_filled)	; reset buffer full flag

    ld   #0,DP
    stm  #RcvBuf, pINBUF       		;   top of Rcv Buffer
    stm  #XmitBuf, pOUTBUF  		;   top of Xmit Buffer
    bitf mmBSPCE0, #4000h   		;   Test 1st or 2nd half of buffer
    nop
    bc   SecondH, ntc       		;   	If 1st half jump
    mar  *+pOUTBUF(XmitLen2)       	;
    mar  *+pINBUF(RcvLen2)       	;   Add offset for second half
SecondH:
    bitf mmBSPCE0, #0800h
    bc   SecondH2, ntc
SecondH2:    
    mar  *+pINBUF(1)
    ret							; Return to caller

;=============================================================================
;
;	BSP0 Interrupt Service Routine
;		Sets input and output pointers to the just-received half
;		of the BSP. The buffers are aligned so that if the top
;		half of the BSP0 receive buffer transmits the top half
;		of the BSP0 transmit buffer.
;
;=============================================================================

; ANALOG_IFC: Serial port receive interrupt service routine
ANALOG_IFC	
	st #1,*(buf_filled)
	rete
