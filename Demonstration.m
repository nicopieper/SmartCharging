DemoStart=Range.TestInd(1);
DemoStartDay=Time.Vec(Range.TestInd(1));
ShowStockmarketPred=true;
ShowPVPred=true;
ShowBaseScenario=true;
TimeOfForecast=datetime(1,1,1,08,0,0,'TimeZone','Africa/Tunis');
Time.StepIndDemo=4;

NumPredMethod=1;
SpotmarketLabel=strcat("Dayahead Auction Price");
SpotmarketReal=Smard.DayaheadRealH;

if ~exist('Users', 'var') && ShowBaseScenario
    StorageFiles=dir(strcat(Path.Simulation, Dl, "Users_*"));
    [~, StorageInd]=max(datetime({StorageFiles.date}, "InputFormat", "dd-MMM-yyyy HH:mm:ss", 'Locale', 'de_DE'));
    load(strcat(Path.Simulation, Dl, StorageFiles(StorageInd).name))
end

DemoUser=2;
while (Users{DemoUser}.PVPlantExists==false && ShowPVPred) || sum(Users{DemoUser}.LogbookSource(:,1)>2)<100
    DemoUser=DemoUser+1;
end

if ~exist("SpotmarketPred", "var") && ShowStockmarketPred
    PredMethodName="LSQ";
    StorageFiles=dir(strcat(Path.Prediction, "DayaheadRealH_", PredMethodName, "*"));
    PredStart=NaT(size(StorageFiles,1), 'TimeZone', 'Africa/Tunis');
    PredEnd=NaT(size(StorageFiles,1), 'TimeZone', 'Africa/Tunis');
    FileFits=false(0);
    for n=1:size(StorageFiles,1)
        PredStart(n)=datetime(StorageFiles(n).name(end-37:end-30), 'InputFormat', 'yyyyMMdd', 'TimeZone', 'Africa/Tunis') + hours(0);
        PredEnd(n)=datetime(StorageFiles(n).name(end-28:end-21), 'InputFormat', 'yyyyMMdd', 'TimeZone', 'Africa/Tunis')+hours(23)+minutes(45);
        FileFits(n)=PredStart(n) <= Time.Vec(DemoStart) & PredEnd(n)>=Time.End;
    end
    if sum(FileFits)==0
        disp("No matching prediction data could be found")
    else
        load(strcat(Path.Prediction, StorageFiles(find(datetime({StorageFiles(FileFits).date}, 'InputFormat', "dd-MMM-yyyy HH:mm:ss")==max(datetime({StorageFiles(FileFits).date}, 'InputFormat', "dd-MMM-yyyy HH:mm:ss")),1)).name))
        SpotmarketPred=interp1(Time.VecPred(ismember(Time.VecPred, Time.Vec)),Prediction(ismember(Time.VecPred, Time.Vec)), Time.Vec);
        SpotmarketPred(end-2:end)=SpotmarketPred(end-3);
%         SpotmarketPredMat=interp1((1:Pred.ForecastIntervalInd)',PredictionMat(:,:), (1:1/Time.StepInd:Pred.ForecastIntervalInd+1-1/Time.StepInd));
        SpotmarketPredMat=interp1(1:Pred.ForecastIntervalInd, upsample(PredictionMat(:,ismember(Time.VecPred, Time.Vec))',4)',1:1/Time.StepInd:Pred.ForecastIntervalInd+(Time.StepInd-1)/Time.StepInd);
        SpotmarketPredMat(end-2:end,:)=ones(3,1)*SpotmarketPredMat(end-3,:);
    end
end
Pred.ForecastIntervalInd;=Pred.ForecastIntervalInd*Time.StepInd;
    
if length(SpotmarketReal)~= length(Time.Vec) && length(SpotmarketReal) == length(TimeH)
    SpotmarketReal=interp1(TimeH,SpotmarketReal, Time.Vec); % DayaheadRealQH
    SpotmarketReal(end-2:end)=SpotmarketReal(end-3);
end

if ShowPVPred
    PredMethodName="LSQ";
    StorageFiles=dir(strcat(Path.Prediction, "PVPlants_1", "_", PredMethodName, "*"));
    PredStart=NaT(size(StorageFiles,1), 'TimeZone', 'Africa/Tunis');
    PredEnd=NaT(size(StorageFiles,1), 'TimeZone', 'Africa/Tunis');
    FileFits=false(0);
    for n=1:size(StorageFiles,1)
        PredStart(n)=datetime(StorageFiles(n).name(end-37:end-30), 'InputFormat', 'yyyyMMdd', 'TimeZone', 'Africa/Tunis') + hours(0);
        PredEnd(n)=datetime(StorageFiles(n).name(end-28:end-21), 'InputFormat', 'yyyyMMdd', 'TimeZone', 'Africa/Tunis')+hours(23)+minutes(45);
        FileFits(n)=PredStart(n) <= Time.Vec(DemoStart) & PredEnd(n)>=Time.End;
    end
    if sum(FileFits)==0
        disp("No matching prediction data could be found")
    else
        load(strcat(Path.Prediction, StorageFiles(find(datetime({StorageFiles(FileFits).date}, 'InputFormat', "dd-MMM-yyyy HH:mm:ss")==max(datetime({StorageFiles(FileFits).date}, 'InputFormat', "dd-MMM-yyyy HH:mm:ss")),1)).name))
        PVPredQH=Prediction(ismember(Time.VecPred, Time.Vec));
        PVPredMat=PredictionMat;
    end
end

ResPoDemLabel="Secondary Reserve Capacity Energy Demand";
ResEnPricesLabel="Secondary Reserve Capacity & Energy Price";

SoCPlotLabel=strcat("SoC of the Vehicle of User ", num2str(DemoUser));
PVPlotLabel=strcat("PV Generation Power of User ", num2str(DemoUser));

Time.VecDateNum=datenum(Time.Vec);

TimeInd=DemoStart;
SimulationDemoInit;
for TimeInd=DemoStart:Time.StepIndDemo:Range.TestInd(2)
    SimulationDemoLoop;
end

