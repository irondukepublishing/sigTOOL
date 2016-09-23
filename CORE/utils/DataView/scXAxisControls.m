function h=scXAxisControls(parent, MaxTime)
% scXAxisControls creates data view x-axis controls
% 
% Example:
% scXAxisControls(Panel, MaxTime)
%           Panel is the sigTOOL data view or uipanel handle 
%           MaxTime is the maximum time in the data file
%
%
% -------------------------------------------------------------------------
% Author: Malcolm Lidierth 11/06
% Copyright © The Author & King's College London 2006-
% -------------------------------------------------------------------------

% LF=javax.swing.UIManager.getLookAndFeel();
% javax.swing.UIManager.setLookAndFeel('javax.swing.plaf.metal.MetalLookAndFeel');

desc=scGetFigureType(parent);

icons=[scGetBaseFolder() 'CORE' filesep 'icons' filesep];

% X-Axis slider control
axh=getappdata(parent, 'AxesList');
% 30.06.2016 Add cast
axh=axh(double(axh)>0);
set(axh(end),'Units','pixels');
p=get(axh(end),'position');
set(axh(end), 'Units', 'normalized');
XLim=get(axh(end),'XLim');
% XRange=XLim(2)-XLim(1);

AxesPanel=findobj(parent, 'Tag', 'sigTOOL:TabPanel');
if isempty(AxesPanel)
    AxesPanel=findobj(parent, 'Tag', 'sigTOOL:AxesPanel');
end

set(AxesPanel, 'Units', 'pixels');
pos=get(AxesPanel, 'Position');

h.Panel=uipanel(parent, 'Units', 'pixels',...
    'Position', [pos(1),0,pos(3),35],...
    'Background', [1 0 0],...
    'ForegroundColor', [64 64 122]/255,... 
    'HighlightColor', [64 64 122]/255,...    
    'Tag', 'sigTOOL:XAxisControls');

set(AxesPanel, 'Units', 'normalized');
set(h.Panel, 'Units', 'normalized');

% Slider
sliderpos=[p(1) 10 p(3) 20];
h.Slider=jcontrol(h.Panel,'javax.swing.JScrollBar',...
    'Units','pixels',...
    'Position', sliderpos,...
    'Orientation', 0,...
    'Minimum',XLim(1)*1000,...
    'Maximum',MaxTime*1000,...
    'UnitIncrement', 1000,...
    'BlockIncrement', 10000,...
    'ToolTipText','Move through data',...
    'Tag',[desc 'XSlider'],...
    'AdjustmentValueChangedCallback',{@scSliderAct},...
    'Value',XLim(1)*1000);
set(h.Slider, 'Units', 'normalized');


% X-Axis minimum editable text control
xminT=[sliderpos(1)-51 sliderpos(2) 50 sliderpos(4)];
h.MinText=jcontrol(h.Panel,'javax.swing.JTextField',...
    'Units','pixels',...
    'Position',xminT,...
    'Text','0.0',...
    'ToolTipText','Set axis minumum',...
    'ActionPerformedCallback',@xmin,...
    'Tag',[desc 'XMin']);
set(h.MinText,'Units','character');
hpos=get(h.MinText,'Position');
set(h.MinText,'Position',[hpos(1) hpos(2) 7 1.5]);
set(h.MinText,'Units','normalized');

%'Position',[pos(1)-0.04,max(0,pos(2)-0.05),0.08,0.025]);

% X-Axis maximum editable text control
xmaxT=[sliderpos(1)+sliderpos(3) sliderpos(2) 50 sliderpos(4)];
h.MaxText=jcontrol(h.Panel,'javax.swing.JTextField',...
    'Text','1.0',...
    'Units','pixels',...
    'Position', xmaxT,...
    'ToolTipText','Set axis maximum',...
    'ActionPerformedCallback',@xmax,...
    'Tag',[desc 'XMax']);
set(h.MaxText,'Units','character');
hpos=get(h.MaxText,'Position');
set(h.MaxText,'Position',[hpos(1)-7 hpos(2) 7 1.5]);
set(h.MaxText,'Units','normalized');

%set(h,'Position',[pos(1)+pos(3)-0.04,max(0,pos(2)-0.05),0.08,0.025]);

% % X-Axis increase XRange control button
C=javax.swing.ImageIcon([icons 'IncreaseXRange.gif']);
upButton=[xminT(1)-25 sliderpos(2) 25 sliderpos(4)];
h.IncreaseRange=jcontrol(h.Panel,'javax.swing.JButton',...
    'Units','pixels',...
    'Position',upButton,...
    'Icon',C,...
    'ToolTipText','Increase X axis XRange',...
    'MousePressedCallback',@scIncreaseXRange,...
    'Tag',[desc 'IncreaseXRange']);
set(h.IncreaseRange,'Units','normalized');

% X-Axis reduce XRange control button
C=javax.swing.ImageIcon([icons 'DecreaseXRange.gif']);
downButton=[xminT(1)-50 sliderpos(2) 25 sliderpos(4)];
h.ReduceRange=jcontrol(h.Panel, 'javax.swing.JButton',...
    'Units','pixels',...
    'Position',downButton,...
    'Icon',C,...
    'ToolTipText','Decrease X axis XRange',...
    'MousePressedCallback',@scReduceXRange,...
    'Tag',[desc 'ReduceXRange']);
set(h.ReduceRange,'Units','normalized');

setappdata(parent, 'XAxisControls', h)

return
end

%--------------------------------------------------------------------------
function xmin(hObject, EventData)
%--------------------------------------------------------------------------
% Callback for axis minimum text box
fhandle=ancestor(get(hObject,'hghandle'),'figure');
if isempty(fhandle)
    % Being deleted
    return
end
AxesList=getappdata(fhandle,'AxesList');
AxesList=AxesList(AxesList~=0);
XLim=get(AxesList(1),'XLim');
XRange=XLim(2)-XLim(1);

XLim(1)=str2double(get(hObject,'Text'));
if isnan(XLim(1))
    return
end
if XLim(2)<=XLim(1)
    XLim(2)=XLim(1)+XRange;
end
set(AxesList,'XLim',XLim);

% Update axis controls
scUpdateAxisControls(fhandle, 'xmin');
end

%--------------------------------------------------------------------------
function xmax(hObject, EventData)
%--------------------------------------------------------------------------
% Callback for axis maximum text box
fhandle=ancestor(get(hObject,'hghandle'),'figure');
if isempty(fhandle)
    % Being deleted
    return
end
AxesList=getappdata(fhandle,'AxesList');
AxesList=AxesList(AxesList~=0);
XLim=get(AxesList(1),'XLim');
XRange=XLim(2)-XLim(1);

XLim(2)=str2double(get(hObject,'Text'));
if isnan(XLim(2))
    return
end
if XLim(2)<=XLim(1)
    XLim(1)=XLim(2)-XRange;
end
set(AxesList,'XLim',XLim);

% Update axis controls
scUpdateAxisControls(fhandle, 'xmax');
end
