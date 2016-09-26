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

% Axis control panel
h.Panel=uipanel(parent, 'Units', 'pixels',...
    'Position', [pos(1)+2, 1, pos(3)-2, 30],...
    'ForegroundColor', [64 64 122]/255,...    
    'Tag', 'sigTOOL:XAxisControls');
set(AxesPanel, 'Units', 'normalized');
set(h.Panel, 'Units', 'normalized');

jpanel=jcontrol(h.Panel,javax.swing.JPanel(java.awt.FlowLayout(java.awt.FlowLayout.CENTER, 1, 3)),'Position', [0 0 1 1]);
jpanel.setBorder(javax.swing.BorderFactory.createLineBorder(java.awt.Color.GRAY));
C=javax.swing.ImageIcon([icons 'DecreaseXRange.gif']);
h.ReduceRange=javax.swing.JButton(C);
C=javax.swing.ImageIcon([icons 'IncreaseXRange.gif']);
h.IncreaseRange=javax.swing.JButton(C);
h.MinText=javax.swing.JTextField(java.lang.Double(XLim(1)).toString());
h.MaxText=javax.swing.JTextField(java.lang.Double(XLim(2)).toString());
h.Slider=javax.swing.JSlider();
h.Dial=kcl.waterloo.widget.GJDial(22,200);

h.Slider.setMinimum(0);
h.Slider.setMaximum(MaxTime);
h.Dial.setMinimum(0);
h.Dial.setMaximum(MaxTime);
h.Slider=handle(h.Slider, 'callbackproperties');
set(h.Slider,'StateChangedCallback',{@scSliderAct, parent});
h.Dial=handle(h.Dial, 'callbackproperties');
set(h.Dial,'StateChangedCallback',{@scSliderAct, parent});

h.IncreaseRange.setPreferredSize(java.awt.Dimension(28,28));
h.ReduceRange.setPreferredSize(java.awt.Dimension(28,28));
h.MinText.setPreferredSize(java.awt.Dimension(55,28));
h.Slider.setPreferredSize(java.awt.Dimension(550,28));
h.Dial.setPreferredSize(java.awt.Dimension(22,22));
h.MaxText.setPreferredSize(java.awt.Dimension(55,28));

jpanel.add(h.IncreaseRange);
jpanel.add(h.ReduceRange);
jpanel.add(h.MinText);
jpanel.add(h.Slider);
jpanel.add(h.Dial);
jpanel.add(h.MaxText);

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
