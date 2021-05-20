try
    system("top -b -n 1 > top.txt");
    File=fopen("top.txt");
    File = fscanf(File,"%s");
    strfind(File, "KiBSpch");
    RAMStr=File(strfind(File, "KiBSpch")+8:strfind(File, "Puff")-1);
    RAM(1,1:3)=[str2double(RAMStr(1:strfind(RAMStr,"gesamt")-1)),...
              str2double(RAMStr(strfind(RAMStr,"gesamt")+7:strfind(RAMStr,"frei")-1)),...
              str2double(RAMStr(strfind(RAMStr,"frei")+5:strfind(RAMStr,"belegt")-1))];
    RAMStr=File(strfind(File, "Swap:")+5:strfind(File, "verf")-1);    
    RAM(2,1:3)=[str2double(RAMStr(1:strfind(RAMStr,"gesamt")-1)),...
              str2double(RAMStr(strfind(RAMStr,"gesamt")+7:strfind(RAMStr,"frei")-1)),...
              str2double(RAMStr(strfind(RAMStr,"frei")+4:strfind(RAMStr,"belegt")-1))];
catch
    disp("Could not measure RAM")
end