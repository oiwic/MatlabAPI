% author:guocheng
% data:2017/3/21
% version:1.1
% file:waveform.m
% describe:generate some simple waveform

classdef waveform
    properties
        amplitude;
        offset;
        frequency;
    end
    properties(Constant = true)
        sample_rate = 2e9;
    end
    methods(Static = true)
        function seq = generate_seq(count)
            seq  = zeros(1,16384);
            if(mod(count,8) ~= 0)
                count = floor(count/8)+1;
            else
                count = count/8;
            end
            for k = 1:4096
                seq(4*k-3) = 0;
                seq(4*k-2) = 0;
                seq(4*k-1) = count;
                seq(4*k)   = 0;
            end
        end
        
        function seq = generate_trig_seq(count,delay)
            % �����8~15��������
            if(mod(count,8) ~= 0)
                count = (floor(count/8)+1);
            else
                count = count/8;
            end
            % ��2����������,���Ǳ������512bitλ�������
            seq  = zeros(1,16384);
            %first sequence,�����16ns��ʱ�����ڴ������������
            function_ctrl = 64;     %53-63λ
            trigger_ctrl  = 0;      %48-55λ
            counter_ctrl  = 0;      %32-47λ����ʱ������
            length_wave   = 2;      %16-31λ,������γ���
            address_wave  = 0;      %0-15������ʼ��ַ
            for  k = 1:2:4096  
                seq(4*k-3) = function_ctrl*256 + trigger_ctrl;
                seq(4*k-2) = counter_ctrl;
                seq(4*k-1)   = length_wave;
                seq(4*k) = address_wave;
            end
            if(delay ~= 0)
                function_ctrl = 32;     %53-63λ����ʱ�����ֹͣ��ʶ
                counter_ctrl  = delay-1;%32-47λ����ʱ������
            else
                function_ctrl = 0;      %�������
                counter_ctrl  = 0;
            end
            trigger_ctrl = 0;       %48-55λ
            length_wave  = count;   %16-31λ,������γ���
            address_wave = count;   %0-15������ʼ��ַ����1��Ϊ����������ı�����
            for k = 2:2:4096    
                seq(4*k-3) = function_ctrl*256 + trigger_ctrl;
                seq(4*k-2) = counter_ctrl;
                seq(4*k-1)   = length_wave;
                seq(4*k) = address_wave;
            end
        end
        
        function  total_point = best_fit_count(fre)
            %SETDACFREQUENCY ��2G�����ʺ���������Ϊ32768���������ɸ���Ƶ�ʲ���
            % �ڹ̶������ʺ����޳���������������һ��Ƶ�������С�Ĳ���
            sample_rate = 2e9;
            period_point = 1/fre*sample_rate;
            err = ones(1,floor(32768/period_point));
            for k = 1:floor(32768/period_point)
                total_point = floor((floor(k * period_point)/8))*8;
                err(k) = abs(k*period_point - total_point);
            end
            index = find(err == min(err));
            total_point = floor(index(1) * period_point);
        end
        
    end
    
    methods
        function obj = waveform()
            obj.amplitude = 65535;
            obj.offset = 32767.5;
            obj.frequency = 10e6;
        end
        function wave = generate_squr(obj)
            period = obj.sample_rate/obj.frequency;         %����period��һ������
            total_count = obj.best_fit_count(obj.frequency);
            wave = zeros(1,total_count);
            x = 0:(total_count-1);
            wave(mod(x,period) <  period/2) = obj.offset - obj.amplitude/2;
            wave(mod(x,period) >= period/2) = obj.offset + obj.amplitude/2;
        end
        
        function wave = generate_sine(obj)
            period = obj.sample_rate/obj.frequency;         %����period��һ������
            total_count = obj.best_fit_count(obj.frequency);
            x = 0:(total_count - 1);
            wave = 0.5*obj.amplitude*sin(2*pi*x./period);
            wave = wave + obj.offset;
        end
        
        function wave = generate_raw(obj)
            period = obj.sample_rate/obj.frequency;         %����period��һ������
            total_count = obj.best_fit_count(obj.frequency);
            x = 0:(total_count - 1);
            wave = mod(x,period)*obj.amplitude/period - obj.amplitude/2 + obj.offset;
        end
        
        function wave = generate_dc(obj)
            wave = ones(1,8)*obj.offset;
        end
        
    end
end