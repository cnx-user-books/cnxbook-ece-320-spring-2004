bit_rev:
        STM     #_bit_rev_data,AR3          ; AR3 -> original input
        STM     #_fft_data,AR7              ; AR7 -> data processing buffer
        MVMM    AR7,AR2                     ; AR2 -> bit-reversed data
        STM     #K_FFT_SIZE-1,BRC
        RPTBD   bit_rev_end-1
        STM     #K_FFT_SIZE,AR0             ; AR0 = 1/2 size of circ buffer
        MVDD    *AR3+,*AR2+
        MVDD    *AR3-,*AR2+
        MAR     *AR3+0B
bit_rev_end:
        NOP
        RET