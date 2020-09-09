NumUsers=800;
LikelihoodPV=0.45; % 44 % der privaten und 46 % der gewerblichen Nutzer über eine eigene Photovoltaikanlage, https://elib.dlr.de/96491/1/Ergebnisbericht_E-Nutzer_2015.pdf S. 10
AddPV=false;

Users=cell(NumUsers+1,1);
PVPlantPointer=1;
VehicleSizes=[{'small'}; {'medium'}; {['large', 'transporter']}];
VehiclePointer=zeros(length(VehicleSizes),1);

if ~exist('Vehicles', 'var')
    GetVehicleData;
end

VehicleDatabase=cell(length(VehicleSizes),1);
for n=2:length(Vehicles)
    SizeNum=find(cellfun(@length, strfind(VehicleSizes, Vehicles{n}.VehicleSize)),1);
    if ~isempty(SizeNum)
        VehicleDatabase{SizeNum}=[VehicleDatabase{SizeNum}; n];
    end
end
    
if ~exist('VehicleProperties', 'var')
    PathVehicleData=[Path 'Predictions' Dl 'VehicleData' Dl];
    VehicleProperties=readmatrix(strcat(PathVehicleData, 'Vehicle_Properties.xlsx'), 'NumHeaderLines', 1, 'OutputType', 'string'); % Model Name, Fleet Share cum., Battery Capacity [kWh], Consumption [kWh/km], Share Charging Point Power
end

TemperatureMonths=[1, 1; 2, 1; 3, 1.2; 4, 1.3; 5, 1.7; 6, 1.9; 7, 2; 8, 2; 9, 1.7; 10, 1.4; 11, 1.2; 12, 1.1];
TemperatureTimeVec=TemperatureMonths(month(TimeVec), 2);

Users{1}.VehicleDataFileName=Vehicles{1}.FileName;
Users{1}.NumVehicles=length(Vehicles)-1;
Users{1}.TimeVec=intersect(TimeVec, Vehicles{1}.TimeVec);
UsersTimeVecLog=ismember(Vehicles{1}.TimeVec,Users{1}.TimeVec);
Users{1}.TimeStep=TimeStep;


for n=2:NumUsers+1
    a=rand(5,1);
    Model=max((a(1)>=str2double(VehicleProperties(:,2))).*(1:size(VehicleProperties,1))');
    Users{n}.ModelName=VehicleProperties(Model, 1);
    Users{n}.ModelSize=VehicleProperties(Model, 3); % small, medium, large
    Users{n}.BatterySize=uint32(str2double(VehicleProperties(Model, 4))*1000); % [Wh]
    Users{n}.Consumption=reshape(str2double(VehicleProperties(Model, 5:8))*1000, 2, 2); % Cold City, Mild City; Cold Highway, Mild Highway
    Users{n}.DCChargingPowerVehicle=str2double(VehicleProperties(Model, 9))*1000; % [W]
    Users{n}.ACChargingPowerVehicle=str2double(VehicleProperties(Model, 10))*1000; % [W]
    Users{n}.AChargingPowerHomeCharger=max((a(2)>=str2double(VehicleProperties(Model,11:16))).*[2.3 3.7 3.7 7.3 11 22]*1000); % [W]
    Users{n}.ACChargingPowerHomeCharging=uint32(min(Users{n}.AChargingPowerHomeCharger, Users{n}.ACChargingPowerVehicle)); % [W];
    Users{n}.ACChargingPowerHomeChargingLossFactor=a(3)*(0.95-0.85)+0.85;
    
    if a(4)>=LikelihoodPV && AddPV
        Users{n}.PVPlant=uint8(PVPlantPointer);
        Users{n}.PVPlantExists=true;
        PVPlantPointer=mod(PVPlantPointer,length(PVPlants))+1;
    else
        Users{n}.PVPlantExists=false;
    end
    Users{n}.ChargingStrategy=uint8((a(5,1)>=0.0)+1);
    if Users{n}.ChargingStrategy==1
        Users{n}.MinimumPluginTime=minutes(randi([30 90], 1,1));
    elseif Users{n}.ChargingStrategy==2
        Users{n}.ChargingPThreshold=1.4+TruncatedGaussian(0.2,[0.7 2]-1.4,1); % Mean=1.4, stdw=0.2, range(0.7, 2)
    end
    
    SizeNum=find(cellfun(@length, strfind(VehicleSizes, Users{n}.ModelSize)),1);
    VehiclePointer(SizeNum)=mod(VehiclePointer(SizeNum), length(VehicleDatabase{SizeNum}))+1;
    while ~strcmp(Vehicles{VehicleDatabase{SizeNum}(VehiclePointer(SizeNum))}.VehicleSizeMerged, Users{n}.ModelSize) || Users{n}.BatterySize < Vehicles{VehicleDatabase{SizeNum}(VehiclePointer(SizeNum))}.AverageMileageYear_km % first condition: search for next vehicle with the same vehicle size. second condition: ensure that battery of model (in Wh) is larger than mileage per year of vehicle (in km) so that large ranges aren't driven by a car with a too small battery
        VehiclePointer(SizeNum)=mod(VehiclePointer(SizeNum), length(VehicleDatabase{SizeNum}))+1;
    end
    
    Users{n}.VehicleSize=Vehicles{VehicleDatabase{SizeNum}(VehiclePointer(SizeNum))}.VehicleSize; % In vehicle size transporters are differentiated from large models!
    Users{n}.VehicleNum=VehicleDatabase{SizeNum}(VehiclePointer(SizeNum));
    Users{n}.VehicleID=Vehicles{VehicleDatabase{SizeNum}(VehiclePointer(SizeNum))}.ID;
    Users{n}.NumUsers=Vehicles{VehicleDatabase{SizeNum}(VehiclePointer(SizeNum))}.NumberUsers;
    Users{n}.DistanceCompanyToHome=Vehicles{VehicleDatabase{SizeNum}(VehiclePointer(SizeNum))}.DistanceCompanyToHome;
    Users{n}.VehicleUtilisation=Vehicles{VehicleDatabase{SizeNum}(VehiclePointer(SizeNum))}.VehicleUtilisation;
    Users{n}.AvgHomeParkingTime=Vehicles{VehicleDatabase{SizeNum}(VehiclePointer(SizeNum))}.AvgHomeParkingTime;
    
    Users{n}.LogbookSource=Vehicles{VehicleDatabase{SizeNum}(VehiclePointer(SizeNum))}.Logbook(UsersTimeVecLog, :);
    Velocities=double(Users{n}.LogbookSource(:,3))./double(Users{n}.LogbookSource(:,2))/60;
    Velocities(Velocities<14)=1;
    Velocities(Velocities>=14 & Velocities<=33)=(Velocities(Velocities>=14 & Velocities<=33)-14)/(33-14)+1;
    Velocities(Velocities>33)=2;
    
    Consumption=uint32(Users{n}.Consumption(1,1).*(2-Velocities).*(2-TemperatureTimeVec)+Users{n}.Consumption(2,1)*(Velocities-1).*(2-TemperatureTimeVec)+Users{n}.Consumption(1,2)*(2-Velocities).*(TemperatureTimeVec-1)+Users{n}.Consumption(2,2)*(Velocities-1).*(TemperatureTimeVec-1));
    
    Users{n}.LogbookSource(:,4)=uint32(Users{n}.LogbookSource(:,3).*Consumption/1000);
    Users{n}.LogbookSource(1,7)=uint32(double(Users{n}.BatterySize)*0.7+TruncatedGaussian(0.1,[0.4 1]-0.7,1)); % Initial SoC between 0.4 and 1 of BatterySize. Distribution is normal
    Users{n}.AverageMileageDay_m=uint32(sum(Users{n}.LogbookSource(:,3))/days(DateEnd-DateStart)); %[m]
    Users{n}.AverageMileageYear_km=uint32(sum(Users{n}.LogbookSource(:,3))/days(DateEnd-DateStart)*365.25/1000); %[km]
end

clearvars LikelihoodPV PVPlantPointer Consumption Velocities SizeNum VehiclePointer VehicleDatabase AddPV TemperatureMonths TemperatureTimeVec
clearvars NumUsers a n Model VehicleSizes UsersTimeVecLog