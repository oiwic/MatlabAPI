function SendWave(obj,WaveformObj)
    % send waveform to awg. this method is intended to be called within
    % the method SendWave of class waveform only.

% Copyright 2015 Yulin Wu, Institute of Physics, Chinese  Academy of Sciences
% mail4ywu@gmail.com/mail4ywu@icloud.com

    TYP = lower(obj.drivertype);
    switch TYP
        case {'tek5000','tek5k'}
            % AWG: Tecktronix AWG 5000
            WaveformData = qes.hwdriver.sync.awg.PrepareWvData(WaveformObj,0.6,14);
            if WaveformObj.iq
                if isempty(WaveformObj.name)
                    WvfrmName = ['Untitled_',datestr(now,'yymmdd_HHMMSS'),'_',num2str(10000*rand(1),'%0.0f'),'_I'];
                else
                    WvfrmName = [WaveformObj.name,'_I'];
                end
                startidx = 0;
                wvdatasize = WaveformObj.length;
                fprintf(obj.interfaceobj, ['WLIS:WAV:DEL "',WaveformObj.name, '"']);
                WvfrmNameStr = ['WLIS:WAV:NEW "', WvfrmName, '"'];
                WvfrmWriteStr = ['WLIS:WAV:DATA "', WvfrmName, '"',',',num2str(startidx),',',num2str(wvdatasize),...
                        ',#', num2str(length(num2str(2*wvdatasize))), num2str(2*wvdatasize)];
                % create a waveform in the AWG waveform list
                % send by integer is 2.5 times faster than send by float.
                fprintf(obj.interfaceobj,[WvfrmNameStr,',', num2str(wvdatasize), ',INT']);
                % send waveform data to the newly created waveform
                fwrite(obj.interfaceobj,WvfrmWriteStr);
                fwrite(obj.interfaceobj,WaveformData(1,startidx+1:startidx+wvdatasize),'uint16');  % 'uint16'! NOT 'int16'
                fwrite(obj.interfaceobj, 10);
                
                if isempty(WaveformObj.name)
                    WvfrmName = ['Untitled_',datestr(now,'yymmdd_HHMMSS'),'_',num2str(10000*rand(1),'%0.0f'),'_Q'];
                else
                    WvfrmName = [WaveformObj.name,'_Q'];
                end
                startidx = 0;
                wvdatasize = WaveformObj.length;
                fprintf(obj.interfaceobj, ['WLIS:WAV:DEL "',WaveformObj.name, '"']);
                WvfrmNameStr = ['WLIS:WAV:NEW "', WvfrmName, '"'];
                WvfrmWriteStr = ['WLIS:WAV:DATA "', WvfrmName, '"',',',num2str(startidx),',',num2str(wvdatasize),...
                        ',#', num2str(length(num2str(2*wvdatasize))), num2str(2*wvdatasize)];
                % create a waveform in the AWG waveform list
                % send by integer is 2.5 times faster than send by float.
                fprintf(obj.interfaceobj,[WvfrmNameStr,',', num2str(wvdatasize), ',INT']);
                % send waveform data to the newly created waveform
                fwrite(obj.interfaceobj,WvfrmWriteStr);
                fwrite(obj.interfaceobj,WaveformData(2,startidx+1:startidx+wvdatasize),'uint16');  % 'uint16'! NOT 'int16'
                fwrite(obj.interfaceobj, 10);
            else
                if isempty(WaveformObj.name)
                    WvfrmName = ['Untitled_',datestr(now,'yymmdd_HHMMSS'),'_',num2str(10000*rand(1),'%0.0f')];
                else
                    WvfrmName = WaveformObj.name;
                end
                startidx = 0;
                wvdatasize = WaveformObj.length;
                fprintf(obj.interfaceobj, ['WLIS:WAV:DEL "',WaveformObj.name, '"']);
                WvfrmNameStr = ['WLIS:WAV:NEW "', WvfrmName, '"'];
                WvfrmWriteStr = ['WLIS:WAV:DATA "', WvfrmName, '"',',',num2str(startidx),',',num2str(wvdatasize),...
                        ',#', num2str(length(num2str(2*wvdatasize))), num2str(2*wvdatasize)];
                % create a waveform in the AWG waveform list
                % send by integer is 2.5 times faster than send by float.
                fprintf(obj.interfaceobj,[WvfrmNameStr,',', num2str(wvdatasize), ',INT']);
                % send waveform data to the newly created waveform
                fwrite(obj.interfaceobj,WvfrmWriteStr);
                fwrite(obj.interfaceobj,WaveformData(startidx+1:startidx+wvdatasize),'uint16');  % 'uint16'! NOT 'int16'
                fwrite(obj.interfaceobj, 10);
            end
        case {'tek7000','tek7k'}
            % AWG: Tecktronix awg 7000
            WaveformData = qes.hwdriver.sync.awg.PrepareWvData(WaveformObj,0.5,10);
            if WaveformObj.iq
                if isempty(WaveformObj.name)
                    WvfrmName = ['Untitled_',datestr(now,'yymmdd_HHMMSS'),'_',num2str(10000*rand(1),'%0.0f'),'_I'];
                else
                    WvfrmName = [WaveformObj.name,'_I'];
                end
                startidx = 0;
                wvdatasize = WaveformObj.length;
                WvfrmNameStr = ['WLIS:WAV:NEW "', WvfrmName, '"'];
                WvfrmWriteStr = ['WLIS:WAV:DATA "', WvfrmName, '"',',',num2str(startidx),',',num2str(wvdatasize),...
                        ',#', num2str(length(num2str(2*wvdatasize))), num2str(2*wvdatasize)];
                % create a waveform in the AWG waveform list
                % send by integer is 2.5 times faster than send by float.
                fwrite(obj.interfaceobj,[WvfrmNameStr,',', num2str(wvdatasize), ',INT',10]); 
                % send waveform data to the newly created waveform
                fwrite(obj.interfaceobj,WvfrmWriteStr);
                fwrite(obj.interfaceobj,WaveformData(1,startidx+1:startidx+wvdatasize),'uint16');  % 'uint16'! NOT 'int16'
                fwrite(obj.interfaceobj, 10);
                
                if isempty(WaveformObj.name)
                    WvfrmName = ['Untitled_',datestr(now,'yymmdd_HHMMSS'),'_',num2str(10000*rand(1),'%0.0f'),'_Q'];
                else
                    WvfrmName = [WaveformObj.name,'_Q'];
                end
                startidx = 0;
                wvdatasize = WaveformObj.length;
                WvfrmNameStr = ['WLIS:WAV:NEW "', WvfrmName, '"'];
                WvfrmWriteStr = ['WLIS:WAV:DATA "', WvfrmName, '"',',',num2str(startidx),',',num2str(wvdatasize),...
                        ',#', num2str(length(num2str(2*wvdatasize))), num2str(2*wvdatasize)];
                % create a waveform in the AWG waveform list
                % send by integer is 2.5 times faster than send by float.
                fwrite(obj.interfaceobj,[WvfrmNameStr,',', num2str(wvdatasize), ',INT',10]); 
                % send waveform data to the newly created waveform
                fwrite(obj.interfaceobj,WvfrmWriteStr);
                fwrite(obj.interfaceobj,WaveformData(2,startidx+1:startidx+wvdatasize),'uint16');  % 'uint16'! NOT 'int16'
                fwrite(obj.interfaceobj, 10);
            else
                if isempty(WaveformObj.name)
                    WvfrmName = ['Untitled_',datestr(now,'yymmdd_HHMMSS'),'_',num2str(10000*rand(1),'%0.0f')];
                else
                    WvfrmName = [WaveformObj.name];
                end
                startidx = 0;
                wvdatasize = WaveformObj.length;
                WvfrmNameStr = ['WLIS:WAV:NEW "', WvfrmName, '"'];
                WvfrmWriteStr = ['WLIS:WAV:DATA "', WvfrmName, '"',',',num2str(startidx),',',num2str(wvdatasize),...
                        ',#', num2str(length(num2str(2*wvdatasize))), num2str(2*wvdatasize)];
                % create a waveform in the AWG waveform list
                % send by integer is 2.5 times faster than send by float.
                fwrite(obj.interfaceobj,[WvfrmNameStr,',', num2str(wvdatasize), ',INT',10]); 
                % send waveform data to the newly created waveform
                fwrite(obj.interfaceobj,WvfrmWriteStr);
                fwrite(obj.interfaceobj,WaveformData(startidx+1:startidx+wvdatasize),'uint16');  % 'uint16'! NOT 'int16'
                fwrite(obj.interfaceobj, 10);
            end
        case {'tek70000','tek70k'}
            % AWG: Tecktronix AWG 70000
            if WaveformObj.length < 4800
                error('AWG:SendWaveError','Waveform length short than Tek 70000 minimum: 4800 points!');
            end
            WaveformData = qes.hwdriver.sync.awg.PrepareWvData_Tek70k(WaveformObj);
            if WaveformObj.iq
                if isempty(WaveformObj.name)
                    WvfrmName = ['Untitled_',datestr(now,'yymmdd_HHMMSS'),'_',num2str(10000*rand(1),'%0.0f'),'_I'];
                else
                    WvfrmName = [WaveformObj.name,'_I'];
                end
                startidx = 0;
                wvdatasize = WaveformObj.length;
                if isprop(WaveformObj,'uploadstartidx') && isprop(WaveformObj,'uploadendidx') &&...
                        ~isempty(WaveformObj.uploadstartidx) && ~isempty(WaveformObj.uploadendidx)
                    startidx = WaveformObj.uploadstartidx - 1;
                    wvdatasize = WaveformObj.uploadendidx - WaveformObj.uploadstartidx + 1;
                end
                WvfrmNameStr = ['WLIS:WAV:NEW "', WvfrmName, '"'];
                WvfrmWriteStr = ['WLIS:WAV:DATA "', WvfrmName, '"',',',num2str(startidx),',',num2str(wvdatasize),...
                        ',#', num2str(length(num2str(4*wvdatasize))), num2str(4*wvdatasize)];  % float point, 4 bytes per data point
                % create a waveform in the AWG waveform list
                fprintf(obj.interfaceobj,[WvfrmNameStr,',', num2str(wvdatasize)]);
                % send waveform data to the newly created waveform
                fwrite(obj.interfaceobj,WvfrmWriteStr);
                fwrite(obj.interfaceobj,WaveformData(1,startidx+1:startidx+wvdatasize),'float'); % awg 70k only support floating point waveform data points
                fwrite(obj.interfaceobj, 10);
                
                if isempty(WaveformObj.name)
                    WvfrmName = ['Untitled_',datestr(now,'yymmdd_HHMMSS'),'_',num2str(10000*rand(1),'%0.0f'),'_Q'];
                else
                    WvfrmName = [WaveformObj.name,'_Q'];
                end
                startidx = 0;
                wvdatasize = WaveformObj.length;
                if isprop(WaveformObj,'uploadstartidx') && isprop(WaveformObj,'uploadendidx') &&...
                        ~isempty(WaveformObj.uploadstartidx) && ~isempty(WaveformObj.uploadendidx)
                    startidx = WaveformObj.uploadstartidx - 1;
                    wvdatasize = WaveformObj.uploadendidx - WaveformObj.uploadstartidx + 1;
                end
                WvfrmNameStr = ['WLIS:WAV:NEW "', WvfrmName, '"'];
                WvfrmWriteStr = ['WLIS:WAV:DATA "', WvfrmName, '"',',',num2str(startidx),',',num2str(wvdatasize),...
                        ',#', num2str(length(num2str(4*wvdatasize))), num2str(4*wvdatasize)];  % float point, 4 bytes per data point
                % create a waveform in the AWG waveform list
                fprintf(obj.interfaceobj,[WvfrmNameStr,',', num2str(wvdatasize)]);
                % send waveform data to the newly created waveform
                fwrite(obj.interfaceobj,WvfrmWriteStr);
                fwrite(obj.interfaceobj,WaveformData(2,startidx+1:startidx+wvdatasize),'float'); % awg 70k only support floating point waveform data points
                fwrite(obj.interfaceobj, 10);
            else
                if isempty(WaveformObj.name)
                    WvfrmName = ['Untitled_',datestr(now,'yymmdd_HHMMSS'),'_',num2str(10000*rand(1),'%0.0f')];
                else
                    WvfrmName = [WaveformObj.name];
                end
                startidx = 0;
                wvdatasize = WaveformObj.length;
                if isprop(WaveformObj,'uploadstartidx') && isprop(WaveformObj,'uploadendidx') &&...
                        ~isempty(WaveformObj.uploadstartidx) && ~isempty(WaveformObj.uploadendidx)
                    startidx = WaveformObj.uploadstartidx - 1;
                    wvdatasize = WaveformObj.uploadendidx - WaveformObj.uploadstartidx + 1;
                end
                WvfrmNameStr = ['WLIS:WAV:NEW "', WvfrmName, '"'];
                WvfrmWriteStr = ['WLIS:WAV:DATA "', WvfrmName, '"',',',num2str(startidx),',',num2str(wvdatasize),...
                        ',#', num2str(length(num2str(4*wvdatasize))), num2str(4*wvdatasize)];  % float point, 4 bytes per data point
                % create a waveform in the AWG waveform list
                fprintf(obj.interfaceobj,[WvfrmNameStr,',', num2str(wvdatasize)]);
                % send waveform data to the newly created waveform
                fwrite(obj.interfaceobj,WvfrmWriteStr);
                fwrite(obj.interfaceobj,WaveformData(startidx+1:startidx+wvdatasize),'float'); % awg 70k only support floating point waveform data points
                fwrite(obj.interfaceobj, 10);
            end
        case {'hp33120','agl33120','hp33220','agl33220'} % not tested
            % todo
        case {'ustc_da_v1'}
            WaveformData = qes.hwdriver.sync.awg.PrepareWvData(WaveformObj,0.67,16);
%             WaveformData(:,1:10000) = 0; % debug
%             WaveformData(:,10001:20000) = 65535; % debug
            if WaveformObj.iq
                obj.interfaceobj.SendWave(WaveformObj.awgchnl(1),WaveformData(1,:));
                obj.interfaceobj.SendWave(WaveformObj.awgchnl(2),WaveformData(2,:));
            else
                obj.interfaceobj.SendWave(WaveformObj.awgchnl,WaveformData);
            end
%             figure();
%             plot(WaveformData(1,:));
            
        otherwise
            error('awg:SendWaveError','Unsupported awg!');
    end
    
end