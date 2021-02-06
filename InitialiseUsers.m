%% Description
% This script initialises the variable that covers the users (==drivers) of
% the system. The script makes use of the VehicleData that is extracted
% from real driving profiles in the file GetVehicleData. The users are
% driving cars that represent the German EV market in 2019. Therefore, the
% EVs with the highest market share in Germany in 2019 are used as
% references. Their properties regarding market share, battery size,
% vehicle size and consumption were collected from KBA and ev-database.com.
% These information are loaded from a local xlsx file. The file covers
% also a guess (because there was not public data!) regarding the 
% distribution of private charger power for each model. Basing on these 
% information and the driving profile, each users is assigned with an real
% EV model and its properties and one driving profile of a vehicle that has
% the same size as the assigned real EV model. Using the guessed charger
% distribution, each user gets a private charger with a certain charging
% power. In addition, some users are assigned with a PV plant, whichs data 
% was downloaded from the sunny portal of SMA. The related files are stored
% in the folder GetSMAData. General information about the dataset is stored
% in Users{1}.
%
% Depended scripts / folders
%   Initialisation          Needed for the execution of this script
%   GetVehicleData          This script is calls GetVehicleData and uses 
%                           its vehicle profiles
%
% Description of important variables
%   NumUsers:           The number of users that will be initialised. (1,1)
%   LikelihoodPV:       The likelihood that one users owns a PV plant.
%                       (1,1)
%   AddPV               Control variable to skip the assignment of PV
%                       plants to the Users. Logical
%   Users:              The cell array that covers all user data. The 
%                       first cell contains processing information. Inside
%                       the following cells, the user data is stored, 
%                       each as a struct. cell (NumUsers+1,1)
%   VehicleSizes        The vehicle sizes that are accepted. In general,
%                       the vehicles in Vehicles have four different sizes:
%                       small, medium, large, transporter. VehicleSizes
%                       determines which of them will be considered for the
%                       users. Two sizes can be merged (considered as one
%                       class) by putting them into one cell {['large',
%                       'transporter']}. In consequence, a real car
%                       with the size large wil lget a driving profile of a
%                       large or transporter vehicle. cell of strings (1,N)
%   PVPlantPointer      A pointer that indicates which PV plant will be
%                       assigned to the next user that owns a PV plant. The
%                       same plant can be assigned to multiple users. (1,1)
%   VehiclePointer      A set of pointer that indicate which vehicle from
%                       Vehicles of a certain vehicle size will be assigned
%                       to the next user. Therefore, there are as many
%                       pointers as VehicleSizes has entries. The first row
%                       corresponds to the first vehicle size (usually
%                       small) and so on. The same vehicle can be assigned 
%                       to multiple users. (N,1)
%   VehicleDatabase     A cell array of N rows. Each row covers the vehicle
%                       numbers of one VehicleSize. cell (N,1)
%   VehicleProperties   The real data of the cars that are assigned to the
%                       users. Covers the car name, market share
%                       (cumulated), size, battery capacity, for
%                       consumption values (cold city, mild city, cold
%                       highway, mild highway) and a guess about the
%                       typical distribution of chargers the usual driver 
%                       of this car have.
%   TemperatureMonths   A first step to consider weather conditions for
%                       energy consumptions of vehicles. Each month is
%                       referred to a general temperature indicator between
%                       1 and 2. Small values represent cold temperatures
%                       and the other way around. The values are estimated
%                       from a climate chart for Germany. The first colum
%                       represents the month number, the second column the
%                       temperature indicator. (12, 2)
%   TemperatureTimeVec  The temperature indicator for each entry within
%                       Time.Vec. Therefore the months of Time.Vec are
%                       matched with the first col of TemperatureMonths.
%                       (M,1)
%   UsersTime.VecLogical Indicates which entries of Vehicles logbook are
%                       used within the given time interval set in
%                       Initialisation. If the Vehicles were processed with
%                       the same time interval, than all entries of this
%                       variable are one. Time points that are only part of
%                       Vehicles are deleted from the logbooks.

%% Initialisation
rng('default');
rng(1);
NumUsers=10; % number of users
PVGridConvenientChargingLikelihoodMatrix=single([0, 1; 1, 0]); % Matrix that defines with type of users use grid convenient charging (14a) and own a PV plant: [PV&14a, PV&~14a; ~PV&14a, ~PV&~14a]

Users=cell(NumUsers+1,1); % the main cell variable all user data is stored in
Users{1}.MwSt=single(1.19); % The VAT rate
Users{1}.EEGBonus=single(9.17); %[ct/kWh] Bonus paid by the DSO to PV plant owner for supplying energy to the grid
AddPV=true; % determines wheter PV plants shall be assigned to the users. In general true, only false for test purposes
MeanPrivateElectricityPrice=single(30.43/1.19 - 3.7513 - 7.06); % [ct/kWh] average German electricity price in 2019 according to Strom-Report without VAT (19%), electricity production price (avg. Dayahead price was 3.7513 ct/kWh in 2019) and NNE energy price (avg. was 7.06 ct/kWh in 2019)
PublicACChargingPrices=single([29, 39]); % [ct/kWh]
PublicDCChargingPrices=single([39, 49]); % [ct/kWh]
IMSYSInstallationCostsMean=single(80000); % [ct] The costs for the installation of the IMSYS have to be paid by the wallbox owner.

PrivateChargingThresholdMean=single(1.4);
PublicChargingThresholdMean=single(0.33);
VCity=single(14); % [m/s] lower velocities indicate driving within the city, hence low consumption
VHighway=single(27); % [m/s] higher velocities indicate driving on a highway, hence high consumption

PVPlantPointer=1;
PVGridConvenientChargingLikelihoodMatrix=cumsum(PVGridConvenientChargingLikelihoodMatrix(:)/sum(PVGridConvenientChargingLikelihoodMatrix,'all'));
VehicleSizes=[{'small'}; {'medium'}; {['large', 'transporter']}]; % determines which sizes shall be considered. In general, {'small'}; {'medium'}; {['large', 'transporter']}
VehicleUtilisation=[{'company car'}]; % determines which vehicle utilisations shall be considered. In general, {'company car'}; {'fleet vehicle'}; {'undefined'}
VehiclePointer=zeros(length(VehicleSizes),1); % the pointers that indicate which vehicle will be assigned next per vehicle size class

%% Load data necessary data

if ~exist('Vehicles', 'var')
    GetVehicleData; % load the driving profiles
end

tic

VehicleDatabase=cell(length(VehicleSizes),1); % covers all vehicle numbers for each vehicle size class
for n=2:length(Vehicles)
    SizeNum=find(cellfun(@length, strfind(VehicleSizes, Vehicles{n}.VehicleSize)),1); % compare the strings in VehicleSizes with the entry in Vehicles{n}. Save the row of the matching size in SizeNum
    if ~isempty(SizeNum) && ~isempty(strfind(Vehicles{n}.VehicleUtilisation, VehicleUtilisation)) % if the size of Vehicle{n} is member of VehicleSizes and it matches the selcted vehicle utilisations
        VehicleDatabase{SizeNum}=[VehicleDatabase{SizeNum}; n]; % add the number of the vehicle in the correct row of VehicleDatabase
    end
end
    
if ~exist('VehicleProperties', 'var')
    VehicleProperties=readmatrix(strcat(Path.Simulation, 'Vehicle_Properties.xlsx'), 'NumHeaderLines', 1, 'OutputType', 'string'); % load the real car properties. Model Name, Fleet Share cum., Battery Capacity [kWh], Consumption [kWh/km], Share Charging Point Power
end
if ~exist('GridConvenienChargingDistribution', 'var')
    GridConvenienChargingDistribution=readmatrix(strcat(Path.Simulation, 'GridConvenientCharging_Distribution.csv'), 'NumHeaderLines', 1, 'OutputType', 'string');
    GridConvenienChargingDistribution=single(str2double(GridConvenienChargingDistribution(:,2:end)));
end

%% Store processing information

Time.Sim.Start=dateshift(max([Range.TestDate(1), Vehicles{1}.Time.Vec(1)]), 'start', 'day');
Time.Sim.End=min([Range.TestDate(2), Vehicles{1}.Time.Vec(end)]);
Time.Sim.Vec=Time.Sim.Start:Time.Step:Time.Sim.End;
Time.Sim.VecInd=1:length(Time.Sim.Vec);
Time.Sim.StepInd=Time.StepInd;
Time.Sim.Step=Time.Step;

Users{1}.Time=Time.Sim;
Users{1}.VehicleDataFileName=Vehicles{1}.FileName; % save general processing information in the first cell
Users{1}.NumVehicles=length(Vehicles)-1;
UsersTimeVecLogical=ismember(Vehicles{1}.Time.Vec,Users{1}.Time.Vec);
Users{1}.AddPV=AddPV;

%% Use TemperatureData
TemperatureMonths=[1, 1; 2, 1; 3, 1.2; 4, 1.3; 5, 1.7; 6, 1.9; 7, 2; 8, 2; 9, 1.7; 10, 1.4; 11, 1.2; 12, 1.1]; 
TemperatureTimeVec=TemperatureMonths(month(Users{1}.Time.Vec), 2);


%% Initialise the users

for n=2:NumUsers+1
    
    % Selection of a car model
    RandomNumbers=rand(9,1); % get some random numbers that will be used during the initialsation of this user
    Model=max((RandomNumbers(1)>=str2double(VehicleProperties(:,2))).*(1:size(VehicleProperties,1))'); % with respect to market share of the cars, pick one of them. a(1) is uniformly distributed between 0 and 1. find the first vehicle whichs cumulated market share value (in decimal) is large than a(1). the cumulated market share value of the first car is 0, the one of the next car represents the market share of the first vehicle. the number of the second car represents the cumulated share of the first two vehicles and so on
    Users{n}.ModelName=VehicleProperties(Model, 1); % the car name, e. g. "BMW i3s"
    Users{n}.ModelSize=VehicleProperties(Model, 3); % small, medium, large
    Users{n}.BatterySize=single(str2double(VehicleProperties(Model, 4))*1000); % [Wh] Wh is used to keep accuracy while using only integers
    Users{n}.Consumption=single(reshape(str2double(VehicleProperties(Model, 5:8)), 2, 2)); % [Wh/m == kWh/km] Cold City, Mild City; Cold Highway, Mild Highway
    
    % Determine charging properties
    Users{n}.ChargingEfficiency=single(str2double(VehicleProperties(Model, 9))); % consider a charging loss factor
    Users{n}.DCChargingPowerVehicle=single(str2double(VehicleProperties(Model, 10))*1000); % [Wh/m] max DC charging power of car
    Users{n}.ACChargingPowerVehicle=single(str2double(VehicleProperties(Model, 11))*1000); % [W] max ac power chrging power of car
    Users{n}.AChargingPowerHomeCharger=single(max((RandomNumbers(2)>=str2double(VehicleProperties(Model,12:17))).*[2.3 3.7 3.7 7.3 11 22]*1000)); % [W] with respect to the guessed distribution of chargers for this car, pick one ac charging power for the private charging point. selection mechanism equals the on described for the Model
    Users{n}.ACChargingPowerHomeCharging=single(min(Users{n}.AChargingPowerHomeCharger, Users{n}.ACChargingPowerVehicle)*Users{n}.ChargingEfficiency); % [W] the charging power at the private charging point is determined by the minimum of the cars and the charging points power
    Users{n}.PrivateElectricityPrice=single(MeanPrivateElectricityPrice+randn(1));
    Users{n}.PublicACChargingPrices=single(max((RandomNumbers(4)>=[0, 0.5]).*PublicACChargingPrices));
    Users{n}.PublicDCChargingPrices=single(max((RandomNumbers(5)>=[0, 0.5]).*PublicDCChargingPrices));
    
    % Add a PV plant
    %if RandomNumbers(6)<=LikelihoodPV && AddPV 
    if RandomNumbers(6)<=PVGridConvenientChargingLikelihoodMatrix(2) && AddPV 
        Users{n}.PVPlant=uint8(PVPlantPointer); % save the assigned PV plant number
        Users{n}.PVPlantExists=true; % and set this variable to true to indicate that this user owns a PV plant
        PVPlantPointer=mod(PVPlantPointer,length(PVPlants))+1; % increase pointer
    else
        Users{n}.PVPlantExists=false;
    end
    
    % Selection of a charging strategy
    Users{n}.ChargingStrategy=uint8((RandomNumbers(7,1)>=0.0)+1); % pick a charging strategy
    if Users{n}.ChargingStrategy==1 % this one is primitive
        Users{n}.MinimumPluginTime=minutes(randi([30 90], 1,1));
    elseif Users{n}.ChargingStrategy==2 % only use this strategy which will be explained in Simulation
        Users{n}.PrivateChargingThreshold=single(PrivateChargingThresholdMean+TruncatedGaussian(0.2,[PrivateChargingThresholdMean*0.6 PrivateChargingThresholdMean*1.3]-PrivateChargingThresholdMean,1)); % Mean=1.4, stdw=0.2, range(0.7, 2)
    end
    Users{n}.PublicChargingThreshold=single(PublicChargingThresholdMean+TruncatedGaussian(0.03,[PublicChargingThresholdMean*0.75 PublicChargingThresholdMean*1.4]-PublicChargingThresholdMean,1)); % Mean=1.4, stdw=0.2, range(0.7, 2)
    Users{n}.PublicChargingThreshold_Wh=Users{n}.BatterySize*Users{n}.PublicChargingThreshold;
    
    % Selection of a grid convenient charging profile
    GridConvenientChargingProfile=max(single(RandomNumbers(8)>=(0:1/size(GridConvenienChargingDistribution,2):1-1/size(GridConvenienChargingDistribution,2))).*(1:size(GridConvenienChargingDistribution,2)));
%     if RandomNumbers(8)<=LikelihoodGridConvenientCharging
    Users{n}.NNEEnergyPriceGridConvenientCharging=GridConvenienChargingDistribution(3,GridConvenientChargingProfile); % [ct/kWh] netto (without VAT). reduced NNE energy price due to the allowance for the DSO to manage the charging
    Users{n}.NNEEnergyPriceNotGridConvenientCharging=GridConvenienChargingDistribution(1,GridConvenientChargingProfile); % [ct/kWh] netto (without VAT). normal NNE prices
    if RandomNumbers(6)<=PVGridConvenientChargingLikelihoodMatrix(1) || (RandomNumbers(6)>PVGridConvenientChargingLikelihoodMatrix(2) & RandomNumbers(6)<=PVGridConvenientChargingLikelihoodMatrix(3))
        Users{n}.GridConvenientCharging=true;
        Users{n}.GridConvenientChargingAvailability=GridConvenienChargingDistribution(5:end,GridConvenientChargingProfile);
        Users{n}.NNEExtraBasePrice=GridConvenienChargingDistribution(2,GridConvenientChargingProfile)*100; % [ct/a] netto (without VAT) due to the extra electricity meter
        Users{n}.NNEBonus=GridConvenienChargingDistribution(4,GridConvenientChargingProfile)*100; % [ct] a single bonus paid by the DSO
        Users{n}.IMSYSInstallationCosts=single(IMSYSInstallationCostsMean*(1+TruncatedGaussian(0.1,[0.5 1.5]-1,1)));
        Users{n}.NNEEnergyPrice=Users{n}.NNEEnergyPriceGridConvenientCharging;
    else
        Users{n}.GridConvenientCharging=false;
        Users{n}.GridConvenientChargingAvailability=ones(24*Time.StepInd,1, 'single');
        Users{n}.NNEExtraBasePrice=single(0); % not extra electricity meter required
        Users{n}.NNEBonus=single(0); % no extra Bonus
        Users{n}.IMSYSInstallationCosts=single(0);
        Users{n}.NNEEnergyPrice=Users{n}.NNEEnergyPriceNotGridConvenientCharging;
    end
    
    
    % Choose a driving profile from VehicleData
    SizeNum=find(cellfun(@length, strfind(VehicleSizes, Users{n}.ModelSize)),1); % find a vehicle that fits the size of the assigned car model
    VehiclePointer(SizeNum)=mod(VehiclePointer(SizeNum), length(VehicleDatabase{SizeNum}))+1;
    while (~strcmp(Vehicles{VehicleDatabase{SizeNum}(VehiclePointer(SizeNum))}.VehicleSizeMerged, Users{n}.ModelSize) || Users{n}.BatterySize < Vehicles{VehicleDatabase{SizeNum}(VehiclePointer(SizeNum))}.AverageMileageYear_km) %|| strcmp(Vehicles{VehicleDatabase{SizeNum}(VehiclePointer(SizeNum))}.VehicleUtilisation, 'fleet vehicle') % first condition: search for next vehicle with the same vehicle size. second condition: ensure that battery of model (in Wh) is larger than mileage per year of vehicle (in km) so that large ranges aren't driven by a car with a too small battery
        VehiclePointer(SizeNum)=mod(VehiclePointer(SizeNum), length(VehicleDatabase{SizeNum}))+1; % increase the pointer of the vehicle size class
    end
    
    % Copy Vehicle Properties
    Users{n}.VehicleSize=Vehicles{VehicleDatabase{SizeNum}(VehiclePointer(SizeNum))}.VehicleSize; % In vehicle size transporters are differentiated from large models!
    Users{n}.VehicleNum=VehicleDatabase{SizeNum}(VehiclePointer(SizeNum));
    Users{n}.VehicleID=Vehicles{VehicleDatabase{SizeNum}(VehiclePointer(SizeNum))}.ID;
    Users{n}.NumUsers=Vehicles{VehicleDatabase{SizeNum}(VehiclePointer(SizeNum))}.NumberUsers;
    Users{n}.DistanceCompanyToHome=Vehicles{VehicleDatabase{SizeNum}(VehiclePointer(SizeNum))}.DistanceCompanyToHome;
    Users{n}.VehicleUtilisation=Vehicles{VehicleDatabase{SizeNum}(VehiclePointer(SizeNum))}.VehicleUtilisation;
    Users{n}.AvgHomeParkingTime=Vehicles{VehicleDatabase{SizeNum}(VehiclePointer(SizeNum))}.AvgHomeParkingTime;
    Users{n}.Logbook=single(Vehicles{VehicleDatabase{SizeNum}(VehiclePointer(SizeNum))}.Logbook(UsersTimeVecLogical, :));
    Users{n}.Logbook=[Users{n}.Logbook, zeros(length(Users{n}.Logbook), 9-size(Users{n}.Logbook,2))]; % [State, DrivingTime [min], Distance [m], Energy consumed [Wh], Energy charged private Spotmarket [Wh], Energy charged private PV plant [Wh], Energy charged private reserve energy [Wh], Energy charged public [Wh], SoC [Wh]]
        
    % Calc energy consumption in Logbook by using consumption data from model
    Velocities=Users{n}.Logbook(:,3)./Users{n}.Logbook(:,2)/60; % [m/s] depending on the velocity of each trip and the temperature indicator of its month, determine the energy consumption of the trip
    Velocities(Velocities<VCity)=1; % all trips with velocities smaller VCity m/s have the city consumption value
    Velocities(Velocities>=VCity & Velocities<=VHighway)=(Velocities(Velocities>=VCity & Velocities<=VHighway)-VCity)/(VHighway-VCity)+1; % in between the consumption value is interpolated
    Velocities(Velocities>VHighway)=2; % all above VHighway m/s the highway consumption value
    
    Consumption=Users{n}.Consumption(1,1).*(2-Velocities).*(2-TemperatureTimeVec)+Users{n}.Consumption(2,1)*(Velocities-1).*(2-TemperatureTimeVec)+Users{n}.Consumption(1,2)*(2-Velocities).*(TemperatureTimeVec-1)+Users{n}.Consumption(2,2)*(Velocities-1).*(TemperatureTimeVec-1); % calculate the consumption of all trips depending of velocity and temperature
    
    % Initialisation of LogbookBase
    Users{n}.Logbook(:,4)=single(uint32(double(Users{n}.Logbook(:,3)).*Consumption)); % add consumption to logbook
    Users{n}.Logbook(1,9)=single(uint32(double(Users{n}.BatterySize)*0.7+TruncatedGaussian(0.1,[0.4 1]-0.7,1))); % Initial SoC between 0.4 and 1 of BatterySize. Distribution is normal
    
    % Evaluation of User properties
    Users{n}.AverageMileageDay_m=single(sum(Users{n}.Logbook(:,3))/days(Time.Sim.Vec(end)-Time.Sim.Vec(1))); %[m]
    Users{n}.AverageMileageYear_km=single(sum(Users{n}.Logbook(:,3))/days(Time.Sim.Vec(end)-Time.Sim.Vec(1))*365.25/1000); %[km]
end

disp(strcat("Users successfully initialised ", num2str(toc)))

%% Clean up Workspace

clearvars LikelihoodPV PVPlantPointer Consumption Velocities SizeNum VehiclePointer VehicleDatabase AddPV TemperatureMonths TemperatureTimeVec
clearvars RandomNumbers n Model VehicleSizes MeanPrivateElectricityPrice NumTripDays NumUsers PublicACChargingPrices PublicDCChargingPrices StorageFiles StorageInd
clearvars TimeNoiseStdFac UsersTime VehicleProperties GridConvenientChargingProfile UsersTimeVecLogical VCity VHighway PublicChargingThresholdMean
clearvars PrivateChargingThresholdMean LikelihoodGridConvenientCharging GridConvenienChargingDistribution PVGridConvenientChargingLikelihoodMatrix
clearvars VehicleUtilisation