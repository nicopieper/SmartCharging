%%
clearvars -except DayaheadRealQH ResEnPricesRealQH ResPoDemRealQH ResPoPricesReal4H Time.Vec UsersT PVPlants
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

MaxPower=[];
for n=1:Vehicles
    MaxPower(1,n)=double(UsersT{n}.ACChargingPowerHomeCharging);
end

%%
tic
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
    
    CostVehicleMatV=Costs;
    CostVehicleMatT=Costs;
    CostVehicleMatV(Availability==0)=Inf;
    CostVehicleMatT(Availability==0)=-Inf;
    [CostVehicleMatV, CostVehicleMatIndV]=sort(CostVehicleMatV, 1);

    PTimes=min(EnergyDemand./(MaxPower/4), sum(Availability,1));
    PMat=zeros(ControlPeriods, Vehicles);
    for n=find(PTimes)
        PMat(1:floor(PTimes(1,n)),n)=MaxPower(1,n)/4;
        PMat(ceil(PTimes(1,n)),n)=MaxPower(1,n)*(PTimes(1,n)-floor(PTimes(1,n)))/4;
    end

    for n=1:Vehicles
        PMat(CostVehicleMatIndV(:,n),n)=PMat(:,n);
    end
    
    
    RegelList=CostVehicleMatT>=-ResEnPricesRealQH((k-1)*96+1:(k-1)*96+ControlPeriods,3)/100;
        


%     [CostVehicleMatT, CostVehicleMatIndT]=sort(CostVehicleMatT, 2, 'descend');
    
    
    
    ChargingMat(:,:,k)=PMat;
    ChargingReal=[ChargingReal; ChargingMat(1:96,:,k)];
   
end
ChargingSum=sum(ChargingReal, 2);


toc


% Costs=TruncatedGaussian(5, [25,60]-38,Periods,1)+38;
% MaxPower=TruncatedGaussian(2, [3,11]-7,1,Vehicles)+7;
% EnergyDemand=MaxPower.*(TruncatedGaussian(0.1, [1.2 1.9]-1.5,1,Vehicles)+1.5);

% Availability=ones(Periods, Vehicles);
% for n=1:Vehicles
%     Availability(randi([1,Periods],randi([1,6],1,1),1), n)=0;
% end
% EnergyDemand=MaxPower.*(TruncatedGaussian(0.1, [1.2 1.9]-1.5,1,Vehicles)+1.5);