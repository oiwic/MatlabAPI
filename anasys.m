%% ·ÖÎö
clc
code = [];
index = 1;
for k = 1:len_row
    if(chip(1,k)~=chip(2,k))
        code(index) = k;
        index = index+1;
    end
end
