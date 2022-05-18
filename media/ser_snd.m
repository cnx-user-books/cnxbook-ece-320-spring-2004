% wrt_slid: write values of sliders out to com port

% open com port for data transfer
fid = fopen('com2:','w');

% send data from each slider
v = round(get(sld1,'value'));
fwrite(fid,v,'int8');
disp(['Setting rate change to ',num2str(v)])

% close com port connection
fclose(fid);


