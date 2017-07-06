function [WaveformData] = PrepareWvData(WaveformObj,DAVpp,NB)
    % this function is a static private method
    %

% Copyright 2015 Yulin Wu, Institute of Physics, Chinese  Academy of Sciences
% mail4ywu@gmail.com/mail4ywu@icloud.com

    t = WaveformObj.t0:WaveformObj.t0+WaveformObj.length-1;
    y = WaveformObj(t);
    if WaveformObj.iq
        WaveformData = [real(y);imag(y)];
        N = 2;
    else
        WaveformData = real(y);
        N = 1;
    end
    
    for ii = 1:N
        VHi = max(WaveformData(ii,:));
        VLo = min(WaveformData(ii,:));
        Vpp =  VHi - VLo;
        WaveformData(ii,:)  = WaveformData(ii,:) - (VHi + VLo)/2;
        if Vpp > 0 
            WaveformData(ii,:) = WaveformData(ii,:)/Vpp;
        end

        if Vpp > 0
            WaveformData(ii,:) = WaveformData(ii,:) + 0.5;
        end

        RequiredMinDAVpp = 2*max(abs(VHi),abs(VLo));
        if DAVpp < RequiredMinDAVpp - 1e-4
            error('AWG:PrepareWvDataError',['Waveform Vpp out of DA Vpp range, maximum: ', num2str(DAVpp,'%0.4f'), ', ', num2str(RequiredMinDAVpp,'%0.4f'),' required.']);
        end

        K = 2^NB-1;
        if Vpp > 0
            r1 = (1-RequiredMinDAVpp/DAVpp)/2;
            r2 = Vpp/DAVpp;
            if abs(VHi)>= abs(VLo)
                WaveformData(ii,:) = round(K*(r2*WaveformData(ii,:)+1-r2-r1));
            else
                WaveformData(ii,:) = round(K*(r2*WaveformData(ii,:)+r1));
            end
        else % DC
            WaveformData(ii,1:end) = (2^(NB-1)-1)*(1 + VHi/(DAVpp/2));
        end
    end
    WaveformData = uint16(WaveformData);
end