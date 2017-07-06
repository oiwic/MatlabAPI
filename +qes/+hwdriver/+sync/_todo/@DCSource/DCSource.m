classdef DCSource < Instrument
    % dc current or voltage source driver.
    % basic properties and functions of a dc source, for extensive
    % properties and functions, use class DCSource_e.
    % adcmt 6166: 6161-compatible mode must be set to ON (set by using the instrument front panel)

% Copyright 2015 Yulin Wu, Institute of Physics, Chinese  Academy of Sciences
% mail4ywu@gmail.com/mail4ywu@icloud.com

    properties
        dcval   % dc value
        % maximun dc output value, the smallest range for this value is selected. 
        % if empty, instrument will be set to auto range if possible.
        max
        on % true/false, output on/off
        % set to the target dc output value directly or tune to it slowly
        % while setting a new dc value. default: tune
        tune@logical scalar = true 
    end
    properties % (SetAccess = immutable)
        % safty limits, dcvals out of safty limits are rejected.
        limits
    end
    methods (Access = private,Hidden = true)
        function obj = DCSource(name,interfaceobj,drivertype)
            if isempty(interfaceobj)
                error('DCSource:InvalidInput',...
                    'Input ''%s'' can not be empty!',...
                    'interfaceobj');
            end
            if nargin < 3
                drivertype = [];
            end
            obj = obj@Instrument(name,interfaceobj,drivertype);
            if nargin > 3
                obj.intinfo = intinfo;
            end
            ErrMsg = obj.InitializeInstr();
            if ~isempty(ErrMsg)
                error('DCSource:InstSetError',[obj.name, ': %s'], ErrMsg);
            end
        end
        [varargout] = InitializeInstr(obj)
        SetRange(obj,val)
        SetDCVal(obj,val)
        SetOnOff(obj,OnOrOff)
        onstatus = GetOnOff(obj)
        dcval = GetDCVal(obj)
        SetAgilent_33120(obj,val)
        SetAdcmt_6166I(obj,val)
        SetAdcmt_6166V(obj,val)
        SetYokogawa_7651I(obj,val)
        SetYokogawa_7651V(obj,val)
    end
    methods (Static)
        obj = GetInstance(name,interfaceobj,drivertype)
    end
    methods
        function set.dcval(obj,val)
            if isempty(val) || ~isnumeric(val) || ~isreal(val)
                error('DCSource:InvalidInput',...
                    [obj.name, ': Invalid input ''%s''!'],...
                    'val');
            end
            if ~isempty(obj.limits) &&...
                    (val(1) < obj.limits(1) || val(1) > obj.limits(2))
                warning('DCSource:InvalidInput',[obj.name, ': DC value out of safty limits!']);
                return;
            end
            if length(val) > 1 % to be compatible with the old version.
                obj.tune = true;
                val = val(1);
            end
            SetDCVal(obj,val);
            obj.dcval = val;
        end
        function dcval = get.dcval(obj)
            dcval = GetDCVal(obj);
        end
        function set.max(obj,val)
            if ~isnumeric(val) || val <= 0
                error('DCSource:SetRange', 'max dcval should be a positive number.');
            end
            ErrMsg = SetRange(obj,val);
            if ~isempty(Msg)
                error('DCSource:SetRange', ErrMsg);
            end
            obj.max = val;
        end
        function set.on(obj,val)
            if isempty(val)
                error('DCSource:SetOnOff', 'on must be a bolean.');
            end
            if ~islogical(val)
                if val == 0 || val == 1
                    val = logical(val);
                else
                    error('DCSource:SetOnOff', 'on must be a bolean.');
                end
            end
            obj.SetOnOff(val);
            obj.on = val;
        end
        function val = get.on(obj)
            val = GetOnOff(obj);
        end
        function On(obj)
            % set on, this method is introduced for functional
            % programming.
            obj.on = true;
        end
        function Off(obj)
            % set off, this method is introduced for functional
            % programming.
            obj.on = false;
        end
        function delete(obj)
%             Off(obj); % close dc output might change the working point,
%             better not close at object deletion!
        end
    end
end