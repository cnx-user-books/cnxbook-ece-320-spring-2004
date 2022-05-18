% wrt_slid: write values of sliders out to com port

% open com port for data transfer
fid = fopen('com2:','w');

% send data from each slider
v = round(get(sld1,'value'));
fwrite(fid,v,'int8');

v = round(get(sld2,'value'));
fwrite(fid,v,'int8');

v = round(get(sld3,'value'));
fwrite(fid,v,'int8');

% send reset pulse
fwrite(fid,255,'int8');

% close com port connection
fclose(fid);
