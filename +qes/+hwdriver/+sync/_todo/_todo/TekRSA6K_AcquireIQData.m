function IQData = TekRSA6K_AcquireIQData(IPAddress)
% This function returns a complex vector of the Inphase and Quadrature (IQ)
% data from the TekTronix RSA6000 series spectrum analyzer at IP Address
% specified by IPAddress
% Example: IQData = TekRSA6K_AcquireIQData('172.31.57.50')

% Copyright 2010, MathWorks, Inc.
% 18-07-2010, VC.

recordTime = 0.5;         % time in seconds
bandwidth = 10e6;         % bandwidth in Hz
centerFrequency = 503e6;  % center frequency in Hz
frequencySpan = 10e6;     % frequency span in Hz

% Tek instruments use port 4000 for their Sockets connections
% We could use VISA, but using sockets means we don't need to
% install VISA software
TekPort = 4000;
maxRetries = 9;
maxDots = 20;

% Find and close any open connections
openConnections = instrfind('Tag','TekRSA6K_AcquireIQData');
if ~isempty(openConnections)
    fclose(openConnections(:));
end

% Create TCPIP Object set it up and open connection
rsa = tcpip(IPAddress,TekPort);
rsa.InputBufferSize = 50e6;
rsa.Tag = 'TekRSA6K_AcquireIQData';
rsa.Timeout = 3;                    % set timeout to 3 seconds
rsa.ByteOrder = 'littleEndian';     % Instrument returns data in littleEndian format
warning('off','instrument:query:unsuccessfulRead')
fopen(rsa);

% Reset the instrument and query it
fprintf(rsa,'*RST;*CLS');
instrumentID = query(rsa,'*IDN?');
if isempty(instrumentID)
    throw(MException('RSAIQCapture:ConnectionError','Unable to connect to instrument'));
end
disp(['Connected to: ' instrumentID]);

% Abort any current measurement and set up for measurement
fprintf(rsa,'ABORt');
fprintf(rsa,'TRIGger:SEQuence:STATus 0');
fprintf(rsa,'INIT:CONT OFF');


% Select the IQ Measurement and the display for it
fprintf(rsa,'DISPlay:GENeral:MEASview:NEW IQVTime');
fprintf(rsa,'DISPlay:GENeral:MEASview:SELect IQVTime');
fprintf(rsa,'SENSe:IQVTime:CLEar:RESults');
fprintf(rsa,'DISPlay:IQVTime:X:SCALe:AUTO');
fprintf(rsa,'DISPlay:IQVTime:Y:SCALe:AUTO');
fprintf(rsa,'DISPlay:GENeral:MEASview:DELete SPECTrum');

% Set up parameters for measurement
fprintf(rsa,'SENSe:ACQuisition:MODE LENGTH');
fprintf(rsa,['SENSe:ACQuisition:SEConds ' num2str(recordTime)]);
fprintf(rsa,['SENSe:ACQuisition:BANDwidth ' num2str(bandwidth)]);
fprintf(rsa,'SENSe:IQVTime:MAXTracepoints NEVerdecimate');
fprintf(rsa,['SENSe:IQVTime:FREQuency:SPAN ' num2str(frequencySpan)]);
fprintf(rsa,['SENSe:IQVTime:FREQuency:CENTer ' num2str(centerFrequency)]);

% Make meaurement
fprintf(rsa,'INITIATE:IMMEDIATE');
disp('Making measurement...');
% wait till the instrument completes making the measurement
operationComplete = query(rsa,'*OPC?');
count = 1;
while ~isequal(str2double(operationComplete),1)
    operationComplete = query(rsa,'*OPC?');
    disp(sprintf('\b.')); %#ok
    count = count+1;
    if isequal(mod(count,maxDots),0)
        disp(sprintf('\n.')); %#ok
    end
end
disp(sprintf('\b...Done!')); %#ok

% Get number of IDs
IDDetails = query(rsa,'FETCh:RFIN:RECord:IDS?');
IDFields = regexp(IDDetails, ',', 'split');
count = 0;
while ~isequal(length(IDFields),2)
    IDdetails = query(rsa,'FETCh:RFIN:RECord:IDS?');
    IDFields = regexp(IDDetails, ',', 'split');
    count = count + 1;
    if count>maxRetries
        throw(MException('RSAIQCapture:IDError', sprintf('Unable to obtain number of record ID''s from the instrument after %d tries.',count)));
    end
end

% Warn if there are more than one ID
if ~isequal(str2double(IDFields{1}),str2double(IDFields{2}))
    warning(sprintf('Unexpected number of IDs in this acquisition. IDdetails: %s .\nData only being returned for first ID.',IDdetails)); %#ok
end
% Get the header. For details of the header fields, refer to page 2-488 of the PDF file:
% http://www2.tek.com/cmsreplive/marep/17272/077024902web_2010.06.21.11.36.16_17272_EN.pdf
header = query(rsa,'FETCh:RFIN:IQ:HEADer? 1');
count = 0;
while length(header)<10
    header = query(rsa,'FETCh:RFIN:IQ:HEADer? 1');
    count = count + 1;
    if count>maxRetries
        throw(MException('RSAIQCapture:HeaderError',sprintf('Unable to obtain measurement header information from the instrument after %d tries.',count)));
    end
end
headerField = regexp(header, ',', 'split');

% Display info to user so they know MATLAB is busy
disp(sprintf('Signal sampled at %d Hz. Transferring %d points to MATLAB.',str2double(headerField{2}),str2double(headerField{3}))); %#ok

% Increase the timeout as transferring data can take time
fclose(rsa);
rsa.Timeout = 300;
fopen(rsa);

% The firmware crashes if we try and retrieve a lot of data in one go so we
% get data from the instrument in smaller chunks
maxSafeSamples = rsa.InputBufferSize/16; % total buffer size/(2 bytes per IQ point)
maxSamples = str2double(headerField{3});
if maxSamples <= maxSafeSamples
    fprintf(rsa,['FETCh:RFIN:IQ? 1,0,' num2str(maxSamples)]);
    data = binblockread(rsa,'single');
else
    remainingData = maxSamples;
    startSamples = 0;
    data = zeros(1,maxSamples*2);
    count = 1;
    while remainingData>0
        fprintf(rsa,['FETCh:RFIN:IQ? 1,' num2str(startSamples) ',' num2str(startSamples+maxSafeSamples - 1)]);
        data((startSamples*2+1):(startSamples+maxSafeSamples)*2) = binblockread(rsa,'single');
        startSamples = startSamples + maxSafeSamples;
        remainingData = remainingData - maxSafeSamples;
        if remainingData < maxSafeSamples
            maxSafeSamples = remainingData;
        end
        disp(sprintf('\b.')); %#ok
        count = count + 1;
        if isequal(mod(count,maxDots),0)
            disp(sprintf('\n.')); %#ok
        end
    end
end
disp(sprintf('\b...Done!')); %#ok

% clear variables to free up space
fclose(rsa); delete(rsa); clear rsa; 
% generate the complex vector to return
IQData = data(1:2:end) + 1i.*data(2:2:end);
warning('on','instrument:query:unsuccessfulRead')
end