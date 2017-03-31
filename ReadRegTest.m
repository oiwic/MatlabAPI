%% ¶Á¼Ä´æÆ÷
da = USTCDAC('10.0.2.8',80);
da.Open();

len_row = 1314;
len_col = 10;
chip = zeros(len_col,len_row);

for kk = 1:len_col
    for k = 1:len_row
        chip(kk,k) = da.ReadAD9136_1(k-1);
    end
    da.InitBoard();
end

da.Close();

%%
clc
code = [];
index = 1;
for k = 1:len_row
    if(chip(1,k)~=chip(2,k))
        code(index) = k;
        index = index+1;
    end
end

%%
da = USTCDAC('10.0.2.8',80);
da.Open();
for kk = 1:1
    da.InitBoard();
    disp(mod(da.ReadAD9136_1(768),256));
    pause(0.2);
end
da.Close();