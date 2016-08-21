classdef Json
    
    % JSON writes MATLAB data to the JavaScript Object Notation format.
    %
    % Depends on the use of the Jackson Json Java library
    % See http://wiki.fasterxml.com/JacksonHome
    %
    % The output always generates a Json object, delimited by curly braces
    %                               {.....}
    % MATLAB variables and objects are specified within this object by the
    % variable's name or by '.' when no name is available.
    %
    % When variables are specified by name in the calling workspace, the
    % names of the variables will also be included in the json output. Thus
    %          >> myVar='abc';
    %          >> Json.toJson(myVar)
    % will produce:
    %          {"myVar":"abc"}
    % as output.
    %
    % Where no name is available, it will be set to "[n]" where n is the index
    % into the underlying map used to build the description. Thus
    %           >> Json.toJson('abc')
    % will produce:
    %               {"[0]":"abc"}
    % Multiple inputs are stored with an index. Thus
    %           >> x=1.1;y=pi;
    %           >> Json.toJson(x, y, 'abc')
    % produces:
    %           {"x":1.1,"y":3.141592653589793,"[2]":"abc"}
    %
    % The indices, [0], [1] etc will be unique and allow multiple un-named
    % variables as input.
    %
    % The JSON methods support "pretty" printing to produce more human-
    % readable output. Using
    %              >> Json.toJsonPretty(x, y, 'abc')
    % produces:
    %                     {
    %                     "x": 1.1,
    %                     "y": 3.141592653589793,
    %                     "[2]": "abc"
    %                 }
    % [The precise format of pretty json (white space,
    % line-breaks etc.) will depend on the underlying JSON library in use].
    %
    %
    % SCALAR VALUES
    %
    %   Doubles:
    %   When finite and real-valued, doubles are stored without an explicit type as
    %   1.0, 20 etc..
    %
    %   Doubles may be converted to integer in the JSON output if that is possible
    %   without loss of precision (or to representation with a single digit to
    %   the right of the decimal point in some cases). A value of -0 may be
    %   represented as 0 or -0 in the output depending on the route taken
    %   to encode it (via hg the negative sign will be lost, via Java
    %   it will be preserved).
    %
    %   Non-finite, NaN and complex scalars are converted to a text
    %   representation e.g. "Infinity", "NaN" or "1.0+1.0i". In these cases,
    %   the type is included explicity to distinguish such values from pure
    %   strings.
    %   Thus:
    %                       >> x=1.1;y=2;
    %                       Json.toJson(x,y);
    %   yields
    %                  {"x":1.1,"y":2}
    %   while
    %                       >> x=1.1;y=NaN;
    %   yields
    %
    %               {"x":1.1,"y":{"_type":"double","value":"NaN"}}}
    %
    %
    %   Other hg numeric types:
    %   These are stored as Json objects with an explicit type. For example
    %   where
    %           x=int32(10)
    %   we write
    %           {"x":{"_type":"int32","value":10}}
    %
    %   [Note that the scalar numeric representation takes precedence when a
    %   value is also a hg handle, thus while Json.toJson(gcf) will
    %   create a representation of the current figure in Json,
    %   Json.toJson(double(gcf)) will just store the figure number as a
    %   scalar.]
    %
    %   Cells:
    %   These are stored as JSON object, i.e. in {}
    %                       >> x={1};
    %   yields
    %                {"x":{"_type":"cell","[1, 1]":1}}
    %  "[1, 1]" are the subindices - used even though we have only a single
    %   entry here. Note the content is a double, so no explicit type
    %   information is included. However, for
    %                       >> x={int32(1)};
    %   we would get:
    %       {
    %                     "x": {
    %                         "_type": "cell",
    %                         "[1, 1]": {
    %                             "_type": "int32",
    %                             "value": 1
    %                         }
    %                     }
    %                 }
    %
    %   Characters and Strings:
    %   Are stored within double quotes as in the examples above.
    %
    %   Structures:
    %            s.a=1; s.b='abc';s.c=int64(2^10)
    %   yields
    %                 {
    %                     "s": {
    %                         "_type": "struct",
    %                         "a": 1,
    %                         "b": "abc",
    %                         "c": {
    %                             "_type": "int64",
    %                             "value": 1024
    %                         }
    %                     }
    %                 }
    %   s.a is presumed to be double as it has no explicit type. Similarly,
    %   s.b. has no declared type so is assumed to be a string.
    %
    %   Function handles and anonymous functions
    %   These are stored as strings. This
    %               >> f=@(x) disp(x)
    %   yields
    %                 {
    %                   "f" : {
    %                     "_type" : "function_handle",
    %                     "functiontype" : "anonymous",
    %                     "asString" : "@(x)disp(x)",
    %                     "target" : "f",
    %                     "workspace" : {
    %                       "_type" : "struct"
    %                     }
    %                   }
    %                 }
    %
    %   hg Objects:
    %   The output will include the type of the object, together with the
    %   property values provided in the structure returned by the get()
    %   method called on the object instance.
    %   In some cases, When a hg handle object appears as a property of
    %   another object, it will be referenced in the Json output by its double
    %   value in a custom Json "_handle" object e.g.:
    %            {
    %               "_type" : "_handle",
    %               "value" : 2.0001220703125
    %             }
    % . This affects the following properties:
    %   "Parent", ...... TODO
    %
    %  VECTORS AND MATRICES
    %  Chars are stored as Json string arrays with no explicit type.
    %                       >> x=['abc';'def']
    %  yields
    %                    {"x":["abc","def"]}
    %
    %  Doubles are stored as Json arrays with no explicit type unless they
    %  include unsupported values such as NaN or Inf in which case they are
    %  stored with an explicit type as Json char arrays. Thus
    %               >> x=[NaN, Inf, -Inf, -0, 0, 1];
    %  yields
    %     {
    %       "x" : {
    %         "_type" : "double",
    %         "content" : [ "NaN", "Infinity", "-Infinity", "-0.0", "0.0", "1.0" ]
    %       }
    %     }
    %
    %  Other numeric types will be stored with an explicit type
    %                   >> x=int16([0 1 2 3])
    %  yields
    %                     {
    %                       "x" : {
    %                         "_type" : "int16",
    %                         "content" : [ 0, 1, 2, 3 ]
    %                       }
    %                     }
    %
    % Cell and structure arrays are fully supported as are arrays of hg
    % objects etc.
    %
    % Special cases:
    % To reduce the length of the generated Json text, some common special
    % cases are handled by creating custom objects in the output:
    %
    % Ranges:
    % Ranges are created using the colon operator in hg e.g.
    %               >> x=0:0.5:1000
    % It is possible to exactly re-create the vector if unique(diff(x)) is
    % scalar (often it will not be due to IEEE roundoff and because hg
    % seeks internally to create symetrical roundoff errors in the output).
    % In these cases Json will output a range object:
    %                     {
    %                       "x" : {
    %                         "_type" : "range",
    %                         "content" : {
    %                           "_type" : "double",
    %                           "_size" : "1  2001",
    %                           "start" : 0.0,
    %                           "end" : 1000.0,
    %                           "increment" : 0.5
    %                         }
    %                       }
    %                     }
    %
    % Constants:
    % Where all elements of a matrix contain the same value, a Json constant
    % object will be created. Thus
    %                   >> x=ones(1000,1000,100);
    % yields
    %
    %                    {
    %                       "x" : {
    %                         "_type" : "constant",
    %                         "content" : {
    %                           "_type" : "double",
    %                           "_size" : "1000  1000   100",
    %                           "value" : 1.0
    %                         }
    %                       }
    %                     }
    %
    % Sparse matrices:
    % For sparse matrices, we create a 'sparse' object that itemises only
    % the non-zero elements. Thus
    %           >> x=sparse(zeros(100,100))
    %           >> x(10,10)=0.1;
    %           >> x(20,20)=0.2;
    % yields:
    %                 {
    %                   "x" : {
    %                     "_type" : "sparse",
    %                     "content" : {
    %                       "_type" : "double",
    %                       "_size" : "100  100",
    %                       "row" : [ 10, 20 ],
    %                       "column" : [ 10, 20 ],
    %                       "values" : [ 0.1, 0.2 ]
    %                     }
    %                   }
    %                 }
    % Complex, non-finite and NaN values will be accommodated by conversion
    % to text. Note that the double type is included even though all sparse
    % matrices are double in current hg versions.
    
    % Edits:
    % reflector.VarNameWrapper -> VarNameWrapper
    % reflector.Json -> Json
    
    
    
    properties (Constant, Access=private)
        
        % Linked HashMap used during deserialization.
        % Old handle double values, recorded at the time of serialization, are added
        % together with the new handle of the clone created during the
        % deserialization process. Children can therefore be added to the
        % new parent object by looking up the handle of the new parent in the map.
        % For java.awt.Components and Matlab javahandle_withcallbacks objects
        % the old hashCode is used as key and the new object is stored by
        % reference.
        HandleMap=java.util.LinkedHashMap(24);
        
        % When an attempt is made to deserialize an object whose parent
        % has not yet been created, the Json node will be added to this
        % list and the node will be created later.
        BuildLater=java.util.ArrayList();
        BuildLaterFlag=java.util.concurrent.atomic.AtomicBoolean(true);
        
        AppData=java.util.LinkedHashMap(24);
        
        BuildLaterCallbacks=java.util.LinkedHashMap();
        
        % If true, XData, YData and ZData will be base64 encoded using
        % little-endian byte order.
        useBase64=java.util.concurrent.atomic.AtomicBoolean(false);
        % N.B. A version of this code is shipped with MATLAB
        b64=org.apache.commons.codec.binary.Base64();
        
        %KeyStore=java.util.LinkedHashMap();
        
        % For clarity only.
        emptyString=java.lang.String('');
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % If all matrix elements are the same, summarise the contents
        shortenConstantArrays=true;
        % Convert vectors with constant increments to series
        % N.B. unique(diff(x)) must be scalar for this to  apply.
        shortenRanges=true;
        % Convert logical arrays to 0s and 1s.
        logicalArraysAsNumber=true;
        % Serialise only the non-zero elements of sparse matrices
        shortenSparse=true;
        % If the elements of a cell array are all of the same class,
        % serialise them as a matrix (applies to numeric and char only);
        cellArrayAsMatrix=false;
        
        conciseJava=java.util.concurrent.atomic.AtomicBoolean(false);
        conciseMatlab=java.util.concurrent.atomic.AtomicBoolean(false);
        
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % CHANGING ANY OF THE VALUES BELOW MAY BREAK COMPATIBILITY
        % AND PREVENT PROPER DESERIALIZATION OF THE GENERATED FILES
        %
        % If true, empty entries in MATLAB objects will be omitted BUT
        % null may not be the default value so this may make deserialization
        % more difficult.
        omitEmptyObjectProperties=false;
        %
        %  Omit null valued Java properties - quicker
        %  and leads to shorter Json files BUT, null may not be the default
        %  value so may make deserialization more difficult.
        omitNullValuesJava=false;
        
        includeNestedFunctionHandleWorkspace1=true;
        includeNestedFunctionHandleWorkspace2=false;
        
        % If true, only properties of MATLAB objects that can be publically
        % set will be serialized. As properties are set via the
        % constructors, this restriction is not always required - but the
        % code may need to be modified for some properties if
        % settableOnlyFlag is set to false;
        settableOnlyFlag=false;
        %
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        
    end
    
    
    
    methods (Static)
        
        
        function save(varargin)
            % JSON.SAVE: static method to save variables as JSON files.
            %
            % JSON.SAVE() saves the current workspace to 'matlab.json'.
            % JSON.SAVE(FILENAME) saves the current workspace to the
            % specified file.
            % JSON.SAVE(FILENAME,VARIABLENAMES) saves the specified named
            % variables from the current workspace.
            % JSON.SAVE(FILENAME,VARIABLES) saves the variables passed as
            % input together with their names from the current workspace.
            %
            % Note that when variables are passed as input, variablenames
            % can not also be used. JSON.SAVE(FILENAME,x,'y',z) will treat
            % 'y' as an unnamed temporary variable of value 'y'.
            %
            % Options:
            % JSON.SAVE(..., '-pretty')
            % Compact JSON will be used unless the '-pretty' switch is
            % used.
            % JSON.SAVE(..., '-gzip')
            % To compress the output file use the '-gzip' switch. The ".gz"
            % extension will be appended to the filename automatically
            % if not supplied on input.
            %
            % These options are available but the effects will change between
            % versions
            % JSON.SAVE(..., '-concisematlab')
            % Some fields in hg hg objects will be ignored.
            % JSON.SAVE(..., '-concisejava')
            % Some Java AWT/Swing objects will be serialised in a concise
            % format
            
            if nargin==0
                fileName='matlab.json';
                doMap=true;
                doGzip=false;
                doPretty=true;
            else
                
                if ~ischar(varargin{1})
                    error('File name required as first input')
                end
                % Get the variable names for later use if variables passed as input
                variableNames=arrayfun(@inputname,1:length(varargin), 'UniformOutput', false);
                
                % Use pretty printing?
                TF=cellfun(@(x) (ischar(x) && strcmpi(x,'-pretty')), varargin);
                if any(TF)
                    varargin(TF)=[];
                    doPretty=true;
                else
                    doPretty=false;
                end
                
                % Use gzip?
                TF=cellfun(@(x) (ischar(x) && strcmpi(x,'-gzip')), varargin);
                if any(TF)
                    varargin(TF)=[];
                    doGzip=true;
                else
                    doGzip=false;
                end
                
                % Supplying a map to begin with?
                TF=cellfun(@(x) (ischar(x) && strcmpi(x,'-map')), varargin);
                if any(TF)
                    varargin(TF)=[];
                    doMap=false;
                else
                    doMap=true;
                end
                
                fileName=varargin{1};
                varargin(1)=[];
                
            end
            
            if doGzip && ~strcmp(fileName(end-2:end), '.gz')
                fileName=[fileName '.gz'];
            end
            
            
            
            if isempty(varargin) || all(cellfun(@ischar, varargin))
                % Variable names on input
                % Select variables.
                if isempty(varargin)
                    % ... all
                    variableNames=evalin('caller', 'who()');
                else
                    % ... or as specified by user
                    variableNames=varargin;
                end
                % Get the contents of the variables
                values=cell(1,length(variableNames));
                for k=1:length(variableNames)
                    values{k}=evalin('caller', variableNames{k});
                end
            else
                % Variables passed as input
                values=varargin;
                variableNames=variableNames(2:2+length(values)-1);
            end
            
            if doMap
                map=Json.toMap(values{:}, VarNameWrapper(variableNames));
            elseif numel(values)>0
                map=values{1};
            else
                disp('No variables in workspace');
                return;
            end
            
            file=java.io.File(fileName);
            writer=java.io.FileOutputStream(file);
            if doGzip
                writer2=java.util.zip.GZIPOutputStream(writer);
            else
                writer2=writer;
            end
            mapper=com.fasterxml.jackson.databind.ObjectMapper();
            mapper.configure(com.fasterxml.jackson.databind.SerializationFeature.FAIL_ON_EMPTY_BEANS, false);
            generator=mapper.getFactory().createGenerator(writer2);
            if doPretty
                generator.useDefaultPrettyPrinter();
            end
            generator.writeObject(map);
            generator.close();
            if doGzip
                writer2.close();
            end
            writer.close();
        end
        
        
        function out = toJson(varargin)
            % JSON.TOJSON provides a compact JSON description of the input
            %
            % Examples
            % JSON.TOJSON(1:10)
            % JSON.TOJSON(x)
            % JSON.TOJSON(handle)
            % JSON.TOJSON(object)
            % JSON.TOJSON(x,y,z);
            %
            % JSON.TOJSON(java.util.Map, '-map');
            %   is a special case, where the supplied map will be
            %   serialized directly without calling the JSON.TOMAP method.
            %
            % JSON.TOJSON serializes the inputs to JSON. Variables, that
            % are named in the calling hg workspace will be associated
            % with a named entry in the JSON output.
            %
            % These options are available but the effects will change between
            % versions
            % JSON.TOJSON(..., '-concisematlab')
            % Some fields in hg hg objects will be ignored.
            % JSON.TOJSON(..., '-concisejava')
            % Some Java AWT/Swing objects will be serialised in a concise
            % format
            %
            % Supported input types include:
            % Primitives such as int8, uint8, int16, uint16, int32, uint32,
            % int64, uint64, double, single, logical and char.
            % Vectors and matrices
            % Cells and cell arrays
            % Structures and structure arrays
            % hg objects
            % hg handle graphics objects
            % Java objects
            
            if ~isa(varargin{end}, 'VarNameWrapper')
                names=arrayfun(@inputname,1:length(varargin), 'UniformOutput', false);
                varargin{end+1}=VarNameWrapper(names);
            end
            if nargin>=2 && isa(varargin{1}, 'java.util.Map') && ischar(varargin{2}) && strcmp(varargin{2}, '-map')
                map=varargin{1};
            else
                map=Json.toMap(varargin{:});
            end
            writer=java.io.StringWriter();
            mapper=com.fasterxml.jackson.databind.ObjectMapper();
            mapper.configure(com.fasterxml.jackson.databind.SerializationFeature.FAIL_ON_EMPTY_BEANS, false);
            generator=mapper.getFactory().createGenerator(writer);
            generator.writeObject(map);
            generator.close();
            out=writer.toString();
            writer.close();
        end
        
        
        function out = toJsonPretty(varargin)
            % JSON.TOJSONPRETTY provides a pretty JSON description of the input
            %
            % Examples
            % JSON.TOJSONPRETTY(1:10)
            % JSON.TOJSONPRETTY(x)
            % JSON.TOJSONPRETTY(handle)
            % JSON.TOJSONPRETTY(object)
            % JSON.TOJSONPRETTY(x,y,z);
            %
            % JSON.TOJSONPRETTY(java.util.Map, '-map');
            %   is a special case, where the supplied map will be
            %   serialized directly without calling the JSON.TOMAP method.
            %
            % JSON.TOJSONPRETTY serializes the inputs to JSON. Variables, that
            % are named in the calling hg workspace will be associated
            %
            % These options are available but the effects will change between
            % versions
            % JSON.TOJSONPRETTY(..., '-concisematlab')
            % Some fields in hg hg objects will be ignored.
            % JSON.TOJSONPRETTY(..., '-concisejava')
            % Some Java AWT/Swing objects will be serialised in a concise
            % format
            %
            % Supported input types include:
            % Primitives such as int8, uint8, int16, uint16, int32, uint32,
            % int64, uint64, double, single, logical and char.
            % Vectors and matrices
            % Cells and cell arrays
            % Structures and structure arrays
            % hg objects
            % hg handle graphics objects
            % Java objects
            if ~isa(varargin{end}, 'VarNameWrapper')
                names=arrayfun(@inputname,1:length(varargin), 'UniformOutput', false);
                varargin{end+1}=VarNameWrapper(names);
            end
            if nargin>=2 && isa(varargin{1}, 'java.util.Map') && ischar(varargin{2}) && strcmp(varargin{2}, '-map')
                map=varargin{1};
            else
                map=Json.toMap(varargin{:});
            end
            writer=java.io.StringWriter();
            mapper=com.fasterxml.jackson.databind.ObjectMapper();
            mapper.configure(com.fasterxml.jackson.databind.SerializationFeature.FAIL_ON_EMPTY_BEANS, false);
            generator=mapper.getFactory().createGenerator(writer);
            generator.useDefaultPrettyPrinter();
            generator.writeObject(map);
            generator.close();
            out=writer.toString();
            writer.close();
        end
        
        
        function varargout = parseText(json, varargin)
            % Deserializes a Json string
            % JSON.PARSETEXT(json)
            % map=JSON.PARSETEXT(json)
            %   Creates (or overwrites) all specified variables in the
            %   calling workspace.
            %   Where temporary variables are used as input to the
            %   serialization stage, those inputs are assigned a name of
            %   "[0]", "[1]" etc corresponding to their position in the
            %   input list. These variables will be deserialized using a
            %   valid Matlab variable name generated using
            %   matlab.lang.makeValidName. For "[0]" this will be "x_0_ .
            %   The optional output argument contains the map of handles as
            %   described below.
            %   If a single output argument is specified, it contains the
            %   map of handles as described below.
            %
            % [a,b,...,map]=JSON.PARSETEXT(json)
            %   Assigns variables to the specified output variables in the
            %   sequence that they are encountered in the input.
            %   Spare outputs will be left empty.
            %   If an extra output argument is specified, it contains the
            %   map of handles as described below.
            %   This form of call will generally only be useful when the
            %   variables within the json input is fully known.
            %
            % [a,b,...,map]=JSON.PARSETEXT(json, 'x', 'y')
            %   Assigns the variables specified by names in the input, to
            %   the specified outputs. The number of requested variables
            %   ('x', 'y' etc) must match the number of outputs ('a', 'b'
            %   etc.).
            %   Spare outputs will be left empty.
            %   If an extra output argument is specified, it contains the
            %   map of handles as described below.
            %
            % Map of handles
            % When the json input describes hg graphics or GUI objects,
            % clones of those objects will be created by JSON.PARSETEXT.
            % The map of handles is a java.util.LinkedHasMap
            % with the following key, value pairs:
            %       Key                                 Value
            %  double representing              double representing
            %  the original handle              the handle of the cloned
            %  that was valid during            object created during
            %  the serialization stage          deserialization
            %                          OR
            %  double representing              reference to the
            %  the 32bit integer                equivalent Java component
            %  hash code of a                   created at deserialization.
            %  Java component
            %  at the serialization
            %  stage
            if ~isa(json, 'java.lang.String') && ~ischar(json)
                error('java.lang.String or hg char array required as input');
            end
            
            checkArguments(nargin, nargout, varargin);
            
            
            Json.HandleMap.clear();
            Json.BuildLater.clear();
            Json.BuildLaterCallbacks.clear();
            Json.AppData.clear();
            Json.BuildLaterFlag.set(true);
            varargout=cell(1,nargout());
            inc=0;
            
            if nargin>1
                TFsum=zeros(1, numel(varargin));
            else
                TFsum=[];
            end
            
            mapper=com.fasterxml.jackson.databind.ObjectMapper();
            % Needed to cope with unsigned integer classes ...
            mapper.enable(com.fasterxml.jackson.databind.DeserializationFeature.USE_BIG_INTEGER_FOR_INTS);
            parser=mapper.getFactory().createJsonParser(json);
            node=parser.readValueAsTree();
            
            fields=node.fields;
            
            while fields.hasNext()
                element=fields.next();
                key=char(element.getKey());
                
                if nargin>1 && ~any(strcmp(key,varargin))
                    continue
                end
                
                temp=deserializeMapEntry(element, key);
                if ~isempty(temp)
                    if nargout==0 || (nargin==1 && nargout==1)
                        % Create variables using stored name in caller workspace...
                        if isempty(strfind(key, '['))
                            assignin('caller', key, temp);
                        else
                            assignin('caller', matlab.lang.makeValidName(key), temp);
                        end
                    else
                        % ... or assign to outputs;
                        if nargin>1
                            TF = strcmp(key,varargin);
                            TFsum=TFsum+TF;
                            index= find(TF,1);
                            varargout{index}=temp;
                            %Json.KeyStore.put(key, index);
                        else
                            inc=inc+1;
                            varargout{inc}=temp;
                            %Json.KeyStore.put(key, inc);
                        end
                    end
                end
            end
            
            if Json.BuildLater.size()>0
                iterator=Json.BuildLater.iterator;
                Json.BuildLaterFlag.set(false);
                while iterator.hasNext
                    object=iterator.next();
                    key=char(object.get('key').textValue());
                    temp=deserializeObjectNode(object, char(object.get('_type').textValue()),key);
                    if ~isempty(key)
                        if nargout==0 || (nargin==1 && nargout==1)
                            % Create variables using stored name in caller workspace...
                            if isempty(strfind(key, '['))
                                assignin('caller', key, temp);
                            else
                                assignin('caller', matlab.lang.makeValidName(key), temp);
                            end
                        else
                            % ... or assign to outputs;
                            if nargin>1
                                TF = strcmp(key,varargin);
                                TFsum=TFsum+TF;
                                index= find(TF,1);
                                varargout{index}=temp;
                                %Json.KeyStore.put(key, index);
                            else
                                inc=inc+1;
                                varargout{inc}=temp;
                                %Json.KeyStore.put(key, inc);
                            end
                        end
                    end
                end
                Json.BuildLaterFlag.set(true);
            end
            
            addCallbacks();
            
            if ~isempty(TFsum)
                TF=TFsum==0;
                if any(TF)
                    warning('Json:notFound', 'Some requested variables were not found in the input');
                end
            end
            
            if nargout>0 && (nargin>1 && isempty(varargout{end})) || (nargout>nargin-1)
                varargout{end}=Json.HandleMap.clone();
            end
            
            Json.HandleMap.clear();
            Json.BuildLater.clear();
            Json.BuildLaterCallbacks.clear();
            Json.AppData.clear();
        end
        
        function varargout = load(fileName, varargin)
            % Deserializes a Json file. Decompression will be applied if
            % the files has a ".gz" extension.
            %
            % JSON.LOAD(fileName)
            % map=JSON.LOAD(fileName)
            %   Creates (or overwrites) all specified variables in the
            %   calling workspace.
            %   Where temporary variables are used as input to the
            %   serialization stage, those inputs are assigned a name of
            %   "[0]", "[1]" etc corresponding to their position in the
            %   input list. These variables will be deserialized using a
            %   valid Matlab variable name generated using
            %   matlab.lang.makeValidName. For "[0]" this will be "x_0_
            %   If a single output argument is specified, it contains the
            %   map of handles as described below.
            %
            % [a,b,...,map]=JSON.LOAD(fileName)
            %   Assigns variables to the specified output variables in the
            %   sequence that they are encountered in the input.
            %   Spare outputs will be left empty.
            %   If an extra output argument is specified, it contains the
            %   map of handles as described below.
            %   This form of call will generally only be useful when the
            %   variables within the json input is fully known.
            %
            % [a,b,...,map]=JSON.LOAD(fileName, 'x', 'y')
            %   Assigns the variables specified by names in the input, to
            %   the specified outputs. The number of requested variables
            %   ('x', 'y' etc) must match the number of outputs ('a', 'b'
            %   etc.).
            %   Spare outputs will be left empty.
            %   If an extra output argument is specified, it contains the
            %   map of handles as described below.
            %
            % Map of handles
            % When the json input describes hg graphics or GUI objects,
            % clones of those objects will be created by JSON.LOAD.
            % The map of handles is a java.util.LinkedHasMap
            % with the following key, value pairs:
            %       Key                                 Value
            %  double representing              double representing
            %  the original handle              the handle of the cloned
            %  that was valid during            object created during
            %  the serialization stage          deserialization
            %                          OR
            %  double representing              reference to the
            %  the 32bit integer                equivalent Java component
            %  hash code of a                   created at deserialization.
            %  Java component
            %  at the serialization
            %  stage
            
            checkArguments(nargin, nargout, varargin);
            
            Json.HandleMap.clear();
            Json.BuildLater.clear();
            Json.BuildLaterFlag.set(true);
            Json.BuildLaterCallbacks.clear();
            Json.AppData.clear();
            varargout=cell(1,nargout());
            inc=0;
            
            if nargin>1
                TFsum=zeros(1, numel(varargin));
            else
                TFsum=[];
            end
            
            mapper=com.fasterxml.jackson.databind.ObjectMapper();
            % Needed to cope with unsigned integer classes ...
            mapper.enable(com.fasterxml.jackson.databind.DeserializationFeature.USE_BIG_INTEGER_FOR_INTS);
            file = java.io.File(fileName);
            if strcmp(fileName(end-2:end), '.gz')
                isGzip=true;
            else
                isGzip=false;
            end
            reader=java.io.FileInputStream(file);
            if isGzip
                reader2=java.util.zip.GZIPInputStream(reader);
            else
                reader2=reader;
            end
            parser=mapper.getFactory().createJsonParser(reader2);
            node=parser.readValueAsTree();
            if isGzip
                reader2.close()
            end
            reader.close();
            
            fields=node.fields;
            
            while fields.hasNext()
                element=fields.next();
                key=char(element.getKey());
                
                if nargin>1 && ~any(strcmp(key,varargin))
                    continue
                end
                
                temp=deserializeMapEntry(element,key);
                if nargout==0 || (nargin==1 && nargout==1)
                    % Create variables using stored name in caller workspace...
                    if isempty(strfind(key, '['))
                        assignin('caller', key, temp);
                    else
                        assignin('caller', matlab.lang.makeValidName(key), temp);
                    end
                else
                    % ... or assign to outputs;
                    if nargin>1
                        TF = strcmp(key,varargin);
                        TFsum=TFsum+TF;
                        index= find(TF,1);
                        varargout{index}=temp;
                    else
                        inc=inc+1;
                        varargout{inc}=temp;
                    end
                end
            end
            
            if Json.BuildLater.size()>0
                iterator=Json.BuildLater.iterator;
                Json.BuildLaterFlag.set(false);
                while iterator.hasNext
                    object=iterator.next();
                    key=char(object.get('key').textValue());
                    temp=deserializeObjectNode(object, char(object.get('_type').textValue()),key);
                    if ~isempty(key)
                        if nargout==0 || (nargin==1 && nargout==1)
                            % Create variables using stored name in caller workspace...
                            if isempty(strfind(key, '['))
                                assignin('caller', key, temp);
                            else
                                assignin('caller', matlab.lang.makeValidName(key), temp);
                            end
                        else
                            % ... or assign to outputs;
                            if nargin>1
                                TF = strcmp(key,varargin);
                                TFsum=TFsum+TF;
                                index= find(TF,1);
                                varargout{index}=temp;
                            else
                                inc=inc+1;
                                varargout{inc}=temp;
                            end
                        end
                    end
                end
                Json.BuildLaterFlag.set(true);
            end
            
            addCallbacks();
            
            if ~isempty(TFsum)
                TF=TFsum==0;
                if any(TF)
                    warning('Json:notFound', 'Some requested variables were not found in the input');
                end
            end
            
            if nargout>0 && (nargin>1 && isempty(varargout{end})) || (nargout>nargin-1)
                varargout{end}=Json.HandleMap.clone();
            end
            
            Json.HandleMap.clear();
            Json.BuildLater.clear();
            Json.BuildLaterCallbacks.clear();
            Json.AppData.clear();
        end
        
        function keys = who(fileName)
            % Returns a char cell array of the entries in the specified file.
            %
            % varnames=JSON.WHO(fileName)
            %
            % Temporary variables specified on input will be returned by
            % their index, "[0]", "[1]" etc.
            % When returned to a Matlab workspace using JSON.LOAD, these
            % variables will be renamed as x_0_, x_1_ etc using
            % matlab.lang.makeValidName(...).
            mapper=com.fasterxml.jackson.databind.ObjectMapper();
            % Needed to cope with unsigned integer classes ...
            mapper.enable(com.fasterxml.jackson.databind.DeserializationFeature.USE_BIG_INTEGER_FOR_INTS);
            file = java.io.File(fileName);
            if strcmp(fileName(end-2:end), '.gz')
                isGzip=true;
            else
                isGzip=false;
            end
            reader=java.io.FileInputStream(file);
            if isGzip
                reader2=java.util.zip.GZIPInputStream(reader);
            else
                reader2=reader;
            end
            parser=mapper.getFactory().createJsonParser(reader2);
            node=parser.readValueAsTree();
            if isGzip
                reader2.close()
            end
            reader.close();
            fields=node.fields;
            keys={};
            while fields.hasNext()
                element=fields.next();
                keys{end+1}=char(element.getKey());
            end
        end
        
        
        function map=toMap(varargin)
            % JSON.TOMAP returns a linked hashmap describing the inputs
            %
            % Examples
            % JSON.TOMAP(1:10)
            % JSON.TOMAP(x)
            % JSON.TOMAP(handle)
            % JSON.TOMAP(object)
            % JSON.TOMAP(x,y,z);
            %
            % Supported input types include:
            % Primitives such as int8, uint8, int16, uint16, int32, uint32,
            % int64, uint64, double, single, logical and char.
            % Vectors and matrices
            % Cells and cell arrays
            % Structures and structure arrays
            % hg objects
            % hg handle graphics objects
            % Java objects
            
            initialise();
            
            if nargin==0
                map=[];
                return;
            end
            drawnow();
            
            % Use full java description
            TF=cellfun(@(x) (ischar(x) && strcmpi(x,'-concisejava')), varargin);
            if any(TF)
                varargin(TF)=[];
                Json.conciseJava.set(true);
            end
            
            % Use full matlab hg description
            TF=cellfun(@(x) (ischar(x) && strcmpi(x,'-concisematlab')), varargin);
            if any(TF)
                varargin(TF)=[];
                Json.conciseMatlab.set(true);
            end
            
            
            % Use base64
            TF=cellfun(@(x) (ischar(x) && strcmpi(x,'-base64')), varargin);
            if any(TF)
                varargin(TF)=[];
                Json.useBase64.set(true);
            end
            
            if ~isa(varargin{end}, 'VarNameWrapper')
                initialise();
                names=arrayfun(@inputname,1:length(varargin), 'UniformOutput', false);
                names=VarNameWrapper(names);
                varargin{end+1}=names;
            end
            
            value=varargin(1:end-1);
            
            if isa(varargin{end}, 'VarNameWrapper')
                names=varargin{end}.names;
                n=length(value);
            else
                names=cell(1,length(value));
                n=length(value);
            end
            
            map=java.util.LinkedHashMap(n,0.75);
            for m=1:n
                if isempty(names{m})
                    key = ['[' num2str(map.size()) ']'];
                else
                    key = names{m};
                end
                if isempty(value{m})
                    map.put(key, []);
                else
                    processElement(map, key, value{m});
                end
                
            end
        end
        
        function out=toBase64(string)
            % Utility method to encode a string as Base64
            out=char(Json.b64.encodeBase64(java.lang.String(string).getBytes()));
        end
        
        function out=fromBase64(string)
            % Utility method to recover a string from Base64
            out=char(Json.b64.decodeBase64(java.lang.String(string).getBytes()))';
        end
        
    end
end

%-----------------------------------------------------------------------
function processElement(map, field, value, convertHandlesToDouble)
%-----------------------------------------------------------------------
if nargin<4
    convertHandlesToDouble=false;
end

if Json.conciseMatlab.get
    switch field
        % If using conciseMatlab, skip these fields
        case {'Renderer', 'RendererMode', 'CurrentAxes','CurrentCharacter','CurrentObject', 'CurrentPoint',...
                'SelectionType', 'FileName', 'IntegerHandle', 'NextPlot', 'Alphamap','Colormap',...
                'GraphicsSmoothing', 'PointerShapeCData', 'PointerShapeHotSpot', 'NumberTitle',...
                'XDisplay', 'WindowStyle','DockControls', 'Resize', 'PaperPosition','PaperPositionMode','PaperSize',...
                'PaperType','PaperUnits','InvertHardcopy','PaperOrientation', 'CData'
                }
            return
    end
end


% Note: the order of these conditions enforces a precedence as some values
% would potentially satisfy more than one condition
if isempty(value)
    switch field
        case {'Tag','FileName','DisplayName','Name','XDataSource','YDataSource','ZDataSource','TooltipString', 'String'}
            map.put(field, Json.emptyString);
        otherwise
            map.put(field, []);
    end
elseif strcmp(field, 'Parent')
    % Cast parent to double - needed because of
    % circular references that will lead to infinite
    % recursion
    if isjava(value)
        map.put(field, value.toString());
    elseif ishandle(value)
        map2=java.util.LinkedHashMap(3,0.75);
        map2.put('_type', 'handle');
        map2.put('value', double(value));
        map2.put('_parentType', class(value));
        map.put(field, map2);
    end
elseif strcmp(field, 'CurrentAxes') || strcmp(field, 'CurrentObject') || strcmp(field, 'SelectedTab')
    % Current Axes and Current object can also be cast to double otherwise
    % they will be serialised twice
    map.put(field, double(value));
    % elseif strcmp(field, 'ColumnWidth')
    %     processCellArray(map, field, value);
    %     %map.put(field, cell2mat(value));
elseif strcmp(field, 'ColumnEditable')
    processNumeric(map, field, value);
elseif  isa(value, 'matlab.graphics.Graphics') && ~isscalar(value)
    processObjectArray(map, field, value);
elseif isjava(value)
    processJava(map, field, value);
elseif isa(value, 'reflector.FunctionHandleGetter')
    map.put(field,[]);
elseif isobject(value)
    if numel(value)==1
        if ishandle(value)
            if isvalid(value)
                processStructureOrObject(map, field, value, convertHandlesToDouble);
            else
                map.put(field, 'Invalid or deleted object');
            end
        else
            processStructureOrObject(map, field, value, convertHandlesToDouble);
        end
    else
        processObjectArray(map, field, value);
    end
elseif iscell(value)
    if isa(value{1}, 'function_handle')
        processCellArray(map, field, value, field);
    else
        processCellArray(map, field, value);
    end
elseif isstruct(value)
    processStructureOrObject(map, field, value, convertHandlesToDouble);
elseif isscalar(value)
    if isa(value, 'function_handle')
        f=functions(value);
        map2=java.util.LinkedHashMap(5,0.75);
        map2.put('_type', class(value));
        map2.put('functiontype', f.type);
        map2.put('asString', func2str(value));
        if isempty(strfind(field, '['))
            map2.put('target', field);
        end
        if strcmp(f.type, 'anonymous')
            if isfield(f, 'workspace')
                getWorkspace(value, f.workspace{1}, map2, field);
            end
        elseif strcmp(f.type, 'nested')
            if Json.includeNestedFunctionHandleWorkspace1 && isfield(f, 'workspace')
                getWorkspace(value, f.workspace{1}, map2, field);
            end
            
            if Json.includeNestedFunctionHandleWorkspace2 && isfield(f, 'workspace')
                getWorkspace(value, f.workspace{2}, map2, field);
            end
        elseif strcmp(f.type, 'scopedfunction')
            name=f.parentage;
            name=fliplr(name);
            path='';
            for k=1:length(name)
                path=[path name{k} '/'];
            end
            path(end)=[];
            map2.put('asString', path);
        elseif strcmp(f.type, 'simple')
        end
        map.put(field, map2);
    elseif ~isnumeric(value) && ishandle(value)
        processStructureOrObject(map, field,value);
    elseif isnumeric(value)
        if isfloat(value)
            if isa(value, 'double')
                if isreal(value) && isfinite(value)
                    if int64(value)==value
                        map.put(field, int64(value));
                    else
                        map.put(field, value);
                    end
                else
                    map2=java.util.LinkedHashMap(2,0.75);
                    map2.put('_type', class(value));
                    map2.put('content', asString(value));
                    map.put(field, map2);
                end
            else
                map2=java.util.LinkedHashMap(2,0.75);
                map2.put('_type', class(value));
                if isreal(value) && isfinite(value)
                    if int64(value)==value
                        map2.put('content', int64(value));
                    else
                        map2.put('content', value);
                    end
                else
                    map2.put('content', asString(value));
                end
                map.put(field, map2);
            end
        else
            % For other numeric types include the original type
            map2=java.util.LinkedHashMap(2,0.75);
            map2.put('_type', class(value));
            map2.put('content', java.math.BigDecimal(num2str(value)));
            map.put(field, map2);
        end
    elseif islogical(value)
        map.put(field, value);
    else
        map.put(field, value);
    end
elseif isnumeric(value) || islogical(value)
    processNumeric(map, field, value);
elseif ischar(value)
    map.put(field, value);
else
    try
        map2=java.util.LinkedHashMap(32,0.75);
        processStructureOrObject(map2, field, get(value), convertHandlesToDouble);
        map.put(field, map2);
    catch
        warning('Json:processElement', 'We ignored field: %s', field);
    end
end


end

%-----------------------------------------------------------------------
function s=asString(x)
%-----------------------------------------------------------------------
% Use java.lang.Double to convert to string as this gives us the exact
% value with the minimum number of digits.
if isa(x, 'double')
    if isreal(x)
        v=java.lang.Double.valueOf(x);
        s=v.toString();
    else
        vr=java.lang.Double.valueOf(real(x));
        vi=java.lang.Double.valueOf(imag(x));
        switch vi.compareTo(0.0)
            case {0,1}
                op='+';
            case -1
                op='-';
        end
        s=vr.toString().concat(op).concat(vi.toString()).concat('i');
    end
elseif isa(x, 'single')
    if isreal(x)
        v=java.lang.Float.valueOf(x);
        s=v.toString();
    else
        vr=java.lang.Float.valueOf(real(x));
        vi=java.lang.Float.valueOf(imag(x));
        switch vi.compareTo(0.0)
            case {0,1}
                op='+';
            case -1
                op='-';
        end
        s=vr.toString().concat(op).concat(vi.toString()).concat('i');
    end
else
    s=num2str(x);
end
end

%-----------------------------------------------------------------------
function processNumeric(map, field, value)
%-----------------------------------------------------------------------
map2=java.util.LinkedHashMap(2,0.75);
v=value(:);
sz=int64(size(value));
if isfloat(value) || islogical(value)
    if Json.shortenConstantArrays &&  ~issparse(value) && numel(value)>10 && all(v==value(1)) && all(isfinite(v)) && all(isreal(v))
        map2.put('_type', 'constant');
        map3=java.util.LinkedHashMap(3);
        map3.put('_type',class(value));
        map3.put('_size',sz);
        map3.put('value', value(1));
        map2.put('content', map3);
    elseif Json.shortenConstantArrays && numel(value)>10 && all(isnan(v))
        % Case of all(isnan(v)) being true
        map2.put('_type', 'constant');
        map3=java.util.LinkedHashMap(3);
        map3.put('_type',class(value));
        map3.put('_size',sz);
        map3.put('value', 'NaN');
        map2.put('content', map3);
    elseif ~issparse(value) && (~isreal(value) || any(~isfinite(v)))
        % If we have any values that are not supported in Json, convert these to
        % text...
        map2.put('_type', class(value));
        map2.put('_size',sz);
        value=reshapeAndPermute(value,sz);
        t=arrayfun(@(x) asString(x), value, 'UniformOutput', false);
        map2.put('content', t);
    elseif Json.shortenSparse && issparse(value)
        [i,j,vec]=find(value);
        map2.put('_type', 'sparse');
        map3=java.util.LinkedHashMap(3);
        map3.put('_type',class(value));
        map3.put('_size',sz);
        if ismatrix(value)
            map3.put('row', int64(i));
        end
        map3.put('column', int64(j));
        if all(int64(vec)==vec)
            map3.put('values', int64(vec));
        elseif all(isreal(vec)) && all(isfinite(vec))
            map3.put('values', vec);
        else
            list=java.util.ArrayList();
            for k=1:length(vec)
                list.add(asString(vec(k)));
            end
            map3.put('values', list);
        end
        map2.put('content', map3);
    elseif Json.shortenRanges && numel(value)>20 && isscalar(unique(diff(value)))
        map2.put('_type', 'range' );
        map3=java.util.LinkedHashMap(3);
        map3.put('_type',class(value));
        map3.put('_size',sz);
        map3.put('start', value(1));
        map3.put('end', value(end));
        map3.put('increment', value(2)-value(1));
        map2.put('content', map3);
    elseif isa(value, 'double')
        value=reshapeAndPermute(value,sz);
        if Json.useBase64.get() && numel(value)>50
            map2.put('_size', sz);
            map2.put('encoding', 'base64');
            if java.nio.ByteOrder.nativeOrder ~= java.nio.ByteOrder.nativeOrder.LITTLE_ENDIAN
                value=swapbytes(value);
            end
            data=int8(num2str(value(:)'));
            map2.put('content', data);
        elseif ~issparse(value) && all(int64(v)==v)
            map2.put('_size', sz);
            map2.put('content', int64(value));
        else
            map2.put('_size', sz);
            map2.put('content', value);
        end
    elseif isa(value, 'single')
        value=reshapeAndPermute(value,sz);
        if ~issparse(value) && all(int64(v)==v)
            map2.put('_type', class(value));
            map2.put('_size', sz);
            map2.put('content', int64(value));
        else
            map2.put('_type', class(value));
            map2.put('_size', sz);
            map2.put('content', value);
        end
    elseif Json.shortenConstantArrays && numel(value)>10 && all(v==value(1))
        map2.put('_type', 'constant');
        map3=java.util.LinkedHashMap(3);
        map3.put('_type',class(value));
        map3.put('_size',sz);
        map3.put('value', value(1));
        map2.put('content', map3);
    elseif Json.shortenRanges && numel(value)>10 && isvector(value) && isscalar(unique(diff(value)))
        map2.put('_type', 'range' );
        map3=java.util.LinkedHashMap(3);
        map3.put('_type',class(value));
        map3.put('_size',sz);
        map3.put('start', value(1));
        map3.put('end', value(end));
        map3.put('increment', value(2)-value(1));
        map2.put('content', map3);
    elseif islogical(value) && Json.logicalArraysAsNumber
        value=reshapeAndPermute(value,sz);
        map2.put('_type', class(value));
        map2.put('content', int16(value));
    else
        map2.put('_type',class(value));
        map2.put('_size', sz);
        value=reshapeAndPermute(value,sz);
        map2.put('content', asBigInteger(value));
    end
end
map.put(field, map2);
end

%-----------------------------------------------------------------------
function out=asBigInteger(value)
%-----------------------------------------------------------------------
out=javaArray('java.math.BigInteger', numel(value));
for k=1:numel(value)
    out(k)=java.math.BigInteger(num2str(value(k)));
end
end

%-----------------------------------------------------------------------
function processJava(map, field, v)
%-----------------------------------------------------------------------
if isempty(v)
    map.put(field, []);
elseif strcmpi(field, 'parent')
    map.put(field, v.toString());
elseif strcmpi(field, 'rootpane') || strcmpi(field, 'TopLevelAncestor')
    map.put(field, v.toString());
elseif strfind(field, 'Class')
    % Again, Class of Class = Class so need to break the loop.
    map.put('_type', class(v));
elseif isa(v, 'java.awt.Cursor')
    map.put(field, v.getType());
elseif isa(v, 'java.awt.Font')
    map2=java.util.LinkedHashMap(5,0.75);
    map2.put('_type', 'java.awt.Font');
    map2.put('FamilyName', v.getFamily());
    map2.put('Name', v.getName());
    style=v.getStyle();
    switch style
        case java.awt.Font.PLAIN
            s = 'PLAIN';
        case java.awt.Font.ITALIC
            s = 'ITALIC';
        case java.awt.Font.BOLD
            s=  'BOLD';
        case java.awt.Font.ITALIC + java.awt.Font.BOLD
            s= 'ITALIC BOLD';
    end
    map2.put('Style', s);
    map2.put('ItalicAngle', v.getItalicAngle());
    map2.put('Size2D', v.getSize2D());
    map.put(field, map2);
elseif isa(v, 'java.awt.AWTKeyStroke')
    map.put(field, v.toString());
elseif isa(v, 'java.lang.String')
    map.put(field, v);
elseif isa(v, 'java.awt.Color')
    % Replace color with RGB and alpha.
    map2=java.util.LinkedHashMap(2,0.75);
    map2.put('_type', 'java.awt.Color');
    components=[];
    components=v.getComponents(components);
    map2.put('args', components);
    map.put(field, map2);
elseif isa(v, 'java.awt.Point')
    map2=java.util.LinkedHashMap(2,0.75);
    map2.put('_type', class(v));
    map2.put('args', [v.getX() v.getY()]);
    map.put(field, map2);
elseif isa(v, 'java.awt.Dimension')
    map2=java.util.LinkedHashMap(2,0.75);
    map2.put('_type', class(v));
    map2.put('args', [v.getWidth() v.getHeight()]);
    map.put(field, map2);
elseif isa(v, 'java.awt.Rectangle')
    map2=java.util.LinkedHashMap(2,0.75);
    map2.put('_type', class(v));
    map2.put('args', [v.getX() v.getY() v.getWidth() v.getHeight()]);
    map.put(field, map2);
elseif isa(v, 'java.awt.Insets')
    map2=java.util.LinkedHashMap(2,0.75);
    map2.put('_type', class(v));
    map2.put('args', [v.top v.left v.bottom v.right]);
    map.put(field, map2);
elseif isa(v, 'java.lang.Number')
    map2=java.util.LinkedHashMap(2,0.75);
    map2.put('_type', class(v));
    map2.put('value', v.toString());
    map.put(field, map2);
elseif isa(v, 'java.util.Map') || isa(v, 'java.util.Dictionary')
    keys=v.keySet().toArray();
    values=v.values().toArray();
    map2=java.util.LinkedHashMap(length(keys),0.75);
    for k=1:length(keys)
        if isjava(values(k))
            processJava(map2, keys(k), values(k));
        else
            processElement(map2, keys(k), values(k));
        end
    end
    map3=java.util.LinkedHashMap(2,0.75);
    map3.put('_type', class(v));
    map3.put('content', map2);
    map.put(field, map3);
elseif isa(v, 'java.util.Collection')
    elements=v.toArray();
    map2=java.util.LinkedHashMap(v.size(),0.75);
    for k=1:v.size()
        processElement(map2, ['[' num2str(int64(k-1)) ']'], elements(k));
    end
    map3=java.util.LinkedHashMap(2,0.75);
    map3.put('_type', class(v));
    map3.put('content', map2);
    map.put(field, map3);
elseif v.getClass().isArray() && v.length()>0
    processObjectArray(map, field, v);
elseif isa(v, 'java.util.Locale')
    map2=java.util.LinkedHashMap(4,0.75);
    map2.put('_type', 'java.util.Locale');
    map2.put('Language', v.getLanguage());
    map2.put('Country', v.getCountry());
    map2.put('Variant', v.getVariant());
    map.put(field, map2);
elseif isa(v, 'java.awt.event.Listener')
elseif strfind(field, 'Accessible')
elseif strfind(field, 'SystemClipboard')
elseif  strfind(field, 'Notifier')
elseif strfind(class(v), 'com.mathworks.hg.peer')
elseif strcmpi(field, 'ui')
elseif isa(v, 'java.awt.Graphics')
elseif isa(v, 'java.awt.GraphicsConfiguration')
elseif Json.conciseJava.get()
    if isa(v, 'javax.swing.JSlider') || ~isempty(strfind(class(v), 'javahandle_withcallbacks'))
        map2=java.util.LinkedHashMap(9,1);
        map2.put('_type', class(v));
        map2.put('hashCode', int32(v.hashCode()));
        map2.put('Minimum', v.getMinimum());
        map2.put('Maximum', v.getMaximum());
        map2.put('PaintTicks', v.getPaintTicks());
        map2.put('PaintLabels', v.getPaintLabels());
        map2.put('MinorTickSpacing', v.getMinorTickSpacing());
        map2.put('MajorTickSpacing', v.getMajorTickSpacing());
        map2.put('Orientation', v.getOrientation())
        map.put(field, map2);
    end
else
    
    try
        s=get(v);
    catch ex
        map.put(field, v.toString());
        return;
    end
    fields=fieldnames(s);
    values=struct2cell(s);
    
    % Only look at setable fields
    setable=fieldnames(set(v));
    TF=~ismember(fields, setable);
    fields(TF)=[];
    values(TF)=[];
    
    if Json.omitNullValuesJava
        TF=cellfun(@isempty, values);
        fields(TF)=[];
        values(TF)=[];
    end
    map2=java.util.LinkedHashMap(length(fields)+2,0.75);
    map2.put('_type', class(v));
    if isa(v, 'java.awt.Component') || ~isempty(strfind(class(v), 'javahandle_withcallbacks'))
        map2.put('hashCode', int32(v.hashCode()));
    end
    for k=1:length(fields)
        
        if isjava(values{k})
            try
                % This can fail on some objects
                if values{k}==v
                    map2.put(fields{k}, '@self-reference');
                end
            catch
            end
            if values{k}.equals(v)
                map2.put(fields{k}, '@near self-reference');
            else
                processJava(map2, fields{k}, values{k});
            end
        else
            processElement(map2, fields{k}, values{k});
        end
    end
    map.put(field, map2);
end
end




%-----------------------------------------------------------------------
function processObjectArray(map, field, value)
% Serialize a hg array of objects
%-----------------------------------------------------------------------
% Create a map to represent these items
map2=java.util.LinkedHashMap(numel(value),0.75);
if isjava(value)
    map2.put('_type', class(value));
else
    map2.put('_type', [class(value) '[Array]']);
end
map2.put('_size', int64(size(value)));
for m=1:numel(value)
    % Define a key for the map
    key = getSubsAsString(value, m);
    processElement(map2, key, value(m));
end
% Add map to the parent map.
map.put(field, map2);
end

%-----------------------------------------------------------------------
function processCellArray(map, field, value, callBackTarget)
% Serialize a cell array
%-----------------------------------------------------------------------

if nargin<4
    callBackTarget='';
end

map2=java.util.LinkedHashMap(32,0.75);
map2.put('_type', class(value));
if ~isscalar(value)
    map2.put('_size', uint64(size(value)));
end
try
    useMatrix=Json.cellArrayAsMatrix & isscalar(unique(cellfun(@class, value, 'UniformOutput', false)));
catch
    z=1
end
if useMatrix && isnumeric(value{1})
    v=cell2mat(value);
    processElement(map2, '_asArray', v);
    map.put(field, map2);
elseif useMatrix && ischar(value{1})
    list=java.util.ArrayList();
    for k=1:numel(value)
        list.add(value(k));
    end
    map2.put('_asArray', list);
    map.put(field, map2);
else
    % Create a map to represent these items
    for m=1:numel(value)
        % Define a key for the map
        key = getSubsAsString(value, m);
        if isscalar(value{m}) && ishandle(value{m}) && ~isempty(strfind(field, 'Callback'))
            % If this cell array is in a callback property, convert any
            % handle to double
            map3=java.util.LinkedHashMap(2,0.75);
            map3.put('_type', 'handle')
            map3.put('value', double(value{m}));
            map2.put(key, map3);
        elseif isscalar(value{m}) && ~isempty(strfind(class(value{m}), 'javahandle_withcallbacks')) && ~isempty(callBackTarget)
            z=88;
        elseif  isa(value{m}, 'function_handle') && ~isempty(callBackTarget)
            for k=1:length(value)
                if ishandle(value{k})
                    s.type='handle';
                    s.value=double(value{k});
                    value{k}=s;
                end
            end
            processElement(map2, key, value{m});
            map2.get(key).put('target', field);
        else
            processElement(map2, key, value{m});
        end
    end
    % Add map to the parent map.
    map.put(field, map2);
end
end

%-----------------------------------------------------------------------
function processStructureOrObject(parentMap, field, s, convertHandlesToDouble)
% Serialize a structure, object (or a structure array)
%-----------------------------------------------------------------------

if nargin<4
    % When set to true, this forces handle objects to be converted to
    % double instead of fully serialised. It also prevents function_handles
    % being added
    convertHandlesToDouble=false;
end

map=java.util.LinkedHashMap(64,0.75);
if isstruct(s)
    map.put('_type', 'struct');
else
    map.put('_type', class(s));
    try
        map.put('_handle', double(s));
        ppos=getpixelposition(s);
        if ~any(ppos)
            units=get(s,'Units');
            set(s,'Units', 'pixels');
            ppos=get(s,'Position');
            set(s,'Units',units);
            if numel(ppos)==3
                ppos(end+1)=0;
            end
        end
        if any(ppos)
            if isa(s, 'matlab.ui.Figure')
                pppos=get(0,'ScreenSize');
            else
                pppos=getpixelposition(get(s,'Parent'));
            end
            % Reference to top/left as 0,0 (not bottom left as 1,1 as in hg)
            % Give [anchorLeft anchorTop width height anchorRight anchorBottom]
            pos=round(10*[ppos(1)-1 pppos(4)-(ppos(2)+ppos(4))-1 ppos(3) ppos(4) pppos(3)-(ppos(1)+ppos(3)) ppos(2)])/10;
            map.put('_ppos', pos);
        end
    catch ex
    end
end

if ~isscalar(s)  && ~isrow(s)
    map.put('_size', int64(size(s)));
end

if numel(s)==1
    if isjava(s)
        warning('Should not get here');
    elseif isobject(s)
        omitEmptyEntries=Json.omitEmptyObjectProperties;
        if ishandle(s)
            if isvalid(s)
                s2=get(s);
                fields = fieldnames(s2);
                values = struct2cell(s2);
                if Json.settableOnlyFlag
                    % Only look at settable fields
                    TF=~ismember(fields, fieldnames(set(s)));
                    fields(TF)=[];
                    values(TF)=[];
                end
            else
                fprintf(2, 'Json: Looks like a deleted or invalid handle has been specified on input: "%s"\n', field);
                parentMap.put(field, []);
                return
            end
        else
            s2=get(s);
            fields = fieldnames(s2);
            values = struct2cell(s2);
        end
    elseif isstruct(s)
        omitEmptyEntries=false;
        fields = fieldnames(s);
        values = struct2cell(s);
    else
        fprintf(2, 'Json: Unsupported class "%s in %s"\n', class(s), field);
    end
    
    
    if omitEmptyEntries
        TF=cellfun(@isempty, values);
        fields(TF)=[];
        values(TF)=[];
    end
    
    for k=1:length(fields)
        if isjava(values{k})
            processJava(map, fields{k}, values{k});
        elseif ~isempty(strfind(class(values{k}), 'javahandle_withcallbacks'))
            processJava(map, fields{k}, values{k});
        elseif isscalar(values{k}) && convertHandlesToDouble && ishandle(values{k})
            map2=java.util.LinkedHashMap(2,0.75);
            map2.put('_type', 'handle');
            map2.put('value', double(values{k}));
            map.put(fields{k}, map2);
        else
            processElement(map, fields{k}, values{k}, convertHandlesToDouble);
        end
        
    end
    
else
    for k=1:numel(s)
        key = getSubsAsString(s, k);
        processStructureOrObject(map, key, s(k));
    end
end

% Application data
try
    if isobject(s)
        appData=[];
        try
            appData=getappdata(s);
        catch ex
            if ~strcmp(ex.identifier, 'hg:hgbuiltins:NoAppdataProp')
                rethrow(ex);
            end
        end
        
        if ~isempty(appData) && ~isempty(fieldnames(appData))
            processStructureOrObject(map, 'ApplicationData', appData, true);
        end
    end
catch
end

parentMap.put(field, map);
end

%-----------------------------------------------------------------------
function text=getSubsAsString(matrix, index)
% Returns this subindices for index in matrix as a char array using
% zero based indexing
%-----------------------------------------------------------------------
[subs{1:ndims(matrix)}]=ind2sub(size(matrix),index);
text='[';
for k=1:length(subs)-1
    text=[text num2str(subs{k}-1) ', '];
end
text=[text num2str(subs{end}-1) ']'];
end

%-----------------------------------------------------------------------
function space=getWorkspace(funchandle, space, map, field)
%-----------------------------------------------------------------------
if isempty(space)
    return
end
fields=fieldnames(space);
for k=1:length(fields)
    if strcmp(fields{k}, 'varargin')
        space=rmfield(space, 'varargin');
    elseif strcmp(fields{k}, 'varargout')
        space=rmfield(space, 'varargout');
    elseif iscell(space.(fields{k}))
        TF=cellfun(@isa, space.(fields{k}), repmat({'function_handle'}, size(space.(fields{k}))));
        index=find(TF);
        for n=1:length(index)
            s=func2str(space.(fields{k}){index});
            space.(fields{k}){index}=struct('_type', 'function_handle', 'functiontype', 'anonymous',...
                'asString', '@()disp(''JSON: REMOVED FUNCTION HANDLE WORKSPACE SELF REFERENCE'')',...
                'target', field);
        end
        space.(fields{k})=convertFromCell(space.(fields{k}), fields{k});
    elseif isjava(space.(fields{k})) || ~isempty(strfind(class(space.(fields{k})), 'javahandle_withcallbacks'));
        s=[];
        s.type=class(space.(fields{k}));
        s.hashCode=space.(fields{k}).hashCode();
        space.(fields{k})=s;
    elseif ishandle(space.(fields{k}))
        s=[];
        s.type='handle';
        s.value=double(space.(fields{k}));
        space.(fields{k})=s;
    end
end
processStructureOrObject(map, 'workspace', space, true);
end

%-----------------------------------------------------------------------
function in=convertFromCell(in, field)
%-----------------------------------------------------------------------
for kk=1:length(in)
    if isa(in{kk}, 'function_handle')
        f=functions(in{kk});
        if isfield(f, 'workspace')
            space=f.workspace{1};
            if isfield(space, field)
                space=rmfield(space, field);
            end
            if isfield(space, 'varargin')
                space=rmfield(space, 'varargin');
            end
            if isfield(space, 'varargout')
                space=rmfield(space, 'varargout');
            end
            in{kk}=struct('_type', 'function_handle', 'functiontype', f.type, 'asString', func2str(in{kk}), 'workspace', space);
        else
            in{kk}=struct('_type', 'function_handle', 'functiontype', f.type, 'asString', func2str(in{kk}));
        end
    elseif isjava(in{kk}) || (isscalar(in{kk}) && ~isempty(strfind(class(in{kk}), 'javahandle_withcallbacks')));
        s2.type=class(in{kk});
        s2.hashCode=in{kk}.hashCode();
        in{kk}=s2;
    elseif ishandle(in{kk})
        s.type='handle';
        s.value=double(in{kk});
        in{kk}=s;
    end
end
end


%**********************************************************
%   Deserialization code
%**********************************************************

%-----------------------------------------------------------------------
function temp=deserializeMapEntry(mapEntry, key)
%-----------------------------------------------------------------------
% The value stored in this mapEntry
value=mapEntry.getValue();
% Retrieve the data type - 'double' or 'char' where none
% specified
type=value.get('_type');
if isempty(type)
    if isa(value, 'com.fasterxml.jackson.databind.node.TextNode')...
            || (isa(value,'com.fasterxml.jackson.databind.node.ArrayNode') && value.get(0).isTextual())
        type='char';
    else
        type='double';
    end
else
    type=char(type.toString().replaceAll('"',''));
end
temp=deserializeNode(value, type, key);
end

%------------------------------------------------------------------------
function temp=deserializeNode(node, type, key, updataHandles)
%------------------------------------------------------------------------
if nargin<3
    key='';
end
if nargin<4
    updataHandles=false;
end
if isa(node, 'com.fasterxml.jackson.databind.node.TextNode')
    temp=char(node.textValue());
elseif isa(node, 'com.fasterxml.jackson.databind.node.NumericNode')
    % Scalar value - only doubles are serialized
    % this way: other data types will always be
    % stored with a type.
    temp=node.doubleValue();
elseif isa(node,'com.fasterxml.jackson.databind.node.ObjectNode')
    temp=deserializeObjectNode(node, type, key, updataHandles);
elseif isa(node, 'com.fasterxml.jackson.databind.node.ArrayNode')
    temp=deserializeArrayNode(node, type);
elseif isa(node, 'com.fasterxml.jackson.databind.node.NullNode')
    temp=[];
elseif isa(node, 'com.fasterxml.jackson.databind.node.BooleanNode')
    temp=node.booleanValue();
else
    fprintf(2, 'Json: deserializeNode FAILED: unsupported type: %s', class(node));
    temp=[];
end
end

%-----------------------------------------------------------------------
function temp=deserializeArrayNode(node, type)
%-----------------------------------------------------------------------
switch type
    case 'double'
        str=node.toString().replaceAll('"','''').replaceAll('Infinity', 'Inf').replaceAll(''',''',' ').replaceAll('''','');
        temp=str2num(char(str));
    case 'char'
        str=node.toString().replaceAll('","',''';''').replaceAll('"','''');
        temp=eval(char(str));
    otherwise
        fprintf(2, 'Json: deserializeArrayNode FAILED: unsupported type: %s', type);
        temp=[];
end
end

%-----------------------------------------------------------------------
function temp=deserializeObjectNode(value, type, key, updateHandles)
%-----------------------------------------------------------------------
if nargin<3
    key='';
end
if nargin<4
    updateHandles=false;
end
content=value.get('content');
if isempty(content)
    switch type
        case 'cell'
            fields=value.fieldNames();
            sz=value.get('_size');
            if isempty(sz)
                sz=[1,1];
            else
                fields.next();
                sz=str2num(sz);
            end
            temp={};
            while fields.hasNext()
                field=fields.next();
                if strcmp(field, '_type') || strcmp(field, '_size')
                    continue;
                else
                    node=value.get(field);
                    innerType=node.get('_type');
                    if isempty(innerType)
                        if isa(node, 'com.fasterxml.jackson.databind.node.TextNode')...
                                || (isa(node,'com.fasterxml.jackson.databind.node.ArrayNode') && node.get(0).isTextual())
                            innerType='char';
                        else
                            innerType='double';
                        end
                    else
                        innerType=char(innerType.textValue());
                    end
                    temp{end+1}=deserializeNode(node, innerType, char(field));
                end
            end
            temp=reshape(temp, sz);
        case 'function_handle'
            temp=char(value.get('asString').textValue());
            functiontype=char(value.get('functiontype').textValue());
            if strcmp(functiontype, 'nested')
                space=value.get('workspace');
                temp=createLocalOrNestedFunction(temp, space);
            elseif strcmp(functiontype, 'scopedfunction')
                temp=createLocalOrNestedFunction(temp, []);
            elseif strcmp(functiontype, 'anonymous')
                space=value.get('workspace');
                if isempty(space) || isa(space, 'com.fasterxml.jackson.databind.node.NullNode')
                    temp=str2func(temp);
                else
                    temp=createAnonymousFunction(temp, space);
                end
            elseif strcmp(functiontype, 'simple')
                temp=str2func(temp);
            else
                fprintf(2, 'Json: Unsupported function_handle. Type = %s\n', char(value.get('functiontype').textValue()));
            end
        case 'handle'
            if updateHandles
                temp=value.get('value').doubleValue();
                temp=handle(Json.HandleMap.get(temp));
            else
                temp=value.get('value').doubleValue();
            end
        case 'matlab.ui.control.WebComponent'
            temp=[];
        case 'matlab.ui.container.internal.JavaWrapper'
            innerType=char(value.get('JavaPeer').get('_type').textValue());
            % Construct a new instance of the Java peer
            f=str2func(innerType);
            temp=f();
            
            % Add it via javacomponent
            units=deserializeNode(value.get('Units'), 'char');
            position=deserializeNode(value.get('Position'), 'double','');
            parent=Json.HandleMap.get(value.get('Parent').get('value').doubleValue());
            [temp, container]=javacomponent(temp, [1 1 100 100], handle(parent));
            set(container, 'Units', units, 'Position', position);
            
            % Set the properties of the new instance
            fields=value.get('JavaPeer').fieldNames();
            while fields.hasNext()
                field=char(fields.next());
                if strcmp(field, '_type') || strcmp(field, '@hashcode')
                    continue
                end
                propValue=value.get('JavaPeer').get(field);
                try
                    if ~isempty(strfind(field, 'Callback')) && isempty(strfind(field, 'Data')) && ~isa(propValue, 'com.fasterxml.jackson.databind.node.NullNode');
                        Json.BuildLaterCallbacks.put(temp, propValue);
                        %temp.(field)=deserializeNode(propValue, char(propValue.get('_type').textValue()));
                    else
                        type=propValue.get('_type');
                        if isa(type, 'com.fasterxml.jackson.databind.node.TextNode')
                            temp.(['set' field])(deserializeNode(propValue, char(type.textValue())));
                        else
                            temp.(['set' field])(deserializeNode(propValue));
                        end
                    end
                catch ex
                end
            end
            Json.HandleMap.put(value.get('_handle').doubleValue(), double(container));
            Json.HandleMap.put(value.get('JavaPeer').get('hashCode').doubleValue(), temp);
        case 'java.awt.Color'
            args=single(deserializeArrayNode(value.get('args'), 'double'));
            temp=java.awt.Color(args(1), args(2), args(3), args(4));
        case 'java.awt.Dimension'
            args=deserializeArrayNode(value.get('args'), 'double');
            temp=java.awt.Point(args(1), args(2));
        case 'java.awt.Point'
            args=int32(deserializeArrayNode(value.get('args'), 'double'));
            temp=java.awt.Point(args(1), args(2));
        case {'java.awt.Rectangle', 'java.awt.Insets'}
            f=str2func(type);
            args=int32(deserializeArrayNode(value.get('args'), 'double'));
            temp=f(args(1), args(2), args(3), args(4));
        case 'java.awt.Font'
            name=char(value.get('Name').textValue());
            style=eval(['java.awt.Font.' char(value.get('Style').textValue())]);
            size=value.get('Size2D').doubleValue();
            temp=java.awt.Font(name, style, size);
        case {'java.lang.Byte', 'java.lang.Short', 'java.lang.Integer', 'java.lang.Long',...
                'java.lang.Float', 'java.lang.Double', 'java.math.BigInteger', 'java.math.BigDecimal'}
            f=str2func(type);
            temp=f(value.get('value').textValue());
        case 'java.util.Locale'
            temp=java.util.Locale(value.get('Language').textValue(), value.get('Country').textValue(), value.get('Variant').textValue());
        otherwise
            if strcmp(type, 'struct')
                temp = getAsStructure(value, updateHandles);
            elseif ~isempty(strfind(type, 'matlab'))
                [s,childNodes,callbacks]=getAsStructure(value);
                if Json.BuildLaterFlag.get() && isfield(s, 'Parent') && s.Parent~=0 && isempty(Json.HandleMap.get(double(s.Parent)))
                    % This object's parent has not been created yet. It is
                    % a child but not among the 'Children' e.g. an XLabel
                    % for a Matlab Axes.
                    value.put('key', key);
                    Json.BuildLater.add(value);
                    temp=[];
                    return
                end
                % Create the new object
                temp=createMatlabObject(s, type, value);
                
                % Deserialize the children - these will be instantiated via
                % the call to deserializeObjectNode
                if isa(childNodes, 'com.fasterxml.jackson.databind.node.ObjectNode')
                    sz=childNodes.get('_size');
                    if isempty(sz)
                        deserializeObjectNode(childNodes, char(childNodes.get('_type').textValue()));
                    else
                        iterator=childNodes.fieldNames();
                        while iterator.hasNext
                            field=iterator.next();
                            if strcmp(field, '_type') || strcmp(field, '_size')
                                continue;
                            else
                                innerNode=childNodes.get(field);
                                deserializeObjectNode(innerNode, char(innerNode.get('_type').textValue()), char(field));
                            end
                        end
                    end
                    
                end
                
                % Add callbacks at end - solves issues where handles are
                % provided as arguments and the new objects have not been
                % created yet.
                if ~isempty(callbacks)
                    for k=1:length(callbacks)
                        innerNode=value.get(callbacks{k});
                        if ~isa(innerNode, 'com.fasterxml.jackson.databind.node.NullNode')
                            Json.BuildLaterCallbacks.put(double(temp), innerNode);
                        end
                    end
                end
            elseif ~isempty(strfind(type, 'javahandle_withcallbacks'))
                try
                    temp=Json.HandleMap.get(value.get('hashCode').doubleValue());
                catch ex
                    fprintf(2,'Json: %s not in HandleMap\n', type);
                    temp=[];
                end
            else
                fprintf(2,'Json: Failed to deserialize node of type %s\n', type);
                temp='UNSUPPORTED';
            end
    end
elseif content.isArray()
    str=content.toString().replaceAll('"','''').replaceAll('Infinity', 'Inf').replaceAll(''',''',' ').replaceAll('''','');
    temp=eval(['str2num(''' type '('  char(str) ')'');']);
    sz=deserializeArrayNode(value.get('_size'), 'double');
    temp=reshape(temp, sz);
elseif content.isTextual()
    if ~isempty(value.get('encoding')) && strcmp(value.get('encoding').textValue(), 'base64')
        sz=deserializeArrayNode(value.get('_size'), 'double');
        temp=str2num(char(Json.b64.decodeBase64(content.textValue().getBytes('UTF-8'))'));
        temp=typecast(temp, type);
        temp=reshape(temp,sz);
    else
        % Scalar value as text
        str=content.textValue().replaceAll('Infinity', 'Inf');
        temp=eval(['str2num(''' type '('  char(str) ')'');']);
        temp=cast(temp, type);
    end
else
    switch type
        case {'double', 'single', 'int8','uint8','int16', 'uint16', 'int32', 'uint32', 'int64', 'uint64'}
            temp=str2num([type '('  char(value.get('content').toString()) ')']); %#ok<*ST2NM>
            sz=deserializeArrayNode(content.get('_size'), 'double');
            temp=reshape(temp, sz);
            temp=cast(temp, char(content.get('_type').textValue()));
        case 'range'
            sz=deserializeArrayNode(content.get('_size'), 'double');
            temp=content.get('start').doubleValue():content.get('increment').doubleValue():content.get('end').doubleValue();
            temp=reshape(temp, sz);
            temp=cast(temp, char(content.get('_type').textValue()));
        case 'constant'
            sz=deserializeArrayNode(content.get('_size'), 'double');
            temp=ones(sz, char(content.get('_type').textValue()));
            temp=temp*content.get('value').doubleValue();
            temp=cast(temp, char(content.get('_type').textValue()));
        case 'sparse'
            sz=deserializeArrayNode(content.get('_size'), 'double');
            r=deserializeNode(content.get('row'), 'double','');
            c=deserializeNode(content.get('column'), 'double','');
            temp=spalloc(sz(1), sz(2), length(r));
            v=deserializeNode(content.get('values'), 'double','');
            for k=1:length(r)
                temp(r(k),c(k))=v(k); %#ok<SPRIX>
            end
            temp=cast(temp, char(content.get('_type').textValue()));
        otherwise
            fprintf(2, 'Json: Failed to deserialize node of type %s\n', type);
            temp='TODO';
    end
end
end

%-----------------------------------------------------------------------
function temp=reshapeAndPermute(temp, sz)
%-----------------------------------------------------------------------
if ~(length(sz)==2 && sz(1)==1)
    % Reshape to original dimensions
    % reversed...
    dim=fliplr(sz);
    temp=reshape(temp, dim);
    % ... then restore column-major order
    nd=length(sz);
    nd=nd:-1:1;
    temp=permute(temp, nd);
end
end

%-----------------------------------------------------------------------
function [temp, children, callbacks]=getAsStructure(value, updateHandles)
%-----------------------------------------------------------------------
if nargin<2
    updateHandles=false;
end
fields=value.fieldNames();
temp=struct();
callbacks={};
while fields.hasNext()
    field=fields.next();
    if strcmp(field, '_type') || strcmp(field, '_size') || strcmp(field, '_handle')...
            || strcmp(field, '_parentType') || strcmp(field, '_ppos') || strcmp(field, 'Children')
        continue;
    elseif ~isempty(strfind(field, 'Callback'))
        callbacks{end+1}=field;
    else
        node=value.get(field);
        innerType=node.get('_type');
        if isempty(innerType)
            if isa(node, 'com.fasterxml.jackson.databind.node.TextNode')...
                    || (isa(node,'com.fasterxml.jackson.databind.node.ArrayNode') && node.get(0).isTextual())
                innerType='char';
            else
                innerType='double';
            end
        else
            innerType=char(innerType.textValue());
        end
        
        if ~isempty(node.get('encoding'))
            temp.(field)=str2num(char(Json.b64.decodeBase64(node.get('content').textValue().getBytes('UTF-8'))'));
            temp.(field)=reshape(temp.(field), deserializeNode(node.get('_size'), 'double'));
        else
            if isempty(strfind(field, '['))
                temp.(field)=deserializeNode(node, innerType, '', updateHandles);
            else
                temp.(matlab.lang.makeValidName(field))=deserializeNode(node, innerType, '', updateHandles);
            end
        end
        children=value.get('Children');
    end
end
end

%-----------------------------------------------------------------------
function temp=createMatlabObject(temp, type, value)
%-----------------------------------------------------------------------

if ~Json.settableOnlyFlag
    temp=removeNotSettableProperties(temp);
end

% Must remove CurrentAxes as not create yet
if isfield(temp, 'CurrentAxes')
    %currentAxes=temp.CurrentAxes;
    % TODO: May want to restore this perhaps?
    temp=rmfield(temp, 'CurrentAxes');
end

% May have been added earlier
if isfield(temp, 'key')
    temp=rmfield(temp, 'key');
end

if isfield(temp, 'Parent')
    p=Json.HandleMap.get(double(temp.Parent));
    if strcmp(type, 'matlab.ui.Figure')
        temp.Parent=handle(0);
    elseif ~isempty(p)
        temp.Parent=handle(p);
    else
        temp.Parent=[];
    end
end

if isfield(temp, 'Units')
    units=temp.Units;
    pos=temp.Position;
    try
        temp=eval([type '(temp)']);
    catch ex
        z=88;
    end
    set(temp, 'Units', units, 'Position', pos);
else
    temp=eval([type '(temp)']);
end

if ishandle(temp)
    Json.HandleMap.put(value.get('_handle').doubleValue(), double(temp));
end

if ishghandle(temp)
    if ~isempty(get(temp, 'Parent'))
        uistack(temp, 'bottom');
    end
end

if ~isempty(value.get('ApplicationData'))
    Json.AppData.put(double(temp), value.get('ApplicationData'));
end
end

%-----------------------------------------------------------------------
function temp=removeNotSettableProperties(temp)
%-----------------------------------------------------------------------
% Non-settable graphics properties
if isfield(temp, 'Type')
    temp=rmfield(temp, 'Type');
end
% Non-settable Figure properties
if isfield(temp, 'CurrentCharacter')
    temp=rmfield(temp, 'CurrentCharacter');
end
if isfield(temp, 'Number')
    temp=rmfield(temp, 'Number');
end
if isfield(temp, 'XDisplay')
    temp=rmfield(temp, 'XDisplay');
end
if isfield(temp, 'BeingDeleted')
    temp=rmfield(temp, 'BeingDeleted');
end
if isfield(temp, 'Extent')
    temp=rmfield(temp, 'Extent');
end
% Non-settable Axes properties
if isfield(temp, 'TightInset')
    temp=rmfield(temp, 'TightInset');
end
if isfield(temp, 'CurrentPoint')
    temp=rmfield(temp, 'CurrentPoint');
end
% Non-settable Legend properties
if isfield(temp, 'LegendInformation')
    temp=rmfield(temp, 'LegendInformation');
end
% Non-settable Line properties
if isfield(temp, 'Annotation')
    temp=rmfield(temp, 'Annotation');
end
end

%-----------------------------------------------------------------------
function addCallbacks()
%-----------------------------------------------------------------------
% Add callbacks
if Json.BuildLaterCallbacks.size()>0
    iterator=Json.BuildLaterCallbacks.keySet().iterator();
    while iterator.hasNext
        key=iterator.next();
        object=Json.BuildLaterCallbacks.get(key);
        if isempty(object.get('target'))
            iterator2=object.fieldNames();
            args={};
            while iterator2.hasNext()
                field=char(iterator2.next());
                if strcmp(field, '_type') || strcmp(field, '_size') || strcmp(field, 'target')
                    continue
                end
                innerType=char(object.get(field).get('_type').textValue());
                args{end+1}=deserializeObjectNode(object.get(field), innerType);
                if length(args)==1 && strcmp(innerType, 'function_handle')
                    target=char(object.get(field).get('target').textValue());
                end
                if strcmp(innerType, 'handle')
                    args{end}=handle(Json.HandleMap.get(args{end}));
                end
            end
            set(handle(key), target, args);
        else
            callback=deserializeObjectNode(object, char(object.get('_type').textValue()));
            set(handle(key), char(object.get('target').textValue()), callback);
        end
    end
end
% Add application data
iterator=Json.AppData.keySet().iterator();
while iterator.hasNext()
    h=iterator.next();
    appData=deserializeNode(Json.AppData.get(h), 'struct', 'ApplicationData', true);
    fields=fieldnames(appData);
    for k=1:length(fields)
        setappdata(handle(h), fields{k}, appData.(fields{k}));
    end
end
end

%-----------------------------------------------------------------------
function checkArguments(nIN, nOUT, args)
%-----------------------------------------------------------------------
if nIN>1 && ~ischar(args{1}) || (nIN>2 && ~all(cellfun(@ischar, args)))
    error('Requested variables must be specified as strings');
end
if nIN>1 && nOUT~=0 && nOUT<numel(args)
    error('Number of outputs must match the number of requested variables or be one greater');
end
if nIN>1 && numel(unique(args))~=numel(args)
    error('Duplicate variable names requested on input');
end
end

%-----------------------------------------------------------------------
function temp=createAnonymousFunction(node, space)
%-----------------------------------------------------------------------
fields=space.fieldNames();
while fields.hasNext()
    key=fields.next();
    if strcmp(key,'_type')
        continue
    end
    field=space.get(key);
    if ~isa(field, 'com.fasterxml.jackson.databind.node.NullNode')
        type=char(field.get('_type').textValue());
        if strcmp(type, 'handle')
            h=field.get('value').doubleValue();
            if isempty(Json.HandleMap.get(h))
                fprintf(2, 'Json: An anonymous function ["%s"] requires a handle to an object that has not been created yet\n', node);
                temp=[];
                return
            else
                % N.B. the variable name stored in the workspace (key) will
                % be the original name across multiple
                % serializations/deserializations.
                assign(key, handle(Json.HandleMap.get(h)));
            end
        end
    end
end
% Remove anything not needed from this functions workspace
clear space;
clear fields;
clear key;
clear field;
clear type;
% Create the function handle
temp=eval(node);
end

%-----------------------------------------------------------------------
function temp=createLocalOrNestedFunction(node, space)
%-----------------------------------------------------------------------
if ~isempty(space)
    fields=space.fieldNames();
    while fields.hasNext()
        key=fields.next();
        if strcmp(key,'_type')
            continue
        end
        value=space.get(key);
        type=value.get('_type');
        if isempty(type)
            if isa(value, 'com.fasterxml.jackson.databind.node.TextNode')...
                    || (isa(value,'com.fasterxml.jackson.databind.node.ArrayNode') && value.get(0).isTextual())
                type='char';
            else
                type='double';
            end
        else
            type=char(type.textValue());
        end
        if strcmp(type, 'handle')
            h=value.get('value').doubleValue();
            if isempty(Json.HandleMap.get(h))
                fprintf(2, 'Json: An anonymous function ["%s"] requires a handle to an object that has not been created yet\n', node);
                continue;
            else
                % N.B. the variable name stored in the workspace (key) will
                % be the original name across multiple
                % serializations/deserializations.
                s.(key)=handle(Json.HandleMap.get(h));
            end
        else
            s.(key)=deserializeNode(value, type, key);
        end
    end
    clear space;
    clear fields;
    clear key;
    clear value;
    clear type;
else
    s=[];
end

strarray=java.lang.String(node).split('/');
getter=reflector.FunctionHandleGetter(strarray(1), strarray(2), s);
local_Function_Handle____=eval(['@()' getter.getFile() '(getter)']);

temp=local_Function_Handle____();
end


%-----------------------------------------------------------------------
function assign(key, v)
%-----------------------------------------------------------------------
assignin('caller', key, v);
end

function initialise()
Json.conciseJava.set(false);
Json.conciseMatlab.set(false);
Json.useBase64.set(false);
end





