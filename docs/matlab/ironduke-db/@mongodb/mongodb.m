classdef mongodb < handle
    %
    %
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright Ironduke Publishing Ltd, 2016-
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    properties (Access=private)
        
        % The thread on which this instance was created
        thread;
        
        % The client for the database.
        % An array of char or a cell array containing one or more addresses
        % and port numbers to access the database e.g.:
        %    ['localhost', '27017', 'xxx.xxx.xxx.xxx', '9000']
        % or
        %    {'localhost', 27017, 'xxx.xxx.xxx.xxx', 9000}
        client;
        
        % The name of the database to use from the specified client
        database;
        
        collection;
    end
    
    
    methods
        
        % Constructor. The client must be specified. The database name is
        % optional.
        % Examples:
        % db=mongodb(['localhost', '27017], 'myData')
        function this=mongodb(client, dataBase, collectionName)
            this.thread=java.lang.Thread.currentThread();
            if nargin >=2
                this.database=com.mongodb.MongoClient.getDB(dataBase);
            end
        end
        
        
        function ret=subsref(this, S)
            if S(1).type == '.'
                ret=builtin('subsref', this, S);
            else
                warning('db:subsef:indexing', 'Only "." indexing is supported with db objects');
            end
                
        end
        
        function use(this, dataBase)
            this.database=com.mongodb.MongoClient.getDB(dataBase);
        end
    end
    
    
    
end