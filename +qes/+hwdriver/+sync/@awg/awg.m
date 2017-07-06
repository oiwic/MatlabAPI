classdef awg < qes.hwdriver.sync.instrument
    % arbitary waveform generator(awg) driver, basic.
    % basic properties and functions of an awg, for extensive properties
    % and functions, use class awg_e.

% Copyright 2015 Yulin Wu, Institute of Physics, Chinese  Academy of Sciences
% mail4ywu@gmail.com/mail4ywu@icloud.com

    properties
        nchnls      % number of channels(number of channels may differ even for the same awg model, so has to be set by user)
    end
    properties (SetAccess = private)
        % id of the waveforms of each channel, 
        waveforms
    end
    properties % (AbortSet = true) do not use AbortSet
        smplrate      % sampling rate, unit: Hz
        runmode = 1;    % 1/2..., implication depends on the specific awg model, for tek5014: 0,1,2,3-triggered(default)/sequence/gated/continues
        trigmode = 1;  % 1/2, internal(default) or external
        triginterval    % trigger frequency = 1/triginterval (Hz), not needed if trigmode is external
    end
    methods (Access = private)
        function obj = awg(name,interfaceobj,drivertype)
            if isempty(interfaceobj)
                error('awg:InvalidInput',...
                    'Input ''%s'' can not be empty!',...
                    'interfaceobj');
            end
            if nargin < 3
                drivertype = [];
            end
            obj = obj@qes.hwdriver.sync.instrument(name,interfaceobj,drivertype);
            ErrMsg = obj.InitializeInstr();
            if ~isempty(ErrMsg)
                error('awg:InstSetError',[obj.name, ': %s'], ErrMsg);
            end
            % because set methods are not called during object creation for
            % properties with default value(not sure on this point), set
            % RunMode and TrigMode with default value.
            SetRunMode(obj);
            SetTrigMode(obj);
            
        end
        [varargout] = InitializeInstr(obj)
        SetSmplRate(obj)
        SetRunMode(obj)
        SetTrigMode(obj)
        SetTrigInterval(obj)
    end
    methods (Static)
        obj = GetInstance(name,interfaceobj,drivertype)
    end
    methods (Static = true, Access = private)
        [WaveformData, Vpp, Offset,MarkerData,MarkerVpp,MarkerOffset] = PrepareWvData_Tek70k(WaveformObj)
        [WaveformData] = PrepareWvData(WaveformObj,DAVpp,NB)
    end
    methods
        varargout = Run(obj,N)
        function set.nchnls(obj,val)
            if ~isempty(obj.nchnls) && obj.nchnls ~= val
                error('awg:SetPropError','nchnls(number of channel) is an immutable property, once set, it is not allowed to be changed!');
            end
            if isempty(val) || val <= 0 || ceil(val) ~=val
                error('awg:InvalidInput','nchnls value should be positive integer!');
            end
            obj.nchnls = val;
            obj.waveforms = cell(obj.nchnls,1);
        end
        function set.smplrate(obj,val)
            if isempty(val) || val <= 0
                error('awg:InvalidInput','smplrate value should be a positive number!');
            end
            obj.smplrate = val;
            SetSmplRate(obj);
        end
        function val = get.smplrate(obj)
            % query from the instrument is to be implemented in the future.
            val = obj.smplrate;
        end
        function set.runmode(obj,val)
            if isempty(val) || val<0 || ceil(val) ~=val
                error('awg:InvalidInput','runmode value should be a positive integer!');
            end
            obj.runmode = val;
            SetRunMode(obj);
        end
        function val = get.runmode(obj)
            % query from the instrument is to be implemented in the future.
            val = obj.runmode;
        end
        function set.trigmode(obj,val)
            if isempty(val) || val<=0 || round(val) ~=val
                error('awg:InvalidInput','trigmode value can only be 0(internal) or 1(external)!');
            end
            if val >2
                val = 2;
            end
            obj.trigmode = val;
            SetTrigMode(obj);
        end
        function val = get.trigmode(obj)
            % query from the instrument is to be implemented in the future.
            val = obj.trigmode;
        end
        function set.triginterval(obj,val)
            if isempty(val) || val <= 0
                error('awg:InvalidInput','triginterval value should be a positive number!');
            end
            obj.triginterval = val;
            SetTrigInterval(obj);
        end
        function val = get.triginterval(obj)
            % query from the instrument is to be implemented in the future.
            val = obj.triginterval;
        end
        function ret = AddWaveform(obj,wvfrmobj,chnl)
            ret = 0;
            if ~isa(wvfrmobj,'Waveform') || ~IsValid(wvfrmobj)
                error('awg:AddWaveform','wvfrmobj not valid or not a Waveform class object.');
            end
            if ceil(chnl) ~=chnl || chnl <=0
                error('awg:AddWaveform','chnl should be a positive integer!');
            end
            if  isempty(obj.nchnls) || chnl > obj.nchnls
                error('awg:AddWaveform','chnl inconsistent with the awg or number of channels not set.');
            end
            if ~isempty(obj.waveforms{chnl})
                if obj.waveforms{chnl} == wvfrmobj.id
                    return;
                end
                oldwvobj = HandleQES.FindByProp('id',obj.waveforms{chnl});
                if isempty(oldwvobj) % in such case, the waveform has been removed already
%                     warning('awg:AddWaveform','There is already a waveform object attached to this channel, this waveform will be removed.');
                else
                    oldwvobj{1}.awgchnl = [];
                    warning(['awg:AddWaveform',' Waveform ''',oldwvobj{1}.name,...
                        '''(id:', num2str(oldwvobj{1}.id,'%0.0f'),') seems to be running on the channel to output waveform ''',...
                        wvfrmobj.name, '''(id:', num2str(wvfrmobj.id,'%0.0f'),'), it will be removed.']);
                end
            end
            obj.waveforms{chnl} = wvfrmobj.id;
        end
    end
    methods (Hidden = true) % hidden, only to be indirectly called by methods of Waveform class objects
        SendWave(obj,WaveformObj)
        LoadWave(obj,WaveformObj)
    end
end