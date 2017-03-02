classdef ustcadda < handle & qes.hwdriver.icinterface_compatible
    properties
        record_ln = 2000;
    end
    properties (Constant = true)
        smplrate = 1e9
    end
    properties (SetAccess = private, GetAccess = private)
        ad;
        da1;
        da2;
        master;
    end
    methods
        function obj = ustcadda()
%             mac=['34';'97';'f6';'8d';'41';'45'];
            mac=['68';'05';'CA';'30';'AA';'78'];
            mac = uint32(hex2dec(mac));
            obj.ad = qes.hwdriver.sync.ustcadda_backen.USTCADC(2);
            obj.ad.Open();
            obj.ad.SetMacAddr(mac');
            obj.da1 = qes.hwdriver.sync.ustcadda_backen.USTCDAC('10.0.1.180',80);
            obj.da1.Open();
            obj.da1.SetIsMaster(1);
            obj.da2 = qes.hwdriver.sync.ustcadda_backen.USTCDAC('10.0.1.21',80);
            obj.da2.Open();
            
            obj.master = obj.da1;
        end
        function [da,da_channel]= Translate(obj,channel)
            if(channel>4)
                da = obj.da2;
                da_channel = channel - 5;
            else
                da = obj.da1;
                da_channel = channel - 1;
            end
        end
        
        function SendWave(obj,channel,data)
            [da,da_channel] = Translate(obj,channel);
            da.WriteWave(da_channel,0,data);
        end
        
        function LoadWave(obj,channel,data,delay)%new function
             [da,da_channel] = Translate(obj,channel);
             delay_count = floor(delay/4e-9);
             da.LoadWave(da_channel,0,data,delay_count);%如果是0通道，对齐
             if(da_channel == 0)
                 trig_start = 65;
                 trig_width = 40;
                 da.SetTrigStart(trig_start+257.5*delay_count);
                 da.SetTrigStop(trig_start +257.5*delay_count + trig_width);
             end
        end
        
%         function SetVpp(obj, channel, value)
%             [da,da_channel] = Translate(obj,channel);
%             da.SetVpp(da_channel,value);
%         end
        
        function [I,Q] = Run(obj,count)
            depth = obj.record_ln;
            obj.master.SetTrigCount(count);
            obj.ad.SetSampleDepth(depth);
            obj.ad.SetTrigCount(count);
            ret = -1;
            while(ret ~= 0)
                obj.ad.EnableADC();
                obj.master.SendIntTrig();
                [ret,I,Q] = obj.ad.RecvData(count,depth);
            end
            I = (reshape(I,[depth,count]))';
            Q = (reshape(Q,[depth,count]))';
        end
        
        function Config(obj)
            TempConfig(obj.da1);
            TempConfig(obj.da2);
        end
    end
end
