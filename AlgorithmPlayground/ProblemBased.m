%%
clearvars -except DayaheadReal1QH ResEnPricesRealQH ResPoDemRealQH OfferLists ResPoPricesReal4H TimeVec Users PVPlants VehiclesTemp
Vehicles=10;
Periods=length(TimeVec);
ControlPeriods=96*1.5;
ElectricityBasePrice=0.222;
CostCats=3;

if ~exist("Users", "var")
    load('C:\Users\nicop\MATLAB\SmartCharging\Simulation\Users_1.2_800_2020-09-17_17-06.mat');
end
UsersT=Users(2:Vehicles+1);
for n=1:Vehicles
    if mod(n,2)==1
        UsersT{n}.PVPlantExists=true;
        UsersT{n}.PVPointer=mod(n-1, 482)+1;
    else
        UsersT{n}.PVPlantExists=false;
    end
end

VehiclesTemp=Vehicles;

MaxPower=[];
for n=1:Vehicles
    MaxPower(1,1,n)=double(UsersT{n}.ACChargingPowerHomeCharging);
end




%%
options=optimset('linprog');
options.Display = 'off';

tic
Availability=[];
EnergyDemand=[];
ChargingMat=[];
ChargingVehicle=[];
ChargingType=[];
PVPowerSum=[];
for k=1:Periods/96-1
    CalcOptVars;
%     Costs(:,3,:)=100000;
        
%     PowerCons=[ones(ControlPeriods, 1, Vehicles).*MaxPower/4, PVPower/4, ones(ControlPeriods, 1, Vehicles).*MaxPower/4].*Availability;
%     P=optimvar('P', ControlPeriods, CostCats, Vehicles, 'LowerBound', zeros(ControlPeriods, CostCats, Vehicles), 'UpperBound', PowerCons);
    P=optimvar('P', ControlPeriods, CostCats, Vehicles, 'LowerBound', zeros(ControlPeriods, CostCats, Vehicles), 'UpperBound', MaxPower/4.*ones(ControlPeriods, CostCats, Vehicles));
    SumPowerCons=sum(P,2)<=ones(ControlPeriods,1,Vehicles).*MaxPower/4;
    PowerCons=P(:,1:3,:)<=[ones(ControlPeriods, 1, Vehicles).*MaxPower/4, PVPower/4, ones(ControlPeriods, 1, Vehicles).*MaxPower/4].*Availability;
    EnergyCons=sum(sum(P,2),1) == min(EnergyDemand, sum(Availability, 1).*MaxPower/4);
    
    

% 	RLOffer=reshape(sum(P(:,3,:),3),16,ControlPeriods/16); % find minimum offered reserve capacity in each 4h Zeitscheibe. this minimum power is the power offer to the TSO. Emuneration of power capacity according to this power
%     RLOffer=reshape(repelem(min(RLOffer,[],1),16),ControlPeriods,1);
    
%     RLOffer=(reshape(sum(P(:,3,:),3),16,[]));
%     RLOfferCons=RLOffer(1,:)-RLOffer(2,:)-RLOffer(3,:)-RLOffer(4,:)-RLOffer(5,:)-RLOffer(6,:)-RLOffer(7,:), RLOffer(8,:), RLOffer(9,:), RLOffer(10,:), RLOffer(11,:), RLOffer(12,:), RLOffer(13,:), RLOffer(14,:), RLOffer(15,:), RLOffer(16,:))==1;

%     
% 	RLEarnings=RLEarnings.*RLOfferPrices;
    CostFunction=sum(sum(sum(Costs.*P)));

    OptProb=optimproblem('ObjectiveSense', 'minimize');
    OptProb.Objective=CostFunction;
    OptProb.Constraints.EnergyCons=EnergyCons;
    OptProb.Constraints.PowerCons=PowerCons;
    OptProb.Constraints.SumPowerCons=SumPowerCons;
    OptProb.Constraints.RLOfferCons=RLOfferCons;

    [P_opt,Cost_opt,exitflag,output] = solve(OptProb, 'Options', options);
    
    ChargingMat(:,:,:,k)=P_opt.P;
    ChargingVehicle=[ChargingVehicle; sum(ChargingMat(1:96,:,:,k),2)];
    ChargingType=[ChargingType; sum(ChargingMat(1:96,:,:,k),3)];
    
    PVPowerSum=[PVPowerSum; sum(PVPower(1:96,1,:),3)];
    
    if sum(P_opt.P>0 & Availability==0)>1
        error("Availability was not considered")
    end
    
end
ChargingSum=sum(ChargingVehicle, 3);
[sum(ChargingType(:,1,:),'all'), sum(ChargingType(:,2,:),'all'), sum(ChargingType(:,3,:),'all')]/sum(ChargingType(:,:,:),'all')
toc

% Load=mean(reshape(ChargingType',3,96,[]),3)';
% x = 1:96;
% y = mean(reshape(ChargingSum, 96, []), 2)';
% z = zeros(size(x));
% col = (Load./repmat(max(Load, [], 2),1,3))';
% surface([x;x],[y;y],[z;z],[permute(repmat(col,1,1,2),[3,2,1])], 'facecol','no', 'edgecol','interp', 'linew',2);

