%%
clearvars -except DayaheadRealQH ResEnPricesRealQH ResPoDemRealQH ResPoPricesReal4H Time.Vec Users PVPlants VehiclesTemp
Vehicles=800;
Periods=length(Time.Vec);
ControlPeriods=96*1.5;


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
    MaxPower(1,n)=double(UsersT{n}.ACChargingPowerHomeCharging);
end

options=optimset('linprog');
options.Display = 'off';


%%
Availability=[];
EnergyDemand=[];
ChargingMat=[];
ChargingReal=[];
for k=1:Periods/96-1
    for n=1:Vehicles
        Availability(:,n)=ismember(UsersT{n}.LogbookBase((k-1)*96+1:(k-1)*96+ControlPeriods,1), 4:5);
        EnergyDemand(1,n)=double(UsersT{n}.BatterySize-UsersT{n}.LogbookBase((k-1)*96+ControlPeriods,7));
        if UsersT{n}.PVPlantExists==true
            Costs(:,n)=(min(double(PVPlants{UsersT{n}.PVPointer}.Profile((k-1)*96+1:(k-1)*96+ControlPeriods)), MaxPower(1,n))*0.097 + (MaxPower(1,n)-min(double(PVPlants{UsersT{n}.PVPointer}.Profile((k-1)*96+1:(k-1)*96+ControlPeriods)), MaxPower(1,n))).*(0.27+DayaheadRealQH((k-1)*96+1:(k-1)*96+ControlPeriods)/1000))/(MaxPower(1,n));
        else
            Costs(:,n)=0.27+DayaheadRealQH((k-1)*96+1:(k-1)*96+ControlPeriods)/1000;
        end
    end
        
    P=optimvar('P', ControlPeriods, Vehicles, 'LowerBound', zeros(ControlPeriods, Vehicles), 'UpperBound', MaxPower/4.*ones(ControlPeriods, Vehicles));
    AvailabilityCons=P(Availability == 0) == 0;
    EnergyCons=ones(1,ControlPeriods)*P == min(EnergyDemand, sum(Availability, 1).*MaxPower/4);
    
    CostFunction=ones(1,ControlPeriods)*(Costs.*P*ones(Vehicles,1));

    OptProb=optimproblem('ObjectiveSense', 'minimize');
    OptProb.Objective=CostFunction;
    OptProb.Constraints.EnergyCons=EnergyCons;
    OptProb.Constraints.AvailabilityCons=AvailabilityCons;

    [P_opt,Cost_opt,exitflag,output] = solve(OptProb, 'Options', options);
    
    ChargingMat(:,:,k)=P_opt.P;
    ChargingReal=[ChargingReal; ChargingMat(1:96,:,k)];
    
end
ChargingSum=sum(ChargingReal, 2);
toc






% 
% 
% 
% %%
% Periods=96*1.5;
% Vehicles=10000;
% Costs=TruncatedGaussian(5, [25,60]-38,Periods,1)+38;
% MaxPower=TruncatedGaussian(2, [3,11]-7,1,Vehicles)+7;
% EnergyDemand=MaxPower.*(TruncatedGaussian(0.1, [1.2 1.9]-1.5,1,Vehicles)+1.5);
% Availability=ones(Periods, Vehicles);
% for n=1:Vehicles
%     Availability(randi([1,Periods],randi([1,6],1,1),1), n)=0;
% end
% 
% 










%%

Periods=2;
Vehicles=3;
Costs=[30; 40];
MaxPower=[3,6, 7];
EnergyDemand=[4,8, 10];

P=optimvar('P', Periods, Vehicles, 'LowerBound', zeros(Periods, Vehicles), 'UpperBound', MaxPower.*ones(Periods, Vehicles));
EnergyCons=ones(1,Periods)*P == EnergyDemand;

CostFunction=Costs'*P*ones(Vehicles,1);

OptProb=optimproblem('ObjectiveSense', 'minimize');
OptProb.Objective=CostFunction;
OptProb.Constraints.EnergyCons=EnergyCons;

[P_opt,Cost_opt,exitflag,output] = solve(OptProb);

%working
