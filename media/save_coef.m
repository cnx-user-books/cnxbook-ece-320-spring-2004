function save_coef_ti(f_name, x)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% inputs :
%           f_name      desired output filename
%                       (Matlab string)
%
%           x           coefficients
%                       (real column vector)
%
% example:   save_coef_ti('my_coef.asm',h)
%
% Note that when saving FIR coefficients to
%   a file used in a FIR implementation on 
%   the TI processors you must save them
%   in reverse order (last coefficient first)
%   This can be done using the example
%
% example:   save_coef_ti('my_coef.asm',flipud(h(:)))

if( max(abs(x)) > 1 )
   error('X must be not contain any numbers outside [-1, 1]');
end

% make sure x is real and a column vector
x = round(real(x(:))*32768);
x = x - (x > 32767);
 
% open file
fid = fopen(f_name,'w');
 
% save coefficients in decimal rep.
for i = 1:length(x)
  fprintf(fid,'        .word      %i\n',x(i));
end
 
fclose(fid);

