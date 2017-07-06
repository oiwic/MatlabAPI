function [varargout]=GateAndTrigOutput(TrigFreq,NPlsPerGate,GateSource,GateSourTyp,TrigSource,TrigSourTyp,CounterType)
% TrigFreq: kHz, measurement pulse output frequency.
% if value bigger than 500e3, it will be set to 500e3(500kHz).
% NPlsPerGate: Trig N measurement pulses in every Gate pulse. 
% NPlsPerGate <= 3500, a limit set buy the maximun sampling point number
% (16000 points) of HP33120, NPlsPerGate < 200 is recomended.
%
% GateSource: Gate Source gpib object, not opened.
% TrigSource: Trigger Source gpib object, not opened.
%
% example:
% GateGpibAddr = 10;	% gpib address of gate source AWG(HP/AGL33120)
% TrigGpibAddr = 20;	% gpib address of trigger source AWG(HP/AGL33120)
% GateSource = gpib('ni', 0, GateGpibAddr);
% TrigSource = gpib('ni', 0, TrigGpibAddr);
% GateAndTrigOutput(8,100,GateSource,'HP/AGL33120',TrigSource,'HP/AGL33120','SR620');

ErrorMes = [];
switch CounterType
    case {'SR620','sr620','SR_620','sr_620','SR-620','sr-620','SR 620','sr 620'}
        COUNTERWAITTIME = 800e-6;   % 800 micro-sec.
    otherwise
        ErrorMes  = ['''COUNTERWAITTIME'' unknown for counter type: ',CounterType];
end

if isempty(ErrorMes)
    UnitTime = 0.5e-6;                  % minimum time scale in this function (second)
    MarginTime = 10e-6;                 % margin accounts for sync discrepancy and voltage
                                    % sigal(Vout) delay
    SingleTrigPls = [1 1 0 0];
    if NPlsPerGate > 3500
        ErrorMes = '''NPlsPerGate'' value too big!';
    else
        TrigPlsSmplN = length(SingleTrigPls);
        MinPlsPeriod = TrigPlsSmplN*UnitTime;
        PulsePeriod = 1/(TrigFreq*1e3);    % TrigFreq unit: kHz
        n = round(PulsePeriod/MinPlsPeriod); 
        if n < 1
            n = 1;
        end
        PulsePeriod = n*MinPlsPeriod;   % snap 'PulsePeriod' to n times 'MinPlsPeriod'
        TrigPlsSmplTime = PulsePeriod/TrigPlsSmplN;
        NPlsPerGate = round(NPlsPerGate);                   % convert to integer(if it is not)
        if NPlsPerGate<1
            NPlsPerGate = 1;
        end
        ii = 0;
        while ii < NPlsPerGate
            TrigWave(TrigPlsSmplN*ii+1:TrigPlsSmplN*(ii+1)) = SingleTrigPls;
            ii = ii+1;
        end
        MarginLF = ceil(MarginTime/TrigPlsSmplTime);
        MarginLE = floor(MarginTime/TrigPlsSmplTime);
        MarginF = zeros(1,MarginLF);      % sync. margin
        MarginE = zeros(1,MarginLE);      % sync. margin
        TrigWave = [MarginF, TrigWave, MarginE];  % add margin
        TrigWaveL = length(TrigWave);
        GateWave = ones(1,TrigWaveL);
        CounterWait = zeros(1,ceil(1.2*COUNTERWAITTIME/TrigPlsSmplTime));
        TrigWave = [CounterWait,TrigWave];
        GateWave = [CounterWait,GateWave];
        L = length(GateWave);

      % for plotting
%     x = 1:length(GateWave);
%     x = x*TrigPlsSmplTime*1000;     % micro second
%     plot(x,GateWave,'r--','LineWidth',2);
%     hold on;
%     plot(x,TrigWave,'r-','LineWidth',2);
%     hold on;
%     xlabel('mS','FontSize',14);
%     ylabel('A','FontSize',14);

    
        GateVpp = 2;
        PulseTrigVpp = 2;
        GateFreq = 1/(L*TrigPlsSmplTime);
    end
    
    %输出 Gate 脉冲
    if isempty(ErrorMes)
        switch GateSourTyp
            case {'HP/AGL33120','HP33120','AGL33120','hp/agl33120','hp33120','agl33120',...
                 'HP/AGL_33120','HP_33120','AGL_33120','hp/agl_33120','hp_33120','agl_33120',...
                 'HP/AGL-33120','HP-33120','AGL-33120','hp/agl-33120','hp-33120','agl-33120',...
                 'HP/AGL 33120','HP 33120','AGL 33120','hp/agl 33120','hp 33120','agl 33120'}
                set(GateSource,'OutputBufferSize',1000000);
                set(GateSource,'ByteOrder','littleEndian');    % 10 little littleEndian
                set(GateSource,'Timeout',1000); 
                opfstr=['FREQ ',num2str(GateFreq),' HZ'];
                opvstr=['VOLT ',num2str(GateVpp),' VPP'];        % 设置 Vpp 值（伏）
                offsstr=['VOLT:OFFS ',num2str(0),' V']; 
                wparray=floor((GateWave)*2047);
                fopen(GateSource); 
                binblockwrite(GateSource,wparray,'int16','DATA:DAC VOLATILE,');
                fprintf(GateSource,'');
                fprintf(GateSource,'DATA:COPY arbtemp,VOLATILE'); 
                fprintf(GateSource,opvstr);
                fprintf(GateSource,offsstr); 
                fprintf(GateSource,opfstr); 
                fprintf(GateSource,'FUNC:SHAP USER'); 
                fprintf(GateSource,'FUNC:USER arbtemp');   
                pause(0.5);
                fclose(GateSource);
            otherwise
                ErrorMes  = ['Unsupported counter gate pulse source: ',GateSourTyp];
        end
    end
    
    %输出pulse的Trig脉冲
    if isempty(ErrorMes)
        switch TrigSourTyp
            case {'HP/AGL33120','HP33120','AGL33120','hp/agl33120','hp33120','agl33120',...
                 'HP/AGL_33120','HP_33120','AGL_33120','hp/agl_33120','hp_33120','agl_33120',...
                 'HP/AGL-33120','HP-33120','AGL-33120','hp/agl-33120','hp-33120','agl-33120',...
                 'HP/AGL 33120','HP 33120','AGL 33120','hp/agl 33120','hp 33120','agl 33120'}
                set(TrigSource,'OutputBufferSize',1000000);
                set(TrigSource,'ByteOrder','bigEndian');    % 10 little littleEndian
                set(TrigSource,'Timeout',1000); 
                TrigFreq = GateFreq+0.1;
                % TrigFreg 一定要比 GateFreq 稍微大一点，以保证每一个‘Trig波形’
                % 在下一个Gate源输给Trig源的触发到来前完成。’
                opfstr=['FREQ ',num2str(TrigFreq),' HZ']; 
                opvstr=['VOLT ',num2str(PulseTrigVpp),' VPP'];        % 设置 Vpp 值（伏）
                offsstr=['VOLT:OFFS ',num2str(0),' V'];
                clear  wparray;
                wparray=floor((TrigWave)*2047);
                fopen(TrigSource); 
                binblockwrite(TrigSource,wparray,'int16','DATA:DAC VOLATILE,');
                fprintf(TrigSource,'');
                fprintf(TrigSource,'DATA:COPY arbtemp,VOLATILE'); 
                fprintf(TrigSource,opvstr);
                fprintf(TrigSource,offsstr); 
                fprintf(TrigSource,opfstr); 
                fprintf(TrigSource,'FUNC:SHAP USER'); 
                fprintf(TrigSource,'FUNC:USER arbtemp');  
                % 以下设置 Trig 为外部 Trig
                fprintf(TrigSource,'BM:NCYC 1');
                fprintf(TrigSource,'BM:PHAS 0');
                fprintf(TrigSource,'TRIG:SOUR EXT');
                fprintf(TrigSource,'BM:STAT ON');
                pause(2);
                fclose(TrigSource); 
           otherwise
                ErrorMes  = ['Unsupported trigger source: ',TrigSourTyp];
        end
    end
end
if ~isempty(ErrorMes)
    ErrorMes = ['@ ''GateAndTrigOutput''',char(13),char(10),ErrorMes];
end
varargout{1} = ErrorMes;