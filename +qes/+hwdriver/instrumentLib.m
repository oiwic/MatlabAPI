classdef instrumentLib
    % instrumentLib provides a central place to manager instrument dirver
    % type alias.
    % 

% Copyright 2015 Yulin Wu, Institute of Physics, Chinese  Academy of Sciences
% mail4ywu@gmail.com/mail4ywu@icloud.com
    
    properties (Constant = true, GetAccess = private)
        % manufacturer, and driver alias, N by 2 cells, cell row represents
        % a tuple of instruments that can use the same driver alias, for
        % example(case insensitive):
        % {'tektronix','tek'}, {'tek5k', 'awg5014b', 'awg5014c'}
        % if the instrument Manufacturer is 'tektronix' or 'tek' and Model is
        % any of 'tek5k', 'awg5014b', 'awg5014c', the drivertype will be
        % 'tek5k'
        driveralias = {{'adc corp.','adcmt'}, {'place_holder'};...
                        {'agilent technologies','agilent', 'keysight technologies', 'keysight'}, {'agilent_n9030b', 'n9030b'};... % spectrum analyzer N9000 series
                        {'agilent technologies','agilent', 'keysight technologies', 'keysight'}, ...
                                {'agilent_n5230c', 'n5230a', 'n5230b', 'n5230c', 'e8361a', 'e8361b', 'e8361c', 'e8362a', 'e8362b', 'e8362c', 'e8363a', 'e8363b', 'e8363c', 'e8364a', 'e8364b', 'e8364c'};... % network analyzer
                        {'anritsu'}, {'anritsu_mg3692c', 'mg3692c'};... % signal generate
                        {'hewlett-packard','hewlett packard'}, {'place_holder'};...
                        {'national instruments'}, {'place_holder'};...
                        {'stanford research systems', 'stanford research'}, {'place_holder'};...
                        {'tektronix','tek'}, {'tek5k', 'awg5014b', 'awg5014c'};...
                        {'tektronix','tek'}, {'tek7k', 'awg7012c'};...
                        {'ustc'}, {'ustc_da_v1'};...
                       }
    end
    methods
        function drivertype = GetDriverTyp(obj,Manufacturer,Model)
            % this method call by class Instrument, not meant for end user
            % usage.
            persistent numdrivertypes
            if isempty(numdrivertypes)
                numdrivertypes = size(obj.driveralias,1);
            end
            Manufacturer = lower(Manufacturer);
            Model = lower(Model);
            drivertype = [];
            for ii = 1:numdrivertypes
                if ismember(Manufacturer, obj.driveralias{ii,1}) &&...
                        ismember(Model, obj.driveralias{ii,2})
                    drivertype = obj.driveralias{ii,2}{1};
                    break;
                end
            end
        end
    end
end