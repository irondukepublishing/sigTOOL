function scExportFigure(fhandle, varargin)
% scExportFigure - exports a sigTOOL view to a graphics file
%
% Example:
% scExportFigure(fhandle, varargin)
% where fhandle is the handle of the data view or sigTOOL result figure
%     varargin{1}, optionally, contains the default target file extension
%
% -------------------------------------------------------------------------
% Author: Malcolm Lidierth 06/08
% Copyright  The Author & King's College London 2008-
% -------------------------------------------------------------------------

% SmoothState=[];

if nargin==2
    init=[tempdir() 'temp' '.' varargin{1}];
    switch varargin{1}
        case 'pdf'
            FilterSpec='temp.pdf';
        case 'eps'
            FilterSpec='temp.eps';
        case 'svg'
            FilterSpec='temp.svg';
        case 'bmp'
            FilterSpec='temp.bmp';
        case {'tiff', 'tif'}
            FilterSpec='temp.tif';
        case {'tiffn', 'tifn'}
            FilterSpec='temp.tifn';
        case 'hdf'
            FilterSpec='temp.hdf';
    end
else
    init=tempdir();
    FilterSpec={'*.pdf' '*.pdf' '*.eps'  '*.svg' '*.bmp' '*.tiff;*.tif' '*.tiffn;*.tinf' '*.hdf'...
    'PDF (*.pdf)',...
    'Encapsulated PS (*.eps)',...
    'SVG (*.svg)',...
    'Bitmap (*.bmp)',...
    'TIF (*.tiff; *.tif)',...
    'TIF uncompressed (*.tiffn; *.tifn)',...
    'HDF (*.hdf)'
    }';
end

[filename pathname]=uiputfile(FilterSpec, 'Save Figure As', init);
if filename==0
    return
end
[dum1 dum2 format]=fileparts(filename);
if isempty(format)
    filename=[filename '.pdf'];
end
if strcmp(format, '.tifn') || strcmp(format, '.tiffn')
    filename=strrep(filename, format, '.tif');
end
filename=fullfile(pathname, filename);


mode=get(fhandle, 'PaperPositionMode');
orientation=get(fhandle, 'PaperOrientation');
set(fhandle, 'PaperPositionMode', 'manual');
set(fhandle, 'PaperUnits', 'normalized');
set(fhandle, 'PaperPosition', [0 0 1 1]);
set(fhandle, 'RendererMode', 'auto');


dmode=[];
if strcmp(get(fhandle, 'Tag'), 'sigTOOL:ResultView')        
    [fhandle, AxesPanel, annot, pos, dmode]=printprepare(getappdata(fhandle, 'sigTOOLResultView'));
elseif strcmp(get(fhandle, 'Tag'), 'sigTOOL:DataView') 
    [fhandle, AxesPanel, annot, pos]=printprepare(getappdata(fhandle, 'sigTOOLDataView'));
end

if strcmp(get(fhandle, 'Tag'), 'sigTOOL:DataView') &&...
        any(strcmp(format, {'ai' 'pdf' 'eps'}))
        % Render at high-res if a vector format is required
        scDataViewDrawData(fhandle, false)
end

if strcmp(format,'.ai')
    orient(fhandle, 'portrait');    
else
    orient(fhandle, 'landscape');
end

    try
        set(fhandle, 'PaperPositionMode', 'auto');
        switch format
            case '.pdf'
                print(fhandle, '-dpdf', '-noui', filename);
            case '.eps'
                print(fhandle, '-depsc', '-tiff', '-noui', filename);
            case '.svg'
                print(fhandle, '-dsvg', '-noui', '-noui', filename);
            case '.bmp'
                print(fhandle, '-dbmp', '-noui',  '-r300', filename);
            case {'.tif' '.tiff'}
                print(fhandle, '-dtiff', '-noui', '-r300', filename);
            case {'.tifn' '.tiffn'}
                print(fhandle, '-dtiffn', '-noui', '-r300', filename);
            case '.hdf'
                print(fhandle, '-dhdf', '-noui',  '-r300', filename);
            otherwise
        end
    catch %#ok<CTCH>
        m=lasterror(); %#ok<LERR>
        if strcmp(m.identifier,'MATLAB:Print:CannotCreateOutputFile')
            warning('%s may be open in another application', filename); %#ok<WNTAG>
        else
            warning('Could not open/create %s', filename); %#ok<WNTAG>
        end
    end


set(fhandle, 'PaperPositionMode', mode);
set(fhandle, 'PaperOrientation', orientation);
tidy(fhandle, AxesPanel, annot, pos, dmode);


% Open output in preview
status=0;
if ispc
    winopen(filename);
elseif ismac
    try
        status=system(sprintf('open "%s"', filename));
    catch ex
        disp(ex);
    end
elseif isunix
    % Load application name from scPreferences.mat
    s=load([scGetBaseFolder() 'program' filesep 'scPreferences.mat'], 'Filing');
    switch format
        case {'.pdf' '.eps'}
            % Document Viewer (set to evince by default)
            status=system(sprintf('%s "%s"', s.Filing.ExportVector, filename));
        case {'.bmp' '.tif' }
            % Bitmap viewer (set eof, Eye of Gnome, by default);
            status=system(sprintf('%s "%s"', s.Filing.ExportBitmap, filename));
    end
    if status~=0
        fprintf('scExportFigure: Failed to open with "%s" or "%s"\n%s\n',...
            s.Filing.ExportVector, s.Filing.ExportBitmap, filename);
    end
end

if status~=0
    fprintf('scExportFigure: Failed to open by all routes\n%s\n', filename);
end

scStandardView(fhandle);

% Copy output filename to system clipboard (for manual open)
clipboard('copy', filename);

return
end


%----------------------------------------------------------
function tidy(fhandle, AxesPanel, annot, pos, dmode)
%----------------------------------------------------------
if strcmp(get(fhandle, 'Tag'), 'sigTOOL:ResultView')
    postprinttidy(getappdata(fhandle, 'sigTOOLResultView'), AxesPanel, annot, pos, dmode);
elseif strcmp(get(fhandle, 'Tag'), 'sigTOOL:DataView') 
    postprinttidy(getappdata(fhandle, 'sigTOOLDataView'), AxesPanel, annot, pos);
end
return
end
%----------------------------------------------------------