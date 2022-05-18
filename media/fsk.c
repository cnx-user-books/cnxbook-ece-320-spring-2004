/* ECE320, Lab 5, Reference Implementation (Non-Optimized) */
/* Michael Frutiger 2/24/04 */

#include "v:/ece320/54x/dspclib/core.h"   /* Declarations for core file */

main()
{
    int *Rcvptr,*Xmitptr;                 /* pointers to Xmit & Rcv Bufs   */
    int r1,r2;      // temp random bit storage
    int symbol;		// 0 for [00], 1 for [01], 2 for [10], 3 for [11]
    int n;          // dummy variable

    int freqs[4] = {9, 13, 21, 17};     // 32*freqs
    int phase[32];
    int output[64];                     // temp output storage      


    // Initial PN generator register contents
    int seed = 1;

    // Initial phase
    int prev_phase = 0;      

        
    while( 1 )
    {   
    	/* Wait for a new block of samples */
    	WaitAudio(&Rcvptr,&Xmitptr);
    	
        // Get next two random bits
		r1 = randbit( &seed );
		r2 = randbit( &seed );
		// Convert 2 bit binary number to decimal 
		symbol = series2parallel(r1,r2);

		for (n=0; n<32; n++)
		{
 			phase[n] = ( freqs[symbol]*n + prev_phase ) % 64;   // get into 0 to 64 range 
 			if (phase[n] > 32) phase[n]=phase[n]-64;            // get into -32 to 32 range
			phase[n] = phase[n] * 1024;                         // 1024=2^15*1/32
			                                                    // [-2^15 2^15] range for use with
			                                                    // SINE.asm     
		}
		sine(&phase[0], &output[0], 32);		// compute SINE, put result in output[0 - 31]
		prev_phase = ( freqs[symbol]*32 + prev_phase ) % 64; 	// save current phase offset
   	
  		// Get next two random bits
		r1 = randbit( &seed );
		r2 = randbit( &seed ); 
		// Convert 2 bit binary number to decimal
		symbol = series2parallel(r1,r2);

		for (n=0; n<32; n++)
		{                   
			phase[n] = ( freqs[symbol]*n + prev_phase ) % 64; 
			if (phase[n] > 32) phase[n]=phase[n]-64; 
			phase[n] = phase[n] * 1024;
		}
		sine(&phase[0], &output[32], 32);
		prev_phase = ( freqs[symbol]*32 + prev_phase ) % 64;

	
		// Transfer the two symbols to transmit buffer
		for (n=0; n<64; n++)
		{
			Xmitptr[6*n] = output[n];
		}	
	
    }    
}


// Converts 2 bit binary number (r2r1) to decimal
int series2parallel(int r2, int r1)
{
	if ((r2==0)&&(r1==0)) return 0;
	else if ((r2==0)&&(r1==1)) return 1;
	else if ((r2==1)&&(r1==0)) return 2;
	else return 3;
}

//Returns as an integer a random bit, based on the 15 low-significance bits in iseed (which is
//modified for the next call).
int randbit(unsigned int *iseed)
{
	unsigned int newbit; // The accumulated XORs.
	newbit =  (*iseed >> 14) & 1 ^ (*iseed >> 13)  & 1;  // XOR bit 15 and bit 14
	// Leftshift the seed and put the result of the XOR’s in its bit 1.
	*iseed=(*iseed << 1) | newbit;  
	return (int) newbit;
};
