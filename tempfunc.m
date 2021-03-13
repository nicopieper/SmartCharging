% Batteries=[];
% 
% for n=2:20001
%     Batteries(n-1,1)=enwg{n}.BatterySize;
% end
% 
% Batteries=unique(Batteries);
% BatteriesC=num2cell(Batteries);
% BatteriesC(:,2:5)=cell(length(Batteries),4);
% 
% for n=2:20001
%     ind=find(Batteries==enwg{n}.BatterySize);
%     BatteriesC{ind,2}(end+1,1)=sum(enwg{n}.FinListSmart, 'all')+enwg{n}.NNEExtraBasePrice;
%     BatteriesC{ind,2}(end,2)=sum(enwg{n}.Logbook(:, 5:8), 'all');
%     BatteriesC{ind,2}(end,3)=n;
% end
% 
% 
% for n=1:length(Batteries)
%     BatteriesC{n,3}=mean(BatteriesC{n,2}(:,1));
%     BatteriesC{n,4}=mean(BatteriesC{n,2}(:,2));
%     BatteriesC{n,5}=sum(BatteriesC{n,2}(:,1))/sum(BatteriesC{n,2}(:,2))*1000;
% end
% 







CostN14NPVenwg=[];
Cost14NPVenwg=[];
CostN14PVenwg=[];
Cost14PVenwg=[];
CostN14NPVenwgh=[];
Cost14NPVenwgh=[];
CostN14PVenwgh=[];
Cost14PVenwgh=[];
for n=2:1001
    
    if ~enwg{n}.PVPlantExists && ~enwg{n}.GridConvenientCharging
        CostN14NPVenwg(end+1,1)=n;
        CostN14NPVenwg(end,2:5)=sum(enwg{n}.Logbook(:,5:8),1)/enwg{n}.ChargingEfficiency;
        CostN14NPVenwg(end,6)=sum(CostN14NPVenwg(end,2:5));
        CostN14NPVenwg(end,7:10)=sum(enwg{n}.FinListSmart(:,:),1)/100;
        CostN14NPVenwg(end,11)=sum(CostN14NPVenwg(end,7:10))+enwg{n}.NNEExtraBasePrice/100;
        %CostN14NPVenwg(end,11)=sum(CostN14NPVenwg(end,7:10));
        CostN14NPVenwg(end,12)=enwg{n}.NNEEnergyPrice;
    elseif ~enwg{n}.PVPlantExists && enwg{n}.GridConvenientCharging
        Cost14NPVenwg(end+1,1)=n;
        Cost14NPVenwg(end,2:5)=sum(enwg{n}.Logbook(:,5:8),1)/enwg{n}.ChargingEfficiency;
        Cost14NPVenwg(end,6)=sum(Cost14NPVenwg(end,2:5));
        Cost14NPVenwg(end,7:10)=sum(enwg{n}.FinListSmart(:,:),1)/100;
        Cost14NPVenwg(end,11)=sum(Cost14NPVenwg(end,7:10))+enwg{n}.NNEExtraBasePrice/100;
        %Cost14NPVenwg(end,11)=sum(Cost14NPVenwg(end,7:10));
        Cost14NPVenwg(end,12)=enwg{n}.NNEEnergyPrice;
    elseif enwg{n}.PVPlantExists && ~enwg{n}.GridConvenientCharging
        CostN14PVenwg(end+1,1)=n;
        CostN14PVenwg(end,2:5)=sum(enwg{n}.Logbook(:,5:8),1)/enwg{n}.ChargingEfficiency;
        CostN14PVenwg(end,6)=sum(CostN14PVenwg(end,2:5));
        CostN14PVenwg(end,7:10)=sum(enwg{n}.FinListSmart(:,:),1)/100;
        CostN14PVenwg(end,11)=sum(CostN14PVenwg(end,7:10))+enwg{n}.NNEExtraBasePrice/100;
        %CostN14PVenwg(end,11)=sum(CostN14PVenwg(end,7:10));
        CostN14PVenwg(end,12)=enwg{n}.NNEEnergyPrice;
    elseif enwg{n}.PVPlantExists && enwg{n}.GridConvenientCharging
        Cost14PVenwg(end+1,1)=n;
        Cost14PVenwg(end,2:5)=sum(enwg{n}.Logbook(:,5:8),1)/enwg{n}.ChargingEfficiency;
        Cost14PVenwg(end,6)=sum(Cost14PVenwg(end,2:5));
        Cost14PVenwg(end,7:10)=sum(enwg{n}.FinListSmart(:,:),1)/100;
        Cost14PVenwg(end,11)=sum(Cost14PVenwg(end,7:10))+enwg{n}.NNEExtraBasePrice/100;
        %Cost14PVenwg(end,11)=sum(Cost14PVenwg(end,7:10));
        Cost14PVenwg(end,12)=enwg{n}.NNEEnergyPrice;
        Cost14PVenwg(end,13)=PVPlants{enwg{n}.PVPlant}.PeakPower;
        Cost14PVenwg(end,14)=sum(PVPlants{enwg{n}.PVPlant}.ProfileQH);
        Cost14PVenwg(end,15)=enwg{n}.ConsumptionPrivateYear_kWh;
        Cost14PVenwg(end,16)=sum(enwg{n}.Logbook(:,6))/sum(enwg{n}.Logbook(:,5:7), 'all');
    end
    
    if ~enwgh{n}.PVPlantExists && ~enwgh{n}.GridConvenientCharging
        CostN14NPVenwgh(end+1,1)=n;
        CostN14NPVenwgh(end,2:5)=sum(enwgh{n}.Logbook(:,5:8),1)/enwgh{n}.ChargingEfficiency;
        CostN14NPVenwgh(end,6)=sum(CostN14NPVenwgh(end,2:5));
        CostN14NPVenwgh(end,7:10)=sum(enwgh{n}.FinListSmart(:,:),1)/100;
        CostN14NPVenwgh(end,11)=sum(CostN14NPVenwgh(end,7:10))+enwgh{n}.NNEExtraBasePrice/100;
        %CostN14NPVenwg(end,11)=sum(CostN14NPVenwg(end,7:10));
        CostN14NPVenwgh(end,12)=enwgh{n}.NNEEnergyPrice;
    elseif ~enwgh{n}.PVPlantExists && enwgh{n}.GridConvenientCharging
        Cost14NPVenwgh(end+1,1)=n;
        Cost14NPVenwgh(end,2:5)=sum(enwgh{n}.Logbook(:,5:8),1)/enwgh{n}.ChargingEfficiency;
        Cost14NPVenwgh(end,6)=sum(Cost14NPVenwgh(end,2:5));
        Cost14NPVenwgh(end,7:10)=sum(enwgh{n}.FinListSmart(:,:),1)/100;
        Cost14NPVenwgh(end,11)=sum(Cost14NPVenwgh(end,7:10))+enwgh{n}.NNEExtraBasePrice/100;
        %Cost14NPVenwg(end,11)=sum(Cost14NPVenwg(end,7:10));
        Cost14NPVenwgh(end,12)=enwgh{n}.NNEEnergyPrice;
    elseif enwgh{n}.PVPlantExists && ~enwgh{n}.GridConvenientCharging
        CostN14PVenwgh(end+1,1)=n;
        CostN14PVenwgh(end,2:5)=sum(enwgh{n}.Logbook(:,5:8),1)/enwgh{n}.ChargingEfficiency;
        CostN14PVenwgh(end,6)=sum(CostN14PVenwgh(end,2:5));
        CostN14PVenwgh(end,7:10)=sum(enwgh{n}.FinListSmart(:,:),1)/100;
        CostN14PVenwgh(end,11)=sum(CostN14PVenwgh(end,7:10))+enwgh{n}.NNEExtraBasePrice/100;
        %CostN14PVenwg(end,11)=sum(CostN14PVenwg(end,7:10));
        CostN14PVenwgh(end,12)=enwgh{n}.NNEEnergyPrice;
    elseif enwgh{n}.PVPlantExists && enwgh{n}.GridConvenientCharging
        Cost14PVenwgh(end+1,1)=n;
        Cost14PVenwgh(end,2:5)=sum(enwgh{n}.Logbook(:,5:8),1)/enwgh{n}.ChargingEfficiency;
        Cost14PVenwgh(end,6)=sum(Cost14PVenwgh(end,2:5));
        Cost14PVenwgh(end,7:10)=sum(enwgh{n}.FinListSmart(:,:),1)/100;
        Cost14PVenwgh(end,11)=sum(Cost14PVenwgh(end,7:10))+enwgh{n}.NNEExtraBasePrice/100;
        %Cost14PVenwg(end,11)=sum(Cost14PVenwg(end,7:10));
        Cost14PVenwgh(end,12)=enwgh{n}.NNEEnergyPrice;
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
% for n=enwg{1}.UserNum
%     VarCounter=VarCounter+1;
%     Availability(:,1,VarCounter)=max(0, ismember(double(enwg{n}.Logbook(:,1)), 3:5) - double(enwg{n}.Logbook(:,2))/Time.StepMin) .* repmat(double(enwg{n}.GridConvenientChargingAvailability), length(enwg{n}.Logbook(:,1))/96,1);
% end
% AvailabilityMat=reshape(Availability, 96, [], Numenwg);
% figure
% plot(mean(mean(AvailabilityMat,3),2))



% Debugging=1;
% NumDecissionGroups=1;
% UseParallel=0;
% x111=[];
% Numenwg=1;
% for y=1001:10000
%     UserNum=y:y+Numenwg-1;
%     InitialisePreAlgo;
%     CalcConsOptVars;
%     CalcDynOptVars;
%     PreAlgo;
%     x111=[x111;x];
% end
    


% lob=1;
% upb=length(enwg)-1;
% 
% while abs(lob-upb)>1
%     Numenwg=ceil((upb+lob)/2);
%     UserNum=2:Numenwg+1;
%     try
%         InitialisePreAlgo;
%         CalcConsOptVars;
%         CalcDynOptVars;
%         PreAlgo;
%         lob=Numenwg;
%     catch
%         upb=Numenwg;
%     end
% end
% UserNum=Numenwg;
% Numenwg=1;
