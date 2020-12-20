ConsumptionMat=[];
VarCounter=1;
for k=UserNum
    ConsumptionMat(:,VarCounter)=Users{k}.Logbook(TimeInd+TD.User:TimeInd+TD.User+ControlPeriodsIt-1,4);
    VarCounter=VarCounter+1;
end
ConsumptionMat=sum(cumsum(reshape(ConsumptionMat,4,[],NumUsers),1),1);

HourlySpotmarketPowers=reshape(squeeze(OptimalChargingEnergies(:,1,:)), Time.StepInd, [], NumUsers);
HourlyPowerAvailability=reshape(MaxPower/4.*Availability-sum(OptimalChargingEnergies(:,2:NumCostCats,:),2), 4, [], NumUsers) .* (ConsumptionMat==0);
HourlyPowerAvailability(abs(HourlyPowerAvailability)<1e-3)=0;
OptimalChargingEnergiesSpotmarket=HourlyPowerAvailability./sum(HourlyPowerAvailability,1).*sum(HourlySpotmarketPowers,1); 
OptimalChargingEnergiesSpotmarket(isnan(OptimalChargingEnergiesSpotmarket))=0;
OptimalChargingEnergiesSpotmarket=reshape(OptimalChargingEnergiesSpotmarket + HourlySpotmarketPowers.*(ConsumptionMat>0), ControlPeriodsIt, 1, NumUsers);

%% Easy expample at first PreAlgo loop
% a=reshape(squeeze(OptimalChargingEnergies(:,1,166)), 4, []);
% b=reshape(MaxPower(166)/4.*Availability(:,1,166)-sum(OptimalChargingEnergies(:,2:3,166),2), 4, []);
% e=sum(a,1);
% f=b./sum(b,1).*e;
% f(isnan(f))=0;
