%% Intitialisation 
ShowStockmarketPred=true;
ShowPVPred=true;
ShowBaseScenario=true;
TimeOfForecast=datetime(1,1,1,08,0,0,'TimeZone','Africa/Tunis');
Time.Demo.Step=minutes(60);
Time.Demo.StepInd=4;


NumPredMethod=1;
SpotmarketLabel=strcat("Dayahead Auction Price");
SpotmarketReal=Smard.DayaheadRealH;

if ~exist('Users', 'var') && ShowBaseScenario
    StorageFile=uigetfile(strcat(Path.Simulation, Dl),'Select the User data');
    load(StorageFile)
end

%% Find DemoUser

DemoUser=2;
while (ShowPVPred && (Users{DemoUser}.PVPlantExists==false || ~isfield(PVPlants{Users{DemoUser}.PVPlant}, 'PredictionH'))) || sum(Users{DemoUser}.LogbookSource(:,1)>2)<100
    DemoUser=DemoUser+1;
end

%% Extend SpotmarketReal if its hourly value
if length(SpotmarketReal)~= length(Time.Vec) && length(SpotmarketReal) == length(Time.H)
    SpotmarketReal=repelem(SpotmarketReal, 4);
end

%% Load Spotmarket Prediction

if ~exist("SpotmarketPred", "var") && ShowStockmarketPred
    StorageFile=uigetfile(strcat(Path.Prediction, Dl),'Select the Prediction data');
    load(StorageFile)
    SpotmarketPred=repelem(Pred.Data, Time.StepInd/Pred.Time.StepPredInd);
    SpotmarketPredMat=repelem(Pred.DataMat, Time.StepInd/Pred.Time.StepPredInd,Time.StepInd/Pred.Time.StepPredInd);
%         SpotmarketPred=interp1(Time.Pred(ismember(Time.Pred, Time.Vec)),Prediction(ismember(Time.Pred, Time.Vec)), Time.Vec);
%         SpotmarketPred(end-2:end)=SpotmarketPred(end-3);
%         SpotmarketPredMat=interp1(1:ForecastIntervalPredInd, upsample(PredictionMat(:,ismember(Time.Pred, Time.Vec))',4)',1:1/Time.StepInd:ForecastIntervalPredInd+(Time.StepInd-1)/Time.StepInd);
%         SpotmarketPredMat(end-2:end,:)=ones(3,1)*SpotmarketPredMat(end-3,:);
end
ForecastIntervalInd=Pred.ForecastIntervalInd*Time.StepInd;


% if length(SpotmarketReal)~= length(Time.Vec) && length(SpotmarketReal) == length(Time.H)
%     SpotmarketReal=interp1(Time.H,SpotmarketReal, Time.Vec); % DayaheadRealQH
%     SpotmarketReal(end-2:end)=SpotmarketReal(end-3);
% end

%% Initialise Plot Labels

ResPoDemLabel="Secondary Reserve Capacity Energy Demand";
ResEnPricesLabel="Secondary Reserve Capacity & Energy Price";

SoCPlotLabel=strcat("SoC of the Vehicle of User ", num2str(DemoUser));
PVPlotLabel=strcat("PV Generation Power of User ", num2str(DemoUser));

%% Resolve Time issues

Time.Demo.Start=max([Time.Vec(1), Range.TestDate(1), Users{1}.Time.Vec(1), Pred.Time.Vec(1)]);
Time.Demo.End=min([Time.Vec(end), Range.TestDate(2), Users{1}.Time.Vec(end), Pred.Time.Vec(end)]);
Time.Demo.Vec=(Time.Demo.Start:Time.Step:Time.Demo.End)';
Time.Demo.VecDateNum=datenum(Time.Demo.Vec);
Time.Demo.StartInd=48*Time.StepInd+1;

TD.Main=find(ismember(Time.Vec,Time.Demo.Start),1)-1;
TD.SpotmarketPred=find(ismember(Pred.Time.Vec,Time.Demo.Start),1)-1;
TD.User=find(ismember(Users{1}.Time.Vec,Time.Demo.Start),1)-1;

TimeInd=Time.Demo.StartInd-1;
SimulationDemoInit;
for TimeInd=Time.Demo.StartInd:Time.Demo.StepInd:length(Time.Demo.Vec)
    SimulationDemoLoop;
end

clearvars DemoUser EndCounter figPVPlot figPVPred figResPoDemRealNeg figResPoDemRealPos figSoCPlot figSpotmarketPred figSpotmarketReal
clearvars ForcastLength ForecastDuration ForecastIntervalInd NumPredMethod p PlotColors Pred PVPlotLabel PVPredQH PVQH ResEnPricesLabel 
clearvars ResPoDemLabel ShowBaseScenario ShowPVPred ShowStockmarketPred SoCPlotLabel SpotmarketLabel SpotmarketPred SpotmarketPredMat
clearvars SpotmarketReal StorageFile TimeDiffs TimeInd TimeOfForecast ymaxResPoDem ymaxSpotmarket yminResPoDem yminSpotmarket

