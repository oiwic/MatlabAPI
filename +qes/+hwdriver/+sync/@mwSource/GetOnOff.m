function On = GetOnOff(obj)
   % query instrument output status

% Copyright 2015 Yulin Wu, Institute of Physics, Chinese  Academy of Sciences
% mail4ywu@gmail.com/mail4ywu@icloud.com

    TYP = lower(obj.drivertype);
    switch TYP
        case {'agle82xx','agle8200','agl e82xx','agl e8200',...
                'rohde&schwarz sma100', 'r&s sma100',...
                'anritsu_mg3692c'}
            str = query(obj.interfaceobj,':OUTP?');    % operate
            if strcmp(str(1),'1')
                On = true;
            else
                On = false;
            end
        otherwise
             error('DCSource:GetOnOff', ['Unsupported instrument: ',TYP]);
    end
end