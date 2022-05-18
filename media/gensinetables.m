
% Creates table of twiddle factors for the C FFT used in UIUC's ECE320

% Written by:
% Matt Kleffner   4/28/04
% Licensed under the
% Creative Commons Attribution License

clear all;

N=1024;
Nby2=N/2;
elemperline=8;
lines=round(Nby2/elemperline);
q=[0:(Nby2-1)];

c = cos(-2*pi*q/N);
c = round(real(c(:))*32768);
c = c - (c > 32767);
c = c + (c < -32767);
s = sin(-2*pi*q/N);
s = round(real(s(:))*32768);
s = s - (s > 32767);
s = s + (s < -32767);

nextline='\\\n';
fid=fopen('sinetables.h','wt');

fprintf(fid,['#define Nt ' num2str(N) '\n\n']);

% cosine table
fprintf(fid,'int costable[]={ \\\n');
for r=1:(lines-1)
   idc=((r-1)*elemperline+1):(r*elemperline);
   fprintf(fid,'%6i, ', c(idc));
   fprintf(fid,nextline);
end

% last element isn't followed by a comma
idc=((lines-1)*elemperline+1):(lines*elemperline-1);
fprintf(fid, '%6i, ', c(idc));
fprintf(fid, '%6i  ', c(lines*elemperline));
fprintf(fid, nextline);
fprintf(fid, ['};\n\n']);

% sine table
fprintf(fid,'int sintable[]={ \\\n');
for r=1:(lines-1)
   idc=((r-1)*elemperline+1):(r*elemperline);
   fprintf(fid,'%6i, ', s(idc));
   fprintf(fid,nextline);
end

% last element isn't followed by a comma
idc=((lines-1)*elemperline+1):(lines*elemperline-1);
fprintf(fid, '%6i, ', s(idc));
fprintf(fid, '%6i  ', s(lines*elemperline));
fprintf(fid, nextline);
fprintf(fid, ['};\n']);

fclose(fid);
