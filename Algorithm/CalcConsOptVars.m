% a negative price means that the offerer pays money for getting the energy

ResPoOffers(:,1,PreAlgoCounter+1)=ResPoPricesReal4H(floor((TimeInd+TD.Main)/(4*Time.StepInd))+1-hour(TimeOfPreAlgo(1))/4:floor((TimeInd+TD.Main)/(4*Time.StepInd))+1-hour(TimeOfPreAlgo(1))/4+5,3)/1000*ResPoPriceFactor; % [€/kW] The offered reserve price for the next day. Get the marginal prices of yesterdays auctions (for the fulfillment today, as the autions were yesterday, the prices are already available) and reduce it by a fixed factor to enhance the probability of a successful offer.
ResPoOfferPrices=[ResPoOffers(hour(TimeOfPreAlgo(1))/4+1:6,1,PreAlgoCounter); ResPoOffers(1:6,1,PreAlgoCounter+1)];
ResPoOfferPrices=repelem([ResPoOfferPrices; ResPoOffers(1:ControlPeriods/(4*Time.StepInd)-length(ResPoOfferPrices),1,PreAlgoCounter+1)], 4*Time.StepInd); % [€/kW]
%ResPoOfferPrices(isnan(ResPoOfferPrices))=-10000;

ResEnOffers(:,1,PreAlgoCounter+1)=ResEnPricesRealQH(TimeInd+TD.Main-hour(TimeOfPreAlgo(1))*4-96:16:TimeInd+TD.Main-hour(TimeOfPreAlgo(1))*4-96-1+96,7)/1000; % [€/kWh] Similiar here but we can not use the prices for today as we do not know which reserve energy offers will be successful. Hence use the marginal price of the sucessfull reserve energy offers of yesterday. Substract a margin and use it for the offer
ResEnOffers(:,1,PreAlgoCounter+1)=ResEnOffers(:,1,PreAlgoCounter+1)-ResEnPriceFactor*abs(ResEnOffers(:,1,PreAlgoCounter+1)); 
ResEnOfferPrices=[ResEnOffers(hour(TimeOfPreAlgo(1))/4+1:6,1,PreAlgoCounter); ResEnOffers(1:6,1,PreAlgoCounter+1)];
ResEnOfferPrices=repelem([ResEnOfferPrices; ResEnOffers(1:ControlPeriods/(4*Time.StepInd)-length(ResEnOfferPrices),1,PreAlgoCounter+1)], 4*Time.StepInd); % [€/kW]
%ResEnOfferPrices(isnan(ResEnOfferPrices))=-10000;


%RLOfferPrices=repelem(ResPoPricesReal4H(floor((TimeInd+TD.Main)/(4*Time.StepInd))+1:floor((TimeInd+TD.Main)/(4*Time.StepInd))+ControlPeriods/(4*Time.StepInd),3)/1000,4*Time.StepInd); % [€/kW]
%RLOfferPrices=RLOfferPrices(1:ControlPeriods);
%AEOfferPrices=(ResEnPricesRealQH(TimeInd+TD.Main:TimeInd+TD.Main-1+ControlPeriods,7)-AEFactor*abs(ResEnPricesRealQH(TimeInd+TD.Main:TimeInd+TD.Main-1+ControlPeriods,7)))/1000; % [€/kWh]

CostsPV=ones(ControlPeriods, 1, NumUsers)*(Users{1}.PVEEGBonus/100); % 0.097€
PVPower=zeros(ControlPeriods, 1,NumUsers);
VarCounter=0;
for k=UserNum
    VarCounter=VarCounter+1;
    
    if Users{k}.PVPlantExists==true
        PVPower(:,1,VarCounter)=double(PVPlants{Users{k}.PVPlant}.(PVPlants_Profile_Prediction)(TimeInd+TD.Main:TimeInd+TD.Main-1+ControlPeriods))*Users{n}.ChargingEfficiency;
    else
        CostsPV(:,1,VarCounter)=10000*ones(ControlPeriods,1); % Ensure never use PVPlant if there is non. Also ensured by PowerCons as PVPower is constantly zero
    end
end

CostsPV=CostsPV+((1:ControlPeriodsIt)'-ControlPeriodsIt/2)*0.00001; % Prefer early PV charging over late charging --> The price for charging early is lower than for charging later