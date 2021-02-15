a=eval(string(system("timeout 1s top", '-echo')));
system("q");
1


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
