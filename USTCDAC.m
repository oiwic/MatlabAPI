% 	FileName:USTCDAC.m
% 	Author:GuoCheng
% 	E-mail:fortune@mail.ustc.edu.cn
% 	All right reserved @ GuoCheng.
% 	Modified: 2017.7.1
%   Description:The class of DAC

classdef USTCDAC < handle
    properties (SetAccess = private)
        id = 0;             % device id
        ip = '';            % device ip
        port = 80;          % port number
        status = 'close';   % open state
        isopen = 0;         % open flag
    end
    
    properties
        isblock = 0;            % is run in block mode
        name = 'Unnamed';       % DAC's name
        channel_amount = 4;     % DAC maximum channel number
        sample_rate = 2e9;      % DAC sample rate
        sync_delay = 0;         % DAC sync delay
        trig_delay = 0;         % DAC trig sync delay
        da_range = 0.8;         % maximum voltage，unused
        gain = zeros(1,4);      % DAC channel gain
        offset = zeros(1,4);    % DAC channel offset, unused
        offsetCorr = zeros(1,4);% DAC offset voltage code.
        
        trig_sel = 0;           % trigger source select
        trig_interval = 200e-6; % trigger interval
        ismaster = 0;           % master flag
        daTrigDelayOffset = 0;  % fix offset between trig and dac output.
    end
    
    properties (GetAccess = private,Constant = true)
        driver  = 'USTCDACDriver';      % dll module name
        driverh = 'USTCDACDriver.h';    % dll header file name
        driverdll = 'USTCDACDriver.dll' % dll binary file name
    end
    
    properties(GetAccess = private,Constant = true)
        func = {...
            struct('name','SetLoop','instruction',uint32(hex2dec('00000905')),'para1',@(para)(para{1}*65536+para{2}),'para2',@(para)(para{3}*65536+para{4})),...
            struct('name','StartStop','instruction',uint32(hex2dec('00000405')),'para1',@(para)uint32(para{1}),'para2',@(para)(0)),...
            struct('name','SetTotalCount','instruction',uint32(hex2dec('00001805')),'para1',@(para)uint32(1),'para2',@(para)(uint32(para{1}*2^16))),...
            struct('name','SetDACStart','instruction',uint32(hex2dec('00001805')),'para1',@(para)uint32(2),'para2',@(para)(uint32(para{1}*2^16))),...
            struct('name','SetDACStop','instruction',uint32(hex2dec('00001805')),'para1',@(para)uint32(3),'para2',@(para)(uint32(para{1}*2^16))),...
            struct('name','SetTrigStart','instruction',uint32(hex2dec('00001805')),'para1',@(para)(uint32(4)),'para2',@(para)(uint32(para{1}*2^16))),...
            struct('name','SetTrigStop','instruction',uint32(hex2dec('00001805')),'para1',@(para)uint32(5),'para2',@(para)(uint32(para{1}*2^16))),...
            struct('name','SetIsMaster','instruction',uint32(hex2dec('00001805')),'para1',@(para)uint32(6),'para2',@(para)(uint32(para{1}*2^16))),...
            struct('name','SetTrigSel','instruction',uint32(hex2dec('00001805')),'para1',@(para)uint32(7),'para2',@(para)(uint32(para{1}*2^16))),...
            struct('name','SendIntTrig','instruction',uint32(hex2dec('00001805')),'para1',@(para)uint32(8),'para2',@(para)(uint32(2^16))),...
            struct('name','SetTrigInterval','instruction',uint32(hex2dec('00001805')),'para1',@(para)uint32(9),'para2',@(para)(uint32(para{1}*2^12))),...
            struct('name','SetTrigCount','instruction',uint32(hex2dec('00001805')),'para1',@(para)uint32(10),'para2',@(para)(uint32(para{1}*2^12))),...
            struct('name','ClearTrigCount','instruction',uint32(hex2dec('00001F05')),'para1',@(para)(0),'para2',@(para)(0)),...
            struct('name','SetGain','instruction',uint32(hex2dec('00000702')),'para1',@(para)(mod(para{1}+1,4)),'para2',@(para)(para{2})),...
            struct('name','SetOffset','instruction',uint32(hex2dec('00000702')),'para1',@(para)(mod(para{1}+1,4)+4),'para2',@(para)(para{2})),...
            struct('name','SetDefaultVolt','instruction',uint32(hex2dec('00001B05')),'para1',@(para)(para{1}-1),'para2',@(para)(para{2})),...
            struct('name','InitBoard','instruction',uint32(hex2dec('00001A05')),'para1',@(para)(11),'para2',@(para)(0)),...
            struct('name','PowerOnDAC','instruction',uint32(hex2dec('00001E05')),'para1',@(para)(para{1}),'para2',@(para)(para{2})),...
            struct('name','SetBoardcast','instruction',uint32(hex2dec('00001305')),'para1',@(para)(para{1}),'para2',@(para)(floor(para{2})*5)),...
        }
    end
    
    methods (Static = true), 
        function LoadLibrary()
            if(~libisloaded(USTCDAC.driver))
                loadlibrary(USTCDAC.driverdll,USTCDAC.driverh);
            end
        end 
        function info = GetDriverInformation()
            USTCDAC.LoadLibrary();
            str = libpointer('cstring',blanks(1024));
            [ErrorCode,info] = calllib(USTCDAC.driver,'GetSoftInformation',str);
            USTCDAC.DispError('USTCDAC:GetDriverInformation:',ErrorCode);
        end
        function data = FormatData(datain)
            len = length(datain);
            data = datain;
            if(mod(len,32) ~= 0)     % 补齐512bit
                len = (floor(len/32)+1)*32;
                data = zeros(1,len);
                data(1:length(datain)) = datain;
            end
            for k = 1:length(data)/2 % 颠倒前后数据，这是由于FPGA接收字节序问题
                temp = data(2*k);
                data(2*k) = data(2*k-1);
                data(2*k-1) = temp;
            end
        end
        function DispError(MsgID,errorcode)
            if(errorcode ~= 0)
                str = libpointer('cstring',blanks(1024));
                [~,info] = calllib(USTCDAC.driver,'GetErrorMsg',int32(errorcode),str);
                msg = ['Error code:',num2str(errorcode),' --> ',info];
                error(MsgID,[MsgID,' ',msg]);
            end
        end
    end
    
    methods
        function obj = USTCDAC(ip,port)   % Construct function 
            obj.ip = ip;obj.port = port;
        end
        function Open(obj)                % Connect to DAC board.
            obj.LoadLibrary();
            if ~obj.isopen
                [ErrorCode,obj.id,~] = calllib(obj.driver,'Open',0,obj.ip,obj.port);
                obj.DispError(['USTCDAC:Open:',obj.name],ErrorCode);
                obj.isopen = 1; obj.status = 'open';
            end
        end
        function Close(obj)               % Disconnect to DAC board.
            if obj.isopen
                ErrorCode = calllib(obj.driver,'Close',uint32(obj.id));
                obj.DispError(['USTCDAC:Close:',obj.name],ErrorCode);
                obj.id = [];obj.status = 'closed';obj.isopen = false;
            end
        end
        function Init(obj)                % Init DAC after first time connect DAC
            isDACReady = 0; try_count = 10;
            while(try_count > 0 && ~isDACReady)
                lane = zeros(1,8);idx = 1;
                for addr = 1136:1139
                    lane(idx)   = obj.ReadAD9136(1,addr);
                    lane(idx+1) = obj.ReadAD9136(2,addr);
                    idx = idx + 2;
                end
                light = obj.ReadReg(5,8);
                lane = mod(lane,256);
                if(sum(lane == 255) == length(lane) && mod(floor(light/(2^20)),4) == 3)
                    isDACReady= 1;
                else                 
                    subsref(obj,[struct('type','.','subs','InitBoard'),struct('type','()','subs',{})]);
                    pause(1); try_count =  try_count - 1;
                end
            end
            if(isDACReady == 0)
                error('USTCDAC:Init',['Init DAC ',obj.name,' failed']);
            end
            obj.SetTimeOut(0,10); obj.SetTimeOut(1,10);
            subsref(obj,[struct('type','.','subs','SetIsMaster'),struct('type','()','subs',{{obj.ismaster}})]);
            subsref(obj,[struct('type','.','subs','SetTrigSel'),struct('type','()','subs',{{obj.trig_sel}})]);
            subsref(obj,[struct('type','.','subs','SetTrigInterval'),struct('type','()','subs',{{obj.trig_interval}})]);
            subsref(obj,[struct('type','.','subs','SetTotalCount'),struct('type','()','subs',{{obj.trig_interval/4e-9 - 5000}})]);
            subsref(obj,[struct('type','.','subs','SetLoop'),struct('type','()','subs',{[{1},{1},{1},{1}]})]);
            subsref(obj,[struct('type','.','subs','SetDACStart'),struct('type','()','subs',{{obj.sync_delay/4e-9 + 1}})]);
            subsref(obj,[struct('type','.','subs','SetDACStop'),struct('type','()','subs',{{obj.sync_delay/4e-9 + 10}})]);
            subsref(obj,[struct('type','.','subs','SetTrigStart'),struct('type','()','subs',{{obj.trig_delay/4e-9 + 1}})]);
            subsref(obj,[struct('type','.','subs','SetTrigStop'),struct('type','()','subs',{{obj.trig_delay/4e-9 + 10}})]);
            for k = 1:obj.channel_amount
                subsref(obj,[struct('type','.','subs','SetGain'),struct('type','()','subs',{[{k},{obj.gain(k)}]})]);
                subsref(obj,[struct('type','.','subs','SetDefaultVolt'),struct('type','()','subs',{[{k},{obj.offsetCorr(k)+32768}]})]);
            end
        end
        function WriteReg(obj,bank,addr,data)
             cmd = bank*256 + 2; %1表示ReadReg，指令和bank存储在一个DWORD数据中
             ErrorCode = calllib(obj.driver,'WriteInstruction',obj.id,uint32(cmd),uint32(addr),uint32(data));
             obj.DispError(['USTCDAC:WriteReg:',obj.name],ErrorCode);
             obj.Block();
        end
        function reg = ReadReg(obj,bank,addr)
             cmd = bank*256 + 1; %1表示ReadReg，指令和bank存储在一个DWORD数据中
             ErrorCode = calllib(obj.driver,'WriteInstruction',obj.id,uint32(cmd),uint32(addr),0);
             obj.DispError(['USTCDAC:ReadReg:',obj.name],ErrorCode);
             value = obj.GetReturn(1);
             reg = value.ResponseData;
        end
        function WriteWave(obj,ch,offset,wave)
            wave(wave > 65535) = 65535;  % 范围限制
            wave(wave < 0) = 0;
            data = obj.FormatData(wave); % 调字节序以及补够512bit的位宽
            data = 65535 - data;         % 数据反相，临时需要
            if(ch < 1 || ch > obj.channel_amount) % 从0通道开始编号
                error('Wrong channel!');
            end
            startaddr = (ch-1)*2*2^18+2*offset;
            len = length(data)*2;
            pval = libpointer('uint16Ptr', data);
            [ErrorCode,~] = calllib(obj.driver,'WriteMemory',obj.id,uint32(hex2dec('000000004')),uint32(startaddr),uint32(len),pval);
            obj.DispError(['USTCDAC:WriteWave:',obj.name],ErrorCode);
            obj.Block();
        end
        function WriteSeq(obj,ch,offset,seq)
            data = obj.FormatData(seq);
            if(ch < 1 || ch > obj.channel_amount)
                error('Wrong channel!');        % 检查通道编号
            end
            startaddr = (ch*2-1)*2^18+offset*8; %序列的内存起始地址，单位是字节。
            len = length(data)*2;               %字节个数。
            pval = libpointer('uint16Ptr', data);
            [ErrorCode,~] = calllib(obj.driver,'WriteMemory',obj.id,uint32(hex2dec('00000004')),uint32(startaddr),uint32(len),pval);
            obj.DispError(['USTCDAC:WriteSeq:',obj.name],ErrorCode);
            obj.Block();
        end
        function functype = GetFuncType(obj,offset)
             [ErrorCode,functiontype,instruction,para1,para2] = calllib(obj.driver,'GetFunctionType',uint32(obj.id),uint32(offset),0,0,0,0);
             obj.DispError(['USTCDAC:GetFuncType:',obj.name],ErrorCode);
             template = {{'Write instruction type'},{'Write memory type.'},{'Read memory type.'}};
             functype = struct('functiontype',functiontype,'instruction',instruction,'para1',para1,'para2',para2,'description',template{functiontype});
        end
        function SetTimeOut(obj,isRecv,time)
            if(isRecv)
                ErrorCode = calllib(obj.driver,'SetTimeOut',obj.id,0,time);
            else
                ErrorCode = calllib(obj.driver,'SetTimeOut',obj.id,1,time);
            end
            obj.DispError(['USTCDAC:SetTimeOut:',obj.name],ErrorCode);
        end
        function Block(obj)
            if(obj.isblock)
                obj.GetReturn(1);
            end
        end
        function data = ReadAD9136(obj,chip,addr)
            if(chip == 1)
                ErrorCode = calllib(obj.driver,'WriteInstruction',obj.id,uint32(hex2dec('00001c05')),uint32(addr),uint32(0));
            else
                ErrorCode = calllib(obj.driver,'WriteInstruction',obj.id,uint32(hex2dec('00001d05')),uint32(addr),uint32(0));
            end
            obj.DispError(['USTCDAC:ReadAD9136:',obj.name],ErrorCode);
            value = obj.GetReturn(1);
            data = value.ResponseData;
        end
        function SetTrigDelay(obj,point)
            subsref(obj,[struct('type','.','subs','SetTrigStart'),struct('type','()','subs',{{(obj.daTrigDelayOffset + point)/8+1}})]);
            subsref(obj,[struct('type','.','subs','SetTrigStop'),struct('type','()','subs',{{(obj.daTrigDelayOffset + point)/8+10}})]);
        end
        function value = GetReturn(obj,offset)
           functype = obj.GetFuncType(1);
           pData = libpointer('uint16Ptr',zeros(1,functype.para2/2));
           [ErrorCode,ResStat,ResData,data] = calllib(obj.driver,'GetReturn',uint32(obj.id),uint32(offset),0,0,pData);
           obj.DispError(['USTCDAC:GetReturn:',obj.name],ErrorCode);
           obj.DispError(['USTCDAC:GetReturn:',obj.name],int32(ResStat));
           value = struct('ResponseState',ResStat,'ResponseData',ResData,'data',data);
        end
        function state = CheckStatus(obj)
           [ErrorCode,isSuccessed,pos] = calllib(obj.driver,'CheckSuccessed',uint32(obj.id),0,0);
           state = struct('isSuccessed',isSuccessed,'position',pos);
           obj.DispError(['USTCDAC:CheckStatus:',obj.name],ErrorCode);
        end
        function sref = subsref(obj,s)
            isInstruction = 0;sref = [];
            if(s(1).type == '.')
                for k = 1:length(obj.func)
                    if(strcmp(s(1).subs,obj.func{k}.name))
                        isInstruction = 1; break;
                    end
                end
            end
            if(isInstruction)
                ErrorCode = calllib(obj.driver,'WriteInstruction',obj.id,obj.func{k}.instruction,obj.func{k}.para1(s(2).subs),obj.func{k}.para2(s(2).subs)); 
                obj.Block();
                obj.DispError(['USTCDAC:',obj.func{k}.name,':',obj.name],ErrorCode);
            else
                try
                   sref = builtin('subsref',obj,s);
                catch
                   builtin('subsref',obj,s);
                end
            end
        end
    end
end