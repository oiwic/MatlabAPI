function SetFreq(obj,val)
% set microwave source frequecy and power
%

% Copyright 2015 Yulin Wu, Institute of Physics, Chinese  Academy of Sciences
% mail4ywu@gmail.com/mail4ywu@icloud.com

    TYP = lower(obj.drivertype);
    switch TYP
        case {'agilent e82xx','agilent e8200','agle82xx','agle8200','agl e82xx','agl e8200',...
                'anritsu_mg3692c'}
            fprintf(obj.interfaceobj,[':SOUR:FREQ:FIX ',num2str(val(1),'%0.3f'),'Hz']);
        case {'rohde&schwarz sma100', 'r&s sma100','rssma100'}
            fprintf(obj.interfaceobj,[':SOUR:FREQ ',num2str(val(1),'%0.3f'),'Hz']);
        otherwise
            error('MWSource:SetError', ['Unsupported instrument: ',TYP]);
    end
end