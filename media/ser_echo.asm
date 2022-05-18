	.copy "v:\54x\dsplib\core.asm"

	.sect ".data"
hold	.word 0
                
	.sect ".text"
main
	stm #hold,AR3      	; Read to hold location
	 
	READSER 1		; Read one byte from serial port
	 
	cmpm AR1,#1		; Did we get a character?
	bc main,NTC		; if not, branch back to start
	 
	stm #hold,AR3		; Write from hold location
	WRITSER 1		; ... one byte
	 
	b main
