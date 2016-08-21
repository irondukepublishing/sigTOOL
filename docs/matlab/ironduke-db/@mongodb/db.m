classdef mongoDB
    
    properties (Access=private)
        dbName
    end
    
    
    methods
        
        function obj=db(targetDB)
            obj.dbName=targetDB;
        end
        
        
        function ret=subsref(obj, S)
            if S.type == '.'
                ret=builtin('subsref', obj, S.subs);
                disp('db:subsef:indexing = OK');
            else
                warning('db:subsef:indexing', 'Only "." indexing is supported with db objects');
            end
                
        end
    end
    
    
    
end