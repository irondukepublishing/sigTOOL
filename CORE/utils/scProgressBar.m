function panel=scProgressBar(value, whichbar, varargin)
% scProgressBar is a waitbar like function
%
% Examples:
% obj=scProgressBar(value, message)
% obj=scProgressBar(value, message, PropName1, PropName2.....)
%   create and display a progress bar
%
% scProgressBar(value)
%   updates the most recently created bar
%
% scProgressBar(string)
%   updates the message of the most recently created bar
%
% scProgressBar(value, obj)
%   updates the bar specified by obj
%
%       obj is a JCONTROL object (you need this class installed -see below)
%       value: is a scalar between 0 and 1
%       message: is a string which may contain HTML formatting tags
%
% Valid property name/value pairs are:
%       Icon:   specifies the icon to be displayed with the progress bar
%                   this should be a javax.swing.ImageIcon object or the 
%                   name of a file to load via javax.swing.ImageIcon -
%                   typically a gif file
%       Name:   the name for the title bar
%                   (string)
%       Step:   value is scaled to a percentage and rounded. The display
%               will be updated only if the scaled value is a multiple of
%               step. Set step to 5 or 10% to reduce the CPU overhead when
%               scProgressBar is called repeatedly from a loop
%                   (scalar - default NaN).
%               Note: it is better to include such a test in your code
%                       loop and call scProgressBar only when an update
%                       is required
%       Position: the position for the frame (normalized). Note that 
%                   width/height will be overridden
%       Progbar: 'on' to show a progressbar within the panel, 'off' to
%               suppress it
% See also waitbar
%
% scProgressBar maintains an internal stack of handles to the created 
% progress bars. This stack can be accessed by calling scProgressBar()
% and cleared with scProgressBar(-1).
% 
% scProgressBar('on'/'off') toggles the display of progress bars. Default
% is 'on'. Set to 'off' to use sigTOOL functions from the command line
% with no Java Runtime Environment.
%
% Requirements:
% The JCONTROL class and its methods are needed and available from 
% MATLAB Central 
% <a href="http://www.mathworks.com/matlabcentral/fileexchange/loadFile.do?objectId=15580&objectType=FILE">LinkOut</a>
%
% -------------------------------------------------------------------------
% Author: Malcolm Lidierth 09/07
% Copyright © The Author & King's College London 2007-
% -------------------------------------------------------------------------
%
% Revisions:
%   25.10.08    Revised for R2008b jcontrol with uipanel
%   14.10.09    See within


%--------------------------------------------------------------------------
persistent STEP     % Size of increments for progress bar - scalar
                    % All bars use the latest set value.
persistent PANEL    % Internal stack of progress bars - cell array
persistent MODE     % Switches progress bar on/off
%--------------------------------------------------------------------------



panel=[];

if nargin==1 && ischar(value)
    % Mode must be 'on' or 'off'
    if strcmp(value,'on') || strcmp(value,'off');
        MODE=value;
    else
        whichbar=PANEL{end};
        if ~isempty(whichbar)
            pb=get(findobj(whichbar, 'Tag', 'sigTOOL:ProgressMessage'),...
                'UserData');
            if ~isempty(pb)
                pb.setText(value);
            end
            drawnow();
        end
    end
    return
end


if nargin==0
    % scProgressBar(): return the stack of handles
    panel=PANEL;
    return
end

if nargin==1
    if value==-1
        % scProgressBar(-1): delete the stack
        PANEL=[];
        return
    else
        % scProgressBar(X)  use most recently created panel
        whichbar=PANEL{end};
    end
end

% 14.10.09 Moved from above
fhandle=get(0,'CurrentFigure');
if isempty(fhandle)
    return
end

if nargin==1 || (nargin>=2 && ~ischar(whichbar))
    % scProgressBar(X)
    % scProgressBar(X, H) or scProgressBar(X, H, 'MESSAGE')
    value=round(value*100);
    if ~isnan(STEP) && rem(value, STEP)~=0
        % Do not update display
        return
    end
    if ishandle(whichbar)
        % Update display
        % Progress Bar
        pb=get(get(whichbar,'Children'),'UserData');
        try
        b=pb.getContentPane().getComponent(1).getComponent(1);
        if ~isempty(pb)
            b.setValue(value);
            b.setString(sprintf('Completed %d%%', value));
        end
        catch
        end
        % Message
        if nargin==3 && ischar(varargin{1})
            m=pb.getContentPane().getComponent(1).getComponent(0);
            if ~isempty(pb)
                m.setText(varargin{1});
            end
        end
        drawnow();
    else
        % Most likely get here because bar has been deleted
        error('%s: invalid handle (deleted bar/figure?)', mfilename);
    end
end


%Initialize new control
if nargin>=2 && ischar(whichbar)
    % scProgressBar(X, 'MESSAGE')
    % or scProgressBar(X, 'MESSAGE', 'PROPNAME', PROPVALUE......)

    % Defaults
    Progbar=true;
    
    % workaround: drawnow is needed here to prevent hang-up due to 
    % interaction with dismissed MATLAB dialogs (R2007b)
    drawnow();
    
    MessageText=whichbar;
    STEP=NaN;
    Icon=javax.swing.ImageIcon(fullfile(scGetBaseFolder(),'program','Alt_Logo_64.png'));
    Position=[0.375 0.475 0.35 0.2];
    % Inputs
    for i=1:2:length(varargin)-1
        switch lower(varargin{i})
            case 'name'
                Name=varargin{i+1};
            case 'step'
                STEP=varargin{i+1};
            case 'position'
                Position=varargin{i+1};
            case 'icon'
                if isjava(varargin{i+1})
                    Icon=varargin{i+1};
                elseif ischar(varargin{i+1})
                    Icon=javax.swing.ImageIcon(varargin{i+1});
                end
            case 'progbar'
                Progbar=varargin{i+1};
        end
    end
    
    % Set up frame
    panel=uipanel('Parent', fhandle, 'Position', Position);
    set(panel, 'Units', 'pixels');
    Position=get(panel, 'Position');
    Position(3)=350;
    Position(4)=125;
    set(panel, 'Position', Position);
    set(panel, 'ResizeFcn', {@PanelResizeFcn get(panel, 'Position')}, 'Tag', 'sigTOOL:ProgressPanel', 'Visible', 'on');
    
    j=javax.swing.JInternalFrame(Name,false,true,false,false);
    img=javax.swing.ImageIcon(fullfile(scGetBaseFolder(),'CORE','icons','ChannelTreeWaveformClosed.gif'));
    j.setFrameIcon(img);
    j.setLayout(org.jdesktop.swingx.HorizontalLayout(9));
    f=jcontrol(panel, j, 'Position', [0 0 1 1]);
    f.setVisible(true);
    f.InternalFrameClosedCallback=@DeleteFrame;
    f.DeleteFcn=@DeletePanel;

    % Logo
    logo=javax.swing.JButton(Icon);
    f.getContentPane().add(logo);
    %logo.setPreferredSize(java.awt.Dimension(50,50));

    panel2=f.getContentPane().add(javax.swing.JPanel());
    %panel2.setBackground(java.awt.Color.white);
    panel2.setLayout(org.jdesktop.swingx.VerticalLayout(5));

    
    % Message
    message=javax.swing.JLabel(MessageText);
    message.setHorizontalAlignment(javax.swing.SwingConstants.CENTER);
    %message.setForeground(java.awt.Color(100/255, 100/255, 100/255));
    message.setPreferredSize(java.awt.Dimension(200,35));
    panel2.add(message);
    
    
    % Bar
    if Progbar==true
        pm=javax.swing.JProgressBar();
        pm.setStringPainted(true)
        pm.setMinimum(0);
        pm.setMaximum(100);
        pm.setValue(round(value*100));
        %pm.setPreferredSize(java.awt.Dimension(200,15));
        pm.setBorder(javax.swing.border.LineBorder.createBlackLineBorder());
        panel2.add(pm);
    end
    
    % Spacer
    panel2.add(javax.swing.JSeparator(javax.swing.SwingConstants.HORIZONTAL));
    
    
    
    drawnow();
    j.setFocusable(true);
    j.setSelected(true);
    % Add to stack
    PANEL{end+1}=panel;
    return
end


    function DeletePanel(hObject, EventData) %#ok<INUSD>
        % TODO: Should this have a veto from user input included?
        % Delete and stack manager - embedded to keep PANEL in scope
        obj=get(hObject, 'Parent');
        % Clean up STACK on deletion
        idx=1;
        while idx<=length(PANEL)
            if PANEL{idx}==obj;
                PANEL(idx)=[];
            end
            idx=idx+1;
        end
        if ishandle(obj);delete(obj);end
        % Delete the internal frame explicitly as JAVACOMPONENT's
        % containerDelete has been over-ridden
        %frame.InternalFrameClosedCallback=@DeleteFrame;
        try
        delete(get(hObject,'UserData'));
        catch
        end
%         if ~isempty(PANEL)
%             PANEL{end}.setSelected(true);
%         end
        return
    end


end

function PanelResizeFcn(hObject, EventData, sz) %#ok<INUSL>
% Fix size in pixels
hObject=handle(hObject);
hObject.Position(1)=0.375;
hObject.Position(2)=0.475;
hObject.Units='pixels';
hObject.Position(3)=sz(3);
hObject.Position(4)=sz(4);
hObject.Units='normalized';
return
end

function DeleteFrame(hObject, EventData) %#ok<INUSD>
h=get(hObject,'uipanel');
if ishandle(h);delete(h);end
return
end


