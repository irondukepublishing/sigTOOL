function postprinttidy(obj, AxesPanel, annot, pos)
% postprinttidy methods for sigTOOLDataView objects
%
% serves as helper for print/export functions
%
% Example:
% postprinttidy(obj, AxesPanel, annot, pos)

% 27.06.2016 See within

fhandle=get(obj, 'Parent');
set(findobj(fhandle, 'Type', 'uicontrol'), 'Visible', 'on');
warning('on','MATLAB:Print:CustomResizeFcnInPrint')
delete(annot);
set(AxesPanel, 'Position', pos,'Background', [224 223 227]/255);
h=findobj(fhandle, 'Tag', 'sigTOOL:ShowOnExport');
set(h, 'Visible', 'off')

% 27.06.2016 Change from true - we are using uistack not delete now so 
% ChannelManager is still there
% scChannelManager(fhandle, false);
% h=findobj(fhandle, 'Tag', 'sigTOOL:ShowOnExport');
% set(h, 'Visible', 'off')
% warning('on','MATLAB:Print:CustomResizeFcnInPrint');
% scCreateFigControls(fhandle, scMaxTime(getappdata(fhandle, 'channels')));
return
end