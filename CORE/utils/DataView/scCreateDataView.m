function [AxesList]=scCreateDataView(fhandle, start, stop)
% scCreateDataView generates a strip chart data view in sigTOOL
%
% Example:
%     [AxesList]=CreateDataView(fhandle)
%
%     Inputs:   fhandle = handle of the target figure
%     Outputs:  AxesList = vector containing handles for each
%               of the axes
%
% Creates a strip chart with one set of axes for each channel in the
% 'channel' field of fhandle's application data area.
% scCreateDataView calls scCreateFigControls to add the uicontrols.
%
% See also scCreateFigControls
%
% -------------------------------------------------------------------------
% Author: Malcolm Lidierth 10/06
% Copyright © The Author & King's College London 2006-2007
% -------------------------------------------------------------------------
%
% Revisions:
%   23.09.09    Limit channel title display to 8 characters
%   05.11.09    See within

% Get data from the figure application area
[fhandle channels]=scParam(fhandle);

if nargin<2
    start=0;
end
if nargin<3
    stop=start+1;
end


% Set up the figure window
set(fhandle,'NumberTitle','on','Tag','sigTOOL:DataView','WindowButtonDownFcn',{@scWindowButtonDownFcn});

% Get the maximum time on any channel for the slider control
MaxTime2=scMaxTime(fhandle);
setappdata(fhandle, 'MaxTime', MaxTime2);
AxesList=zeros(length(channels),1);

AxesPanel=scCreateAxesPanel(fhandle, start, stop);

% Put up the uicontrols...
scCreateFigControls(fhandle, MaxTime2);
scSec();
sigTOOLDataView(fhandle);
scDataViewDrawData(fhandle);

%Before exit, make sure we resize controls if figure is resized
set(fhandle,'ResizeFcn','scResizeFigControls');

end

