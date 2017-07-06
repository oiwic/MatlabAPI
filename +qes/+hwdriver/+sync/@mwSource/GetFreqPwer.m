function [Frequency, Power] = GetFreqPwer(obj)
% query frequency and power from instrument
%

% Copyright 2015 Yulin Wu, Institute of Physics, Chinese  Academy of Sciences
% mail4ywu@gmail.com/mail4ywu@icloud.com

    TYP = lower(obj.drivertype);
    switch TYP
        case {'agle82xx','agle8200','agl e82xx','agl e8200',...
                'rohde&schwarz sma100', 'r&s sma100',...
                'anritsu_mg3692c'}
            Frequency = str2double(query(obj.interfaceobj,':SOUR:FREQ?'));
            Power = str2double(query(obj.interfaceobj, ':SOUR:POW?'));
        case {}
        otherwise
             error('MWSource:QueryError', ['Unsupported instrument: ',TYP]);
    end
end