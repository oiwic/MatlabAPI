% 	FileName:USTCDAC.m
% 	Author:GuoCheng
% 	E-mail:fortune@mail.ustc.edu.cn
% 	All right reserved @ GuoCheng.
% 	Create at 2016.11.23

classdef USTCDAC < handle
    properties (SetAccess = private)
        timeout = 10 % seconds
    end
    
    properties (SetAccess = private)
        id = [];
        ip = '';
        port = 0;
        status = 'close';
        isopen = 0;
    end
    
    properties (GetAccess = private,Constant = true)
        driver = 'USTCDACDriver';
        driverh = 'USTCDACDriver.h';
    end
    
    properties (SetAccess = private, GetAccess = private)
        ibuffer; % input buffer
        obuffer; % output buffer
        errorstatus = false;
    end
    
    methods(Static = true)
        function seq = Generate(count)
            function_ctrl = 64;%53-63位
            trigger_ctrl = 0;%48-55位
            counter_ctrl = 0;%32-47位，计时计数器
            length_wave = count;%16-31位,输出波形长度
            address_wave = 0;%0-15波形起始地址
            seqlength = 4096; %共4096个序列控制数据块
            seq  = zeros(1,seqlength*4);  % 共4096个序列数据
            for k = 0:(seqlength-1)
                seq(4*k+1) = counter_ctrl;
                seq(4*k+2) = function_ctrl*256 + trigger_ctrl;
                seq(4*k+3) = address_wave;
                seq(4*k+4) = length_wave;
            end
        end
    end
    
    methods
        function obj = USTCDAC(ip,port) %construct function.
            obj.ip = ip;
            obj.port = port;
            driverfilename = [obj.driver,'.dll'];
            if(~libisloaded(obj.driver))
                loadlibrary(driverfilename,obj.driverh);
            end
        end
             
        function Open(obj)              %open the device
            if ~obj.isopen
                [ret,pid,~] = calllib(obj.driver,'Open',0,obj.ip,obj.port);
                if(ret == 0)
                    obj.id = uint32(pid);
                    obj.status = 'open';
                    obj.isopen = true;
                    InitDevice(obj); 
                else
                   error('USTCDA:OpenError','Open DAC failed!');
                end 
            end
         end
        
        function Close(obj)
            if obj.isopen
                if(libisloaded(obj.driver))
                    ret = calllib(obj.driver,'Close',uint32(obj.id));
                    if(ret == -1)
                        error('USTCDA:CloseError','Close DA failed.');              
                    end
                end
                obj.id = [];
                obj.status = 'closed';
                obj.isopen = false;
            end
        end
         
        function InitDevice(obj)
            %init gain of B03
%             if (obj.id == 3020007616)%init B03,ip180
                WriteGain(obj,0,511);
                WriteGain(obj,1,511);
                WriteGain(obj,2,511);
                WriteGain(obj,3,511);
%             end
%             if(obj.id == 352430272)%init B07,ip21
%                 WriteGain(obj,0,975);
%                 WriteGain(obj,1,974);
%                 WriteGain(obj,2,978);
%                 WriteGain(obj,3,982);
%             end
            SetTrigSel(obj,3);
            obj.SetTotalCount(8000);
            obj.SetDACStart(1);
            obj.SetDACStop(5);
            obj.SetTrigStart(36);
            obj.SetTrigStop(100);
            obj.SetTrigInterval(200*1e-6);
            obj.SetTrigCount(10);
            obj.SetLoop(1,1,1,1);
            obj.SetIsMaster(0);
        end
        
        function StartStop(obj,index)            %
            if ~obj.isopen
                obj.Open();
            end
            ret = calllib(obj.driver,'WriteInstruction', obj.id,uint32(hex2dec('00000405')),uint32(index),0);
            if(ret == -1)
                error('USTCADDA:StartStopError','Start/Stop failed.');
            end
        end
        
        function FlipRAM(obj,index)
            if ~obj.isopen
                obj.Open();
            end
            ret = calllib(obj.driver,'WriteInstruction', obj.id,uint32(hex2dec('00000305')),uint32(index),0);
            if(ret == -1)
                 error('USTCADDA:FlipRAMError','FlipRAM failed.');
            end
        end
        
        function SetLoop(obj,arg1,arg2,arg3,arg4)
            if ~obj.isopen
                obj.Open();
            end
            para1 = arg1*2^16 + arg2;
            para2 = arg3*2^16 + arg4;
            ret = calllib(obj.driver,'WriteInstruction', obj.id,uint32(hex2dec('00000905')),uint32(para1),uint32(para2));
            if(ret == -1)
                error('USTCADDA:SetLoopError','SetLoop failed.');
            end
        end

        function ret = SetTotalCount(obj,count)
            if ~obj.isopen
                obj.Open();
            end
             ret = calllib(obj.driver,'WriteInstruction',uint32(obj.id),uint32(hex2dec('00001805')),1,uint32(count*2^16));
             if(ret == -1)
                 error('USTCADDA:SetTotalCount','Set SetTotalCount failed.');
             end
        end
        
        function ret = SetDACStart(obj,count)
            if ~obj.isopen
                obj.Open();
            end
             ret = calllib(obj.driver,'WriteInstruction',uint32(obj.id),uint32(hex2dec('00001805')),2,uint32(count*2^16));
             if(ret == -1)
                 error('USTCADDA:SetDACStart','Set SetDACStart failed.');
             end
        end
         
        function ret = SetDACStop(obj,count)
            if ~obj.isopen
                obj.Open();
            end
             ret = calllib(obj.driver,'WriteInstruction',uint32(obj.id),uint32(hex2dec('00001805')),3,uint32(count*2^16));
             if(ret == -1)
                 error('USTCADDA:SetDACStop','Set SetDACStop failed.');
             end
        end
        
        function ret = SetTrigStart(obj,count)
            if ~obj.isopen
                obj.Open();
            end
             ret = calllib(obj.driver,'WriteInstruction',uint32(obj.id),uint32(hex2dec('00001805')),4,uint32(count*2^16));
             if(ret == -1)
                 error('USTCADDA:SetTrigStart','Set SetTrigStart failed.');
             end
        end
        
        function ret = SetTrigStop(obj,count)
            if ~obj.isopen
                obj.Open();
            end
             ret = calllib(obj.driver,'WriteInstruction',uint32(obj.id),uint32(hex2dec('00001805')),5,uint32(count*2^16));
             if(ret == -1)
                 error('USTCADDA:SetTrigStop','Set SetTrigStop failed.');
             end
         end
        
        function SetIsMaster(obj,ismaster)
            if ~obj.isopen
                obj.Open();
            end
            ret= calllib(obj.driver,'WriteInstruction',uint32(obj.id),uint32(hex2dec('00001805')),6,uint32(ismaster*2^16));
            if(ret == -1)
                error('USTCADDA:SetIsMaster','Set SetIsMaster failed.');
            end
        end
        
        function SetTrigSel(obj,sel)
            if ~obj.isopen
                obj.Open();
            end
            ret= calllib(obj.driver,'WriteInstruction',uint32(obj.id),uint32(hex2dec('00001805')),7,uint32(sel*2^16));
            if(ret == -1)
                error('USTCADDA:SetTrigSel','Set SetTrigSel failed.');
            end
        end
        
        function ret = SendIntTrig(obj)
            if ~obj.isopen
                obj.Open();
            end
             ret = calllib(obj.driver,'WriteInstruction',uint32(obj.id),uint32(hex2dec('00001805')),8,uint32(2^16));
             if(ret == -1)
                 error('USTCADDA:SendIntTrig','Set SendIntTrig failed.');
             end
        end
                
        function ret = SetTrigInterval(obj,T)
            % T unit: seconds
            if ~obj.isopen
                obj.Open();
            end
            count = T/4e-9;
            ret= calllib(obj.driver,'WriteInstruction',obj.id,uint32(hex2dec('00001805')),9,uint32(count*2^12));
             if(ret == -1)
                 error('USTCADDA:SelectTrigIntervalError','Set trigger interval failed.');
             end
        end
        
        function ret = SetTrigCount(obj,count)
            if ~obj.isopen
                obj.Open();
            end
            ret= calllib(obj.driver,'WriteInstruction',obj.id,uint32(hex2dec('00001805')),10,uint32(count*2^12));
             if(ret == -1)
                 error('USTCADDA:SetTrigCountError','Set trigger Count failed.');
             end
        end
        
        function WriteWave(obj,ch,offset,data0)
            if ~obj.isopen
                obj.Open();
            end
            for k = 1:length(data0)/2
                temp = data0(2*k);
                data0(2*k) = data0(2*k-1);
                data0(2*k-1) = temp;
            end
            len = length(data0);
            data = data0;
            if(mod(len,32) ~= 0)
                len = (floor(len/32)+1)*32;
                data = zeros(1,len);
                data(1:length(data0)) = data0;
            end
            obj.StartStop(240);
            seq = qes.hwdriver.sync.ustcadda_backen.USTCDAC.Generate(length(data0)/8);
            WriteSeq(obj,ch,0,seq);
            pval = libpointer('uint16Ptr', data);
            startaddr = ch*2*2^18+2*offset;
            len = length(data)*2;
            [ret,~] = calllib(obj.driver,'WriteMemory',obj.id,uint32(hex2dec('000000004')),uint32(startaddr),uint32(len),pval);
            if(ret == -1)
                error('USTCADDA:WriteWaveError','WriteWave failed.');
            end
            obj.StartStop(15);
        end
        
        function WriteSeq(obj,ch,offset,data)
            if ~obj.isopen
                obj.Open();
            end
            pval = libpointer('uint16Ptr', data);
            startaddr = (ch*2+1)*2^18+offset*8;%采样点的内存起始地址，单位是字节。
            len = length(data)*2;%字节个数，以采样点为单位。
            [ret,~] = calllib(obj.driver,'WriteMemory',obj.id,uint32(hex2dec('00000004')),uint32(startaddr),uint32(len),pval);
            if(ret == -1)
                error('USTCADDA:WriteSeqError','WriteSeq failed.');
            end
        end
       
        function ret = ReadWave(obj,ch,offset,len)
              if ~obj.isopen
                 obj.Open();
              end
              startaddr = (ch*2)*2^18 + 2*offset;
             [ret,pwave] = calllib(obj.driver,'ReadMemory',obj.pid,uint32(hex2dec('00000003')),uint32(startaddr),uint32(len*2),0);
             if(ret == 0)
                 ret = pwave; % ret = get(pwave,'Value');
             else
                  error('USTCADDA:ReadWaveError','ReadWave failed.');
             end
        end
        
        function ret = ReadSeq(obj,ch,offset,len)
              if ~obj.isopen
                 obj.Open();
              end
              startaddr = (ch*2+1)*2^18 + offset*8;
             [ret,pwave] = calllib(obj.driver,'ReadMemory',obj.pid,uint32(hex2dec('00000003')),uint32(startaddr),uint32(len*8),0);
             if(ret == 0)
                 ret = pwave; % ret = get(pwave,'Value');
             else
                  error('USTCADDA:ReadSeqError','ReadSeq failed.');
             end
        end
        
        function ret = ReadReg(obj,addr)
             if ~obj.isopen
                 obj.Open();
             end 
             ret = calllib(obj.driver,'ReadInstruction',obj.id,uint32(hex2dec('00000001')),uint32(addr),0);
             if(ret == -1)
                 error('USTCADDA:ReadRegError','WriteReg failed.');
             end
        end
        
        function ret = WriteReg(obj,addr,data)
             if ~obj.isopen
                 obj.Open();
             end 
             ret = calllib(obj.driver,'WriteInstruction',obj.id,uint32(hex2dec('00000002')),uint32(addr),uint32(data));
             if(ret == -1)
                 error('USTCADDA:WriteRegError','WriteReg failed.');
             end
        end
        
        function ret = WriteGain(obj,channel,data)
             if ~obj.isopen
                 obj.Open();
             end 
             ret = calllib(obj.driver,'WriteInstruction',obj.id,uint32(hex2dec('00000702')),uint32(channel),uint32(data));
             if(ret == -1)
                 error('USTCADDA:WriteGain','WriteGain failed.');
             end
        end
        
        function flushinput(obj)
            obj.ibuffer = [];
        end
        
        function flushoutput(obj)
            obj.obuffer = [];
        end
        
        function response = query(obj,cmd)
            obj.HandleCmd(cmd);
            response = obj.ibuffer;
            obj.ibuffer = [];
        end
        
        function fprintf(obj,cmd)
            obj.HandleCmd(cmd);
        end

        function fopen(obj)
            obj.Open();
        end
        
        function fclose(obj)
            obj.Close();
        end
        
        function close(obj)
            obj.Close();
        end
        
        function delete(obj)
            obj.Close();
        end
    end
    
    methods (Static = true)
       
        function SetParallel()
            if(libisloaded(USTCDAC.driver))
                ret = calllib(USTCDAC.driver,'SetTaskMode');
                if(ret == -1)
                    error('USTCADDA:SetParallel','SetParallel failed.');
                end
            else
                error('USTCADDA:SetParallel','Library does not load!');
            end
        end
       
        function StartTask()
            if(libisloaded(USTCDAC.driver))
                ret = calllib(USTCDAC.driver,'StartTask');
                if(ret == -1)
                    warning('USTCADDA:StartTask','Does not run in parallel mode!.');
                end
            else
                error('USTCADDA:SetParallel','Library does not load!');
            end           
        end
    end
    
    methods (Access = private)
         function HandleCmd(obj, cmd)
            cmd = upper(cmd);
            switch cmd
                case '*IDN?'
                    obj.ibuffer = 'USTC,USTC_DA_V1';
                    obj.errorstatus = false;
                case {'*CLS','*RST'}
                    % to be implemented
                    obj.errorstatus = false;
                otherwise
                    obj.ibuffer = ['Unrecognized command string: ', cmd];
                    obj.errorstatus = true;
            end
         end
    end
end