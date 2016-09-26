function [fhandle, AxesPanel, annot, pos]=printprepare(obj)
% printprepare helper function for printing
% 
% Example:
% [fhandle, AxesPanel, annot, pos]=printprepare(obj)

% 27.06.2016 Updated. This takes a better approach in v0.99 using uistack
%            to control visibility instead of object deletetion.


% This maximises the ROI for drawing and hides unwanted components beneath
fhandle=get(obj, 'Parent');
AxesPanel=findobj(fhandle, 'Tag', 'sigTOOL:AxesPanel');
uistack(AxesPanel, 'top');
set(AxesPanel, 'Units', 'normal', 'Position', [0 0 1 1]);

% Backwards compatibility. Return all references as in previous versions.
% Pos needed to restor size later.

% Show any components tagged for display
h=findobj(fhandle, 'Tag', 'sigTOOL:ShowOnExport');
set(h, 'Visible', 'on')

annot=annotation(fhandle, 'textbox',...
    'Position',[0.65 0.01 0.3 0.04],...
    'EdgeColor', [1 1 1],...
    'String','Printed from sigTOOL \copyright King''s College London',...
    'Color', [0.5 0.5 0.5]);

% 27.06.2016 Get the position. Do this always in pixels for v 0.99
% Get units for restore and position
units=get(AxesPanel, 'Units');
set(AxesPanel, 'Units', 'pixels')
pos=get(AxesPanel, 'Position');
% Fill the figure
set(AxesPanel, 'Units', 'normal')
set(AxesPanel, 'Position', [0 0 1 1],...
    'BackgroundColor', 'w');
% Restore the units setting
set(AxesPanel, 'Units', units)

return
end