CostN14NPV=[];
Cost14NPV=[];
CostN14PV=[];
Cost14PV=[];
CostN14NPV50=[];
Cost14NPV50=[];
CostN14PV50=[];
Cost14PV50=[];
for n=2:1001
    if ~Users{n}.PVPlantExists && ~Users{n}.GridConvenientCharging
        CostN14NPV(end+1,1)=n;
        CostN14NPV(end,2:5)=sum(Users{n}.Logbook(:,5:8),1)/Users{n}.ChargingEfficiency;
        CostN14NPV(end,6)=sum(CostN14NPV(end,2:5));
        CostN14NPV(end,7:10)=sum(Users{n}.FinListSmart(:,:),1)/100;
        CostN14NPV(end,11)=sum(CostN14NPV(end,7:10))+Users{n}.NNEExtraBasePrice/100;
        %CostN14NPV(end,11)=sum(CostN14NPV(end,7:10));
        CostN14NPV(end,12)=Users{n}.NNEEnergyPrice;
    elseif ~Users{n}.PVPlantExists && Users{n}.GridConvenientCharging
        Cost14NPV(end+1,1)=n;
        Cost14NPV(end,2:5)=sum(Users{n}.Logbook(:,5:8),1)/Users{n}.ChargingEfficiency;
        Cost14NPV(end,6)=sum(Cost14NPV(end,2:5));
        Cost14NPV(end,7:10)=sum(Users{n}.FinListSmart(:,:),1)/100;
        Cost14NPV(end,11)=sum(Cost14NPV(end,7:10))+Users{n}.NNEExtraBasePrice/100;
        %Cost14NPV(end,11)=sum(Cost14NPV(end,7:10));
        Cost14NPV(end,12)=Users{n}.NNEEnergyPrice;
        
        Cost14NPV50(end+1,1)=n;
        Cost14NPV50(end,2:5)=sum(Smart50{n}.Logbook(:,5:8),1)/Smart50{n}.ChargingEfficiency;
        Cost14NPV50(end,6)=sum(Cost14NPV50(end,2:5));
        Cost14NPV50(end,7:10)=sum(Smart50{n}.FinListSmart(:,:),1)/100;
        Cost14NPV50(end,11)=sum(Cost14NPV50(end,7:10))+Users{n}.NNEExtraBasePrice/100;
        %Cost14NPV(end,11)=sum(Cost14NPV(end,7:10));
        Cost14NPV50(end,12)=Smart50{n}.NNEEnergyPrice;
    elseif Users{n}.PVPlantExists && ~Users{n}.GridConvenientCharging
        CostN14PV(end+1,1)=n;
        CostN14PV(end,2:5)=sum(Users{n}.Logbook(:,5:8),1)/Users{n}.ChargingEfficiency;
        CostN14PV(end,6)=sum(CostN14PV(end,2:5));
        CostN14PV(end,7:10)=sum(Users{n}.FinListSmart(:,:),1)/100;
        CostN14PV(end,11)=sum(CostN14PV(end,7:10))+Users{n}.NNEExtraBasePrice/100;
        %CostN14PV(end,11)=sum(CostN14PV(end,7:10));
        CostN14PV(end,12)=Users{n}.NNEEnergyPrice;
    elseif Users{n}.PVPlantExists && Users{n}.GridConvenientCharging
        Cost14PV(end+1,1)=n;
        Cost14PV(end,2:5)=sum(Users{n}.Logbook(:,5:8),1)/Users{n}.ChargingEfficiency;
        Cost14PV(end,6)=sum(Cost14PV(end,2:5));
        Cost14PV(end,7:10)=sum(Users{n}.FinListSmart(:,:),1)/100;
        Cost14PV(end,11)=sum(Cost14PV(end,7:10))+Users{n}.NNEExtraBasePrice/100;
        %Cost14PV(end,11)=sum(Cost14PV(end,7:10));
        Cost14PV(end,12)=Users{n}.NNEEnergyPrice;
        Cost14PV(end,13)=sum(PVPlants{Users{n}.PVPlant}.ProfileQH(end-366*24*4:end-96));
        
        Cost14PV50(end+1,1)=n;
        Cost14PV50(end,2:5)=sum(Smart50{n}.Logbook(:,5:8),1)/Smart50{n}.ChargingEfficiency;
        Cost14PV50(end,6)=sum(Cost14PV50(end,2:5));
        Cost14PV50(end,7:10)=sum(Smart50{n}.FinListSmart(:,:),1)/100;
        Cost14PV50(end,11)=sum(Cost14PV50(end,7:10))+Users{n}.NNEExtraBasePrice/100;
        %Cost14NPV(end,11)=sum(Cost14NPV(end,7:10));
        Cost14PV50(end,12)=Smart50{n}.NNEEnergyPrice;
    end
end














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
