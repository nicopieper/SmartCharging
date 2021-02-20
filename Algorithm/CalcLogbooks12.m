Logbooks1=zeros(ControlPeriodsIt,1,NumUsers);
Logbooks2=zeros(ControlPeriodsIt,1,NumUsers);
VarCounter=0;
for k=UserNum
    VarCounter=VarCounter+1;
    Logbooks1(:,1,VarCounter)=double(Users{k}.Logbook(TimeInd+TD.User:TimeInd+TD.User-1+ControlPeriodsIt,1));
    Logbooks2(:,1,VarCounter)=double(Users{k}.Logbook(TimeInd+TD.User:TimeInd+TD.User-1+ControlPeriodsIt,2));
end