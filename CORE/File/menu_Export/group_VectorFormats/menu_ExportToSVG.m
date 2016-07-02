function varargout=menu_ExportToSVG(varargin)
% menu_ExportToSVG sigTOOL menu callback: exports a tagged image
% 
% Example:
% menu_ExportToSVG(hObject, EventData)
%       standard callback
%
% This is a callback designed specifically for sigTOOL data views
%
%--------------------------------------------------------------------------
% Author: Malcolm Lidierth 07/06
% Copyright © The Author & King's College London 2006-
%--------------------------------------------------------------------------


% Setup
if nargin==1 && varargin{1}==0
    varargout{1}=true;
    varargout{2}='SVG';
    varargout{3}=[];
    return
end

[button, handle]=gcbo;
scExportFigure(handle, 'svg');
return
end
