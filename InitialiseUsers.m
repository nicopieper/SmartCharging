NumUsers=2000;
LikelihoodChargingDay=4.1/7;
StdwChargingDay=2/7;
LikelihoodPV=0.45; % 44 % der privaten und 46 % der gewerblichen Nutzer über eine eigene Photovoltaikanlage, https://elib.dlr.de/96491/1/Ergebnisbericht_E-Nutzer_2015.pdf S. 10

Users=cell(NumUsers,1);
PVPlantPointer=1;
VehicleSizes=["small", "medium", "large", "transporter"];
VehiclePointer=zeros(length(VehicleSizes),1);

if ~exist('Vehicles', 'var')
    GetVehicleData;
    VehicleDatabase=cell(length(VehicleSizes),1);
    for n=1:length(Vehicles)
        SizeNum=find(Vehicles{n}.VehicleSize==VehicleSizes,1);
        if ~isempty(SizeNum)
            VehicleDatabase{SizeNum}=[VehicleDatabase{SizeNum}; n];
        end
    end
end
if ~exist('SessionsPerDay', 'var')
    GetELaadData;
end

for n=1:NumUsers
    a=rand(4,1);
    Model=max((a(1)>=str2double(VehicleProperties(:,2))).*(1:size(VehicleProperties,1))');
    Users{n}.ModelName=VehicleProperties(Model, 1);
    Users{n}.ModelSize=VehicleProperties(Model, 3); % small, medium, large
    Users{n}.BatterySize=uint32(str2double(VehicleProperties(Model, 4))*1000); % [Wh]
    Users{n}.Consumption=uint32(str2double(VehicleProperties(Model, 5))*1000*1.2); % [Wh/km] !!!! Consumption artificially increased by factor 1.2 !!!!!!
    Users{n}.DCChargingPowerVehicle=str2double(VehicleProperties(Model, 6))*1000; % [W]
    Users{n}.ACChargingPowerVehicle=str2double(VehicleProperties(Model, 7))*1000; % [W]
    Users{n}.AChargingPowerHomeCharger=max((a(2)>=str2double(VehicleProperties(Model,8:13))).*[2.3 3.7 3.7 7.3 11 22]*1000); % [W]
    Users{n}.ACChargingPowerHomeCharging=uint32(min(Users{n}.AChargingPowerHomeCharger, Users{n}.ACChargingPowerVehicle)); % [W];
    
    if a(3)>=LikelihoodPV
        Users{n}.PVPlant=uint8(PVPlantPointer);
        Users{n}.PVPlantExists=true;
        PVPlantPointer=mod(PVPlantPointer,length(PVPlants))+1;
    else
        Users{n}.PVPlantExists=false;
    end
    Users{n}.ChargingStrategy=uint8((a(4,1)>=0.0)+1);
    if Users{n}.ChargingStrategy==1
        Users{n}.MinimumPluginTime=minutes(randi([30 90], 1,1));
    elseif Users{n}.ChargingStrategy==2
        Users{n}.ChargingPThreshold=1.4+TruncatedGaussian(0.2,[0.7 2]-1.4,1); % Mean=1.4, stdw=0.2, range(0.7, 2)
    end
    
    SizeNum=find(Users{n}.ModelSize==VehicleSizes,1);
    VehiclePointer(SizeNum)=mod(VehiclePointer(SizeNum), length(VehicleDatabase{SizeNum}))+1;
    while ~strcmp(Vehicles{VehicleDatabase{SizeNum}(VehiclePointer(SizeNum))}.VehicleSize,Users{n}.ModelSize) || Users{n}.BatterySize < Vehicles{VehicleDatabase{SizeNum}(VehiclePointer(SizeNum))}.AverageMileageYear_km % first condition: search for next vehicle with the same vehicle size. second condition: ensure that battery of model (in Wh) is larger than mileage per year of vehicle (in km) so that large ranges aren't driven by a car with a too small battery
        VehiclePointer(SizeNum)=mod(VehiclePointer(SizeNum), length(VehicleDatabase{SizeNum}))+1;
    end
    
    Users{n}.VehicleNum=VehicleDatabase{SizeNum}(VehiclePointer(SizeNum));
    Users{n}.LogbookSource=Vehicles{VehicleDatabase{SizeNum}(VehiclePointer(SizeNum))}.Logbook;
    Users{n}.LogbookSource(:,4)=uint32(Users{n}.LogbookSource(:,3)*Users{n}.Consumption/1000);
    Users{n}.LogbookSource(1,7)=uint32(double(Users{n}.BatterySize)*0.7+TruncatedGaussian(0.1,[0.4 1]-0.7,1)); % Initial SoC between 0.4 and 1 of BatterySize. Distribution is normal
    Users{n}.AverageMileageDay_m=uint32(sum(Users{n}.LogbookSource(:,3))/days(DateEnd-DateStart)); %[m]
    Users{n}.AverageMileageYear_km=uint32(sum(Users{n}.LogbookSource(:,3))/days(DateEnd-DateStart)*365.25/1000); %[km]
end

clearvars LikelihoodChargingDay LikelihoodPV PVPlantPointer