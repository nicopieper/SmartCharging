for n=2
    AvailableBlocks=[find(ismember(Users{n}.LogbookSmart(1:end,1),3:5) & ~ismember([0;Users{n}.LogbookSmart(1:end-1,1)],3:5)), find(ismember(Users{n}.LogbookSmart(1:end,1),3:5) & ~ismember([Users{n}.LogbookSmart(2:end,1);0],3:5))];
    ChargingBlocks=any(AvailableBlocks(:,1)'<=find(Users{n}.LogbookSmart(1:end,1)==5) & AvailableBlocks(:,2)'>=find(Users{n}.LogbookSmart(1:end,1)==5))';
    for k=find(ChargingBlocks)'
        Users{n}.LogbookSmart(AvailableBlocks(k,1)-1:AvailableBlocks(k,2)-1,1)=4;
    end
    Users{n}.LogbookSmart(any(Users{n}.LogbookSmart(:,5:7)>0,2),1)=5;
end





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
