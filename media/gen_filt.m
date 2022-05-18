
function h = gen_filt

% script to randomly generate a filter for testing

r = rand(1);

if (r<.2)
  h = fir1(7,[.2,.5]);
end

if ((r>.2) & (r<.4))
  h = fir1(7,[.5,.7]);
end

if ((r>.4) & (r<.6))
  h = fir1(6,[.2,.5],'stop');
  h = [h,0];
end

if ((r>.6) & (r<.8))
  h = fir1(6,[.2,.7],'stop');
  h = [h,0];
end

if (r>.8)
  h = fir1(6,.5,'high');
  h = [h,0];
end

h = h/max(abs(freqz(h)));		% normalize to ensure | H(z) | <= 1

h = h';
