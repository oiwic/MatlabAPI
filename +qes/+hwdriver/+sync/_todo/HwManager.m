classdef HwManager < handle
    %
    
% Copyright 2015 Yulin Wu, Institute of Physics, Chinese  Academy of Sciences
% mail4ywu@gmail.com/mail4ywu@icloud.com

    properties (SetAccess = private)
        % all available visa\gpib\serial instruments, eval(constructor{n}) creates the nth instrument object)
        constructor = {}; 
    end
    methods
        function obj = HwManager()
            obj.Refresh();
        end
        function Refresh(obj)
            obj.constructor = {};
            hwinfo = instrhwinfo('visa');
            adapters = hwinfo.InstalledAdaptors;
            for jj = 1:length(adapters)
                instr = instrhwinfo('visa', adapters{jj});
                
                constructors = instr.ObjectConstructorName(:);
                rmvidx = [];
                for kk = 1:length(constructors)
                    res = regexpi(constructors{kk}, '[a-z]*\(''[a-z]+''[ ]*,[ ]*''(?<resource>[A-Z0-9:]+)''', 'names');
                    if ~isempty(res) && strcmpi(res.resource(1:4),'ASRL')
                        % serial port, ignore
                        rmvidx = [rmvidx,kk];
                    end
                end
                constructors(rmvidx) = [];
                obj.constructor = [obj.constructor;constructors];
            end
            hwinfo = instrhwinfo('gpib');
            adapters = hwinfo.InstalledAdaptors;
            for jj = 1:length(adapters)
                instr = instrhwinfo('gpib', adapters{jj});
                obj.constructor = [obj.constructor;instr.ObjectConstructorName(:)];
            end
            hwinfo = instrhwinfo('serial');
            obj.constructor = [obj.constructor;hwinfo.ObjectConstructorName(:)];
        end
    end
    
end