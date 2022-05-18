/* v:/ece420/54x/dspclib/lab4main.c */
/* dgs - 9/14/2001                  */
/* mdk - 2/10/2004   C FFT update   */

#include "v:/ece420/54x/dspclib/core.h"    

/* comment the next line to use assembly fft */
#define C_FFT

#ifdef C_FFT /* Use C FFT */

   #include "window.h"
   #include "lab4.h" /* Number of C FFT points defined here */

   /* function defined in lab4fft.c */
   void fft(void);

   /* FFT data buffers */
   int real[N]; /* Real part of data      */
   int imag[N]; /* Imaginary part of data */

#else        /* Use assembly FFT */

   #define N 1024   /* Number of assembly FFT points */

   /* Function defined by c_fft_given.asm */            
   void bit_rev_fft(void);

   /* FFT data buffers (declared in c_fft_given.asm) */
   extern int bit_rev_data[N*2]; /* Data input for bit-reverse function */
   extern int fft_data[N*2];     /* In-place FFT & Output array         */
   extern int window[N];         /* The Hamming window                  */

#endif       /* C_FFT */


/* Our input/output buffers */
int inputs[N];
int outputs[N];

volatile int input_full = 0;	/* volatile means interrupt changes it */
int count = 0;


interrupt void irq(void)
{
  int *Xmitptr,*Rcvptr;                      /* pointers to Xmit & Rcv Bufs   */
  int i;                
  
  static int in_irq = 0;		     /* Flag to prevent reentrance */
           
  /* Make sure we're not in the interrupt (should never happen) */
  if( in_irq )
    return;
  	     
  /* Mark we're processing, and enable interrupts */
  in_irq = 1;
  enable_irq();
  
  /* The following waitaudio call is guaranteed not to 
     actually wait; it will simply return the pointers. */
  WaitAudio(&Rcvptr,&Xmitptr); 		

  /* input_full should never be true... */  
  if( !input_full )
  {
    for (i=0; i<BlockLen; i++)
    {
      /* Save input, and echo to channel 1 */
      inputs[count] = Xmitptr[6*i] = Rcvptr[4*i];            
      
      /* Send FFT output to channel 2 */
      Xmitptr[6*i+1] = outputs[count];
                                              
      count++;      
    }
  } 

  /* Have we collected enough data yet? */  
  if( count >= N )
    input_full = 1;
             
  /* We're not in the interrupt anymore... */             
  disable_irq();
  in_irq = 0;
}


main()
{
  /* Initialize IRQ stuff */
  count = 0;
  input_full = 0;  	                 
  SetAudioInterrupt(irq);       	/* Set up interrupts */
  
  while (1)
  {   
    while( !input_full );		/* Wait for a data buffer to collect */
        
    /* From here until we clear input_full can only take *
     * BlockLen sample times, so don't do too much here. */
     
    /* First, transfer inputs and outputs */

#ifdef C_FFT /* Use C FFT */
    /* I n s e r t   c o d e   t o   f i l l   */
    /* C   F F T   b u f f e r s               */

#else        /* Use assembly FFT */
    /* I n s e r t   c o d e   t o   f i l l   */
    /* a s s e m b l y   F F T   b u f f e r s */

#endif       /* C_FFT */

    /* Done with that... ready for new data collection */
    count = 0;      /* Need to reset the count                */
    input_full = 0; /* Mark we're ready to collect more data  */

    /**********************************************************/
    /* Now that we've gotten the data moved, we can do the    */
    /* more lengthy processing.                               */

#ifdef C_FFT /* Use C FFT */

    /* Multiply the input signal by the Hamming window.       */
    /* . . . i n s e r t   C / a s m   code . . .             */

    /* Bit-reverse and compute FFT in C                       */
    fft();

    /* Now, take absolute value squared of FFT                */
    /* . . . i n s e r t   C / a s m   code . . .             */

    /* Last, set the DC coefficient to -1 for a trigger pulse */
    /* . . . i n s e r t   C / a s m   code . . .             */

    /* done, wait for next time around!                       */


#else        /* Use assembly FFT */

    /* Multiply the input signal by the Hamming window.       */
    /* . . . i n s e r t   C / a s m   code . . .             */

    /* Bit-reverse and compute FFT in assembly                */
    bit_rev_fft();

    /* Now, take absolute value squared of FFT                */
    /* . . . i n s e r t   C / a s m   code . . .             */

    /* Last, set the DC coefficient to -1 for a trigger pulse */
    /* . . . i n s e r t   C / a s m   code . . .             */

    /* done, wait for next time around!                       */


#endif       /* C_FFT */
    
  }                 
}
