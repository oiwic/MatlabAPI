% 	FileName:SeqManager.m
% 	Author:GuoCheng
% 	E-mail:fortune@mail.ustc.edu.cn
% 	All right reserved @ GuoCheng.
% 	Modified: 2017.8.31
%   Description:The class of SeqManger
classdef SeqManager
    properties
        function_ctrl = 0;
        trigger_ctrl = 0;
        counter_ctrl = 0;
        length_wave = 0;
        address_wave = 0;
    end

    methods
        function obj = SeqManager(length_wave,address_wave,delay_count)
            obj.counter_ctrl = delay_count;
            obj.length_wave = length_wave;
            obj.address_wave = address_wave;
        end
        function seq = GetTrigSeq(obj,stopflag)
            seq = zeros(1,4);
            if(stopflag)
                seq(1) = (64+128)*256 + obj.trigger_ctrl;
            else
                seq(1) = 64*256 + obj.trigger_ctrl;
            end
            seq(2) = obj.counter_ctrl;
            seq(3) = obj.length_wave;
            seq(4) = obj.address_wave;
        end
        function seq = GetContSeq(obj,stopflag)
            seq = zeros(1,4);
            if(stopflag)
                seq(1) = 128*256 + obj.trigger_ctrl;
            else
                seq(1) = obj.trigger_ctrl;
            end
            seq(2) = obj.counter_ctrl;
            seq(3) = obj.length_wave;
            seq(4) = obj.address_wave;
        end
        function seq = GetDelySeq(obj,stopflag)
            if(obj.counter_ctrl == 0)
                if(stopflag)
                    seq(1) = 128*256 + obj.trigger_ctrl;
                else
                    seq(1) = obj.trigger_ctrl;
                end
            else
                if(stopflag)
                    seq(1) = (128+32)*256 + obj.trigger_ctrl;
                else
                    seq(1) = 32*256 + obj.trigger_ctrl;
                end
            end
            seq(2) = obj.counter_ctrl;
            seq(3) = obj.length_wave;
            seq(4) = obj.address_wave;    
        end
        function seq = GetTrigDelySeq(obj,stopflag)
            seq1 = obj.GetTrigSeq(0);
            seq1(3) = 2;
            seq1(4) = 0;
            seq2 = obj.GetDelySeq(stopflag);
            seq = [seq1,seq2];
        end
    end
    
end