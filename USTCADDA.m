% 	FileName:USTCADDA.m
% 	Author:GuoCheng
% 	E-mail:fortune@mail.ustc.edu.cn
% 	All right reserved @ GuoCheng.
% 	Modified: 2017.3.7
%   Description:The class of ADDA
classdef USTCADDA < handle
    properties(SetAccess = private)
        da_list = [];
        ad_list = [];
        da_channel_list = [];
        ad_channel_list = [];
        da_count = 0;
        ad_count = 0;
        da_master_index = 1;
    end
    
    properties
        sample_depth;           %需要在Run前设置
        trig_count;             %需要在Run前设置
        delay_step = 8;         %未使用
        da_sample_rate = 2e9;   %未使用
        ad_sample_rate = 1e9;   %未使用
        ad_range = 1;           %未使用
        da_taken;               %da通道占用
        ad_taken;               %ad通道占用
        da_start_code;          %触发输出时，起始码码值
        offsetCorr;             %用来补偿差放的0偏置，暂不使用
    end
    
    methods (Static = true)
        function seq = GenerateTrigSeq(count,delay)
            % 多输出8~15个保持码
            if(mod(count,8) ~= 0)
                count = (floor(count/8)+2);
            else
                count = count/8 + 1;
            end
            % 共2个序列数据,但是必须组成512bit位宽的数据
            seq  = zeros(1,16384);
            %first sequence,会产生16ns延时，用于触发启动输出。
            function_ctrl = 64+4;   %53-63位
            trigger_ctrl  = 0;      %48-55位
            counter_ctrl  = 0;      %32-47位，计时计数器
            length_wave   = 2;      %16-31位,输出波形长度
            address_wave  = 0;      %0-15波形起始地址
            for  k = 1:2:4096 
                seq(4*k-3) = counter_ctrl;
                seq(4*k-2) = function_ctrl*256 + trigger_ctrl;
                seq(4*k-1) = address_wave;
                seq(4*k)   = length_wave;
            end

            if(delay ~= 0)
                function_ctrl = 36;     %53-63位，计时输出加停止标识
                counter_ctrl  = delay-1;%32-47位，计时计数器
            else
                function_ctrl = 4;      %保持输出
                counter_ctrl  = 0;
            end
            
            trigger_ctrl = 0;       %48-55位
            length_wave  = count;   %16-31位,输出波形长度
            address_wave = count;   %0-15波形起始地址，加1是为了跳过多余的保持码
            for k = 2:2:4096
                seq(4*k-3) = counter_ctrl;
                seq(4*k-2) = function_ctrl*256 + trigger_ctrl;
                seq(4*k-1) = address_wave;
                seq(4*k)   = length_wave;
            end
        end
        
        function seq = GenerateContinuousSeq(count)
            seq  = zeros(1,16384);
            if(mod(count,8) ~= 0)
                count = floor(count/8)+1;
            else
                count = count/8;
            end
            for k = 1:4096
                seq(4*k-3) = 0;
                seq(4*k-2) = 0;
                seq(4*k-1) = 0;
                seq(4*k)   = count;
            end
        end
    end
    
    methods
        function obj = USTCADDA()
            obj.sample_depth = 2000;
            obj.trig_count = 100;
            obj.da_start_code = 32767;
        end
       
        function Config(obj)
            obj.Close();
            s = qes.util.loadSettings('qes_settings',{'hardware','hwsettings1','ustcadda'});
            % 配置ADDA
            if(isfield(s,'sample_depth'))
                obj.sample_depth = s.sample_depth;
            end
            if(isfield(s,'trigger_count'))
                obj.trig_count = s.trigger_count;
            end
                
            obj.da_count = length(s.da_boards);
            obj.ad_count = length(s.ad_boards);
            % 配置DAC
            for k = 1:obj.da_count
                obj.da_list(k).da = USTCDAC(s.da_boards{k}.ip,s.da_boards{k}.port);
                obj.da_list(k).da.set('name',s.da_boards{k}.name);
                obj.da_list(k).da.set('channel_amount',s.da_boards{k}.numchnl);
                obj.da_list(k).da.set('gain',[511,511,511,511]);
                obj.da_list(k).da.set('offset',[0,0,0,0]);
                obj.da_list(k).da.set('sample_rate',s.da_boards{k}.smplrate);
                obj.da_list(k).da.set('sync_delay',s.da_boards{k}.syncdelay);
                obj.da_list(k).da.set('trig_delay',s.da_boards{k}.trigdelay);
                %设置trig_sel默认值0
                obj.da_list(k).da.set('trig_sel',0);
                if(isfield(s,'trigger_source'))
                    obj.da_list(k).da.set('trig_sel',s.trigger_source);
                end
                %设置master板，默认值为第一个板
                obj.da_list(k).da.set('ismaster', 0);
                if(isfield(s,'da_master') && strcmpi(s.da_boards{k}.name,s.da_master))
                    obj.da_master_index = k;
                end
                % 初始化通道的mask值
                obj.da_list(k).mask_plus = 0; %正mask
                obj.da_list(k).mask_min  = 0; %负mask
            end
            % 设置主板
            obj.da_list(obj.da_master_index).da.set('ismaster',1);
            obj.da_list(obj.da_master_index).da.set('trig_interval',200e-6);% 设置trig_interval默认值200us
            if(isfield(s,'trigger_interval'))
                obj.da_list(obj.da_master_index).da.set('trig_interval',s.trigger_interval);
            end
            % 映射通道
            for k = 1:length(s.da_chnl_map);
                channel = fieldnames(s.da_chnl_map{k});
                ch = channel{1};
                ch = str2double(ch(3:length(ch)));
                channel_info = s.da_chnl_map{k}.(channel{1});
                channel_info = regexp(channel_info,' ', 'split');
                da_name = channel_info{1};
                channel_name = channel_info{2};
                da_index = 1;
                for x = 1:length(obj.da_list)
                    if(strcmpi(da_name,obj.da_list(x).da.get('name')))
                        da_index = x;
                    end
                end
                obj.da_channel_list(ch).index = da_index;
                obj.da_channel_list(ch).ch = str2double(channel_name(3:length(channel_name)));
                % 添加数据结构体
                obj.da_channel_list(ch).data = [];
                % 设置通道触发后输出延时
                obj.da_channel_list(ch).delay = 0;
            end
            % 配置ADC,目前只支持一个网卡
            for k = 1:obj.ad_count
                obj.ad_list(k).ad = USTCADC(s.ad_boards{k}.netcard);
                obj.ad_list(k).ad.set('sample_rate',s.ad_boards{k}.smplrate);
                obj.ad_list(k).ad.set('channel_amount',s.ad_boards{k}.numchnl);
                obj.ad_list(k).ad.set('mac',s.ad_boards{k}.mac);
            end
            % 映射ADC的通道
            for k = 1:length(s.ad_chnl_map);
                channel = fieldnames(s.ad_chnl_map{k});
                ch = channel{1};
                ch = str2double(ch(3:length(ch)));
                channel_info = s.da_chnl_map{k}.(channel{1});
                channel_info = regexp(channel_info,' ', 'split');
                ad_name = channel_info{1};
                channel_name = channel_info{2};
                ad_index = 1;
                for x = 1:length(obj.ad_list)
                    if(strcmpi(ad_name,obj.da_list(x).da.get('name')))
                        ad_index = x;
                    end
                end
                obj.ad_channel_list(ch).index = ad_index;
                obj.ad_channel_list(ch).ch = str2double(channel_name(3:length(channel_name)));
                % 添加数据结构体
                obj.da_channel_list(ch).data = [];
            end
        end
        
        function Close(obj)
            len = length(obj.da_list);
            while(len>0)
                obj.da_list(len).da.Close();
                len = len - 1;
            end
            len = length(obj.ad_list);
            while(len>0)
                obj.ad_list(len).ad.Close();
                len = len - 1;
            end
        end
        
        function Open(obj)
            len = length(obj.da_list);
            while(len>0)
                obj.da_list(len).da.Open();
                len = len - 1;
            end
            len = length(obj.ad_list);
            while(len>0)
                obj.ad_list(len).ad.Open();
                len = len - 1;
            end
        end
        
        function [I,Q] = Run(obj,isSample)
            I=0;Q=0;ret = -1;
            obj.da_list(obj.da_master_index).da.SetTrigCount(obj.trig_count);
            obj.ad_list(1).ad.SetTrigCount(obj.trig_count);
            obj.ad_list(1).ad.SetSampleDepth(obj.sample_depth);
            % 停止除连续波形外的通道，启动触发通道
            for k = 1:obj.da_count
                obj.da_list(k).da.StartStop((15 - obj.da_list(k).mask_min)*16);
                obj.da_list(k).da.StartStop(obj.da_list(k).mask_plus);
            end
            % 检查是否成功写入完毕
            for k=1:obj.da_count
                isSuccessed = obj.da_list(k).da.CheckStatus();
                if(isSuccessed ~= 1)
                    error('USTCADDA:Run','There were some task failed!');
                end
            end
            % 采集数据
            while(ret ~= 0)
                obj.ad_list(1).ad.EnableADC();  
                obj.da_list(obj.da_master_index).da.SendIntTrig();
                if(isSample == true)
                    [ret,I,Q] = obj.ad_list(1).ad.RecvData(obj.trig_count,obj.sample_depth);
                else
                    ret = 0;
                end
            end
            % 将数据整理成固定格式
            if(isSample == true)
                I = (reshape(I,[obj.sample_depth,obj.trig_count]))';
                Q = (reshape(Q,[obj.sample_depth,obj.trig_count]))';
            end
            % 并清空通道记录
            for k = 1:obj.da_count
                obj.da_list(k).mask_plus = 0;
            end
        end
        
        function SendWave(obj,channel,data)
            obj.da_channel_list(channel).data = data;
            ch_info = obj.da_channel_list(channel);
            ch_delay = obj.da_channel_list(channel).delay;
            ch = ch_info.ch;
            da_struct = obj.da_list(ch_info.index);
            len = length(data);
            keep_code = data(len);
            % 生成格式化的序列
            seq = obj.GenerateTrigSeq(len,ch_delay);
            % 发送序列
            da_struct.da.WriteSeq(ch,0,seq);
            % 格式化波形,需要与序列数据配合来实现格式
            if(mod(len,8) ~= 0)
                data(len+1:(floor(len/8)+2)*8) = keep_code;
            else
                data(len+1:len+8) = keep_code;
            end
            len = length(data);
            data(len+1:len+16) = obj.da_start_code;    %16个采样点的起始码
            % 发送波形
            da_struct.da.WriteWave(ch,0,data);
            % 相当于或上一个通道
            if(mod(floor(da_struct.mask_plus/(2^(ch-1))),2) == 0)
                obj.da_list(ch_info.index).mask_plus = da_struct.mask_plus + 2^(ch-1);
            end
        end
       
        function SendContinuousWave(obj,channel,voltage)
            % 如果是直流，则需要将其扩大为1*8数组
            if(length(voltage) == 1)
                voltage = zeros(1,8) + voltage;
            end
            ch_info = obj.da_channel_list(channel);
            ch = ch_info.ch;
            da_struct = obj.da_list(ch_info.index);
            % 停止输出
            da_struct.da.StartStop(2^(ch-1)*16);
            % 写入序列
            seq = obj.GenerateContinuousSeq(length(voltage));
            da_struct.da.WriteSeq(ch,0,seq);
            % 写入波形
            da_struct.da.WriteWave(ch,0,voltage);
            % 更新状态
            if(mod(floor(da_struct.mask_min/(2^(ch-1))),2) == 0)
                obj.da_list(ch_info.index).mask_min = da_struct.mask_min + 2^(ch-1);
            end
            da_struct.da.StartStop(obj.da_list(ch_info.index).mask_min);
        end
        
        function StopContinuousWave(obj,channel)
            ch_info = obj.da_channel_list(channel);
            ch = ch_info.ch;
            da_struct = obj.da_list(ch_info.index);
            if(mod(floor(da_struct.mask_min/(2^(ch-1))),2) ~= 0)
                obj.da_list(ch_info.index).mask_min = da_struct.mask_min - 2^(ch-1);
                da_struct.da.StartStop(2^(ch-1)*16);
            end
        end
        
        function ret = GetDAChannel(obj,ch)
            if(isempty(find(obj.da_taken == ch,1)))
                obj.da_taken = [obj.da_taken,ch];
                ret = 0;
            else
                ret = -1;
            end
        end
        
        function ret = ReleaseDAChannel(obj,ch)
            if(isempty(find(obj.da_taken == ch,1)))
                ret = -1;
            else
                obj.da_taken(obj.da_taken == ch) = [];
                ret = 0;
            end
        end
        
        function da_name = GetDANameFromChannel(obj,channel)
             ch_info = obj.da_channel_list(channel);
             da_name = obj.da_list(ch_info.index).da.get('name');
        end
        
        function SetDATrigDelay(obj,da_name,count)
            for k = 1:obj.da_count
                name = obj.da_list(k).da.get('name');
                if(strcmpi(name,da_name))
                    obj.da_list(k).da.SetTrigDelay(count);
                end
            end
        end
    end
end