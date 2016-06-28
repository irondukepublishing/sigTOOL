function [tp, cs, tree, accordion]=scChannelManager(fhandle, updateflag)
% scChannelManager creates the channel manager for a sigTOOL data view
% 
% Example:
% [tp, cs, tree]=scChannelManager(fhandle)
% 
% scChannelManager returns the handles/jcontrols for the panel, scrollpane
% and tree. These handles are also added to the ChannelManager field of the
% figure's application data area e.g.
%         Panel:        uipanel - component1 of GElasticPane
%     ScrollPane:       JScrollPane
%           Tree:       JTree
%
% The channel tree is drag enabled so you can drag and drop channel
% selections into other sigTOOL GUI items. 
%
% The channel manager GUI provides access to the following (embedded)
% functions
%
% COPY: Places the current channel selection in the system clipboard
% DRAW: Draws the currently selected channels
% INSPECT*: Places a copy of the present (singly) selected channel
% structure (note not object) in the base workspace and opens it in the 
% MATLAB array editor. This can be used to view the data settings. 
% Note that editing values will have no affect on the data stored in the
% data view. 
% REMAP releases virtual memory assigned to the data channels for this, and
% all other, open sigTOOL files
% COMMIT: For the selected channels, this commits memory mapped data stored
% on disc to RAM (in both tim and adc fields). The commit function will
% return harmlessly if you receive an out of memory error. Selected
% channels are commited in numerical order.
%
% *TODO: replace this behaviour with a JTable
%
% -------------------------------------------------------------------------
% Author: Malcolm Lidierth 08/07
% Copyright © The Author & King's College London 2007-
% -------------------------------------------------------------------------
%
% Revisions:
%   08.11.09    See within
%   24.12.10    Substantial updates for sigTOOL 1.00

BACKGROUND=java.awt.Color.WHITE;
base=100;

figure(fhandle);

% Check if channel tree is already present
s=getappdata(fhandle, 'ChannelManager');
channels=getappdata(fhandle, 'channels');

% 08.11.09 Remove ishandle test
if nargin==1 && ~isempty(s)
    tp=s.Panel;
    cs=s.ScrollPane;
    tree=s.Tree;
    accordion=s.Accordion;
    return
end

if nargin==2 && updateflag==true
    % Delete and recreate
    root=BuildTree(fhandle, channels);
    treeModel=javax.swing.tree.DefaultTreeModel(root);
    tree=javax.swing.JTree(treeModel);
    tree.setDragEnabled(true);
    % Scrollpane
    scrollpane=get(get(s,'Children'), 'UserData');
    scrollpane.getComponent(0).setViewportView(tree);
    tree.setBackground(BACKGROUND);
    TreeExpand(tree);
    return
end

% Create a panel
tp=jcontrol(fhandle,'javax.swing.JPanel',...
    'Tag', 'sigTOOL:ChannelManagerPanel',...
    'Border',javax.swing.BorderFactory.createTitledBorder('Channel Manager'));
tp.Position=[0 0 0.15 1];

% Inner scrollpane for channels
cs=javax.swing.JScrollPane();
cs.setVerticalScrollBarPolicy(javax.swing.ScrollPaneConstants.VERTICAL_SCROLLBAR_AS_NEEDED);
% Add tree to the scrollpane
root=BuildTree(fhandle, channels);
treeModel=javax.swing.tree.DefaultTreeModel(root);
tree=javax.swing.JTree(treeModel);
tree.setDragEnabled(true);
% Add to scrollpane
cs.setViewportView(tree);
tree.setBackground(BACKGROUND);
TreeExpand(tree);

% Channel manager
channelmanager=uipanel('Parent', fhandle, 'Units', 'normal','Position', [0 0 0.2 1]);
panel=jcontrol(channelmanager, javax.swing.JPanel(), 'Position', [0.02 0.2 0.996 0.78]);
panel.setLayout(java.awt.GridLayout(1,1));
panel.add(cs);
panel.setBorder(javax.swing.border.EmptyBorder(2,2,2,2));

% Logo and xaxis controls
logo=javax.swing.ImageIcon(fullfile(scGetBaseFolder(),'program','Logo_128.png'));
logobutton=handle(javax.swing.JButton(logo), 'callbackproperties');
logobutton.setMaximumSize(java.awt.Dimension(200,70));
tp=uipanel('Parent', fhandle, 'Units', 'normal','Position', [0.0 0.0 1 0.1]);
p=jcontrol(tp, javax.swing.JPanel(org.jdesktop.swingx.HorizontalLayout()), 'Position', [0,0,1,1]); 
p.setBackground(java.awt.Color.lightGray.brighter());
p.add(logobutton);
p.revalidate();
set(logobutton, 'MouseClickedCallback', 'web(''http://irondukepublishing.com'', ''-browser'')');

tree=handle(tree, 'callbackproperties');
tree.MouseClickedCallback=@CallBack;

% errm=scCheckChannels(fhandle);
% if ~isempty(errm)
%     img=javax.swing.ImageIcon(fullfile(scGetBaseFolder(),'CORE','icons','warning.gif'));
%     button.warning=jcontrol(tp, 'javax.swing.JButton',...
%     'Position', [0.45 0.01 0.1 0.1],...
%     'ToolTipText', 'Click here to view potential problems with this data file',...
%     'ActionPerformedCallback',{@ViewWarnings, errm});
%     button.warning.setIcon(img);
%     button.warning.Units='pixels';
%     button.warning.Position(3:4)=25;
%     button.warning.Units='normalized';
% end

setappdata(fhandle, 'ChannelManager', channelmanager)
return
end

%---------------------------------------------------------------------------
function root=BuildTree(fhandle, channels)
%---------------------------------------------------------------------------
% Build the tree
root=javax.swing.tree.DefaultMutableTreeNode(get(fhandle,'Name'));
% Tree Icons - keep current icons for restore
img=javax.swing.ImageIcon(fullfile(matlabroot, 'toolbox','matlab', 'icons', 'HDF_object02.gif'));%(fullfile(scGetBaseFolder(),'CORE','icons','ChannelTreeWaveformClosed.gif'));
im1=javax.swing.UIManager.get('Tree.closedIcon');
javax.swing.UIManager.put('Tree.closedIcon', img);
%img=javax.swing.ImageIcon(fullfile(scGetBaseFolder(),'CORE','icons','ChannelTreeWaveformOpen.gif'));
im2=javax.swing.UIManager.get('Tree.openIcon');
javax.swing.UIManager.put('Tree.openIcon', img);
im3=javax.swing.UIManager.get('Tree.leafIcon');
img=javax.swing.ImageIcon(fullfile(scGetBaseFolder(),'CORE','icons','ChannelTreeWaveformClosed.gif'));
javax.swing.UIManager.put('Tree.leafIcon', img);

% 09.12.09
ngroup=0;
for idx=1:length(channels)
    if ~isempty(channels{idx}) && channels{idx}.hdr.Group.Number>ngroup
        ngroup=ngroup+1;
        labels{ngroup}=channels{idx}.hdr.Group.Label; %#ok<AGROW>    
    end
end

if ngroup>1
    for idx=1:ngroup
        grp(idx)=javax.swing.tree.DefaultMutableTreeNode(sprintf('%s', labels{idx} )); %#ok<AGROW>
        %set(grp(idx), 'UserData', true);
        root.add(grp(idx));
    end
else
    grp(1)=root;
    %set(grp(1), 'UserData', true)
end

sourcelist=getSourceChannel(channels{:});
for idx=1:length(channels)
    if isempty(channels{idx})
        continue
    end
%     if ngroup==1
%         str=['[' num2str(idx) '] ' channels{idx}.hdr.title];
%         chan=javax.swing.tree.DefaultMutableTreeNode(str);
%         set(chan, 'UserData', false);
%         grp(channels{idx}.hdr.Group.Number).add(chan);
%     else
        grp=CreateChannelEntry(channels, idx, grp, channels{idx}.hdr.Group.Number, [], sourcelist); %#ok<AGROW>
%     end
end

pause(0.2);
% javax.swing.UIManager.put('Tree.closedIcon', im1);
% javax.swing.UIManager.put('Tree.openIcon', im2);
% javax.swing.UIManager.put('Tree.leafIcon', im3);
return
end

%---------------------------------------------------------------------------
function TreeExpand(tree)
%---------------------------------------------------------------------------
% Expand the tree
srow=0;
rows=tree.getRowCount();
while srow~=rows
    for k=rows:-1:1
        tree.expandRow(k);
    end
    srow=rows;
    rows=tree.getRowCount();
end
return
end

%--------------------------------------------------------------------------
function grp=CreateChannelEntry(channels, idx, grp, n, chan, sourcechannels)
%--------------------------------------------------------------------------
str=['[' num2str(idx) '] ' channels{idx}.hdr.title];
if channels{idx}.hdr.Group.SourceChannel==0
    chan=javax.swing.tree.DefaultMutableTreeNode(str);
    grp(n).add(chan);
    %set(chan, 'UserData', false);
    idx2=find(sourcechannels==idx);
    for k=1:numel(idx2)
        grp=CreateChannelEntry(channels, idx2(k), grp, n, chan, sourcechannels);
        %set(chan, 'UserData', true);
    end
elseif ~isempty(chan)
    new=javax.swing.tree.DefaultMutableTreeNode(str);
    chan.add(new);
    %set(new, 'UserData', true);
    idx2=find(sourcechannels==idx);
    for k=1:numel(idx2)
        grp=CreateChannelEntry(channels, idx2(k), grp, n, new, sourcechannels);
        %set(chan, 'UserData', true);
    end
end
return
end
%--------------------------------------------------------------------------


%--------------------------------------------------------------------------
function CallBack(hObject, EventData)
%--------------------------------------------------------------------------
if EventData.getClickCount()>1
    % TODO: Put code here for channel details
end
return
end
%--------------------------------------------------------------------------


%--------------------------------------------------------------------------
function Copy(hObject, EventData, fhandle) %#ok<INUSL>
%--------------------------------------------------------------------------
ChannelList=scGetChannelTree(fhandle, 'selected');
if ~isempty(ChannelList)
    clipboard('copy', num2str(ChannelList));
end
return
end
%--------------------------------------------------------------------------

%--------------------------------------------------------------------------
function Draw(hObject, EventData, fhandle) %#ok<INUSL>
%--------------------------------------------------------------------------
ChannelList=scGetChannelTree(fhandle, 'selected');
if ~isempty(ChannelList)
    % TODO: See called function
    scDataViewDrawChannelList(fhandle, ChannelList);
end
return
end
%--------------------------------------------------------------------------

%--------------------------------------------------------------------------
function remap(hObject, EventData, fhandle) %#ok<INUSD>
%--------------------------------------------------------------------------
scRemap();
return
end
%--------------------------------------------------------------------------


%--------------------------------------------------------------------------
function Inspect(hObject, EventData, fhandle) %#ok<INUSL>
%--------------------------------------------------------------------------
ChannelList=scGetChannelTree(fhandle, 'selected');
if length(ChannelList)==1
    channels=getappdata(fhandle, 'channels');
    inspect(channels{ChannelList});
else
    warndlg('You must select a single channel for editing');
end
return
end

%--------------------------------------------------------------------------
function Commit(hObject, EventData, fhandle) %#ok<INUSL>
%--------------------------------------------------------------------------
ChannelList=scGetChannelTree(fhandle, 'selected');
err=0;
if ~isempty(ChannelList)
    for idx=1:length(ChannelList)
        chan=ChannelList(idx);
        ok=scCommit(fhandle, chan);
        err=err+ok;
    end
end
if err~=0
    errmsg=lasterror(); %#ok<LERR>
    errmsg=sprintf('Some channels could not be committed to RAM\n%s', errmsg.message);
    warndlg(errmsg);
    lasterror('reset'); %#ok<LERR>
end
return
end


function ViewWarnings(hObject, EventData, errm) %#ok<INUSL>
errm=sprintf('%s\n\n%s\n%s',errm, 'Select File->File Information to see details.',...
    'For an explanation of the errors/warnings type "helpwin scCheckChannels"');
warndlg(errm, 'File problems');
return
end


function LocalResize(hObject, EventData)
return
end
% function TreeDropCallback(hObject, EventData)
% % TODO:
% return
% end