% save_test_vector(file, left, right)
% 
% Save a test vector include file based on the left-input and
% right-input vectors given. If 'right' is omitted, the same
% input is sent to both the left and right channels.

function save_test_vector(file, left, varargin)

if nargin==3 
  right=varargin{1};
else
  right=left;
end

if length(left) ~= length(right) 
  disp('Left and right vector length mismatch')
else
  fid = fopen(file, 'wt');
  fprintf(fid,' .global tv_inbuf\n');
  fprintf(fid,' .global tv_outbuf\n');
  fprintf(fid,' .global tv_count_addr\n');
  fprintf(fid,'tv_count .set %i\n',length(left));
  x = zeros(length(left)*2,1);
  x(1:2:2*length(left)) = left;
  x(2:2:2*length(left)) = right;
  fprintf(fid,' .sect ".etext"\n');
  fprintf(fid,'tv_outbuf\n');
  fprintf(fid,' .space 16*%i\n',6*length(left));
  fprintf(fid,'tv_inbuf\n');
  x = round(x*32768);
  x = x - (x > 32767);
  fprintf(fid,' .word %i\n',x);
  fprintf(fid,' .sect ".data"\n');
  fprintf(fid,'tv_count_addr .word %i\n',length(left));
  fclose(fid);
end
