function [Freq, S] = GetData(obj)
    % 

% Copyright 2015 Yulin Wu, Institute of Physics, Chinese  Academy of Sciences
% mail4ywu@gmail.com/mail4ywu@icloud.com

    TYP = lower(obj.drivertype);
    switch TYP
        case {'agilent_n5230c'}
%                 fprintf(obj.interfaceobj,':ABORt');         
            fprintf(obj.interfaceobj,':SENSe1:AVERage:CLEar');
            tic;
            % real swpstartfreq, swpstopfreq or swppoints might be
            % different from their set values in case of set values out
            % of permissible range, so the Freq here is calculated by
            % quering the real values of swpstartfreq, swpstopfreq and
            % swppoints from the instrument.
            if obj.numsegments == 1
                obj.swpstartfreq = str2double(query(obj.interfaceobj,':SENSe:FREQuency:STARt?'));
            else
                obj.swpstartfreq = NaN*ones(1,obj.numsegments);
                for ii = 1:obj.numsegments
                    obj.swpstartfreq(ii) = str2double(query(obj.interfaceobj,sprintf('SENS:SEGM%d:FREQ:START?',ii)));
                end
            end
            if obj.numsegments == 1
                obj.swpstopfreq = str2double(query(obj.interfaceobj,':SENSe:FREQuency:STOP?'));
            else
                obj.swpstopfreq = NaN*ones(1,obj.numsegments);
                for ii = 1:obj.numsegments
                    obj.swpstopfreq(ii) = str2double(query(obj.interfaceobj,sprintf('SENS:SEGM%d:FREQ:STOP?',ii)));
                end
            end
            if obj.numsegments == 1
                obj.swppoints = str2double(query(obj.interfaceobj,':SENSe:SWEep:POINts?'));
            else
                obj.swppoints = NaN*ones(1,obj.numsegments);
                for ii = 1:obj.numsegments
                    obj.swppoints(ii) = str2double(query(obj.interfaceobj,sprintf('SENS:SEGM%d:SWE:POIN?',ii)));
                end
            end
            if obj.averaging
                while 1 && toc < obj.timeout
                    status = str2double(query(obj.interfaceobj,':STATus:OPERation:AVERaging1:CONDition?'));
                    if status ~= 0
                        break;
                    end
                    pause(0.1);
                end
            end
            textdata = query(obj.interfaceobj, ':CALCulate:DATA? SDATA');
            S = eval(['[',textdata,']']);
            S = S(1:2:end) + 1i*S(2:2:end);

            Freq = NaN*ones(1,sum(obj.swppoints));
            dp = 0;
            for ii = 1:obj.numsegments
                ndp = dp+obj.swppoints(ii);
                Freq(dp+1:ndp) = linspace(obj.swpstartfreq(ii),obj.swpstopfreq(ii),obj.swppoints(ii));
                dp = ndp;
            end
            if length(S) ~= dp
                error('SParamMeter:GetData',...
                    'Data buffer size too small or data size too big, try increse buffer size or reduce data size.');
            end
        otherwise
              error('SParamMeter:GetData', ['Unsupported instrument: ',TYP]);
    end
end