*********************************************************************************
*       (C) COPYRIGHT TEXAS INSTRUMENTS, INC. 1996                              *
*********************************************************************************
*                                                                               *
* MODULE NAME:  fft.asm                                                         *
*                                                                               *
* AUTHORS:      Simon Lau and Nathan Baltz                                      *
*                                                                               *
* DESCRIPTION:  PHASE TWO   (LogN)-Stage Complex FFT                            *
*               This function is called from the main module of the 'C54x Real  *
*               FFT code.  Here we assume that the original 2N-point real input *
*               sequence is already packed into an N-point complex sequence and *
*               stored into the data processing buffer in bit-reversed order    *
*               (as done in Phase One).  Now we perform an in-place, N-point    *
*               complex FFT on the data processing buffer, dividing the outputs *
*               by 2 at the end of each stage to prevent overflow.  The         *
*               resulting N-point complex sequence will be unpacked into a      *
*               2N-point complex sequence in Phase Three & Four.                *
*                                                                               *
* REGISTER USAGE:   AR0   offset to next butterfly  (Stages 1 & 2)              *
*                         index of twiddle tables (remaining stages)            *
*                   AR1   group counter                                         *
*                   AR2   pointer to 1st butterfly data PR, PI                  *
*                   AR3   pointer to 2nd butterfly data QR, QI                  *
*                   AR4   pointer to cosine value WR                            *
*                   AR5   pointer to sine value WI                              *
*                   AR6   butterfly counter                                     *
*                   AR7   start address of data processing buffer (Stages 1 & 2)*
*                         stage counter (remaining stages)                      *
*                   BK                                                          *
*                   BRC                                                         *
*                                                                               *
* DATE:         7-16-1996                                                       *
*                                                                               *
*********************************************************************************

        .asg    AR1,GROUP_COUNTER
        .asg    AR2,PX
        .asg    AR3,QX
        .asg    AR4,WR
        .asg    AR5,WI
        .asg    AR6,BUTTERFLY_COUNTER
        .asg    AR7,DATA_PROC_BUF               ; for Stages 1 & 2
        .asg    AR7,STAGE_COUNTER               ; for the remaining stages

K_ZERO_BK       .set    0            
K_TWID_TBL_SIZE .set    512                     ; Twiddle table size
K_DATA_IDX_1    .set    2                       ; Data index for Stage 1
K_DATA_IDX_2    .set    4                       ; Data index for Stage 2
K_DATA_IDX_3    .set    8                       ; Data index for Stage 3
K_FLY_COUNT_3   .set    4                       ; Butterfly counter for Stage 3
K_TWID_IDX_3    .set    128                     ; Twiddle index for Stage 3

	.sect ".scratch"
d_grps_cnt	.word	0
d_twid_idx	.word	0
d_data_idx	.word 	0

        .text

fft:       

; Stage 1 ----------------------------------------------------------------------

        STM     #K_ZERO_BK,BK                   ; BK=0 so that *ARn+0% == *ARn+0
        LD      #-1,ASM                         ; outputs div by 2 at each stage
        MVMM    DATA_PROC_BUF,PX                ; PX -> PR
        LD      *PX,16,A                        ; A  :=  PR
        STM     #fft_data+K_DATA_IDX_1,QX       ; QX -> QR
        STM     #K_FFT_SIZE/2-1,BRC
        RPTBD   stage1end-1
        STM     #K_DATA_IDX_1+1,AR0

        SUB     *QX,16,A,B                      ; B  :=  PR-QR
        ADD     *QX,16,A                        ; A  :=  PR+QR
        STH     A,ASM,*PX+                      ; PR':= (PR+QR)/2  
        ST      B,*QX+                          ; QR':= (PR-QR)/2
        ||LD    *PX,A                           ; A  :=  PI
        SUB     *QX,16,A,B                      ; B  :=  PI-QI
        ADD     *QX,16,A                        ; A  :=  PI+QI
        STH     A,ASM,*PX+0                     ; PI':= (PI+QI)/2
        ST      B,*QX+0%                        ; QI':= (PI-QI)/2 
        ||LD    *PX,A                           ; A  :=  next PR
stage1end:

; Stage 2 ----------------------------------------------------------------------

        MVMM    DATA_PROC_BUF,PX                ; PX -> PR
        STM     #fft_data+K_DATA_IDX_2,QX       ; QX -> QR
        STM     #K_FFT_SIZE/4-1,BRC
        LD      *PX,16,A                        ; A  :=  PR
        RPTBD   stage2end-1
        STM     #K_DATA_IDX_2+1,AR0

; 1st butterfly
        SUB     *QX,16,A,B                      ; B  :=  PR-QR 
        ADD     *QX,16,A                        ; A  :=  PR+QR
        STH     A,ASM,*PX+                      ; PR':= (PR+QR)/2  
        ST      B,*QX+                          ; QR':= (PR-QR)/2
        ||LD    *PX,A                           ; A  :=  PI
        SUB     *QX,16,A,B                      ; B  :=  PI-QI
        ADD     *QX,16,A                        ; A  :=  PI+QI
        STH     A,ASM,*PX+                      ; PI':= (PI+QI)/2
        STH     B,ASM,*QX+                      ; QI':= (PI-QI)/2 

; 2nd butterfly
        MAR     *QX+
        ADD     *PX,*QX,A                       ; A  :=  PR+QI
        SUB     *PX,*QX-,B                      ; B  :=  PR-QI
        STH     A,ASM,*PX+                      ; PR':= (PR+QI)/2  
        SUB     *PX,*QX,A                       ; A  :=  PI-QR
        ST      B,*QX                           ; QR':= (PR-QI)/2
        ||LD    *QX+,B                          ; B  :=     QR
        ST      A, *PX                          ; PI':= (PI-QR)/2
        ||ADD   *PX+0%,A                        ; A  :=  PI+QR
        ST      A,*QX+0%                        ; QI':= (PI+QR)/2
        ||LD    *PX,A                           ; A  :=  PR
stage2end:

; Stage 3 thru Stage logN-1 ----------------------------------------------------

        STM     #K_TWID_TBL_SIZE,BK             ; BK = twiddle table size always
        ST      #K_TWID_IDX_3,d_twid_idx        ; init index of twiddle table
        STM     #K_TWID_IDX_3,AR0               ; AR0 = index of twiddle table
        STM     #cosine,WR                      ; init WR pointer
        STM     #sine,WI                        ; init WI pointer
        STM     #K_LOGN-2-1,STAGE_COUNTER       ; init stage counter
        ST      #K_FFT_SIZE/8-1,d_grps_cnt      ; init group counter
        STM     #K_FLY_COUNT_3-1,BUTTERFLY_COUNTER  ; init butterfly counter
        ST      #K_DATA_IDX_3,d_data_idx        ; init index for input data
        
stage:
        STM     #fft_data,PX                    ; PX -> PR 
        LD      d_data_idx, A
        ADD     *(PX),A
        STLM    A,QX                            ; QX -> QR 
        MVDK    d_grps_cnt,GROUP_COUNTER        ; AR1 contains group counter

group:
        MVMD    BUTTERFLY_COUNTER,BRC           ; # of butterflies in each group
        RPTBD   butterflyend-1
        LD      *WR,T                           ; T  :=  WR
        MPY     *QX+,A                          ; A  :=  QR*WR  || QX->QI

        MACR    *WI+0%,*QX-,A                   ; A  :=  QR*WR+QI*WI  
                                                ; || QX->QR
        ADD     *PX,16,A,B                      ; B  := (QR*WR+QI*WI)+PR
        ST      B,*PX                           ; PR':=((QR*WR+QI*WI)+PR)/2
        ||SUB   *PX+,B                          ; B  :=  PR-(QR*WR+QI*WI)    
                                                ; || PX->PI
        ST      B,*QX                           ; QR':= (PR-(QR*WR+QI*WI))/2
        ||MPY   *QX+,A                          ; A  :=  QR*WI [T=WI]
                                                ; || QX->QI 
        MASR    *QX,*WR+0%,A                    ; A  :=  QR*WI-QI*WR
        ADD     *PX,16,A,B                      ; B  := (QR*WI-QI*WR)+PI
        ST      B,*QX+                          ; QI':=((QR*WI-QI*WR)+PI)/2 
                                                ; || QX->QR          
        ||SUB   *PX,B                           ; B  :=  PI-(QR*WI-QI*WR)
        LD      *WR,T                           ; T  :=  WR
        ST      B,*PX+                          ; PI':= (PI-(QR*WI-QI*WR))/2 
                                                ; || PX->PR
        ||MPY   *QX+,A                          ; A  :=  QR*WR  || QX->QI
butterflyend:

; Update pointers for next group

        PSHM    AR0                             ; preserve AR0
        MVDK    d_data_idx,AR0
        MAR     *PX+0                           ; increment PX for next group
        MAR     *QX+0                           ; increment QX for next group
        BANZD   group,*GROUP_COUNTER-
        POPM    AR0                             ; restore AR0
        MAR     *QX-

; Update counters and indices for next stage

        LD      d_data_idx,A
        SUB     #1,A,B                          ; B = A-1
        STLM    B,BUTTERFLY_COUNTER             ; BUTTERFLY_COUNTER = #flies-1
        STL     A,1,d_data_idx                  ; double the index of data
        LD      d_grps_cnt,A
        STL     A,ASM,d_grps_cnt                ; 1/2 the offset to next group  
        LD      d_twid_idx,A
        STL     A,ASM,d_twid_idx                ; 1/2 the index of twiddle table
        BANZD   stage,*STAGE_COUNTER-
        MVDK    d_twid_idx,AR0                  ; AR0 = index of twiddle table

fft_end:
        RET                                     ; return to Real FFT main module

