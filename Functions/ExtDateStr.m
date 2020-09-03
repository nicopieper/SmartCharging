function Str=ExtDateStr(Str)
    if length(Str)==1
        Str=strcat('0', Str);
    end
end