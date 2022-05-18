;FM transmition code for use with the 6 channel surround sound card.  This code uses
;a modified version of the core.asm code, called core_mod.asm.  The modified core code
;uses the serial port in non-buffered mode.  This means that the program handles the 
;incoming data sample by sample as the samples arrive.  This is done so that the timing 
;information is preserved.
;Programmers: J. Golat, D. Patel, E. Stauffer
;May 1, 2001

	.copy "core_mod.asm"
	.sect ".data" 
dds_data       .word 0
audiosamp      .word 0
scaled         .word 0

	
	.sect ".text"
	

 
main
     ; initialize here
     call radioinit   ;reset the dds chip
     call setcarrier  ;set the carrier to 104.9MHz

loop
	nop    ;Do nothing while we are waiting for the serial receive iterrupt
	nop    ;All the work is done in ANALOG_IFC, which calls handle_sample
	nop
        
    	b 	loop	
        
        ;Here is where all the work is done.  Take a sample from the serial
	;port, scale it, and add an offset and output it to the dds.  Note that
	;this will take input from one of the inputs on the 6 channel card.
        
handle_sample:
	ldm  BDRR0, B	      ;reading sample    
	    					
        stl  B,*(audiosamp)   ;put it in memory
                
  
	
	stl  B, BDXR0         ;output it to the 6-channel card
	        
        ld    #0,A           ;set A to zero for mac
		 
	mac   *(audiosamp),#0Ah,A ;mulitply by #ah and store accum in A
	 
	stl   A,*(scaled)
	sfta  A,-12,A      ;shift to the right
	add   #6Dh,A       ;at the center of the carrier
	stl   A,*(dds_data)

	portw *(dds_data),10000101b   ;output the data to the dds
	ret
	
	

radioinit: 
 	;initalize the DDS
	ld    #1,A
	stl   A,*(dds_data)
	portw *(dds_data),11000000b   ;set reset high
	
	;d0=1 written to address 11xxxxxx will set the dds reset pin to high
	
	rpt 	#0ffffh  ;Wait for the reset to occur
	nop 

    	call  nullop   ;the reset pin needs to be high for a long time
	              
	ld    #0,A
	stl   A,*(dds_data)
	portw *(dds_data),11000000b   ;set reset low for normal operation
	
	;d0=0 written to 11xxxxxx will set the dds reset pin to low
	
	;turn off the inverse sinc
	ld   #40h,A    ;look at the dds register map in the datasheet
	stl   A,*(dds_data)
	portw *(dds_data),10100000b 
        ;all writes to the dds registers are done by writting to
        ;10xxxxxx where the lower six bits correspond to the 6 bits
        ;of the dds register address.
	
	call nullop  
	
	
	ret       

setcarrier:    

	;set the carrier center
	ld   #40h,A                 ;104.9 @60MHz clock
	stl   A,*(dds_data)
	portw *(dds_data),10000100b ;the most significant freq register  

	
	call nullop   	; Waste CPU time since the dds card doesn't 
			; like it when you make two consecutive writes. 
        nop
	
	ld   #06Dh,A
	stl   A,*(dds_data)
	portw *(dds_data),10000101b ;second most significant freq register
	call nullop
	nop   
    
	ret
        
