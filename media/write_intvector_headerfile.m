function write_intvector_headerfile(v, name, elemperline)

% function write_intvector_headerfile(v, name, elemperline)
%
%           v: Vector to write, where |v|<1
%
%        name: Name of file and vector, i.e.
%
%                 name.h is created containing:
%
%                 int name[]={ V };
%
%                 where V is v converted to 16-bit integers
%
% elemperline: Number of vector elements per line

% Written by:
% Matt Kleffner   4/28/04
% Licensed under the
% Creative Commons Attribution License

v = round(real(v(:))*32768);
v = v - (v > 32767);
v = v + (v < -32767);

N=length(v); vmax=max(v); vmin=min(v);

vmaxdigits=ceil(log10(abs(vmax)))+(vmax<0);
vmindigits=ceil(log10(abs(vmin)))+(vmin<0);
maxdigits=max(vmaxdigits,vmindigits);

lines=round(N/elemperline);
nextline='\\\n';
printstr=['%' num2str(maxdigits) 'i, '];
lastprintstr=['%' num2str(maxdigits) 'i  '];

fid=fopen([name '.h'],'wt');
fprintf(fid, ['int ' name '[]={ ' nextline]);

for r=1:(lines-1)
   idc=((r-1)*elemperline+1):(r*elemperline);
   fprintf(fid, printstr, v(idc));
   fprintf(fid, nextline);
end

% last element isn't followed by a comma
idc=((lines-1)*elemperline+1):(lines*elemperline-1);
fprintf(fid, printstr, v(idc));
fprintf(fid, lastprintstr, v(lines*elemperline));
fprintf(fid, nextline);
fprintf(fid, ['};\n']);

fclose(fid);
