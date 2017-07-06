function [V, varargout] = MeasureVolt(Meter,TYP,varargin)
%
%
% Yulin Wu, Q02,IoP,CAS. mail4ywu@gmail.com
% $Revision: 1.0 $  $Date: 2014/05/27 $

ErrorMes = [];
try
    switch TYP
        case {'HP/AGL34401','HP34401','AGL34401','hp/agl34401','hp34401','agl34401',...
                'HP/AGL_34401','HP_34401','AGL_34401','hp/agl_34401','hp_34401','agl_34401',...
                'HP/AGL-34401','HP-34401','AGL-34401','hp/agl-34401','hp-34401','agl-34401',...
                'HP/AGL 34401','HP 34401','AGL 34401','hp/agl 34401','hp 34401','agl 34401'}
            % code for HP/AGL34401 untested
            try
                if nargin > 2 % config instrument
                    % code to be added
                else
                    fprintf(Meter,'MEASure:VOLTage:DC?');
                    V = str2double(fscanf(Meter));
                end
            catch
                ErrorMes = 'Unkonwn error!';
            end
        case {'Keithley2182','KEITHLEY2182','keithley2182','K2182','k2182',...
               'Keithley_2182','KEITHLEY_2182','keithley_2182','K_2182','k_2182',...
               'Keithley-2182','KEITHLEY-2182','keithley-2182','K-2182','k-2182',...
               'Keithley 2182','KEITHLEY 2182','keithley 2182','K 2182','k 2182'}
            try
                if nargin > 2 % config instrument
                    fprintf(Meter,'*RST');   % select channel 1
                    fprintf(Meter,':sens:func ''volt''');
                    
                    % fprintf(Meter,':sens:volt:rang:auto on'); % set to auto range
                    fprintf(Meter,':sens:volt:rang:auto off');
                    fprintf(Meter,':sens:volt:rang 0.2'); % set to 10mV range
                    
                    
                    fprintf(Meter,':sens:volt:nplc 1');  % the integration time can be set from 0.01 PLC to 60 PLC(50 PLC for 50Hz line power). 
                    fprintf(Meter,':sens:chan 1');   % select channel 1
                    fprintf(Meter,':sens:volt:chan1:lpas off'); % Disable analog filter. By test, analog filter makes things worse, don't use it.
                    fprintf(Meter,':sens:volt:chan1:dfil:wind 10'); % Set window to 10%,(in %): 0 to 10. 
                    fprintf(Meter,':sens:volt:chan1:dfil:coun 50'); % Set count to 50(each reading is a average of 50 times), 1 to 100. 
                    fprintf(Meter,':sens:volt:chan1:dfil:tcon rep'); % Select moving average/repeat filter.
                    fprintf(Meter,':sens:volt:chan1:dfil:stat on'); % Enable digital filter.
                    pause(5);
                    V = 'Config instrument done.';
                else
                    fprintf(Meter,':sens:data:fres?'); % Request a fresh reading. 
                    V = str2double(fscanf(Meter));
                end
            catch
                ErrorMes = 'Unknown error!';
            end
            % code to be added;
        case 'DCSource TYP 3'
            ErrorMes  = ['Unsupported DC source: ',TYP];
            % code to be added;
        case {'EMPTY','Empty','empty'}
            disp('No DC source!');
        otherwise
            ErrorMes  = ['Unsupported DC source: ',TYP];
    end
catch
    ErrorMes = 'Unknown error!';
end
if ~isempty(ErrorMes)
    ErrorMes = ['@ ''MeasureVolt''',char(13),char(10),ErrorMes];
    V = NaN;
    varargout{1} = ErrorMes;
else
    varargout{1} = [];
end
