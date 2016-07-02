function varargout=menu_ExportToTIFFN(varargin)
% menu_ExportToTIFFN sigTOOL menu callback: exports a bitmap image
% 
% Example:
% menu_ExportToTIFFN (hObject, EventData)
%       standard callback
%
% This is a callback designed specifically for sigTOOL data views
%
%--------------------------------------------------------------------------
% Author: Malcolm Lidierth 07/06
% Copyright � The Author & King's College London 2006-
%--------------------------------------------------------------------------


% Setup
if nargin==1 && varargin{1}==0
    varargout{1}=true;
    varargout{2}='Uncompressed TIF (24 bit)';
    varargout{3}=[];
    return
end

[button, handle]=gcbo;
scExportFigure(handle, 'tifn');
return
end
