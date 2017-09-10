da = USTCDAC('10.0.2.7',80);
da.isblock = 1;
da.Open();
da.Init();
da.SetTrigInterval(8e-6);
da.SetTotalCount(1500);
da.SetIsMaster(1);
da.SetTrigSel(3);
da.StartStop(240);
loop_count = 2;
trig_count = loop_count*3;
wave_delay = 10;%40ns
%% generate wave
vpp = 65535;
offset = 32768;
length(1:3) = [5000,5000,5000];
t = linspace(0,2*pi,length(1));
wave0 = zeros(1,16) + 32768;
wave1 = sin(t)*vpp*0.5 + offset;
wave2 = linspace(offset - vpp/2,offset + vpp/2,length(2));
wave3 = zeros(1,length(3))+offset - vpp/2 ;wave3(floor(length(3)/2+1):length(3)) = offset + vpp/2;
da.WriteWave(1,0,[wave1,wave2,wave3]);
da.WriteWave(2,0,[wave1,wave2,wave3]);
vpp = vpp/2;wave2 = linspace(offset - vpp/2,offset + vpp/2,length(3));
vpp = vpp/2;wave3 = zeros(1,length(3))+offset - vpp/2 ;wave3(floor(length(3)/2+1):length(3)) = offset + vpp/2;
da.WriteWave(3,0,[wave1,wave2,wave3]);
da.WriteWave(4,0,[wave1,wave2,wave3]);
%% generate sequence
length = length/8;
seqobj = SeqManager(length(1),0,0);
seq1_1 = seqobj.GetTrigSeq(0);
seqobj = SeqManager(length(2),sum(length(1:1)),0);
seq1_2 = seqobj.GetTrigSeq(0);
seqobj = SeqManager(length(3),sum(length(1:2)),0);
seq1_3 = seqobj.GetTrigSeq(1);
da.WriteSeq(1,0,[seq1_1,seq1_2,seq1_3]);
da.WriteSeq(2,0,[seq1_1,seq1_2,seq1_3]);
da.WriteSeq(3,0,[seq1_1,seq1_2,seq1_3]);
da.WriteSeq(4,0,[seq1_1,seq1_2,seq1_3]);

da.SetTrigCount(trig_count);
da.SetLoop(loop_count,loop_count,loop_count,loop_count);
da.StartStop(15);
da.SendIntTrig();

pause(1);
da.Close();