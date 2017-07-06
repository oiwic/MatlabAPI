%% 生成实例
da1 = USTCDAC('10.0.2.8',80);
da2 = USTCDAC('10.0.2.5',80);

%% da1
da1.set('ismaster',1);
da1.Open();

data1 = [ones(1,3200),ones(1,3200)*65535];
seq1 = USTCADDA.GenerateTrigSeq(length(data1),0);

da1.SetTrigCount(100);
da1.SetTrigSel(0);

da1.WriteSeq(1,0,seq1);
da1.WriteSeq(2,0,seq1);
da1.WriteSeq(3,0,seq1);
da1.WriteSeq(4,0,seq1);

data1 = [data1,ones(1,16)*32768];

da1.WriteWave(1,0,data1);
da1.WriteWave(2,0,data1);
da1.WriteWave(3,0,data1);
da1.WriteWave(4,0,data1);

da1.StartStop(15);
da1.CheckStatus();

%% da2
da2.Open();
data2 = [ones(1,12),ones(1,12)*65535];
seq2 = USTCADDA.GenerateTrigSeq(length(data2),0);

da2.SetTrigSel(0);
da2.WriteSeq(0,0,seq2);
da2.WriteSeq(1,0,seq2);
da2.WriteSeq(2,0,seq2);
da2.WriteSeq(3,0,seq2);

data2 = [data1,ones(1,16)*32768];
da1.SetTrigSel(0);

da2.WriteWave(0,0,data2);
da2.WriteWave(1,0,data2);
da2.WriteWave(2,0,data2);
da2.WriteWave(3,0,data2);

da2.StartStop(15);
da2.CheckStatus();

%% 发送触发命令
da1.SendIntTrig();

%% close
da1.Close()
da2.Close()