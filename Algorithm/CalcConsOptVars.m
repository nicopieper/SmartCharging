%% Description
% This script updates the variables needed to solve the optimisation
% problem for algorithm 1 (PreAlgo). Only variables that change once per
% day at 8:00 are calculated in this script. Variables that each
% optimisation are updated in CalcDynOptVars.
%
% Depended scripts / folders
%   Initialisation          Needed for the execution of this script
%   Simulation              This script is called by Simulation.m
%   PreAlgo                 This script is necessary for PreAlgo.m

%% Reserve market offers

% a negative price means that the offerer pays money for getting the energy

ResPoOffers(:,1,PreAlgoCounter+1)=repelem(ResPoPricesReal4H(floor((TimeInd+TD.Main)/(4*Time.StepInd))+1-hour(TimeOfPreAlgo(1))/4:floor((TimeInd+TD.Main)/(4*Time.StepInd))+1-hour(TimeOfPreAlgo(1))/4+5,3)/1000*ResPoPriceFactor, ConstantResPoPowerPeriodsScaling); % [EUR/kW] The offered reserve price for the next day. Get the marginal prices of yesterdays auctions (for the fulfillment today, as the autions were yesterday, the prices are already available) and reduce it by a fixed factor to enhance the probability of a successful offer.
ResPoOfferPrices=[ResPoOffers(hour(TimeOfPreAlgo(1))/4*ConstantResPoPowerPeriodsScaling+1:6*ConstantResPoPowerPeriodsScaling,1,PreAlgoCounter); ResPoOffers(1:6*ConstantResPoPowerPeriodsScaling,1,PreAlgoCounter+1)];
ResPoOfferPrices=repelem([ResPoOfferPrices; ResPoOffers(1:ControlPeriods/(4*Time.StepInd/ConstantResPoPowerPeriodsScaling)-length(ResPoOfferPrices),1,PreAlgoCounter+1)], 4*Time.StepInd/ConstantResPoPowerPeriodsScaling); % [EUR/kW]
%ResPoOfferPrices(isnan(ResPoOfferPrices))=-10000;

ResEnOffers(:,1,PreAlgoCounter+1)=ResEnPricesRealQH(TimeInd+TD.Main-hour(TimeOfPreAlgo(1))*4-96:ConstantResPoPowerPeriods:TimeInd+TD.Main-hour(TimeOfPreAlgo(1))*4-96-1+96,7)/1000; % [EUR/kWh] Similiar here but we can not use the prices for today as we do not know which reserve energy offers will be successful. Hence use the marginal price of the successfull reserve energy offers of yesterday. Substract a margin and use it for the offer
ResEnOffers(:,1,PreAlgoCounter+1)=ResEnOffers(:,1,PreAlgoCounter+1)-ResEnPriceFactor*abs(ResEnOffers(:,1,PreAlgoCounter+1)); 
ResEnOfferPrices=[ResEnOffers(hour(TimeOfPreAlgo(1))/4*ConstantResPoPowerPeriodsScaling+1:6*ConstantResPoPowerPeriodsScaling,1,PreAlgoCounter); ResEnOffers(1:6*ConstantResPoPowerPeriodsScaling,1,PreAlgoCounter+1)];
ResEnOfferPrices=repelem([ResEnOfferPrices; ResEnOffers(1:ControlPeriods/(4*Time.StepInd/ConstantResPoPowerPeriodsScaling)-length(ResEnOfferPrices),1,PreAlgoCounter+1)], 4*Time.StepInd/ConstantResPoPowerPeriodsScaling); % [EUR/kW]
%ResEnOfferPrices(isnan(ResEnOfferPrices))=-10000;

    
%% Available PV power

PVPower=zeros(ControlPeriodsIt, 1,NumUsers);
PVPowerReal=zeros(ControlPeriodsIt, 1,NumUsers);
VarCounter=0;
for k=UserNum
    VarCounter=VarCounter+1;    
    if Users{k}.PVPlantExists==true
        PVPower(:,1,VarCounter)=double(PVPlants{Users{k}.PVPlant}.(PVPlants_Profile_Prediction)(TimeInd+TD.Main:TimeInd+TD.Main-1+ControlPeriodsIt))*Users{n}.ChargingEfficiency;
        PVPowerReal(:,1,VarCounter)=double(PVPlants{Users{k}.PVPlant}.ProfileQH(TimeInd+TD.Main:TimeInd+TD.Main-1+ControlPeriodsIt))*Users{n}.ChargingEfficiency;
    end
end