function scStandardView(fhandle)

channelmanager=getappdata(fhandle, 'ChannelManager');
units=get(channelmanager.Panel, 'Units');
set(channelmanager.Panel, 'Units', 'normal','Position', [0 0 0.2 1]);
set(channelmanager.Panel, 'Units', units);

view=findobj(fhandle, 'Tag', 'sigTOOL:AxesPanel');
if ~isempty(view)
    units=get(view, 'Units');
    set(view, 'Units', 'normal','Position', [0.2 0.0 0.8 1.0]);
    set(view, 'Units', units);
    uistack(view, 'top')
end

xpanel=findobj(fhandle, 'Tag', 'sigTOOL:XAxisControls');
if ~isempty(xpanel)
    units=get(xpanel, 'Units');
    set(xpanel, 'Units', 'normal','Position', [0.2 0.0 0.8 0.09]);
    set(xpanel, 'Units', units);
    uistack(xpanel, 'top')
end

refresh(fhandle);
end

