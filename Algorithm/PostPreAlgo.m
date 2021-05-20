%% Description
% This script reallocates the demand from the spotmarket. In case of equal
% costs at different time steps, the linprog function allocates all of the 
% energy to the last time step. This is not a big issue but as the costs
% during one hour are constant because of the usage of the day ahead
% spotmarket prices, the algorithm allocates most of the energy to the
% least quarter hours which looks awful in the load profiles and does not
% make any sense technically. Hence this function reallocates the
% spotmarket demand in order to smoothen the demand during one hour.
%
% Depended scripts / folders
%   Initialisation          Needed for the execution of this script
%   PreAlgo                 This script is called by PreAlgo.m

ConsumptionMat=sum(cumsum(reshape(squeeze(Logbooks4),4,[],NumUsers),1),1);

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
