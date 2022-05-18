;***********************************************************
; Version 2.20.01                                           
;***********************************************************
;****************************************************************
;  Function:	sine
;  Description: sine vector generation via polynomial evaluation
;
;  Copyright Texas instruments Inc, 1998
;----------------------------------------------------------------
;  Revision History:
;
;  0.01, J. Axelrod 6/15/98 - Original release (from atan code)
;  1.00, R. Piedra 8/31/98
;	   - Removed AR long offsets to reduce cycles/code
;	   - Replaced last poly with macar to avoid dummy read
;	   - Replaced banz with rptbd
;
;  2.00	- Li Yuan, 4/09/02. fixed overflow flag setup at the end of code.
;****************************************************************
        .mmregs

; Far-mode adjustment

	.if __far_mode
offset	.set 1			; far mode uses one extra location for ret addr  ll
	.else
offset	.set 0
	.endif

	.asg	(2), ret_addr		; stack description
					; x in A
	.asg	(3 + offset), arg_y
	.asg	(4 + offset), arg_n
					; register usage
	.asg	ar0, ar_y		; pointer to output vector
	.asg	ar2, ar_x		; pointer to input vector
	.asg	ar3, ar_coef		; pointer to coef table
	.asg	ar4, ar_coefsave	; save coef table address

;****************************************************************
	.def	_sine
	.text

_sine

        PSHM    ST0                                 ; 1 cycle
        PSHM    ST1                                 ; 1 cycle
        RSBX    OVA                                 ; 1 cycle
        RSBX    OVB                                 ; 1 cycle

; Get arguments and set modes
; ---------------------------

	ssbx	frct			; set frct ON				(1)
	ssbx	ovm			; why saturate? no guard bits adv?	(1)
	ssbx	sxm			; 					(1)

	ld	*sp(arg_n),b		; b = n					(1)
	sub	#1,b			; b = n-1				(2)
	stlm	b,brc			; brc = n-1				(1)

	st	#coef, *(ar_coefsave)	; pointer to coef table			(2)

	stlm	a, ar_x 		; pointer to array x			(1)

	rptbd	eloop-1 		; repeat n times			(2)
	mvdk	*sp(arg_y),*(ar_y)	; pointer to array y			(2)

; If angle in 2nd and 4th quadrant then negate the result before removing
; sign bit
; -----------------------------------------------------------------------

	bit	*ar_x, 15-14		; tc = x(bit 14)			(1)
	ld	*ar_x,a 		; al = x (sign-extended)		(1)
	mvmm	ar_coefsave,ar_coef	; initialize ar_coef to beg of table	(1)

	xc	1,tc			; if x(bit 14) == 1 then neg and and	(1)
	neg	a			; a = -x				(1)

	and	#7fffh,a		; a = remove sign-bit from (-x)		(2)

; Start polynomial evaluation
; ---------------------------

	stlm	a,t			; t = al = x				(1)
	ld	*ar_coef+,16,a		; ah = c5;	point to c4		(1)
	ld	*ar_coef+,16,b		; bh = c4;	point to c3		(1)
	poly	*ar_coef+		; a = ah*t + b				(1)
					;   = c5*x + c4
					; bh = c3	point to c2
	poly	*ar_coef+		; a = ah*t + b				(1)	
					;   = (c5*x + c4)*x + c3
					;   = c5*x^2 + c4*x + c3
					; bh = c2	point to c1
	poly	*ar_coef+		; a = ah*t + b				(1)
					;   = (c5*x^2+c4*x+c3)*x + c2
					;   = c5*x^3+c4*x^2+c3*x + c2
					; bh = c1	point to c0

	bit	*ar_x+, 15-15		; tc = x(bit 15) for next xc		(1)
	poly	*ar_coef+		; a = ah*t + b				(1)
					;   = (c5*x^3+c4*x^2+c3*x + c2)*x + c1
					;   = c5*x^4+c4*x^3+c3*x^2+c2*x +c1
					; bh = c0	point to c(-1)
	macar	t,b,a			; a = ah*t + b				(1)
					;   = (c5*x^4+c4*x^3+c3*x^2 + c2*x+c1)*x + c0
					;   = c5*x^5+c4*x^4+c3*x^3+c2*x^2 +c1*x + c0
; Convert result from q4.12 to q1.15
; ----------------------------------

	sfta	a,3			; arithmetic shift on 40-bits		(1)

; If angle in 3rd and 4th quadrant (negative angle), negate the result
; ---------------------------------------------------------------------

	xc	1,tc			;					(1)
	neg	a			;					(1)
	sth a,*ar_y+			; no possible sth a,3,*ar_y because	(1)
					; that will not trigger A saturation
eloop

; Return overflow flag
; --------------------
	ld	#0,a			;					(1)
	xc	1,AOV			;					(1)
	ld	#1,a			;					(1)

	xc	1,BOV			;					(1)
	ld	#1,b			;					(1)

        POPM    ST1                                 ; 1 cycle
        POPM    ST0                                 ; 1 cycle

	.if	__far_mode
	fretd				;					(4)
	.else
	retd				;					(3)
	.endif
	nop
	nop
	
;*****************************************************
; Table containing the coefficients for the polynomial

	.data    
coef:			; hex values values in q4.12
	.word	0x1cce	; 1.800293	(coef for x^5 = c5)
	.word	0x08b7	; 0.5446778	(coef for x^4 = c4)
	.word	0xaacc	; -5.325196	(coef for x^3 = c3)
	.word	0x0053	; 0.02026367	(coef for x^2 = c2)
	.word	0x3240	; 3.140625	(coef for x^1 = c1)
	.word	0x0000	; 0		(coef for x^0 = c0)

;end of file. please do not remove. it is left here to ensure that no lines of code are removed by any editor
