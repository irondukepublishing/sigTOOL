function scInsertLogo(varargin)
% Depracated

% scInsertLogo places the sigTOOL logo in a data view

return

% 
% if ishandle(varargin{1}) && ~strcmp(get(varargin{1},'type'), 'figure')
%     logo(varargin{1});
% else
%     h=findobj(0,'Tag','sigTOOL:DataView');
%     if isempty(h)
%         stop(varargin{1});
%         delete(varargin{1})
%     else
%         for i=1:length(h)
%             if isempty(findobj(h(i),'Tag','sigTOOL:Logo'))
%                 logo(h(i))
%             end
%         end
%     end
% end
% return
% end
% 
% 
% function logo(h)
% set(h,'Units','pixels');
% pos=get(h,'position');
% logo=jcontrol(h, 'javax.swing.JButton',...
%     'Units', 'pixels',...
%     'Position', [pos(3)-92,pos(4)-37,92,37],...
%     'ActionPerformedCallback', []);
% set(get(h, 'Parent'), 'BackGroundColor','w');
% logo.setIcon(javax.swing.ImageIcon(which('Logo_90.png')));
% logo.MouseClickedCallback='web http://irondukepublishing.com -browser';
% set(h,'Units','normalized');
% set(ancestor(h, 'figure'),'ResizeFcn','scResizeFigControls');
% return
% end