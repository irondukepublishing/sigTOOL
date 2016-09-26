function varargout=menu_PrintPreview(varargin)
% menu_PrintPreview sigTOOL menu callback
%
% Example:
% menu_PrintPreview(hObject, EventData)
%       standard callback
%
% This is a print preview function designed specifically for sigTOOL
% data views
%
%--------------------------------------------------------------------------
% Author: Malcolm Lidierth 07/06
% Copyright © The Author & King's College London 2006-
%--------------------------------------------------------------------------


% Called as menu_PrintPreview(0)
if nargin==1 && varargin{1}==0
    varargout{1}=true;
    varargout{2}='Print Preview';
    varargout{3}=[];
    return
end

[button, fhandle]=gcbo;

type=scGetFigureType(fhandle);
warning('off', 'MATLAB:print:CustomResizeFcnInPrint');
switch type
    case 'sigTOOL:DataView:'
        [fhandle, AxesPanel, annot, pos]=printprepare(getappdata(fhandle, 'sigTOOLDataView'));
        orient(fhandle, 'landscape');
        set(fhandle, 'PaperPositionMode', 'manual');
        set(fhandle, 'PaperType', 'A4');
        printpreview(fhandle);
        postprinttidy(getappdata(fhandle, 'sigTOOLDataView'), AxesPanel, annot, pos);
        scDataViewDrawData(fhandle, true);
    case 'sigTOOL:ResultView:'
        [fhandle, AxesPanel, annot, pos]=printprepare(getappdata(fhandle, 'sigTOOLResultView'));
        orient(fhandle, 'landscape');
        et(fhandle, 'PaperPositionMode', 'manual');
        set(fhandle, 'PaperType', 'A4');
        printpreview(fhandle);
        postprinttidy(getappdata(fhandle, 'sigTOOLResultView'), AxesPanel, annot, pos);
end
warning('on', 'MATLAB:print:CustomResizeFcnInPrint');
end


