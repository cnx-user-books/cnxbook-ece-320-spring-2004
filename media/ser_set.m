% ser_set: Initialize serial port and create three sliders

% Set serial port mode
!mode com2:38400,n,8,1

% open a blank figure for the slider
Fig = figure(1);

% open sliders

%  first slider
sld1 = uicontrol(Fig,'units','normal','pos',[.2,.7,.5,.05],...
 'style','slider','value',4,'max',254,'min',0,'callback','wrt_slid');

%  second slider
sld2 = uicontrol(Fig,'units','normal','pos',[.2,.5,.5,.05],...
 'style','slider','value',4,'max',254,'min',0,'callback','wrt_slid');

%  third slider
sld3 = uicontrol(Fig,'units','normal','pos',[.2,.3,.5,.05],...
 'style','slider','value',4,'max',254,'min',0,'callback','wrt_slid');


