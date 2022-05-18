% ser_set: Initialize serial port and create a slider to set
%  the rate change factor (down and upsampling rates)

% Set serial port mode
!mode com2:38400,n,8,1

% open a blank figure for the slider
Fig = figure(1);


% create slider
sld1 = uicontrol(Fig,'units','normal','pos',[.3,.7,.5,.05],...
 'style','slider','value',4,'max',10,'min',1,'callback','ser_snd');

% add text to figure
txt = uicontrol(Fig,'units','normal','pos',[.3,.8,.4,.05],'String', ...
      'Decimation / interpolation rate adjustment');

txt_min = uicontrol(Fig,'units','normal','pos',[.2,.63,.15,.05],'String', ...
      'min D=U=1');

txt_max = uicontrol(Fig,'units','normal','pos',[.7,.63,.15,.05],'String', ...
      'max D=U=10');


