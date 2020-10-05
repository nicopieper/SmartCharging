%% Intitialisation 
ShowStockmarketPred=true;
ShowPVPred=true;
ShowBaseScenario=true;
TimeOfForecast=datetime(1,1,1,08,0,0,'TimeZone','Africa/Tunis');
Time.Demo.Step=minutes(60);
Time.Demo.StepInd=hours(1)/Time.Demo.Step;


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
    PredMethodName="LSQ";
    StorageFiles=dir(strcat(Path.Prediction, "DayaheadRealH_", PredMethodName, "*"));
    PredStart=NaT(size(StorageFiles,1), 'TimeZone', 'Africa/Tunis');
    PredEnd=NaT(size(StorageFiles,1), 'TimeZone', 'Africa/Tunis');
    TimeStamps=NaT(size(StorageFiles,1), 'TimeZone', 'Africa/Tunis');
    FileFits=false(0);
    for n=1:size(StorageFiles,1)
        PredStart(n)=datetime(StorageFiles(n).name(end-34:end-27), 'InputFormat', 'yyyyMMdd', 'TimeZone', 'Africa/Tunis') + hours(0);
        PredEnd(n)=datetime(StorageFiles(n).name(end-25:end-18), 'InputFormat', 'yyyyMMdd', 'TimeZone', 'Africa/Tunis')+hours(23)+minutes(45);
        if PredStart(n) <= Time.Vec(DemoStart) & PredEnd(n)>=Time.End
        	TimeStamps(n)=datetime(StorageFiles(n).name(end-16:end-4), 'InputFormat', 'yyyyMMdd-HHmm', 'TimeZone', 'Africa/Tunis');
        end
    end
    if all(TimeStamps==NaT('TimeZone', 'Africa/Tunis'))
        disp("No matching prediction data could be found")
    else
        [~,LatestPrediction]=max(TimeStamps);
        load(strcat(Path.Prediction, StorageFiles(LatestPrediction).name))
        SpotmarketPred=repelem(Pred.Data, Pred.Time.StepInd/Time.StepInd);
        SpotmarketPredMat=repelem(Pred.DataMat, Pred.Time.StepInd/Time.StepInd,1);
        
%         SpotmarketPred=interp1(Time.Pred(ismember(Time.Pred, Time.Vec)),Prediction(ismember(Time.Pred, Time.Vec)), Time.Vec);
%         SpotmarketPred(end-2:end)=SpotmarketPred(end-3);
%         SpotmarketPredMat=interp1(1:ForecastIntervalPredInd, upsample(PredictionMat(:,ismember(Time.Pred, Time.Vec))',4)',1:1/Time.StepInd:ForecastIntervalPredInd+(Time.StepInd-1)/Time.StepInd);
%         SpotmarketPredMat(end-2:end,:)=ones(3,1)*SpotmarketPredMat(end-3,:);
    end
end
ForecastIntervalInd=ForecastIntervalPredInd*Time.StepInd;


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

TimeInds.General=find(ismember(Time.Vec,Time.Demo.Start),1)+24*Time.StepInd;
TimeInds.SpotmarketPred=find(ismember(Pred.Time.Vec,Time.Demo.Start),1)+24*Time.StepInd;
TimeInds.User=find(ismember(Users{1}.Time.Vec,Time.Demo.Start),1)+24*Time.StepInd;

TimeInd=24*Time.StepInd;
SimulationDemoInit;
for TimeInd=1:length(Time.Demo.Vec)
    SimulationDemoLoop;
end

