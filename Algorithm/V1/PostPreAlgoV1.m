HourlySpotmarketPowers=sum(reshape(squeeze(OptimalChargingEnergies(:,1,:)), Time.StepInd, [], NumUsers),1);
HourlyPowerAvailability=reshape(MaxPower/4.*Availability-sum(OptimalChargingEnergies(:,2:3,:),2), 4, [], NumUsers);
OptimalChargingEnergiesSpotmarket=reshape(HourlyPowerAvailability./sum(HourlyPowerAvailability,1).*HourlySpotmarketPowers, ControlPeriods, 1, NumUsers);
OptimalChargingEnergiesSpotmarket(isnan(OptimalChargingEnergiesSpotmarket))=0;

%% Easy expample at first PreAlgo loop
% a=reshape(squeeze(OptimalChargingEnergies(:,1,166)), 4, []);
% b=reshape(MaxPower(166)/4.*Availability(:,1,166)-sum(OptimalChargingEnergies(:,2:3,166),2), 4, []);
% e=sum(a,1);
% f=b./sum(b,1).*e;
% f(isnan(f))=0;
