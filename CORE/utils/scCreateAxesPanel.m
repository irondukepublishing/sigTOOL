function AxesPanel=scCreateAxesPanel(fhandle, start, stop)

% Get data from the figure application area
[fhandle, channels]=scParam(fhandle);

switch nargin
    case 1
        t=scMinTime(fhandle);
        if t>1
            XLim=[t t+1];
        else
            XLim=[0 1];
        end
    case 2
        XLim=[start start+1];
    case 3
        XLim=[start stop];
end


% If not specified, set the display to show the first 32 channels
ChannelList=getappdata(fhandle,'ChannelList');
if isempty(ChannelList)
    ChannelList=scGenerateChannelList(fhandle);
    setappdata(fhandle,'ChannelList',ChannelList);
end


% How many channels are used?
nchan=0;
for i=1:length(ChannelList)
    if ~isempty(channels{ChannelList(i)})
        nchan=nchan+1;
    end
end
clist=zeros(nchan,1);

channelmanager=scChannelManager(fhandle);

AxesPanel=uipanel(fhandle, 'Position',[0 0 1 1],...
    'Background', [224 223 227]/255,...
    'BorderWidth', 2,...
    'ForegroundColor', [64 64 122]/255,...
    'HighlightColor', [64 64 122]/255,...
    'Tag', 'sigTOOL:AxesPanel');


if ~isempty(channelmanager)
    set(AxesPanel, 'units', 'pixels');
    pos=get(AxesPanel, 'position');
    set(channelmanager, 'units', 'pixels');
    cpos=get(channelmanager, 'position');
    set(AxesPanel, 'position',[cpos(1)+cpos(3),pos(2), pos(3), pos(4)]);
    set(AxesPanel, 'units', 'normalized');
    set(channelmanager, 'units', 'normalized');
end



% For each non-empty channel in ChannelList, create an axes
j=0;


for idx=1:length(ChannelList)
    
    chan=ChannelList(idx);
    
    if isempty(channels{chan})
        continue
    end
    
    % Increment axes counter
    j=j+1;
    % Index of channels
    clist(j)=chan;
    
    % Alternate between labeling left and right axes
    switch (bitget(j,1))
        case {0}
            yalign='right';
        case {1}
            yalign='left';
    end
    
    % Create the axes and store the handle
    AxesList(idx)=subplot(nchan,1,j, 'Parent', AxesPanel); %#ok<AGROW>
    
    % Set up the uicontextmenus activated by a right mouse click
    % (cntrl-click) with non-Windows OS
    pathname=fullfile(scGetBaseFolder(), 'program', 'UiContextMenus', 'DataViewAxes');
    uihandle=dir2menu(pathname, 'uicontextmenu');
    
    % Set up the axes properties
    set(AxesList(idx), 'Units','normalized',...
        'Tag',['ChannelAxes' num2str(chan)],...
        'LooseInset', [0.05 0.05 0.05 0.05],...
        'YTickMode','auto',...
        'YAxisLocation',yalign,...
        'XTick',[],...
        'XLimMode','manual',...
        'YLimMode','manual',...
        'FontSize',8,...
        'UIContextMenu', uihandle);
    % Place the channel number for the axes in the application data area of
    % the axes
    setappdata(AxesList(idx),'ChannelNumber',chan);
    
    % Set up the channel title and, for waveforms, the units field label
    slen=min(length(channels{chan}.hdr.title), 8);
    str=sprintf('%d:%s\n',chan, channels{chan}.hdr.title(1:slen));
    if isfield(channels{chan}.hdr,'adc') && ~isempty(channels{chan}.hdr.adc)
        str=horzcat(str, channels{chan}.hdr.adc.Units); %#ok<AGROW>
    end
    ylabel(str,'FontSize',10);
    if isempty(findstr(channels{chan}.hdr.channeltype,'Waveform'))
        set(AxesList(idx),'YTick',[])
    end
    
    try
        % The YLim field of hdr.adc should be set by the function that
        % created the channel (e.g. an ImportXXX function)
        YLim=channels{chan}.hdr.adc.YLim;
        set(AxesList(idx),'YLim',YLim)
    catch
        % if not ..
        YLim=[-5 5];
        set(AxesList(idx),'YLim',YLim);
        lasterror('reset');
    end
end

% If no axes exists, create one via gca
if isempty(AxesList)
    AxesList=gca;
end

% Save, then ignore zero entries
setappdata(fhandle,'AxesList',AxesList);
% 30.06.2016 Add cast
AxesList=AxesList(double(AxesList)>0);

% Optimize the height of each channel axes
pos1=get(AxesList(1),'Position');
if length(AxesList)>1
    pos2=get(AxesList(end),'Position');
    height=(0.99-pos2(2))/length(AxesList);
    height=min(height,0.99-pos1(2));
else
    height=pos1(4);
end

for i=1:length(AxesList)
    pos2=get(AxesList(i),'Position');
    pos2(4)=height;
    
        pos2(1)=0.075;
    pos2(3)=0.85;
    
    set(AxesList(i),'Position',pos2);
end

set(AxesList,'Units','pixels');
set(channelmanager,'Units','pixels');
for i=1:length(AxesList)
    pos2=get(AxesList(i),'Position');
    pos2(4)=pos2(4)-2;
    set(AxesList(i),'Position',pos2);
end

set(AxesList,'Units','normalized');
set(channelmanager,'Units','normalized');
set(AxesList,'XLim',XLim);

setappdata(fhandle,'DataXLim',[0 0]);

set(AxesList(end),'XTickMode','auto');
xlabel('Time (s)','FontSize',8);
end


