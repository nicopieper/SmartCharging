Subs=cell(4,1);
for n=1:4
    Subs{n,1}=n:4:100000/4;
end
for n=1:4
    Subs{n,1}=(n-1)*96000/4/4 + (1:96000/4/4);
end
a=rand((96000+n)/4,4);
b=cell(4,1);

c=cell(4,1);
for n=1:4
    c{n,1}=a(Subs{n,1},:);
end

ticBytes(gcp);
parfor n=1:4
    b{n,1}=c{n,1};
end
tocBytes(gcp)

















% Subs={};
% for k=1:NumDecissionGroups
%     Subs{k}=SubIndices(DecissionGroups{k,2}, ControlPeriods, ControlPeriodsIt, 1);
% end
% 
% a=cell(NumDecissionGroups,1);
% parfor k=1:NumDecissionGroups
%     a{k,1}=ConsSumPowerTSbIt(Subs{k});
% end























% Availability=[];
% VarCounter=0;
% for n=Users{1}.UserNum
%     VarCounter=VarCounter+1;
%     Availability(:,1,VarCounter)=max(0, ismember(double(Users{n}.Logbook(:,1)), 3:5) - double(Users{n}.Logbook(:,2))/Time.StepMin) .* repmat(double(Users{n}.GridConvenientChargingAvailability), length(Users{n}.Logbook(:,1))/96,1);
% end
% AvailabilityMat=reshape(Availability, 96, [], NumUsers);
% figure
% plot(mean(mean(AvailabilityMat,3),2))



% Debugging=1;
% NumDecissionGroups=1;
% UseParallel=0;
% x111=[];
% NumUsers=1;
% for y=1001:10000
%     UserNum=y:y+NumUsers-1;
%     InitialisePreAlgo;
%     CalcConsOptVars;
%     CalcDynOptVars;
%     PreAlgo;
%     x111=[x111;x];
% end
    


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
