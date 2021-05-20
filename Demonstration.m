%% Description
% This script is a demonstrator for conducted simulations. It provides for
% plots that show several variables in course of the simulation, from the
% start of the simulation until the end. Fleet characterisitcs as well as
% the data of a demo user are shown. The first plot compares the spot
% market predictions to the real spot market prices. The second plot
% compares the predicted pv power of the demo user's plant to the real
% generated pv power. The third plot shows the demo user's energy demand
% thorugh driving, charged energy and the resulting vehicle's SoC. Plot
% number four visualises the load profile of the fleet split into the three
% electricity sources. The demonstartion consists of optimisation phases
% and time progress phases. During the optimisation phases, which are
% present every four hours, the charging schedules are updated and during
% the optimisation phase at 8 am, the spot market forecasts are
% recalculated. During the time progress phases, the user are actually
% driving and charging. Another figure show the characteristics of the demo
% user. In order to use the demonstrator, three files must
% be downloaded: Data for the spot market prediction using the LS method,
% data for the spot market prediction using NARXNETs and the simulated user
% data. If ChoseDataByDialogBox is set to true, the path of the files can 
% specified usign a file selection dialog box or, else the paths are
% specified by the variables set at the beginning of this script.
%
% Depended scripts / folders
%   Initialisation.m        Needed for the execution of this script
%   Demonstration           This script calls all four files in folder
%                           Demonstration


%% Set paths of the required files

ChoseDataByDialogBox=false; % if true, the paths of the three files can be specified by a dialog box, else use the variables below

if ~ChoseDataByDialogBox
    SpotmarketPredictionPath=strcat(Path.Prediction, "DayaheadRealH", Dl); % path where the spotmarket data is stored
    LSQFile="LSQ_20210202-1210_20180101-20200831_52h_232Preds_8hr.mat"; % file name of the spotmarket prediction data using the LS method
    NARXNETFile="NARXNET_20210202-1249_20180101-20200831_52h_78Preds_8hr.mat"; % file name of the spotmarket prediction data using NARXNETs
    UsersFile="UsersSim20000FinListSingleDemo.mat"; % file name of the user data. Path.Simulation is set as the standard path for this file. It ist specified in Initialisation.m

    LSQFilePath=strcat(SpotmarketPredictionPath, LSQFile);
    NARXNETFilePath=strcat(SpotmarketPredictionPath, NARXNETFile);
    UsersFilePath=strcat(Path.Simulation, UsersFile);
end


%% Initialisation

Time.Demo.StepInd=1; % varying this variable changes the speed of the demonstration during the time progress phases. Using a higher value will plot several time steps at once, while using "1" will only plot one time step per time.
Time.Demo.StepIndForecast=8; % varying this variable changes the speed of the demonstration during the optimisation phases. Using a higher value will plot several time steps at once, while using "1" will only plot one time step per time.

TimeOfForecast=datetime(1,1,1,08,0,0,'TimeZone','Africa/Tunis'); % time of day when the forecast are calculated
Time.Demo.Step=minutes(60);
ForecastIntervalInd=48*Time.StepInd;
ChargingMatNumber=1;

clearvars DemoPlots
tic


%% Plot #1: Spotmarket prices

n=1; 
DemoPlots{n}.Title=strcat("Dayahead auction price"); 
DemoPlots{n}.LegendLocation="northwest";
DemoPlots{n}.Ytickformat='%.0f';

k=1; % graph #1
DemoPlots{n}.Data{k}=repelem(Smard.DayaheadRealH, 4); % Spot market data is present in one hour time steps, hence interpolate it using constant values during one hour
DemoPlots{n}.Time.Vec{k}=Time.Vec;
DemoPlots{n}.Label{k}="Price";
DemoPlots{n}.YLabel{k}="Price in EUR/MWh";
DemoPlots{n}.YMin{k}='dynamic'; % scale y axis dynamically
DemoPlots{n}.YMax{k}='dynamic'; % scale y axis dynamically
DemoPlots{n}.YAxis{k}=1;
DemoPlots{n}.PlotColor{k}=k;

k=2; % graph #2
DemoPlots{n}.Label{k}="Prediction LS";
DemoPlots{n}.YLabel{k}="Price in EUR/MWh";
if size(DemoPlots{n}.Data)<=1
    if ChoseDataByDialogBox
        if exist('SpotmarketPredictionPath', 'var') && isfolder(SpotmarketPredictionPath)
            [LSQFile, SpotmarketPredictionPath]=uigetfile(SpotmarketPredictionPath, strcat("Select ", DemoPlots{n}.Title, " ", DemoPlots{n}.Label{k}));
        else
            [LSQFile, SpotmarketPredictionPath]=uigetfile('', strcat("Select ", DemoPlots{n}.Title, " ", DemoPlots{n}.Label{k}));
        end
        LSQFilePath=strcat(SpotmarketPredictionPath,LSQFile);
    end
    load(LSQFilePath)
    DemoPlots{n}.Data{k}=repelem(Pred.Data, Time.StepInd/Pred.Time.StepPredInd);
    DemoPlots{n}.DataMat{1,k}=repelem(Pred.DataMat(:,find(Pred.Time.Pred>Pred.Time.EndTrain,1):end), Time.StepInd/Pred.Time.StepPredInd, Time.StepInd/Pred.Time.StepPredInd);
end
DemoPlots{n}.Time.Vec{k}=repelem(Pred.Time.Pred(find(Pred.Time.Pred>Pred.Time.EndTrain,1):end), Time.StepInd/Pred.Time.StepPredInd, Time.StepInd/Pred.Time.StepPredInd);
DemoPlots{n}.YMin{k}='dynamic';
DemoPlots{n}.YMax{k}='dynamic';
DemoPlots{n}.YAxis{k}=1;
DemoPlots{n}.PlotColor{k}=k;

k=3; % graph #3
DemoPlots{n}.Label{k}="Prediction NARXNET";
DemoPlots{n}.YLabel{k}="Price in EUR/MWh";
if length(DemoPlots{n}.Data)<=2
    if ChoseDataByDialogBox
        if exist('SpotmarketPredictionPath', 'var') && isfolder(SpotmarketPredictionPath)
            [NARXNETFile, SpotmarketPredictionPath]=uigetfile(SpotmarketPredictionPath, strcat("Select ", DemoPlots{n}.Title, " ", DemoPlots{n}.Label{k}));
        else
            [NARXNETFile, SpotmarketPredictionPath]=uigetfile('', strcat("Select ", DemoPlots{n}.Title, " ", DemoPlots{n}.Label{k}));
        end
        NARXNETFilePath=strcat(SpotmarketPredictionPath, NARXNETFile);
    end
    load(NARXNETFilePath)
    DemoPlots{n}.Data{k}=repelem(Pred.Data, Time.StepInd/Pred.Time.StepPredInd);
    DemoPlots{n}.DataMat{1,k}=repelem(Pred.DataMat(:,find(Pred.Time.Pred>Pred.Time.EndTrain,1):end), Time.StepInd/Pred.Time.StepPredInd,Time.StepInd/Pred.Time.StepPredInd);
end
DemoPlots{n}.Time.Vec{k}=repelem(Pred.Time.Pred(find(Pred.Time.Pred>Pred.Time.EndTrain,1):end), Time.StepInd/Pred.Time.StepPredInd, Time.StepInd/Pred.Time.StepPredInd);

DemoPlots{n}.YMin{k}='dynamic';
DemoPlots{n}.YMax{k}='dynamic';
DemoPlots{n}.YAxis{k}=1;
DemoPlots{n}.PlotColor{k}=k;


%% Plot #2: PV power of DemoUser

n=2;
if ~exist("Users", "var")
    if ChoseDataByDialogBox
        if isfolder(SpotmarketPredictionPath)
            UsersFile=uigetfile(Path.Simulation, "Select the user data"');
        else
            UsersFile=uigetfile('', "Select the user data"');
        end
        UsersFilePath=strcat(Path.Simulation, UsersFile);
    end
    load(UsersFilePath)
end

DemoUser=2; % find a Demo user who has a high but not too unrealistiv high mileage, has a not too low AC charging power, uses public charging points but not too frequently and owns a pv plant
while Users{DemoUser}.AverageMileageYear_km<22000 || Users{DemoUser}.AverageMileageYear_km>50000 || Users{DemoUser}.ACChargingPowerHomeCharging<4000 || sum(Users{DemoUser}.Logbook(:,8)>0)/length(Users{DemoUser}.Logbook(:,4))>0.05 || sum(Users{DemoUser}.Logbook(:,8)>0)/length(Users{DemoUser}.Logbook(:,4))<0.005  || ~Users{DemoUser}.PVPlantExists
    DemoUser=DemoUser+1;
end

DemoPlots{n}.Title=strcat("PV power of user ", num2str(DemoUser));
DemoPlots{n}.LegendLocation="northwest";
DemoPlots{n}.Ytickformat='%.0f';

k=1; % graph #1
DemoPlots{n}.Data{k}=double(PVPlants{Users{DemoUser}.PVPlant}.ProfileQH)/1000; % [kW]
DemoPlots{n}.Time.Vec{k}=Time.Vec;
DemoPlots{n}.Label{k}=strcat("Generation");
DemoPlots{n}.YLabel{k}="Power in kW";
DemoPlots{n}.YMin{k}=-0.1;
DemoPlots{n}.YMax{k}=max(DemoPlots{n}.Data{k});
DemoPlots{n}.YAxis{k}=1;
DemoPlots{n}.PlotColor{k}=k;

k=2; % graph #2
DemoPlots{n}.Data{k}=double(PVPlants{Users{DemoUser}.PVPlant}.PredictionQH)/1000; % [kW]
temp=reshape(PVPlants{Users{DemoUser}.PVPlant}.PredictionQH(Users{1}.ShiftInds+1:end-96+Users{1}.ShiftInds), 96,[]);
temp1=[temp(:,2:end), zeros(96,1)];
DemoPlots{n}.DataMat{k}=repelem(double([temp;temp1]),1,Time.StepInd*24)/1000;
DemoPlots{n}.Time.Vec{k}=Time.Vec;
DemoPlots{n}.Label{k}=strcat("Prediction");
DemoPlots{n}.YLabel{k}="Power in kW";
DemoPlots{n}.YMin{k}=-0.1;
DemoPlots{n}.YMax{k}=max(DemoPlots{n}.Data{k});
DemoPlots{n}.YAxis{k}=1;
DemoPlots{n}.PlotColor{k}=k;


%% Plot #3: Vehicle porperties of DemoUser

n=3;
DemoPlots{n}.Title=strcat("Vehicle properties of user ", num2str(DemoUser));
DemoPlots{n}.LegendLocation="northeast";
DemoPlots{n}.Ytickformat='%.0f';

k=1; % graph #1
DemoPlots{n}.Data{k}=double(Users{DemoUser}.Logbook(:,9))/double(Users{DemoUser}.BatterySize)*100;
DemoPlots{n}.Time.Vec{k}=Users{1}.Time.Vec;
DemoPlots{n}.Label{k}="SoC";
DemoPlots{n}.YLabel{k}="SoC in %";
DemoPlots{n}.YMin{k}=-1;
DemoPlots{n}.YMax{k}=115;
DemoPlots{n}.YAxis{k}=1;
DemoPlots{n}.PlotColor{k}=k;

k=2; % graph #2
DemandForecastMat=zeros(ForecastIntervalInd,length(Users{DemoUser}.Logbook));
for l=1:length(Users{DemoUser}.Logbook)-ForecastIntervalInd
    DemandForecastMat(:,l)=double(Users{DemoUser}.Logbook(l:l+ForecastIntervalInd-1,4));
end
Demand=double(Users{DemoUser}.Logbook(:,4));
DemoPlots{n}.Data{k}=Demand/1000*4;
DemoPlots{n}.DataSource{k}=Users{DemoUser}.Logbook(:,4)/1000*4;
DemoPlots{n}.DataMat{k}=DemandForecastMat/1000*4;
DemoPlots{n}.Time.Vec{k}=Users{1}.Time.Vec(1:length(Users{DemoUser}.Logbook)-ForecastIntervalInd);
DemoPlots{n}.Label{k}="Demand plan";
DemoPlots{n}.YLabel{k}="Power in kW";
DemoPlots{n}.YMin{k}=0.01;
DemoPlots{n}.YMax{k}='dynamic';
DemoPlots{n}.YAxis{k}=2;
DemoPlots{n}.PlotColor{k}=k;

k=3; % graph #3
ChargingDemoUser=squeeze(sum(Users{1}.ChargingMatDemoUsers{ChargingMatNumber,1}(:,:,DemoUser-1,:),2));
ChargingDemoUserMat=[zeros(ForecastIntervalInd, Users{1}.ChargingMatDemoUsers{ChargingMatNumber,2}),  repelem(ChargingDemoUser, 1, 24*Time.StepInd)];
ChargingDemoUser=[zeros(Users{1}.ChargingMatDemoUsers{ChargingMatNumber,2},1); reshape(ChargingDemoUser(1:96,:), [], 1)];
ChargingDemoUserMat=cell(6,1);
for l=1:6    
    ChargingDemoUserMat{l}=repelem(squeeze(sum(Users{1}.ChargingMatDemoUsers{l,1}(:,:,DemoUser-1,:),2)), 1,24*Time.StepInd,1)/1000*4;
end   



DemoPlots{n}.Data{k}=sum(Users{DemoUser}.Logbook(:,5:7), 2)/1000*4;
for l=1:6
    DemoPlots{n}.DataMat{l,k}=[zeros(ForecastIntervalInd,96*floor(l/5)),[zeros(ForecastIntervalInd-size(ChargingDemoUserMat{l},1),size(ChargingDemoUserMat{l},2));squeeze(ChargingDemoUserMat{l})]];
end
DemoPlots{n}.Time.Vec{k}=Users{1}.Time.Vec;
DemoPlots{n}.Label{k}="Private charging";
DemoPlots{n}.YLabel{k}="Power in kW";
DemoPlots{n}.YMin{k}=0.01;
DemoPlots{n}.YMax{k}='dynamic';
DemoPlots{n}.YAxis{k}=2;
DemoPlots{n}.PlotColor{k}=k;


k=4; % graph #4
DemoPlots{n}.Data{k}=sum(Users{DemoUser}.Logbook(:,8), 2)/1000*4;
DemoPlots{n}.Time.Vec{k}=Users{1}.Time.Vec;
DemoPlots{n}.Label{k}="Public charging";
DemoPlots{n}.YLabel{k}="Power in kW";
DemoPlots{n}.YMin{k}=0.01;
DemoPlots{n}.YMax{k}='dynamic';
DemoPlots{n}.YAxis{k}=2;
DemoPlots{n}.PlotColor{k}=k;


%% Plot #4: Load curve of fleet

n=4;
DemoPlots{n}.Title=strcat("Load curve of the fleet");
DemoPlots{n}.LegendLocation="northwest";
DemoPlots{n}.Ytickformat='%.0f';

ChargingTypeLive=reshape(permute(Users{1}.ChargingMat{7,1}(1:96,:,:), [1,3,2]), [], Users{1}.NumCostCats)/1000/1000*4;
ChargingTypeMat=cell(6,1);
for l=1:6
    ChargingTypeMat{l}=repelem(permute(Users{1}.ChargingMat{l,1},[1,3,2]), 1,24*Time.StepInd,1)/1000/1000*4;
end    

k=1; % graph #1
DemoPlots{n}.Data{k}=ChargingTypeLive(:,k);
DemoPlots{n}.DataSource{k}=ChargingTypeLive(:,k);
for l=1:6
    DemoPlots{n}.DataMat{l,k}=[zeros(ForecastIntervalInd,96*floor(l/5)),[zeros(ForecastIntervalInd-size(ChargingTypeMat{l},1),size(ChargingTypeMat{l},2));squeeze(ChargingTypeMat{l}(:,:,k))]];
end
DemoPlots{n}.Time.Vec{k}=Users{1}.Time.Vec;
DemoPlots{n}.Label{k}="Spot market";
DemoPlots{n}.YLabel{k}="Charging Power in MW";
DemoPlots{n}.YMin{k}=-1;
DemoPlots{n}.YMax{k}='dynamic';
DemoPlots{n}.YAxis{k}=1;
DemoPlots{n}.PlotColor{k}=8;

k=2; % graph #2
DemoPlots{n}.Data{k}=ChargingTypeLive(:,k);
DemoPlots{n}.DataSource{k}=ChargingTypeLive(:,k);
for l=1:6
    DemoPlots{n}.DataMat{l,k}=[zeros(ForecastIntervalInd,96*floor(l/5)),[zeros(ForecastIntervalInd-size(ChargingTypeMat{l},1),size(ChargingTypeMat{l},2));squeeze(ChargingTypeMat{l}(:,:,k))]];
end
DemoPlots{n}.Time.Vec{k}=Users{1}.Time.Vec;
DemoPlots{n}.Label{k}="PV";
DemoPlots{n}.YLabel{k}="Charging Power in MW";
DemoPlots{n}.YMin{k}=-1;
DemoPlots{n}.YMax{k}='dynamic';
DemoPlots{n}.YAxis{k}=1;
DemoPlots{n}.PlotColor{k}=9;

k=3; % graph #3
DemoPlots{n}.Data{k}=ChargingTypeLive(:,k);
DemoPlots{n}.DataSource{k}=ChargingTypeLive(:,k);
for l=1:6
    DemoPlots{n}.DataMat{l,k}=[zeros(ForecastIntervalInd,96*floor(l/5)),[zeros(ForecastIntervalInd-size(ChargingTypeMat{l},1),size(ChargingTypeMat{l},2));squeeze(ChargingTypeMat{l}(:,:,k))]];
end
DemoPlots{n}.Time.Vec{k}=Users{1}.Time.Vec;
DemoPlots{n}.Label{k}="Reserve energy";
DemoPlots{n}.YLabel{k}="Charging Power in MW";
DemoPlots{n}.YMin{k}=-1;
DemoPlots{n}.YMax{k}='dynamic';
DemoPlots{n}.YAxis{k}=1;
DemoPlots{n}.PlotColor{k}=10;


%% Resolve time issues

Time.Demo.Start=max([Time.Vec(1), Range.TestDate(1)]);
Time.Demo.End=min([Time.Vec(end), Range.TestDate(2)]);
for n=1:length(DemoPlots)
    for k=1:length(DemoPlots{n}.Data)
        Time.Demo.Start=max([Time.Demo.Start, DemoPlots{n}.Time.Vec{k}(1)]);
        Time.Demo.End=min([Time.Demo.End, DemoPlots{n}.Time.Vec{k}(end)]);
    end
end

Time.Demo.Start=Time.Demo.Start;
Time.Demo.Vec=(Time.Demo.Start:Time.Step:Time.Demo.End)';
Time.Demo.VecDateNum=datenum(Time.Demo.Vec);
Time.Demo.StartInd=4*24*Time.StepInd+1;

for n=1:length(DemoPlots)
    for k=1:length(DemoPlots{n}.Data)
        DemoPlots{n}.Time.TD{k}=find(ismember(DemoPlots{n}.Time.Vec{k}, Time.Demo.Start),1)-1;
    end
end

TimesOfPreAlgo=find(ismember((hour(Time.Demo.Vec)*Time.StepInd + minute(Time.Demo.Vec)/60*Time.StepInd),(hour(Users{1}.TimeOfPreAlgo)*Time.StepInd + minute(Users{1}.TimeOfPreAlgo)/60*Time.StepInd)'));
TimesOfPreAlgo(TimesOfPreAlgo<33)=[];

%% DemoInit

TimeInd=Time.Demo.StartInd;
DemoInit; % Create the plots and initialise them

%% Start Demo

for TimeInd=Time.Demo.StartInd:Time.Demo.StepInd:length(Time.Demo.Vec)
    DemoLoop;
end

clearvars DemoUser EndCounter figPVPlot figPVPred figResPoDemRealNeg figResPoDemRealPos figSoCPlot figDemoPlots{n}.Data{k} figDemoPlots{n}.Data{k}
clearvars ForcastLength ForecastDuration ForecastIntervalInd NumPredMethod p PlotColors Pred DemoPlots{n}.Label{k} PVPredQH PVQH DemoPlots{n}.Label{k} 
clearvars DemoPlots{n}.Label{k} ShowBaseScenario ShowPVPred ShowStockmarketPred DemoPlots{n}.Label{k} PlotLabel{k} DemoPlots{n}.Data{k} DemoPlots{n}.DataMat{k}
clearvars DemoPlots{n}.Data{k} StorageFile TimeDiffs TimeInd TimeOfForecast ymaxResPoDem ymaxSpotmarket yminResPoDem yminSpotmarket

