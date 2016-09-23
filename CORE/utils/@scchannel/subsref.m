function out=subsref(obj, index)
% subsref method for overloaded for the scchannel class
%
% Example:
% obj=subsref(obj, index, val)
%   see the builtin subsref for details
%
% -------------------------------------------------------------------------
% Author: Malcolm Lidierth 12/07
% Copyright © The Author & King's College London 2007-2008
% -------------------------------------------------------------------------

switch index(1).type
    case '.'
        switch lower(index(1).subs)
            case {'adc' 'tim' 'mrk' 'hdr' 'eventfilter' 'sequence'  'channelchangeflag' 'currentsubchannel'}
                if length(index)==1
                    out=obj.(index(1).subs);
                else
                    try
                        out=subsref(obj.(index(1).subs), index(2:end));
                    catch ex
                        switch ex.identifier
                            case 'MATLAB:unassignedOutputs'
                                %builtin('subsref',obj, index);
                                % No action needed
                            case 'MATLAB:maxlhs'
                                subsref(obj.(index(1).subs), index(2:end));
                            otherwise
                                rethrow(ex);
                        end
                    end
                end
            otherwise
                error('No such property in scchannel class: ''%s''', index(1).subs);
        end
    case '()'
        out=obj;
    otherwise
        error('Access method not supported');
end

if nargout>0 && issparse(out)
    out=full(out);
end

return
end
