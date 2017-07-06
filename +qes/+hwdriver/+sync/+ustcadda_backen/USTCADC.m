classdef USTCADC < handle
    properties
        isopen;
        status;
        selectnum
    end
    
    properties (GetAccess = private,Constant = true)
        driver = 'USTCADCDriver';
        driverh = 'USTCADCDriver.h';
    end
    
    methods
        function obj = USTCADC(num)
            obj.isopen = false;
            obj.status = 'close';
            obj.selectnum = num;
            driverfilename = [obj.driver,'.dll'];
            if(~libisloaded(obj.driver))
                loadlibrary(driverfilename,obj.driverh);
            end
        end
        
        function Open(obj)
            if ~obj.isopen
                ret = calllib(obj.driver,'OpenADC',int32(obj.selectnum));
                if(ret == 0)
                    obj.status = 'open';
                    obj.isopen = true;
                else
                   error('USTCDA:OpenError','Open ADC failed!');
                end 
            end
        end
        
        function Close(obj)
            if obj.isopen
                ret = calllib(obj.driver,'CloseADC');
                if(ret == 0)
                    obj.status = 'close';
                    obj.isopen = false;
                else
                   error('USTCDA:CloseError','Close ADC failed!');
                end 
            end
        end
        
        function SetSampleDepth(obj,depth)
             if obj.isopen
                data = [0,18,depth/256,mod(depth,256)];
                pdata = libpointer('uint8Ptr', data);
                [ret,~] = calllib(obj.driver,'SendData',int32(4),pdata);
                if(ret ~= 0)
                   error('USTCDA:SendPacket','SetSampleDepth failed!');
                end 
            end
        end
        
        function ClearBuff(obj)
             if obj.isopen
                ret = calllib(obj.driver,'ClearBuff');
                if(ret ~= 0)
                   error('USTCDA:ClearBuff','ClearBuff failed!');
                end 
            end
        end
        
        function SetTrigCount(obj,count)
             if obj.isopen
                data = [0,19,count/256,mod(count,256)];
                pdata = libpointer('uint8Ptr', data);
                [ret,~] = calllib(obj.driver,'SendData',int32(4),pdata);
                if(ret ~= 0)
                   error('USTCDA:SendPacket','SetTrigCount failed!');
                end 
            end
        end
        
        function SetMacAddr(obj,mac)
           if obj.isopen
                data = [0,17];
                data = [data,mac];
                pdata = libpointer('uint8Ptr', data);
                [ret,~] = calllib(obj.driver,'SendData',int32(length(mac)+2),pdata);
                if(ret ~= 0)
                   error('USTCDA:SendPacket','SetMacAddr failed!');
                end 
            end
        end
        
        function ForceTrig(obj)
           if obj.isopen
                data = [0,1,238,238,238,238,238,238];
                pdata = libpointer('uint8Ptr', data);
                [ret,~] = calllib(obj.driver,'SendData',int32(8),pdata);
                if(ret ~= 0)
                   error('USTCDA:SendPacket','ForceTrig failed!');
                end 
            end
        end
        
        function EnableADC(obj)
           if obj.isopen
                data = [0,3,238,238,238,238,238,238];
                pdata = libpointer('uint8Ptr', data);
                [ret,~] = calllib(obj.driver,'SendData',int32(8),pdata);
                if(ret ~= 0)
                   error('USTCDA:SendPacket','EnableADC failed!');
                end 
           end
        end
        
        function [ret,I,Q] = RecvData(obj,row,column)
            if obj.isopen
                I = zeros(row*column,1);
                Q = zeros(row*column,1);
                pI = libpointer('uint8Ptr', I);
                pQ = libpointer('uint8Ptr', Q);
                [ret,I,Q] = calllib(obj.driver,'RecvData',int32(row*column),int32(column),pI,pQ);
            end
        end
    end
end