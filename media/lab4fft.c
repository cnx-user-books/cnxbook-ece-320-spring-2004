/*****************************************************************/
/* lab4fft.c                                                     */
/* Douglas L. Jones                                              */
/* University of Illinois at Urbana-Champaign                    */
/* January 19, 1992                                              */
/* Changed for use w/ short integers and lookup table for ECE420 */
/* Matt Kleffner                                                 */
/* February 10, 2004                                             */
/*                                                               */
/*   fft: in-place radix-2 DIT DFT of a complex input            */
/*                                                               */
/*   Permission to copy and use this program is granted          */
/*   as long as this header is included.                         */
/*                                                               */
/* WARNING:                                                      */
/*   This file is intended for educational use only, since most  */
/*   manufacturers provide hand-tuned libraries which typically  */
/*   include the fastest fft routine for their DSP/processor     */
/*   architectures. High-quality, open-source fft routines       */
/*   written in C (and included in MATLAB) can be found at       */
/*   http://www.fftw.org                                         */
/*                                                               */
/*   #defines expected in lab4.h                                 */
/*         N:   length of FFT: must be a power of two            */
/*      logN:   N = 2**logN                                      */
/*                                                               */
/*   16-bit-limited input/output (must be defined elsewhere)     */
/*   real:   integer array of length N with real part of data    */
/*   imag:   integer array of length N with imag part of data    */
/*                                                               */
/*   sinetables.h must                                           */
/*   1) #define Nt to an equal or greater power of two than N    */
/*   2) contain the following integer arrays with                */
/*      element magnitudes bounded by M = 2**15-1:               */
/*         costable:   M*cos(-2*pi*n/Nt), n=0,1,...,Nt/2-1       */
/*         sintable:   M*sin(-2*pi*n/Nt), n=0,1,...,Nt/2-1       */
/*                                                               */
/*****************************************************************/

#include "lab4.h"
#include "sinetables.h"

extern int real[N];
extern int imag[N];

void fft(void)
{
   int   i,j,k,n1,n2,n3;
   int   c,s,a,t,Wr,Wi;

   j = 0;            /* bit-reverse */
   n2 = N >> 1;
   for (i=1; i < N - 1; i++)
   {
      n1 = n2;
      while ( j >= n1 )
      {
         j = j - n1;
         n1 = n1 >> 1;
      }
      j = j + n1;

      if (i < j)
      {
         t = real[i];
         real[i] = real[j];
         real[j] = t;
         t = imag[i];
         imag[i] = imag[j];
         imag[j] = t;
      }
   }

   /* FFT */
   n2 = 1; n3 = Nt;

   for (i=0; i < logN; i++)
   {
      n1 = n2;      /* n1 = 2**i     */
      n2 = n2 + n2; /* n2 = 2**(i+1) */
      n3 = n3 >> 1; /* cos/sin arg of -6.283185307179586/n2 */
      a = 0;

      for (j=0; j < n1; j++)
      {
         c = costable[a];
         s = sintable[a];
         a = a + n3;

         for (k=j; k < N; k=k+n2)
         {
            /* Code for standard 32-bit hardware, */
            /* with real,imag limited to 16 bits  */
            /*
            Wr = (c*real[k+n1] - s*imag[k+n1]) >> 15;
            Wi = (s*real[k+n1] + c*imag[k+n1]) >> 15;
            real[k+n1] = (real[k] - Wr) >> 1;
            imag[k+n1] = (imag[k] - Wi) >> 1;
            real[k] = (real[k] + Wr) >> 1;
            imag[k] = (imag[k] + Wi) >> 1;
            */
            /* End standard 32-bit code */

            /* Code for TI TMS320C54X series */

            Wr = ((long int)(c*real[k+n1]) - (long int)(s*imag[k+n1])) >> 15;
            Wi = ((long int)(s*real[k+n1]) + (long int)(c*imag[k+n1])) >> 15;
            real[k+n1] = ((long int)real[k] - (long int)Wr) >> 1;
            imag[k+n1] = ((long int)imag[k] - (long int)Wi) >> 1;
            real[k] = ((long int)real[k] + (long int)Wr) >> 1;
            imag[k] = ((long int)imag[k] + (long int)Wi) >> 1;

            /* End code for TMS320C54X series */

            /* Intrinsic code for TMS320C54X series */
            /*
            Wr = _ssub(_smpy(c, real[k+n1]), _smpy(s, imag[k+n1]));
            Wi = _sadd(_smpy(s, real[k+n1]), _smpy(c, imag[k+n1]));
            real[k+n1] = _sshl(_ssub(real[k], Wr),-1);
            imag[k+n1] = _sshl(_ssub(imag[k], Wi),-1);
            real[k] = _sshl(_sadd(real[k], Wr),-1);
            imag[k] = _sshl(_sadd(imag[k], Wi),-1);
            */
            /* End intrinsic code for TMS320C54X series */
         }
      }
   }
   return;
}
