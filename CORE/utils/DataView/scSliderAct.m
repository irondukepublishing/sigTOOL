function scSliderAct(hObject, EventData, fhandle)
% Callback routine for XAxisSlider control
%
%ML 05/05

% Avoid repeated updates if dragging
if  isMultipleCall()
    return
end

AxesList=getappdata(fhandle,'AxesList');
AxesList=AxesList(AxesList~=0);
if isempty(AxesList)
    return
end

% Get slider position and current axis range
val=get(hObject,'Value')/1000;
XLim=get(AxesList(end),'XLim');

range=XLim(2)-XLim(1);
XLim(1)=val;
XLim(2)=val+range;
set(AxesList,'XLim',XLim);
scCleanUpAxes(AxesList);

% Update axis controls
if  isa(hObject, 'javahandle_withcallbacks.kcl.waterloo.widget.GJDial')
    scUpdateAxisControls(fhandle, 'dial');
else
    scUpdateAxisControls(fhandle, 'slider');
end

set(fhandle, 'Pointer', 'arrow');
drawnow();
end



