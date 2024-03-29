%% Description
% This script simulates the base or smart charging scenario dependend on 
% the variable Users{1}.SmartCharging. Therefore, it uses the Users 
% initialised in InitialiseUsers.m. After variable initialization and the 
% loading of prediction data, the simulation starts over the defined 
% simulation period. Hence, with each simulation step, the time is
% increased by Time.Sim.Step minutes. Within each time step the driving and
% charging bevahiour of each user is simulated. After the simulation the
% simulation data is stored and evaluated. Load profiles are generated and
% the charging costs are determined.
%
% Depended scripts / folders
%   Initialisation          Needed for the execution of this script
%   InitialiseUsers         Calls this script to create User profiles
%   InitialisePreAlgo       Calls this script to initialise the algorithm 1
%   InitialiseLiveAlgo      Calls this script to initialise the algorithm 2
%   CalcDynOptVars          Calls this script to calculate variables that
%                           change each Algo 1 interation
%   CalcConsOptVars         Calls this script to calculate variables that 
%                           only change after one day
%   PreAlgo                 Calls this script to execute algorithm 1
%   LiveAlgo                Calls this script to execute algorithm 2
%
% Description of important variables
%   NumUsers:           The number of users that will be initialised. (1,1)
%   Users:              The cell array that covers all user data. The 
%                       first cell contains processing information. Inside
%                       the following cells, the user data is stored, 
%                       each as a struct. cell (NumUsers+1,1)
%   Users{n}.Logbook    Matrix that covers all driving and charging
%                       information of a user during the simulation. Column
%                       description:
%                       1   Vehicle state 
%                           1==Driving
%                           2==Parking anywhere
%                           3==Parking at home charging point
%                           4==connected to home charging point
%                           5==charging at home charging point
%                           6==charging at public AC charger
%                           7==charging at public DC charger
%                       2   Driven time in minutes
%                       3   Driven distance in meters
%                       4   Consumed energy in Wh
%                       5   Energy charged from Spotmarket in Wh
%                       6   Energy charged by PV electricity in Wh
%                       7   Energy charged by reserve energy in Wh
%                       8   Energy charged at public charging point in Wh
%                       9   Energy in battery in Wh
%                       Each row equals one iteration step covering 15
%                       minutes.


%% Initialisation

NumUsers=1000;                          % number of users considered
Users=cell(NumUsers+1,1);               % the main cell variable all user data is stored in
Users{1}.SmartCharging=true;            % if true then the smart charging scenario is executed, else the base scenario
UseParallel=true;                       % if true, in the smart charging scenario parallel computing is used
UseParallelAvailability=false;          
UseSpotPredictions=true;                % if true spot market predictions are used, else it is assumed that the aggregator knows the future market prices
UsePVPredictions=true;                  % if true PV predictions are used, else it is assumed that the aggregator knows the future PV powers
UseIndividualEEGBonus=true;             % if true PV electricity consumption costs are plant specific depending on the start of operation date of the plant (determines the EEG bonus)
InitialiseUserNew=true;                 % if true User profiles are generated newly, else stored data is used
%DemoUsers=[9]%;,22,36,46,66,74,82,83,94,122,124,164,165,167,171,181,187,193,197,241,242,259,286,295,349,352,359,363,365,379,390,392,405,413,430,436,473,490,493,497,535,575,578,610,628,650,665,701,704,723,727,756,778,785,820,851,867,880,884,910,936,956,983,985,987,1002,1011,1019,1021,1045,1062,1075,1080,1083,1093,1113,1167,1168,1174,1182,1186,1190,1194,1198,1215,1217,1226,1232,1244,1284,1292,1298,1301,1319,1383,1390,1423,1426,1430,1436,14,68,92,100,119,130,218,246,270,315,317,408,438,442,451,460,563,568,580,588,589,595,608,614,656,661,667,673,693,703,738,742,744,767,777,807,819,869,878,924,937,943,972,1005,1025,1043,1064,1105,1124,1165,1178,1191,1192,1199,1216,1218,1270,1273,1305,1317,1331,1352,1370,1408,1427,1460,1463,1478,1481,1504,7,9,22,36,46,66,74,82,83,94,122,124,164,165,167,171,181,187,193,195,197,222,241,242,259,286,289,295,308,349];

if ~InitialiseUserNew && isfile(strcat(Path.Simulation, "InitialisedUsers", Dl, "Users", num2str(NumUsers), ".mat"))
    load(strcat(Path.Simulation, "InitialisedUsers", Dl, "Users", num2str(NumUsers), ".mat"))
else    
    InitialiseUsers;
end
ControlPeriods=96*2;                    % number of time steps within one optimization period (2*96 = 2 days)
UsePV=true;                             % User power of PV plants to charge the cars
ApplyGridConvenientCharging=true;       % Apply the � 14a EnWG programme
ActivateWaitbar=true;
SaveResults=true;

FinishSimulation=1;
CleanUpWorkspace=0;

if Users{1}.SmartCharging
    if UseParallel
        NumDecissionGroups=NumUsers/50;         % in case of smart charging, the fleet is divided into subfleets, each of size 50
        gcp
    else
        NumDecissionGroups=1;
    end
end


if ~exist('PublicChargerDistribution', 'var')
    PublicChargerDistribution=single(readmatrix(strcat(Path.Simulation, "PublicChargerProbability.xlsx")));     % load a power probability distribution for charging at a public charging point
end

PublicChargerDist=[];

NumUsers=min(NumUsers, size(Users,1)-1);
ChargingPower=zeros(NumUsers,1, 'single');
EnergyDemandLeft=zeros(NumUsers+1,1, 'single');
delete(findall(0,'type','figure','tag','TMWWaitbar'));

Time.Sim=Users{1}.Time;
TD.Main=find(ismember(Time.Vec,Time.Sim.Start),1)-1;            % Index Offset for all electricity market variables
TD.User=find(ismember(Users{1}.Time.Vec,Time.Sim.Start),1)-1;   % Index Offset for the users

UserNum=2:NumUsers+1;

if ~isfield(Users{1}, "TotalCostsIt")
    Users{1}.TotalCostsIt={};               % Variable to store the energy costs of simulations
end

   
for n=UserNum
    if ApplyGridConvenientCharging && Users{n}.GridConvenientCharging
        Users{n}.NNEEnergyPrice=Users{n}.NNEEnergyPriceGridConvenientCharging;
    else
        Users{n}.NNEEnergyPrice=Users{n}.NNEEnergyPriceNotGridConvenientCharging;
    end
    
    Users{n}.EEGBonus=Users{1}.EEGBonus;
    if UseIndividualEEGBonus && Users{n}.PVPlantExists
        Users{n}.EEGBonus=PVPlants{Users{n}.PVPlant}.EEGBonus;
    end
end


if Users{1}.SmartCharging
    TimeOfPreAlgo=[datetime(1,1,1,8,0,0,'TimeZone','Africa/Tunis'), datetime(1,1,1,12,0,0,'TimeZone','Africa/Tunis'), datetime(1,1,1,16,0,0,'TimeZone','Africa/Tunis'), datetime(1,1,1,20,0,0,'TimeZone','Africa/Tunis'), datetime(1,1,1,0,0,0,'TimeZone','Africa/Tunis'), datetime(1,1,1,4,0,0,'TimeZone','Africa/Tunis')];
    TimeOfReserveMarketOffer=datetime(1,1,1,8,0,0,'TimeZone','Africa/Tunis');            % GCT of Secondary reserve auction is 8 am
    TimeOfDayAheadMarketPriceRelease=datetime(1,1,1,13,0,0,'TimeZone','Africa/Tunis');   % DayAhead market prices are published at 1 pm
	ShiftInds=(hour(TimeOfPreAlgo(1))*Time.StepInd + minute(TimeOfPreAlgo(1))/minutes(Time.Step));
    % Indices when algo 1 shall be executed
    TimesOfPreAlgo=[(hour(TimeOfPreAlgo(1))*Time.StepInd + minute(TimeOfPreAlgo(1))/60*Time.StepInd)+1:24*Time.StepInd:length(Time.Sim.VecInd);...
                    (hour(TimeOfPreAlgo(2))*Time.StepInd + minute(TimeOfPreAlgo(2))/60*Time.StepInd)+1:24*Time.StepInd:length(Time.Sim.VecInd);...
                    (hour(TimeOfPreAlgo(3))*Time.StepInd + minute(TimeOfPreAlgo(3))/60*Time.StepInd)+1:24*Time.StepInd:length(Time.Sim.VecInd);...
                    (hour(TimeOfPreAlgo(4))*Time.StepInd + minute(TimeOfPreAlgo(4))/60*Time.StepInd)+1:24*Time.StepInd:length(Time.Sim.VecInd);...
                    (hour(TimeOfPreAlgo(5))*Time.StepInd + minute(TimeOfPreAlgo(5))/60*Time.StepInd)+1:24*Time.StepInd:length(Time.Sim.VecInd);...
                    (hour(TimeOfPreAlgo(6))*Time.StepInd + minute(TimeOfPreAlgo(6))/60*Time.StepInd)+1:24*Time.StepInd:length(Time.Sim.VecInd);...
                    ];
    TimesOfDayAheadMarketPriceRelease=(hour(TimeOfDayAheadMarketPriceRelease)*Time.StepInd + minute(TimeOfDayAheadMarketPriceRelease)/60*Time.StepInd)+1:24*Time.StepInd:length(Time.Sim.VecInd);

    InitialisePreAlgo;
    InitialiseLiveAlgo;
    
    TimesOfResPoEval=mod(16-hour(Time.Sim.Vec(1))*4 + minute(Time.Sim.Vec(1)),16)+1:ConstantResPoPowerPeriods:length(Time.Sim.VecInd);
    
    if UseSpotPredictions
        if ~exist("SpotmarketPricesPred1", "var")       % Load the spot market predictions
            %[StorageFile, StoragePath]=uigetfile(strcat(Path.Prediction, "DayaheadRealH", Dl), 'Select the first Spotmarket Prediction');
            StorageFile="LSQ_20210202-1210_20180101-20200831_52h_232Preds_8hr.mat";
            StoragePath=strcat(strcat(Path.Prediction, "DayaheadRealH", Dl));
            load(strcat(StoragePath, StorageFile))
            if Pred.Time.StepPredInd~=Time.StepInd
                SpotmarketPricesPred1=repelem(Pred.Data, Time.StepInd/Pred.Time.StepPredInd);
            end
            TD.SpotmarketPricesPred1=find(ismember(Pred.Time.Vec,Time.Sim.Start),1)-1;
        end
        
        if ~exist("SpotmarketPricesPred2", "var")
            %[StorageFile, StoragePath]=uigetfile(strcat(Path.Prediction, "DayaheadRealH", Dl), 'Select the second Spotmarket Prediction');
            StorageFile="LSQ_20210202-1220_20180101-20200831_48h_232Preds_12hr.mat";
            StoragePath=strcat(strcat(Path.Prediction, "DayaheadRealH", Dl));
            load(strcat(StoragePath, StorageFile))
            if Pred.Time.StepPredInd~=Time.StepInd
                SpotmarketPricesPred2=repelem(Pred.Data, Time.StepInd/Pred.Time.StepPredInd);
            end
            TD.SpotmarketPricesPred2=find(ismember(Pred.Time.Vec,Time.Sim.Start),1)-1;
        end
    else
        SpotmarketPricesPred1=repelem(Smard.DayaheadRealH, Time.StepInd);
        TD.SpotmarketPricesPred1=find(ismember(Time.Vec,Time.Sim.Start),1)-1;
        SpotmarketPricesPred2=repelem(Smard.DayaheadRealH, Time.StepInd);
        TD.SpotmarketPricesPred2=find(ismember(Time.Vec,Time.Sim.Start),1)-1;
    end
end

if UsePVPredictions
    PVPlants_Profile_Prediction="PredictionQH";
else
    PVPlants_Profile_Prediction="ProfileQH";
end

SpotmarketPrices=repelem(Smard.DayaheadRealH, Time.StepInd);
TD.SpotmarketPrices=find(ismember(Time.Vec,Time.Sim.Start),1)-1;

if ActivateWaitbar
    h=waitbar(0, "Simulate charging processes: 0%");
end

PreAlgoCounter=0;

%% Start Simulation

TSim=tic;
datetime('now')
TimeIndVec=zeros(Time.Sim.VecInd(end-ControlPeriods),10);

for TimeInd=Time.Sim.VecInd(2:end-ControlPeriods)
              
    for n=UserNum

        % Both scenarios
        % Public charging: Only charge at public charging point if it is requiered due to low SoC
        if Users{n}.Logbook(TimeInd+TD.User-1,9)-Users{n}.Logbook(TimeInd+TD.User,4) < Users{n}.PublicChargingThreshold_Wh
            
            k=TimeInd+TD.User;
            while k < length(Users{n}.Logbook) && ~ismember(Users{n}.Logbook(k,1), 3:5)
                k=k+1;
            end
            NextHomeStop=k; % Index when the next stop at the private charging point occurs
            
            ConsumptionTilNextHomeStop=sum(Users{n}.Logbook(TimeInd+TD.User:NextHomeStop,4)); % Energy consumed until the next stop at the private charging point occurs [Wh]
            TripDistance=sum(Users{n}.Logbook(TimeInd+TD.User:NextHomeStop,3)); % Distance driven until the next stop at the private charging point occurs [m]

            PublicChargerPower=max((rand(1, 'single')>=PublicChargerDistribution(find(PublicChargerDistribution>TripDistance/1000,1),:)).*PublicChargerDistribution(1,:)); % [kW]
            PublicChargerDist(end+1)=PublicChargerPower;
            ChargingPower(n)=min([max([Users{n}.ACChargingPowerVehicle, Users{n}.DCChargingPowerVehicle]), PublicChargerPower])*Users{n}.ChargingEfficiency; % Actual ChargingPower at public charger in [kW]
            
            EnergyDemandLeft(n)=single(min((Users{n}.PublicChargingThreshold*100 + 5+TruncatedGaussian(2,[1 10]-5,1))/100*Users{n}.BatterySize + ConsumptionTilNextHomeStop - Users{n}.Logbook(TimeInd+TD.User-1,9), Users{n}.BatterySize - Users{n}.Logbook(TimeInd+TD.User-1,9))); % Energy that will be charged at the public charging pint during this charging session [Wh]
            TimeStepIndsNeededForCharging=double(ceil(EnergyDemandLeft(n)/ChargingPower(n)*60/Time.StepMin)); % [Wh/W]
            
            if TimeStepIndsNeededForCharging>0
                k=TimeInd+TD.User;
                while k < length(Time.Sim.VecInd)-TimeStepIndsNeededForCharging && ~isequal(Users{n}.Logbook(k:k+TimeStepIndsNeededForCharging-1,3),zeros(TimeStepIndsNeededForCharging,1, 'single'))
                    k=k+1;
                end
                EndOfShift=min(length(Time.Sim.VecInd), k+TimeStepIndsNeededForCharging-1);

                Users{n}.Logbook(TimeInd+TD.User:EndOfShift,:)=Users{n}.Logbook(TimeInd+TD.User-TimeStepIndsNeededForCharging:EndOfShift-TimeStepIndsNeededForCharging,:);
                TimeStepIndsNeededForCharging=min(length(Users{n}.Logbook)-(TimeInd+TD.User-1), TimeStepIndsNeededForCharging);
                Users{n}.Logbook(TimeInd+TD.User:TimeInd+TD.User+TimeStepIndsNeededForCharging-1,1:9)=ones(TimeStepIndsNeededForCharging,1)*[6 + double(PublicChargerPower>30000), zeros(1,8)]; % Public charging due to low SoC
            end
        end
        
        if EnergyDemandLeft(n)>0 
            Users{n}.Logbook(TimeInd+TD.User,8)=min([EnergyDemandLeft(n), ChargingPower(n)*Time.StepMin/60, Users{n}.BatterySize-Users{n}.Logbook(TimeInd+TD.User-1,9)]); % Publicly charged energy during one Time.Step in [Wh]
            EnergyDemandLeft(n)=EnergyDemandLeft(n)-Users{n}.Logbook(TimeInd+TD.User,8); 
        end
        
        Users{n}.Logbook(TimeInd+TD.User,9)=min(Users{n}.BatterySize, Users{n}.Logbook(TimeInd+TD.User-1,9) - Users{n}.Logbook(TimeInd+TD.User,4) + Users{n}.Logbook(TimeInd+TD.User,8));

    end
    
    if ~Users{1}.SmartCharging              % Base scenario
        
        for n=UserNum
        
            % Private charging: Decide whether to plug in the car the or not

            if Users{n}.Logbook(TimeInd+TD.User,1)==3

                if Users{n}.Logbook(TimeInd+TD.User-1,1)<3

                    % ChargingStrategy==1 is not used anymore
                    if Users{n}.ChargingStrategy==1 % Always connect car to charging point if Duration of parking is higher than MinimumPluginTime
                        ParkingDuration=(find(Users{n}.Logbook(TimeInd+TD.User:end,1)<3,1)-1)*Time.Step;
                        if ParkingDuration>Users{n}.MinimumPluginTime
                            Users{n}.Logbook(TimeInd+TD.User,1)=4; % Plugged-in
                        else
                            Users{n}.Logbook(TimeInd+TD.User,1)=3; % Not plugged-in
                        end

                    elseif Users{n}.ChargingStrategy==2 % The probability of connection is a function of Plug-in time, SoC and the consumption within the next 24h
                        Consumption24h=sum(Users{n}.Logbook(TimeInd+TD.User:min(TimeInd+TD.User+24*Time.StepInd-1, size(Users{n}.Logbook,1)), 4)); % [Wh]
                        ConnectionDurations24h=find(ismember(Users{n}.Logbook(TimeInd+TD.User:min(TimeInd+TD.User+24*Time.StepInd-1, size(Users{n}.Logbook,1)), 1), 3:5) & ~ismember([Users{n}.Logbook(TimeInd+TD.User+1:min(TimeInd+TD.User+24*Time.StepInd-1, size(Users{n}.Logbook,1)), 1);0], 3:5)) - find(ismember(Users{n}.Logbook(TimeInd+TD.User:min(TimeInd+TD.User+24*Time.StepInd-1, size(Users{n}.Logbook,1)), 1), 3:5) & ~ismember([0;Users{n}.Logbook(TimeInd+TD.User:min(TimeInd+TD.User+24*Time.StepInd-1-1, size(Users{n}.Logbook,1)-1), 1)], 3:5))+1;
                        if Consumption24h>Users{n}.Logbook(TimeInd+TD.User-1,9) && ~max(ConnectionDurations24h)*Time.StepInd*Users{n}.ACChargingPowerHomeCharging < Consumption24h
                            Users{n}.Logbook(TimeInd+TD.User,1)=4; % Plugged-in
                        else
                            PlugInTime=(find([Users{n}.Logbook(TimeInd+TD.User+1:end,1);0]<3,1)-1)/Time.StepInd;
                            P=min(1,PlugInTime/3) + 0.9*min(1, (Users{n}.BatterySize-Users{n}.Logbook(TimeInd+TD.User-1,9))/Users{n}.BatterySize) + min(1, Consumption24h/Users{n}.Logbook(TimeInd+TD.User-1,9)) + 0.3*ConnectionDurations24h(1)/max(ConnectionDurations24h);
                            if P>Users{n}.PrivateChargingThreshold
                                Users{n}.Logbook(TimeInd+TD.User,1)=4; % Plugged-in
                            else
                                Users{n}.Logbook(TimeInd+TD.User,1)=3; % Not plugged-in
                            end
                        end
                    end

                elseif Users{n}.Logbook(TimeInd+TD.User-1,1)>=4
                    Users{n}.Logbook(TimeInd+TD.User,1)=4;
                end
            end


            if Users{n}.Logbook(TimeInd+TD.User,1)==4 && Users{n}.Logbook(TimeInd+TD.User,9)<Users{n}.BatterySize && (~ApplyGridConvenientCharging || Users{n}.GridConvenientChargingAvailability(mod(TimeInd+TD.User-1, 24*Time.StepInd)+1)) % Charging starts always when the car is plugged in, until the Battery is fully charged
                Users{n}.Logbook(TimeInd+TD.User,1)=5;  % vehicle is charging at its private charging point
                ChargingEnergy=min((Time.StepMin-Users{n}.Logbook(TimeInd+TD.User,2))*Users{n}.ACChargingPowerHomeCharging/60, Users{n}.BatterySize-Users{n}.Logbook(TimeInd+TD.User-1,9)); %[Wh]
                if UsePV && Users{n}.PVPlantExists
                    Users{n}.Logbook(TimeInd+TD.User,6)=min(single(PVPlants{Users{n}.PVPlant}.(PVPlants_Profile_Prediction)(TimeInd+TD.Main))/Users{n}.ChargingEfficiency, ChargingEnergy);
                end
                Users{n}.Logbook(TimeInd+TD.User,5)=ChargingEnergy-Users{n}.Logbook(TimeInd+TD.User,6); % The energy consumed fromt the spotmarkt equals the difference between the energy that needs to be charged and that is charged by pv electricity
            end


            if  Users{n}.Logbook(TimeInd+TD.User,9)<Users{n}.BatterySize && Users{n}.Logbook(TimeInd+TD.User,1)>=5 % vehicle is charging at its private or a public charging point
                Users{n}.Logbook(TimeInd+TD.User,9)=Users{n}.Logbook(TimeInd+TD.User,9)+sum(Users{n}.Logbook(TimeInd+TD.User,5:7));  % update the SoC
            end
        end
    
    elseif TimeInd>=TimesOfPreAlgo(1,1)     % Smart Charging scenario, if Algorithm 1 shall be executed this iteration
        
        ControlPeriodsIt=ControlPeriods-mod(TimeInd-TimesOfPreAlgo(1,1),96);      % How many indices until 8 am of day d + 2? One index step equals 15 min  
        
        if ismember(TimeInd, TimesOfPreAlgo)
            
            %% Algo 1 optimisation

            if ~UseSpotPredictions
                SpotmarktPricesCP=SpotmarketPrices(TimeInd+TD.User:TimeInd+TD.User+ControlPeriodsIt-1);
            end
            
            if ismember(TimeInd, TimesOfPreAlgo(1,:))

                PreAlgoCounter=PreAlgoCounter+1;        % Counter for the number of times Algorithm 1 was executed
                
                if UseSpotPredictions
                    SpotmarktPricesCP=[SpotmarketPrices(TimeInd+TD.User:TimeInd+TD.User + 24*Time.StepInd-mod(TimeInd-1,24*Time.StepInd)-1 + (mod(TimeInd-1,24*Time.StepInd)-13*Time.StepInd > 0)*96); SpotmarketPricesPred1(TimeInd+TD.SpotmarketPricesPred1 + 24*Time.StepInd-mod(TimeInd-1,24*Time.StepInd)-1 + (mod(TimeInd-1,24*Time.StepInd)-13*Time.StepInd > 0)*96+1:TimeInd+TD.SpotmarketPricesPred1+ControlPeriodsIt-1)];
                end
                
                CalcConsOptVars;                        % Update variables that only change at 8 am
                
            elseif UseSpotPredictions
                SpotmarktPricesCP=[SpotmarketPrices(TimeInd+TD.User:TimeInd+TD.User + 24*Time.StepInd-mod(TimeInd-1,24*Time.StepInd)-1 + (mod(TimeInd-1,24*Time.StepInd)-13*Time.StepInd > 0)*96); SpotmarketPricesPred2(TimeInd+TD.SpotmarketPricesPred2 + 24*Time.StepInd-mod(TimeInd-1,24*Time.StepInd)-1 + (mod(TimeInd-1,24*Time.StepInd)-13*Time.StepInd > 0)*96+1:TimeInd+TD.SpotmarketPricesPred2+ControlPeriodsIt-1)];
            end
           
            CalcDynOptVars;                             % Update variables that change each iteration of algorithm 1
            PreAlgo;                                    % Calculate optimal charging profiles (execute Algorithm 1)

            for n=UserNum  
                Users{n}.Logbook(TimeInd+TD.User:TimeInd+TD.User+ControlPeriodsIt-1, [false(1,4), true(1,length(CostCats))])=OptimalChargingEnergies(1:ControlPeriodsIt,:,n==UserNum);
            end
        end
        
        %% Algo 2 optimisation

        LiveAlgo;                                       % Execute Algorithm 2

        
        %%
           
        for n=UserNum % Battery clipping: In case the battery would be overcharged, clip the energy

            ChargedEnergy=min([Users{n}.BatterySize - (Users{n}.Logbook(TimeInd+TD.User-1, 9) - Users{n}.Logbook(TimeInd+TD.User, 4)), sum(Users{n}.Logbook(TimeInd+TD.User, 5:8))]);  % Energy that was charged during this time step [Wh]
            Users{n}.Logbook(TimeInd+TD.User, 9)=Users{n}.Logbook(TimeInd+TD.User-1, 9)-Users{n}.Logbook(TimeInd+TD.User, 4) + ChargedEnergy;
            if ChargedEnergy==0 && Users{n}.Logbook(TimeInd+TD.User, 1)==5
                Users{n}.Logbook(TimeInd+TD.User, 1)=4;
            end
            if ChargedEnergy < sum(Users{n}.Logbook(TimeInd+TD.User, 5:8)) - 0.01
                Users{n}.Logbook(TimeInd+TD.User, 5:8)=Users{n}.Logbook(TimeInd+TD.User, 5:8).*(ChargedEnergy/sum(Users{n}.Logbook(TimeInd+TD.User, 5:8)));
            end

        end
        
    end    
  
    
    if ActivateWaitbar %&& mod(TimeInd+TD.User,1000)==0
        waitbar(TimeInd/length(Time.Sim.Vec), h, strcat("Simulate charging processes: ", num2str(round(TimeInd/length(Time.Sim.Vec)*1000)/10),"%"));
    end
    
end


if FinishSimulation

%%
for n=UserNum
    Users{n}.Logbook(any(Users{n}.Logbook(:,5:7)>0,2),1)=5;
    AvailableBlocks=[find(ismember(Users{n}.Logbook(1:end,1),3:5) & ~ismember([0;Users{n}.Logbook(1:end-1,1)],3:5)), find(ismember(Users{n}.Logbook(1:end,1),3:5) & ~ismember([Users{n}.Logbook(2:end,1);0],3:5))];
    ChargingBlocks=any(AvailableBlocks(:,1)'<=find(Users{n}.Logbook(1:end,1)==5) & AvailableBlocks(:,2)'>=find(Users{n}.Logbook(1:end,1)==5))';
    for k=find(ChargingBlocks)'
        Users{n}.Logbook(AvailableBlocks(k,1):AvailableBlocks(k,2),1)=4;
    end
    Users{n}.Logbook(any(Users{n}.Logbook(:,5:7)>0,2),1)=5;
end

toc(TSim)

if ActivateWaitbar
    close(h);
end

if Users{1}.SmartCharging && SaveResults && NumUsers>5000
    Users{1}.Time.Stamp=datetime('now');
    Users{1}.FileName=strcat(Path.Simulation, "Users_", datestr(Users{1}.Time.Stamp, "yyyymmdd-HHMM"), "_", Time.IntervalFile, "_", num2str(length(Users)-1), "_", num2str(Users{1}.SmartCharging), "_", ".mat");
    save(Users{1}.FileName, "Users", "-v7.3");

    clearvars A ConsEnergyDemandTSA ConsEnergyDemandTSAIt Aeq b beq ConsSumPowerTSA ConseqEnergyCPA ConsSumPowerTSAIt ConseqEnergyCPAIt ConseqResPoOffer ConseqResPoOfferAIt ConseqMatchLastResPoOffers4HA ConseqMatchLastResPoOffers4HAIt Costf Costs OptimalChargingEnergies lb ub ConsPowerTSb PowerTS
end


for n=UserNum
    Users{n}.Logbook=Users{n}.Logbook(1:TimeInd,:);
    Users{n}.ConsumptionTotalYear_kWh=sum(double(Users{n}.Logbook(:,5:8))/Users{n}.ChargingEfficiency, 'all')/1000/(length(Users{n}.Logbook)/(24*Time.StepInd))*365.25;
    Users{n}.ConsumptionPrivateYear_kWh=sum(double(Users{n}.Logbook(:,5:7))/Users{n}.ChargingEfficiency, 'all')/1000/(length(Users{n}.Logbook)/(24*Time.StepInd))*365.25;
end

%% Store Simulation Information

Users{1}.UserNum=UserNum;
Users{1}.SpotmarketPrices=SpotmarketPrices;
Users{1}.TD.SpotmarketPrices=TD.SpotmarketPrices;
Users{1}.ApplyGridConvenientCharging=ApplyGridConvenientCharging;
Users{1}.UseSpotPredictions=UseSpotPredictions;
Users{1}.UsePVPredictions=UsePVPredictions;
Users{1}.UseIndividualEEGBonus=UseIndividualEEGBonus;
Users{1}.UsePV=UsePV;


if Users{1}.SmartCharging
    %Users{1}.ChargingMat=ChargingMat;
    
    for n=1:size(Users{1}.ChargingMat,1)-1
        Users{1}.ChargingMat{n,1}=Users{1}.ChargingMat{n,1}(:,:,1:PreAlgoCounter);
    end
    ResPoOffers=ResPoOffers(:,:,1:PreAlgoCounter+1);
    ResEnOffers=ResEnOffers(:,:,1:PreAlgoCounter+1);
    ProvidedResEn=ProvidedResEn(1:TimeInd);
    DispatchedResEn=DispatchedResEn(1:TimeInd);

    Users{1}.UseParallel=UseParallel;
    Users{1}.NumCostCats=NumCostCats;
    Users{1}.ControlPeriods=ControlPeriods;
    Users{1}.ShiftInds=ShiftInds;
    Users{1}.NumDecissionGroups=NumDecissionGroups;
    Users{1}.TimeOfPreAlgo=TimeOfPreAlgo;
    
    Users{1}.DispatchedResEn=DispatchedResEn;
    Users{1}.ProvidedResEn=ProvidedResEn;
    Users{1}.ResPoOffers=ResPoOffers;
    Users{1}.ResEnOffers=ResEnOffers;
    Users{1}.ResPoPriceFactor=ResPoPriceFactor;
    Users{1}.ResEnPriceFactor=ResEnPriceFactor;
    Users{1}.ConstantResPoPowerPeriodsScaling=ConstantResPoPowerPeriodsScaling;
    Users{1}.ConstantResPoPowerPeriods=ConstantResPoPowerPeriods;
    Users{1}.PublicChargingThresholdBuffer=PublicChargingThresholdBuffer;
    
    disp(strcat(num2str(sum(LastResPoOffersSuccessful4H(:,2:end)>0,'all')/sum(LastResPoOffers(:,2:end)>0,'all')*100), "% of all reserve power offers were successful"))
    
    Users{1}.ResEnVolumenFulfilled=0;
    for n=Users{1}.UserNum
        Users{1}.ResEnVolumenFulfilled=Users{1}.ResEnVolumenFulfilled+sum(Users{n}.Logbook(:,7))/Users{n}.ChargingEfficiency/1000; % Amount of energy that was actually charged as reserve energy [kWh]
    end
    
    toc(TSim)
    
    Users{1}.ResEnVolumenAllocated=sum(Users{1}.ResPoOffers(:,2,2:end),'all')*4/Users{1}.ConstantResPoPowerPeriodsScaling; % Amount of energy that was planned (all successful offers) to be charged as reserve energy [kWh]

    disp(strcat(num2str(Users{1}.ResEnVolumenFulfilled/Users{1}.ResEnVolumenAllocated*100), "% of the successfully offered reserve energy was actually charged"))
else
    Users{1}.ChargingMat=cell(1,2);
    Users{1}.ChargingMat{1}=zeros(96, 3, ceil(size(Users{UserNum(1)}.Logbook,1)/(24*Time.StepInd)));
end


%% Delete not simulated users

SimulatedUsers=@(User) (isfield(User, 'Time') || (isfield(User,"Logbook") && User.Logbook(2,9)>0) || (isfield(User,"Logbook") && User.Logbook(2,9)>0) || (isfield(User,"Logbook") && User.Logbook(2,9)>0));
Users=Users(cellfun(SimulatedUsers, Users));
Users{1}.Time.Stamp=datetime('now');
Users{1}.SimDuration=toc(TSim);


%% Calculate Load Profiles

Users{1}.ChargingMat{end,1}=zeros([24*Time.StepInd, size(Users{1}.ChargingMat{1,1}, 2),size(Users{1}.ChargingMat{1,1}, 3)], 'single');
for n=Users{1}.UserNum
    Users{1}.ChargingMat{end,1}=Users{1}.ChargingMat{end,1}+permute(reshape(Users{n}.Logbook(:,5:7),24*Time.StepInd,[],3), [1, 3, 2]);
end
Users{1}.ChargingMat{end,2}=96;

%% Plot Load Profiles

ChargingType=cell(size(Users{1}.ChargingMat,1),1);
ChargingSum=cell(size(Users{1}.ChargingMat,1),1);
Load=cell(size(Users{1}.ChargingMat,1),1);

for k=find(~cellfun(@isempty,Users{1}.ChargingMat(:,1)))'

    ChargingType{k}=reshape(permute(Users{1}.ChargingMat{k,1}(max(1,24*Time.StepInd-Users{1}.ChargingMat{k,2}+1):24*Time.StepInd-Users{1}.ChargingMat{k,2}+24*Time.StepInd,:,:), [1,3,2]), [], size(Users{1}.ChargingMat{k,1},2))/1000*4; %[kw]

    [sum(ChargingType{k}(:,1,:),'all'), sum(ChargingType{k}(:,2,:),'all'), sum(ChargingType{k}(:,3,:),'all')]/sum(ChargingType{k}(:,:,:),'all')
    ChargingSum{k}=sum(ChargingType{k}, 2);

    Load{k}=mean(reshape(ChargingType{k}',3,length(max(1,24*Time.StepInd-Users{1}.ChargingMat{k,2}+1):24*Time.StepInd-Users{1}.ChargingMat{k,2}+24*Time.StepInd),[]),3)';
    x = 1+96-size(Load{k},1):96;
    y = mean(reshape(ChargingSum{k}, size(Load{k},1), []), 2)';
    z = zeros(size(x));
    col = (Load{k}./repmat(max(Load{k}, [], 2),1,3))';

    figure(k)
    clf;
    surface([x;x],[y;y],[z;z],[permute(repmat(col,1,1,2),[3,2,1])], 'facecol','no', 'edgecol','interp', 'linew',2);
    xticks(1:16:96)
    xlim([1 96])
    xticklabels({datestr(Time.Vec(1:16:96),'HH:MM')})
    ylabel("Charging power in kW")
    xlabel("Time")
    if k<size(Users{1}.ChargingMat,1)
        title(strcat("Optimal charging energies for optimisation at ", datestr(Users{1}.TimeOfPreAlgo(k), "hh:MM")))
    else
        title(strcat("Optimal charging energies for optimisation in total"))
    end
    grid on


    hold on
    plot(x,squeeze(mean(reshape(ChargingType{k}(:,1),length(x),[],1),2)), "LineWidth", 1.2, "Color", [1, 0, 0])
    plot(x,squeeze(mean(reshape(ChargingType{k}(:,2),length(x),[],1),2)), "LineWidth", 1.2, "Color", [0, 1, 0])
    plot(x,squeeze(mean(reshape(ChargingType{k}(:,3),length(x),[],1),2)), "LineWidth", 1.2, "Color", [0, 0, 1])

    legend(["All", "Spotmarket", "PV", "Secondary Reserve Energy"])

end

%%  Plot charging availability

if Users{1}.SmartCharging
    figure(k+1)
    plot(datetime(1,1,1,0,0,0, 'TimeZone', 'Africa/Tunis'):minutes(Time.StepMin):datetime(1,1,1,23,45,0, 'TimeZone', 'Africa/Tunis'), circshift(mean(sum(Users{1}.AvailabilityMat,3),2), Users{1}.ShiftInds)/numel(Users{1}.UserNum))
    xticks(datetime(1,1,1,0,0,0, 'TimeZone', 'Africa/Tunis'):hours(4):datetime(1,1,2,0,0,0, 'TimeZone', 'Africa/Tunis'))
    xticklabels(datestr(datetime(1,1,1,0,0,0, 'TimeZone', 'Africa/Tunis'):hours(4):datetime(1,1,2,0,0,0, 'TimeZone', 'Africa/Tunis'), "HH:MM"))
end


%% Evaluate ResPo Offers

if Users{1}.SmartCharging
    Users{1}.ProvidedResEn(Users{1}.ProvidedResEn<1)=0;
    Users{1}.DispatchedResEn(Users{1}.DispatchedResEn<1)=0;
    Users{1}.ResPoRequestsUnderfulfillment=sum(abs(Users{1}.ProvidedResEn./Users{1}.DispatchedResEn(1:length(Users{1}.ProvidedResEn))-1)'>0.05);
    disp(strcat(num2str(sum(Users{1}.DispatchedResEn>0)), " reserve power requests were received from TSO. ", num2str(Users{1}.ResPoRequestsUnderfulfillment), " (", num2str(round(Users{1}.ResPoRequestsUnderfulfillment/sum(Users{1}.DispatchedResEn>0)*10000)/100), "%) of these were not performed properly."))
end

%% Evaluate  electricity costs

NNEExtraBasePrice=0;
NNEBonus=0;
IMSYSInstallationCosts=0;
if Users{1}.ApplyGridConvenientCharging
    IMSYSPrices=readmatrix(strcat(Path.Simulation, "IMSYS_Prices.csv"), 'NumHeaderLines', 1);
    for n=2:length(Users)
        if ~Users{n}.GridConvenientCharging
            Users{n}.NNEExtraBasePrice=0;
        elseif Users{n}.NNEExtraBasePrice~=20
            Users{n}.NNEExtraBasePrice=IMSYSPrices(Users{n}.ConsumptionPrivateYear_kWh>=IMSYSPrices(:,1) & Users{n}.ConsumptionPrivateYear_kWh<IMSYSPrices(:,2),4)*100;
        end
        
        NNEExtraBasePrice=NNEExtraBasePrice+Users{n}.NNEExtraBasePrice;
        NNEBonus=NNEBonus+Users{n}.NNEBonus;
        IMSYSInstallationCosts=0;%IMSYSInstallationCosts+Users{n}.IMSYSInstallationCosts;
    end
end


if ~Users{1}.SmartCharging
    TotalCostsBase=zeros(9,7);
    
    for n=2:length(Users)
        
        if isfield(Users{n}, "Logbook")
        
            TotalCostsBase(1,1:4)=TotalCostsBase(1,1:4)+sum(Users{n}.Logbook(:,5:8)/1000/Users{n}.ChargingEfficiency, 1);

            Users{n}.FinListBase=zeros(length(Users{n}.Logbook),4, 'single');
            Users{n}.FinListBase(:,1)=single(Users{n}.Logbook(:,5)/1000/Users{n}.ChargingEfficiency .* (Users{n}.PrivateElectricityPrice + Users{1}.SpotmarketPrices(Time.Sim.VecInd(1:length(Users{n}.Logbook(:,5)))+Users{1}.TD.SpotmarketPrices)/10 + Users{n}.NNEEnergyPrice)*Users{1}.MwSt); % [ct] total electricity costs equal base price of user + realtime current production costs + NNE energy price. VAT applies to the end price
            Users{n}.FinListBase(:,2)=single(Users{n}.Logbook(:,6)/1000/Users{n}.ChargingEfficiency .* Users{n}.EEGBonus); % [ct] costs for not selling the PV power to the DSO
            Users{n}.FinListBase(:,3)=zeros(length(Users{n}.Logbook(:,7)),1, 'single');
            Users{n}.FinListBase(:,4)=single(Users{n}.Logbook(:,8)/1000/Users{n}.ChargingEfficiency .* Users{n}.PublicACChargingPrices.*double(Users{n}.Logbook(:,1)==6) + double(Users{n}.Logbook(:,8))/1000/Users{n}.ChargingEfficiency .* Users{n}.PublicDCChargingPrices.*double(Users{n}.Logbook(:,1)==7)); % [ct] fixed price for public AC and DC charging
            TotalCostsBase(2,1:4)=TotalCostsBase(2,1:4)+sum(Users{n}.FinListBase, 1);
            
        end
    end
    
    TotalCostsBase(1:2,6)=sum(TotalCostsBase(1:2,1:4),2);
    TotalCostsBase(3,:)=TotalCostsBase(2,:)./TotalCostsBase(1,:);
    TotalCostsBase(1:2,7)=TotalCostsBase(1:2,6)/(length(Users)-1);
    TotalCostsBase(1:2,8)=TotalCostsBase(1:2,6)/(length(Users)-1)/(length(Users{2}.Logbook)/(24*Time.StepInd))*365;
    TotalCostsBase(2,:)=TotalCostsBase(2,:)/100;
    TotalCostsBase(5,6:8)=[NNEExtraBasePrice / 365*(length(Users{2}.Logbook)/(24*Time.StepInd)), NNEExtraBasePrice/(length(Users)-1), NNEExtraBasePrice/(length(Users)-1)]/100;
    TotalCostsBase(6,6:8)=[NNEBonus / 365*(length(Users{2}.Logbook)/(24*Time.StepInd))/10, NNEBonus / 365*(length(Users{2}.Logbook)/(24*Time.StepInd))/10 / (length(Users)-1), NNEBonus/(length(Users)-1)/10]/100;
    TotalCostsBase(7,6:8)=[IMSYSInstallationCosts / 365*(length(Users{2}.Logbook)/(24*Time.StepInd))/10, IMSYSInstallationCosts / 365*(length(Users{2}.Logbook)/(24*Time.StepInd))/10 / (length(Users)-1), IMSYSInstallationCosts/(length(Users)-1)/10]/100;
    TotalCostsBase(9,6:8)=TotalCostsBase(2,6:8)+sum(TotalCostsBase([5,7],6:8),1);
    
    TotalCostsBase=table(TotalCostsBase(:,1), TotalCostsBase(:,2), TotalCostsBase(:,3), TotalCostsBase(:,4), TotalCostsBase(:,5), TotalCostsBase(:,6), TotalCostsBase(:,7),TotalCostsBase(:,8), 'RowNames',["Energy charged in kWh"; "Energy Costs in EUR"; "Energy Costs in ct/kWh"; "."; "NNE Extra Base Price in EUR"; "NNE Bonus in EUR"; "IMSYS Installation Costs in EUR"; "~"; "Total Costs in EUR"], 'VariableNames',{'Grid','PV','aFRR','Public','ResPoOffered_kW','Total','TotalPerUser', 'TotalPerUserPerYear'});
    TotalCostsBase=[TotalCostsBase; table([0;Users{1}.SmartCharging; Users{1}.ApplyGridConvenientCharging; length(Users)-1; Users{1}.UseSpotPredictions; Users{1}.UsePVPredictions; Users{1}.UseIndividualEEGBonus; Users{1}.SimDuration/3600], zeros(8,1),zeros(8,1),zeros(8,1),zeros(8,1),zeros(8,1),zeros(8,1),zeros(8,1), 'RowNames',["/"; "SmartCharging"; "ApplyGridConvenientCharging"; "NumUsers"; "UseSpotPredictions"; "UsePVPreditions"; "UseIndividualEEGBonus"; "SimulationDuration in h"], 'VariableNames',{'Grid','PV','aFRR','Public','ResPoOffered_kW','Total','TotalPerUser', 'TotalPerUserPerYear'})];
    
    Users{1}.TotalCostsIt{end+1}=TotalCostsBase;
    
    disp(strcat("Costs for base charging the fleet were ", string(table2cell((TotalCostsBase(2,8)))), "EUR per user per year"));
end

if Users{1}.SmartCharging
    TotalCostsSmart=zeros(9,7); % [kWh (6. column kW); EUR; ct/kWh]
    Users{1}.ResEnOffersList=repelem(reshape(Users{1}.ResEnOffers(:,1,1:end-1),[],1),4*Time.StepInd/Users{1}.ConstantResPoPowerPeriodsScaling);

    for n=2:length(Users)
        
        if isfield(Users{n}, "Logbook")
            TotalCostsSmart(1,1:4)=TotalCostsSmart(1,1:4)+sum(Users{n}.Logbook(:,5:8)/1000/Users{n}.ChargingEfficiency, 1);

            Users{n}.FinListSmart=zeros(length(Users{n}.Logbook),4, 'single');
            Users{n}.FinListSmart(:,1)=single(Users{n}.Logbook(:,5)/1000/Users{n}.ChargingEfficiency .* (Users{n}.PrivateElectricityPrice + Users{1}.SpotmarketPrices(Users{1}.Time.VecInd(1:length(Users{n}.Logbook(:,5)))+Users{1}.TD.SpotmarketPrices)/10 + Users{n}.NNEEnergyPrice)*Users{1}.MwSt); % [ct] total electricity costs equal base price of user + realtime current production costs + NNE energy price. VAT applies to the end price
            Users{n}.FinListSmart(:,2)=single(Users{n}.Logbook(:,6)/1000/Users{n}.ChargingEfficiency .* Users{n}.EEGBonus); % [ct] costs for not selling the PV power to the DSO
            Users{n}.FinListSmart(:,3)=single(Users{n}.Logbook(:,7)/1000/Users{n}.ChargingEfficiency .* (Users{n}.PrivateElectricityPrice + Users{1}.ResEnOffersList/100 + Users{n}.NNEEnergyPrice)*Users{1}.MwSt); % [ct] total electricity costs equal base price of user + realtime current production costs + NNE energy price. VAT applies to the end price
            Users{n}.FinListSmart(:,4)=single(Users{n}.Logbook(:,8)/1000/Users{n}.ChargingEfficiency .* Users{n}.PublicACChargingPrices.*double(Users{n}.Logbook(:,1)==6) + double(Users{n}.Logbook(:,8))/1000/Users{n}.ChargingEfficiency .* Users{n}.PublicDCChargingPrices.*double(Users{n}.Logbook(:,1)==7)); % [ct] fixed price for public AC and DC charging
            TotalCostsSmart(2,1:4)=TotalCostsSmart(2,1:4)+sum(Users{n}.FinListSmart, 1);
        end
    end
    
    TotalCostsSmart(1,5)=sum(Users{1}.ResPoOffers(:,2,:),'all') / (4*Time.StepInd) * Users{1}.ConstantResPoPowerPeriods; % [kW]
    TotalCostsSmart(2,5)=-sum(Users{1}.ResPoOffers(:,1,:).*Users{1}.ResPoOffers(:,2,:),'all') / (4*Time.StepInd) * Users{1}.ConstantResPoPowerPeriods * 100; % [EUR/kW]*[kW]
    TotalCostsSmart(3,:)=TotalCostsSmart(2,:)./TotalCostsSmart(1,:);
    TotalCostsSmart(1,6)=sum(TotalCostsSmart(1,1:4));
    TotalCostsSmart(2,6)=sum(TotalCostsSmart(2,1:5),2);
    TotalCostsSmart(3,6)=TotalCostsSmart(2,6)/TotalCostsSmart(1,6);
    TotalCostsSmart(1:2,7)=TotalCostsSmart(1:2,6)/(length(Users)-1);
    TotalCostsSmart(1:2,8)=TotalCostsSmart(1:2,6)/(length(Users)-1)/(length(Users{2}.Logbook)/(24*Time.StepInd))*365;
    TotalCostsSmart(3,7:8)=TotalCostsSmart(3,6);
    TotalCostsSmart(2,:)=TotalCostsSmart(2,:)/100;
    TotalCostsSmart(5,6:8)=[NNEExtraBasePrice / 365*(length(Users{2}.Logbook)/(24*Time.StepInd)), NNEExtraBasePrice/(length(Users)-1), NNEExtraBasePrice/(length(Users)-1)]/100;
    TotalCostsSmart(6,6:8)=-[NNEBonus / 365*(length(Users{2}.Logbook)/(24*Time.StepInd))/10, NNEBonus / 365*(length(Users{2}.Logbook)/(24*Time.StepInd))/10 / (length(Users)-1), NNEBonus/(length(Users)-1)/10]/100;
    TotalCostsSmart(7,6:8)=[IMSYSInstallationCosts / 365*(length(Users{2}.Logbook)/(24*Time.StepInd))/10, IMSYSInstallationCosts / 365*(length(Users{2}.Logbook)/(24*Time.StepInd))/10 / (length(Users)-1), IMSYSInstallationCosts/(length(Users)-1)/10]/100;
    TotalCostsSmart(9,6:8)=TotalCostsSmart(2,6:8)+sum(TotalCostsSmart([5,7],6:8),1);
    
    TotalCostsSmart=table(TotalCostsSmart(:,1), TotalCostsSmart(:,2), TotalCostsSmart(:,3), TotalCostsSmart(:,4), TotalCostsSmart(:,5), TotalCostsSmart(:,6), TotalCostsSmart(:,7),TotalCostsSmart(:,8), 'RowNames',["Energy charged in kWh"; "Energy Costs in EUR"; "Energy Costs in ct/kWh"; "."; "NNE Extra Base Price in EUR"; "NNE Bonus in EUR"; "IMSYS Installation Costs in EUR"; "~"; "Total Costs in EUR"], 'VariableNames',{'Grid','PV','aFRR','Public','ResPoOffered_kW','Total','TotalPerUser', 'TotalPerUserPerYear'});
    TotalCostsSmart=[TotalCostsSmart; table([0;Users{1}.ResEnVolumenAllocated;Users{1}.ResEnVolumenFulfilled/Users{1}.ResEnVolumenAllocated; round(Users{1}.ResPoRequestsUnderfulfillment/sum(Users{1}.DispatchedResEn>0)*10000)/100; Users{1}.ResPoPriceFactor;Users{1}.ResEnPriceFactor;0;Users{1}.SmartCharging; Users{1}.ApplyGridConvenientCharging; length(Users)-1; Users{1}.UseParallel; Users{1}.NumDecissionGroups; Users{1}.UseSpotPredictions; Users{1}.UsePVPredictions; Users{1}.UseIndividualEEGBonus; Users{1}.SimDuration/3600;], zeros(16,1),zeros(16,1),zeros(16,1),zeros(16,1),zeros(16,1),zeros(16,1),zeros(16,1), 'RowNames',["-"; "Planned Reserve Energy in Opt 5 in kWh"; "Share Activated/Planned Renserve Energy in kWh"; "ResEn underfulfillment rate in %"; "ResPoPriceFactor"; "ResEnPriceFactor"; "/"; "SmartCharging"; "ApplyGridConvenientCharging"; "NumUsers"; "UseParallel"; "NumDecissionGroups"; "UseSpotPredictions"; "UsePVPreditions"; "UseIndividualEEGBonus"; "SimulationDuration in h"], 'VariableNames',{'Grid','PV','aFRR','Public','ResPoOffered_kW','Total','TotalPerUser', 'TotalPerUserPerYear'})];    
    
    disp(strcat("Total costs for smart charging the fleet were ", string(table2cell((TotalCostsSmart(2,8)))), "EUR per User per year"));
    
    Users{1}.TotalCostsIt{end+1}=TotalCostsSmart;
end


%% Save data

Users{1}.FileName=strcat(Path.Simulation, "Users_", datestr(Users{1}.Time.Stamp, "yyyymmdd-HHMM"), "_", Time.IntervalFile, "_", num2str(length(Users)-1), "_", num2str(Users{1}.SmartCharging), "_", ".mat");

if SaveResults
    save(Users{1}.FileName, "Users", "-v7.3");
end
disp(strcat("Successfully simulated within ", num2str(Users{1}.SimDuration), " seconds"))

end

if CleanUpWorkspace

%% Clean up workspace
 
clearvars TimeInd TD.User n ActivateWaitbar Consumption24h ParkingDuration ConsumptionTilNextHomeStop TripDistance
clearvars NextHomeStop PublicChargerPower ChargingPower EnergyDemandLeft TimeStepIndsNeededForCharging EndOfShift
clearvars NumPredMethod TotalIterations NumUsers TimeOfForecast P PlugInTime PThreshold
clearvars SimulatedUsers PublicChargerDistribution h k UserNum UsePV UsePredictions UseParallel TSim TimeInd temp  
clearvars SpotmarketPrices PVPlants_Profile_Prediction ApplyGridConvenientCharging ChargingEnergy ConnectionDurations24h ControlPeriods IMSYSPrices n
clearvars SmartCharging SaveResults ResEnVolumen

clearvars x y z Load ChargingBlocks ChargingSum ChargingType AvailableBlocks col

clearvars A Aeq Availability AvailabilityOrder AvailableDispatchedResEn AvailableDispatchedResEnBuffer AvailableDispatchedResEnMax
clearvars b beq ChargedEnergy ChargingInds ConnectionDurations24h ConsEnergyDemandTSA ConsEnergyDemandTSAIt ConseqEnergyCPA ConseqEnergyCPAIt ConseqMatchLastResPoOffers4HA
clearvars ConseqMatchLastResPoOffers4HAIt ConseqMatchLastResPoOffers4HbIt ConseqMaxEnergyChargableDeadlockCPbIt ConseqResPoOfferA
clearvars ConseqResPoOfferAIt ConseqResPoOfferbIt ConsMaxEnergyChargableSoCTSbIt ConsMinEnergyRequiredTSbIt ConsPeriods ConsPowerTSb
clearvars ConsSumPowerTSA ConsSumPowerTSAIt ConsSumPowerTSbIt ConstantResPoPowerPeriods Consumed Consumption24h ConsumptionMat ConsumptionTilNextHomeStop
clearvars ControlPeriods ControlPeriodsIt CostCats CostsElectricityBase CostsPV CostsReserveMarket CostsSpotmarket DecissionGroups DelCols DelCols2
clearvars DelRows DelRows2 DemandInds EnergyDemand fval HourlyPowerAvailability HourlySpotmarketPowers l lb MaxEnergyChargableDeadlockCP
clearvars MaxEnergyChargableDeadlockTS MaxEnergyChargableSoCTS MaxPossibleSoCTS MaxPower MinEnergyRequiredTS MOLPos n NumCostCats NumDecissionGroups
clearvars OfferedResPo OptimalChargingEnergies OptimalChargingEnergiesSpotmarket options p PowerTS PreAlgoCounter Pred PriorityChargingList
clearvars PVPower ResEnMOL ResEnOfferPrices ResEnOffersList ResEnPriceFactor ResEnVolumenAllocated ResEnVolumenFulfilled
clearvars ResPoBlockedIndices ResPoBuffer ResPoOfferEqualiyMat1 ResPoOfferEqualiyMat2 ResPoOfferPrices ResPoPriceFactor Row ShiftInds
clearvars SoC SoCNew SortedOrder SpotmarketPrices SpotmarktPricesCP StorageFile StoragePath SubIndices SumPower Temp TimeOfDayAheadMarketPriceRelease
clearvars TimeOfPreAlgo TimeOfReserveMarketOffer TimesOfDayAheadMarketPriceRelease TimesOfPreAlgo TimesOfResPoEval TimeStepIndsNeededForCharging
clearvars TSOResPoDemand ub VarCounter Costf Costs ChargingVehicle Costsf NNEBonus NNEExtraBasePrice IMSYSInstallationCosts IMSYSInstallationCostsMean
clearvars UseIndividualEEGBonus UsePVPredictions UseSpotPredictions x1 BackwardsOrder FinishSimulation CleanUpWorkspace InitialiseUserNew OwnOfferMOLPos 
clearvars UseParallelAvailability UnsolvedProblems TimeIndVec SuccessfulResPoOffers SpotmarketPricesPred1 SpotmarktPricesCP SoCInit PVPowerReal
clearvars PublicChargingThresholds_Wh PublicChargerDist ProvidedResEn MOLPos1 Logbooks1 Logbooks2 Logbooks4 LastResPoOffersSuccessful4H LastResPoOffers ConstantResPoPowerPeriodsScaling
clearvars GridConvenientChargingAvailabilityControlPeriod Exceeds EEGBonus DispatchedResEn DelRows3 Debugging Costf1 ConstantResPoPowerPeriods ChargingEfficiencies BatterySizes

end

