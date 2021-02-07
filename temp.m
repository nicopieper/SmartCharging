Debugging=1;
NumDecissionGroups=1;
UseParallel=0;
x111=[];
NumUsers=1;
for y=1001:10000
    UserNum=y:y+NumUsers-1;
    InitialisePreAlgo;
    CalcConsOptVars;
    CalcDynOptVars;
    PreAlgo;
    x111=[x111;x];
end
    


% lob=1;
% upb=length(Users)-1;
% 
% while abs(lob-upb)>1
%     NumUsers=ceil((upb+lob)/2);
%     UserNum=2:NumUsers+1;
%     try
%         InitialisePreAlgo;
%         CalcConsOptVars;
%         CalcDynOptVars;
%         PreAlgo;
%         lob=NumUsers;
%     catch
%         upb=NumUsers;
%     end
% end
% UserNum=NumUsers;
% NumUsers=1;
