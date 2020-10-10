%% Intitialisation 
TimeOfForecast=datetime(1,1,1,08,0,0,'TimeZone','Africa/Tunis');
Time.Demo.Step=minutes(60);
Time.Demo.StepInd=4;
NumPredMethod=1;





%% Plot 1

DemoPlots{1}.Title=strcat("Dayahead auction price");


DemoPlots{1}.Label{1}="Price";
DemoPlots{1}.YLabel{1}="Price in €/MWh";
DemoPlots{1}.Data{1}=repelem(Smard.DayaheadRealH, 4);
DemoPlots{1}.Time.Vec{1}=Time.Vec;
DemoPlots{1}.YMin{1}='dynamic';
DemoPlots{1}.YMax{1}='dynamic';
DemoPlots{1}.YAxis{1}=1;


DemoPlots{1}.Label{2}="Prediction";
DemoPlots{1}.YLabel{2}="Price in €/MWh";
if length(DemoPlots{1}.Data)<=1
    StorageFile=uigetfile(Path.Prediction, strcat("Select DemoPlots{1}.Data{2} ", DemoPlots{1}.Title, " ", DemoPlots{1}.Label{2}));
    load(strcat(Path.Prediction, StorageFile))
    DemoPlots{1}.Data{2}=repelem(Pred.Data, Time.StepInd/Pred.Time.StepPredInd);
end

DemoPlots{1}.DataMat{2}=repelem(Pred.DataMat, Time.StepInd/Pred.Time.StepPredInd,Time.StepInd/Pred.Time.StepPredInd);
DemoPlots{1}.Time.Vec{2}=repelem(Pred.Time.Pred, Time.StepInd/Pred.Time.StepPredInd,Time.StepInd/Pred.Time.StepPredInd);
DemoPlots{1}.YMin{2}='dynamic';
DemoPlots{1}.YMax{2}='dynamic';
DemoPlots{1}.YAxis{2}=1;

ForecastIntervalInd=Pred.ForecastIntervalInd*Time.StepInd;


%% Plot 2

DemoPlots{2}.Title="Reserve energy market data";
DemoPlots{2}.YLabel{1}="Demand in MW";

DemoPlots{2}.Data{1}=ResPoDemRealQH(:,1)/4;
DemoPlots{2}.Label{1}="Energy demand";
DemoPlots{2}.Time.Vec{1}=Time.Vec;
DemoPlots{2}.YMin{1}=-0.1;
DemoPlots{2}.YMax{1}='dynamic';
DemoPlots{2}.YAxis{1}=1;

DemoPlots{2}.Label{2}="Mean energy price";
DemoPlots{2}.YLabel{2}="Energy price in €/MWh";
DemoPlots{2}.Data{2}=ResEnPricesRealQH(:,3);
DemoPlots{2}.Time.Vec{2}=Time.Vec;
DemoPlots{2}.YMin{2}='dynamic';
DemoPlots{2}.YMax{2}='dynamic';
DemoPlots{2}.YAxis{2}=2;


%% Plot 3

if length(DemoPlots)<=2 || isempty(DemoPlots{3}) || ~isfield(DemoPlots{3}, "Data") || isempty(DemoPlots{3}.Data{1})
    StorageFile=uigetfile(Path.Simulation, "Select the user data"');
    load(strcat(Path.Simulation, StorageFile))
end

DemoUser=2;
while sum(Users{DemoUser}.LogbookSource(:,1)>2)<100
    DemoUser=DemoUser+1;
end

DemoPlots{3}.Title=strcat("Vehicle properties of user ", num2str(DemoUser));

DemoPlots{3}.YLabel{1}="SoC in %";
DemoPlots{3}.Data{1}=double(Users{DemoUser}.LogbookBase(:,9)/Users{DemoUser}.BatterySize)*100;
DemoPlots{3}.Label{1}="SoC";
DemoPlots{3}.Time.Vec{1}=Users{1}.Time.Vec;
DemoPlots{3}.YMin{1}=0;
DemoPlots{3}.YMax{1}=110;
DemoPlots{3}.YAxis{1}=1;

%% Plot 4

DemoPlots{4}.Title=strcat("PV Generation and Prediction Power of User ", num2str(DemoUser));

DemoPlots{4}.Label{1}=strcat("Generation");
DemoPlots{4}.YLabel{1}="Power in kW";
DemoPlots{4}.Data{1}=double(PVPlants{Users{DemoUser}.PVPlant}.ProfileQH)/1000;
DemoPlots{4}.Time.Vec{1}=Time.Vec;
DemoPlots{4}.YMin{2}=-0.1;
DemoPlots{4}.YMax{2}=max(DemoPlots{4}.Data{1});
DemoPlots{4}.YAxis{1}=1;

DemoPlots{4}.Label{2}=strcat("Prediction");
DemoPlots{4}.YLabel{2}="Power in kW";
DemoPlots{4}.Data{2}=double(PVPlants{Users{DemoUser}.PVPlant}.PredictionQH)/1000;
DemoPlots{4}.Time.Vec{2}=Time.Vec;
DemoPlots{4}.YMin{2}=-0.1;
DemoPlots{4}.YMax{2}=max(DemoPlots{4}.Data{2});
DemoPlots{4}.YAxis{2}=1;


%% Resolve Time issues

Time.Demo.Start=max([Time.Vec(1), Range.TestDate(1)]);
Time.Demo.End=min([Time.Vec(end), Range.TestDate(2)]);
for n=1:length(DemoPlots)
    for k=1:length(DemoPlots{n}.Data)
        Time.Demo.Start=max([Time.Demo.Start, DemoPlots{n}.Time.Vec{k}(1)]);
        Time.Demo.End=min([Time.Demo.End, DemoPlots{n}.Time.Vec{k}(end)]);
    end
end

Time.Demo.Vec=(Time.Demo.Start:Time.Step:Time.Demo.End)';
Time.Demo.VecDateNum=datenum(Time.Demo.Vec);
Time.Demo.StartInd=48*Time.StepInd+1;

for n=1:length(DemoPlots)
    for k=1:length(DemoPlots{n}.Data)
        DemoPlots{n}.Time.TD{k}=find(ismember(DemoPlots{n}.Time.Vec{k}, Time.Demo.Start),1)-1;
    end
end

TimesOfPreAlgo=(hour(TimeOfForecast)*Time.StepInd + minute(TimeOfForecast)/60*Time.StepInd)+1:24*Time.StepInd:length(Time.Demo.Vec);

%% DemoInit

TimeInd=Time.Demo.StartInd-1;
DemoInit;

%% Start Demo

for TimeInd=Time.Demo.StartInd:Time.Demo.StepInd:length(Time.Demo.Vec)
    DemoLoop;
end

clearvars DemoUser EndCounter figPVPlot figPVPred figResPoDemRealNeg figResPoDemRealPos figSoCPlot figDemoPlots{1}.Data{2} figDemoPlots{1}.Data{1}
clearvars ForcastLength ForecastDuration ForecastIntervalInd NumPredMethod p PlotColors Pred DemoPlots{4}.Label{1} PVPredQH PVQH DemoPlots{2}.Label{2} 
clearvars DemoPlots{2}.Label{1} ShowBaseScenario ShowPVPred ShowStockmarketPred DemoPlots{3}.Label{1} PlotLabel{1} DemoPlots{1}.Data{2} DemoPlots{1}.DataMat{2}
clearvars DemoPlots{1}.Data{1} StorageFile TimeDiffs TimeInd TimeOfForecast ymaxResPoDem ymaxSpotmarket yminResPoDem yminSpotmarket

