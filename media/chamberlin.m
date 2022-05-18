%Qc = 0.0625;
%Fc = min([1/Qc, 2-Qc, 2/Qc - Qc, (-Qc+(8+Qc^2)^0.5)/2]); 
%Fc = 1e-1;

Qc = 1/1.2
M = 4;
FC = linspace(0.2,0.5,M)
for i = 1:M
  Fc = FC(i);
  a = [1 -(2- Fc*Qc- Fc^2) (1- Fc*Qc)];
  plot([1:512]*pi/512, abs(freqz(1,a))); hold on; pause;
end;
xlabel('frequency'); ylabel('magnitude');
gtext('F_c = 0.2');
gtext('F_c = 0.3');
%print -deps chamberlinFc.eps


Fc = 0.3;
M = 4;
QC = linspace(0.5,2,4);
for i = 1:M
  Qc = QC(i);
  a = [1 -(2- Fc*Qc- Fc^2) (1- Fc*Qc)];
  plot([1:512]*pi/512, abs(freqz(1,a))); hold on; pause;
end;
xlabel('frequency'); ylabel('magnitude');
gtext('Q_c = 0.5');
gtext('Q_c = 1.0');
print -deps chamberlinQc.eps


format long; a
aq = round(a*32768)/32768;
freqz(1,aq);
freqz(1,conv(conv(aq,aq),aq));

Gain_in = 0.5;
numfreq = 5;
N = 10000;
L = linspace(0,1e-2,numfreq);
Y = zeros(numfreq,N);
X = Y;

for i = 1:numfreq
 x = Gain_in*sin(L(i)*[1:N]);
 X(i,:) = x;
 hp = zeros(1,N); bp=hp; y=hp;
 for n = 2:N
   hp(n) = x(n) - y(n) - bp(n)*Qc;
   bp(n) = hp(n-1)*Fc + bp(n-1);
   y(n) = bp(n)*Fc + y(n-1);
 end;
 Y(i,:) = y;
end;

plot(Y');
hold on;
plot(X');
