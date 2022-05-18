%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Matlab code skeleton for Digital Transmitter

close all;clear;

% Generate random bits
bits_per_symbol=2;
num_symbols=64;
numbits=bits_per_symbol*num_symbols;
bits=rand(1,numbits)>0.5;

Tsymb=32;           % samples per symbol


% These are the 4 frequencies to choose from                    
% Note that 32 samples per symbol does not correspond to 
% an integer number of periods at these frequencies
omega1 =  9*pi/32;
omega2 = 13*pi/32;
omega3 = 17*pi/32;
omega4 = 21*pi/32;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Transmitter section

% Initialize transmit sequence
index=1;			% Initialize bit index
n=1;				% Initialize sample index
phi=0;				% Initialize phase offset

% Generate 64 32-sample symbols
while (n<=num_symbols*Tsymb)
    
  if (bits(index:index+1) == [0 0])
     sig(n:n+Tsymb-1) = sin(omega1*[0:Tsymb-1]+phi);   
     phi = omega1*Tsymb+phi;	% Calculate phase offset for next symbol
     phi = mod(phi, 2*pi);	% Restrict phi to [0,2*pi)
          
 % -----------> Insert code here <-------------%
     
  end % end if-else statements
   
  index=index+2; % increment bit counter so we look at next 2 bits
    
  n=n+Tsymb;
end   % end while


% Show transmitted signal and its spectrum
% ---------------> Insert code here <-----------------%
