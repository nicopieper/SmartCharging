SpotmarketLabel="Dayahead Auction Price";
SpotmarketReal=interp1(TimeH,DayaheadRealH, TimeQH);
SpotmarketReal(end-2:end)=SpotmarketReal(end-3);
SpotmarketPred=interp1(TimeH,DayaheadPredH, TimeQH);
SpotmarketPred(end-2:end)=SpotmarketPred(end-3);
   ForecastIntervalPredInd=52;
SpotmarketPredMat=interp1((1:ForecastIntervalPredInd)',DayaheadPredMat(:,:), (1:1/TimeStepInd:ForecastIntervalPredInd+1-1/TimeStepInd));
SpotmarketPredMat(end-2:end,:)=ones(3,1)*SpotmarketPredMat(end-3,:);
    ForecastIntervalPredInd=52*4;

PVPredQH=PVPredTemp;
PVPredMat=PVPredMatTemp;


ResPoDemLabel="Secondary Reserve Capacity Energy Demand";
ResEnPricesLabel="Secondary Reserve Capacity & Energy Price";

SoCPlotLabel=strcat("SoC of the Vehicle of User ", num2str(DemoUser));
PVPlotLabel=strcat("PV Generation Power of User ", num2str(DemoUser));


PlotColors= [0.0000, 0.4470, 0.7410; 0.8500, 0.3250, 0.0980;... 
             0.9290, 0.6940, 0.1250; 0.4940, 0.1840, 0.5560;... 
             0.4660, 0.6740, 0.1880; 0.3010, 0.7450, 0.9330;...
             0.6350, 0.0780, 0.1840];     

ForecastDuration=0;
EndCounter=TimeInd;

% figure(10)
% 
% uicontrol('Style','text', 'units','norm', 'pos', [0.1 0.9 0.4 0.08], 'string', strcat("User ", num2str(DemoUser)), 'FontSize', 16, 'HorizontalAlignment', 'left')
% 
% uicontrol('Style','text', 'units','norm', 'pos', [0.1 0.7 0.4 0.08], 'string', 'Vehicle Model:', 'FontSize', 16, 'HorizontalAlignment', 'left')
% uicontrol('Style','text', 'units','norm', 'pos', [0.5 0.7 0.4 0.08], 'string', Users{DemoUser}.ModelName, 'FontSize', 16, 'HorizontalAlignment', 'left')
% 
% uicontrol('Style','text', 'units','norm', 'pos', [0.1 0.6 0.4 0.08], 'string', 'Battery size:', 'FontSize', 16, 'HorizontalAlignment', 'left')
% uicontrol('Style','text', 'units','norm', 'pos', [0.5 0.6 0.4 0.08], 'string', strcat(num2str(single(Users{DemoUser}.BatterySize)/1000), " kWh"), 'FontSize', 16, 'HorizontalAlignment', 'left')
% 
% uicontrol('Style','text', 'units','norm', 'pos', [0.1 0.5 0.4 0.08], 'string', 'Max. Charging Power:', 'FontSize', 16, 'HorizontalAlignment', 'left')
% uicontrol('Style','text', 'units','norm', 'pos', [0.5 0.5 0.4 0.08], 'string', strcat(num2str(single(Users{DemoUser}.ChargingPower)/1000), " kW"), 'FontSize', 16, 'HorizontalAlignment', 'left')
% 
% uicontrol('Style','text', 'units','norm', 'pos', [0.1 0.4 0.4 0.08], 'string', 'PV Peak Power:', 'FontSize', 16, 'HorizontalAlignment', 'left')
% uicontrol('Style','text', 'units','norm', 'pos', [0.5 0.4 0.4 0.08], 'string', strcat(num2str(PVPlants{Users{DemoUser}.PVPlant}.PeakPower), " kW"), 'FontSize', 16, 'HorizontalAlignment', 'left')
% 
% uicontrol('Style','text', 'units','norm', 'pos', [0.1 0.3 0.5 0.08], 'string', 'Home Location:', 'FontSize', 16, 'HorizontalAlignment', 'left')
% uicontrol('Style','text', 'units','norm', 'pos', [0.5 0.3 0.5 0.08], 'string', erase(PVPlants{Users{DemoUser}.PVPlant}.Location, '"'), 'FontSize', 16, 'HorizontalAlignment', 'left')

figure(11)
subplot(2,2,1)
cla
title(strcat(SpotmarketLabel, " ", datestr(TimeVec(TimeInd),'dd.mm.yyyy HH:MM')),'Interpreter','none')
xlabel('Time')
ylabel('Price [MWh/€]')
grid on
hold on

figSpotmarketReal = animatedline(TimeVecDateNum(TimeInd-24*TimeStepInd+1:TimeInd), SpotmarketReal(TimeInd-24*TimeStepInd+1:TimeInd,1), 'MaximumNumPoints',400,  'Color', PlotColors(1,:));
% xticks([TimeVecTemp(1) TimeVecTemp(end/2) TimeVecTemp(end)])
% xticklabels({datestr(TimeVecTemp(1),'dd.mm HH:MM') datestr(TimeVecTemp(end/2),'dd.mm HH:MM') datestr(TimeVecTemp(end),'dd.mm HH:MM')})
xticks(TimeVecDateNum(TimeInd-24*TimeStepInd+1:48:end))
xticklabels({datestr(TimeVecDateNum(TimeInd-24*TimeStepInd+1:48:end),'dd.mm HH:MM')})

for p=1:NumPredMethod
    figSpotmarketPred{p}=animatedline(TimeVecDateNum(max(TimeInd-ForecastIntervalInd+ForecastDuration, RangeTestInd(1)):TimeInd+ForecastDuration), SpotmarketPred(max(TimeInd-ForecastIntervalInd+ForecastDuration, RangeTestInd(1)):TimeInd+ForecastDuration,p), 'MaximumNumPoints',400, 'Color', PlotColors(p+1,:));
end

legend(["Real" "Prediction"],'Interpreter','none')



subplot(2,2,2)
cla
title(strcat(ResPoDemLabel, " ", datestr(TimeVec(TimeInd),'dd.mm.yyyy HH:MM')),'Interpreter','none')
xlabel('Time')
ylabel('Demand [MW]')
grid on
hold on

figResPoDemRealNeg=animatedline(TimeVecDateNum(TimeInd-24*TimeStepInd+1:TimeInd), ResPoDemRealQH(TimeInd-24*TimeStepInd+1:TimeInd,1), 'MaximumNumPoints',400, 'Color', PlotColors(1,:));
figResPoDemRealPos=animatedline(TimeVecDateNum(TimeInd-24*TimeStepInd+1:TimeInd), ResPoDemRealQH(TimeInd-24*TimeStepInd+1:TimeInd,2), 'MaximumNumPoints',400, 'Color', PlotColors(2,:));
%     for p=1:NumPredMethod % Create one Figure Property for each model
%         figPred{p}=plot(TimeVec(max(TimeInd-ForecastIntervalInd+ForecastDuration, RangeTestInd(1)):TimeInd+ForecastDuration), SpotmarketPred(max(TimeInd-ForecastIntervalInd+ForecastDuration, RangeTestInd(1)):TimeInd+ForecastDuration,p), 'Color', PlotColors(p,:));
%     end
xticks(TimeVecDateNum(TimeInd-24*TimeStepInd+1:48:end))
xticklabels({datestr(TimeVecDateNum(TimeInd-24*TimeStepInd+1:48:end),'dd.mm HH:MM')})
legend(["Negative" "Positive"],'Interpreter','none')



subplot(2,2,3)
cla
title(strcat(SoCPlotLabel, " ", datestr(TimeVec(TimeInd),'dd.mm.yyyy HH:MM')),'Interpreter','none')
xlabel('Time')
ylabel('SoC')
grid on
hold on

figSoCPlot=animatedline(TimeVecDateNum(TimeInd-24*TimeStepInd+1:TimeInd), double(Users{DemoUser}.LogbookBase(TimeInd-24*TimeStepInd+1:TimeInd,6))/double(Users{DemoUser}.BatterySize), 'MaximumNumPoints',400,  'Color', PlotColors(1,:));
set(figSoCPlot, {'color'}, {[0.0000, 0.4470, 0.7410]});
%     for p=1:NumPredMethod % Create one Figure Property for each model
%         figPred{p}=plot(TimeVec(max(TimeInd-ForecastIntervalInd+ForecastDuration, RangeTestInd(1)):TimeInd+ForecastDuration), SpotmarketPred(max(TimeInd-ForecastIntervalInd+ForecastDuration, RangeTestInd(1)):TimeInd+ForecastDuration,p), 'Color', PlotColors(p,:));
%     end
xticks(TimeVecDateNum(TimeInd-24*TimeStepInd+1:48:end))
xticklabels({datestr(TimeVecDateNum(TimeInd-24*TimeStepInd+1:48:end),'dd.mm HH:MM')})
ylim([-0.1 1.1])
legend(["SoC"],'Interpreter','none')



subplot(2,2,4)
cla
title(strcat(PVPlotLabel, " ", datestr(TimeVec(TimeInd),'dd.mm.yyyy HH:MM')),'Interpreter','none')
xlabel('Time')
ylabel('PV Generation Power [W]')
grid on
hold on

figPVPlot=animatedline(TimeVecDateNum(TimeInd-24*TimeStepInd+1:TimeInd), double(PVPlants{Users{DemoUser}.PVPlant}.Profile(TimeInd-24*TimeStepInd+1:TimeInd)), 'MaximumNumPoints',400,  'Color', PlotColors(1,:));
for p=1:NumPredMethod % Create one Figure Property for each model
    figPVPred{p}=animatedline(TimeVecDateNum(max(TimeInd-ForecastIntervalInd+ForecastDuration, RangeTestInd(1)):TimeInd+ForecastDuration), PVPredQH(max(TimeInd-ForecastIntervalInd+ForecastDuration, RangeTestInd(1)):TimeInd+ForecastDuration,p), 'MaximumNumPoints',400, 'Color', PlotColors(p+1,:));
end
xticks(TimeVecDateNum(TimeInd-24*TimeStepInd+1:48:end))
xticklabels({datestr(TimeVecDateNum(TimeInd-24*TimeStepInd+1:48:end),'dd.mm HH:MM')})
ylim([-round(PVPlants{Users{DemoUser}.PVPlant}.PeakPower)*10   ceil(PVPlants{Users{DemoUser}.PVPlant}.PeakPower)*1000])
legend(["PV Generation" "PV Prediction"],'Interpreter','none')





% 
% figSpotmarketReal=plot(TimeVec(TimeInd-24*TimeStepInd+1:TimeInd), SpotmarketReal(TimeInd-24*TimeStepInd+1:TimeInd,1), 'Color', [0.0000, 0.4470, 0.7410]);
% for p=1:NumPredMethod % Create one Figure Property for each model
%     figSpotmarketPred{p}=plot(TimeVec(max(TimeInd-ForecastIntervalInd+ForecastDuration, RangeTestInd(1)):TimeInd+ForecastDuration), SpotmarketPred(max(TimeInd-ForecastIntervalInd+ForecastDuration, RangeTestInd(1)):TimeInd+ForecastDuration,p), 'Color', PlotColors(p,:));
% end
% 
% legend(["Real" "Prediction"],'Interpreter','none')
% 
% 
% subplot(2,2,2)
% cla
% title(strcat(ResPoDemLabel, " ", datestr(TimeVec(TimeInd),'dd.mm.yyyy HH:MM')),'Interpreter','none')
% xlabel('Time')
% ylabel('Demand [MW]')
% grid on
% hold on
% 
% figResPoDemReal=plot(TimeVec(TimeInd-24*TimeStepInd+1:TimeInd), ResPoDemRealQH(TimeInd-24*TimeStepInd+1:TimeInd,:));
% set(figResPoDemReal, {'color'}, {[0.0000, 0.4470, 0.7410]; PlotColors(1,:)});
% %     for p=1:NumPredMethod % Create one Figure Property for each model
% %         figPred{p}=plot(TimeVec(max(TimeInd-ForecastIntervalInd+ForecastDuration, RangeTestInd(1)):TimeInd+ForecastDuration), SpotmarketPred(max(TimeInd-ForecastIntervalInd+ForecastDuration, RangeTestInd(1)):TimeInd+ForecastDuration,p), 'Color', PlotColors(p,:));
% %     end
% legend(["Negative" "Positive"],'Interpreter','none')
% 
% 
% subplot(2,2,3)
% cla
% title(strcat(SoCPlotLabel, " ", datestr(TimeVec(TimeInd),'dd.mm.yyyy HH:MM')),'Interpreter','none')
% xlabel('Time')
% ylabel('SoC')
% grid on
% hold on
% 
% figSoCPlot=plot(TimeVec(TimeInd-24*TimeStepInd+1:TimeInd), single(Users{DemoUser}.LogbookBase(TimeInd-24*TimeStepInd+1:TimeInd,6))/single(Users{DemoUser}.BatterySize));
% set(figSoCPlot, {'color'}, {[0.0000, 0.4470, 0.7410]});
% %     for p=1:NumPredMethod % Create one Figure Property for each model
% %         figPred{p}=plot(TimeVec(max(TimeInd-ForecastIntervalInd+ForecastDuration, RangeTestInd(1)):TimeInd+ForecastDuration), SpotmarketPred(max(TimeInd-ForecastIntervalInd+ForecastDuration, RangeTestInd(1)):TimeInd+ForecastDuration,p), 'Color', PlotColors(p,:));
% %     end
% ylim([-0.1 1.1])
% legend(["SoC"],'Interpreter','none')
% 
% 
% subplot(2,2,4)
% cla
% title(strcat(PVPlotLabel, " ", datestr(TimeVec(TimeInd),'dd.mm.yyyy HH:MM')),'Interpreter','none')
% xlabel('Time')
% ylabel('PV Generation Power [W]')
% grid on
% hold on
% 
% figPVPlot=plot(TimeVec(TimeInd-24*TimeStepInd+1:TimeInd), PVPlants{Users{DemoUser}.PVPlant}.Profile(TimeInd-24*TimeStepInd+1:TimeInd));
% set(figPVPlot, {'color'}, {[0.0000, 0.4470, 0.7410]});
% for p=1:NumPredMethod % Create one Figure Property for each model
%     figPVPred{p}=plot(TimeVec(max(TimeInd-ForecastIntervalInd+ForecastDuration, RangeTestInd(1)):TimeInd+ForecastDuration), PVPredQH(max(TimeInd-ForecastIntervalInd+ForecastDuration, RangeTestInd(1)):TimeInd+ForecastDuration,p), 'Color', PlotColors(p,:));
% end
% ylim([-round(PVPlants{Users{DemoUser}.PVPlant}.PeakPower)*10   ceil(PVPlants{Users{DemoUser}.PVPlant}.PeakPower)*1000])
% legend(["PV Generation" "PV Prediction"],'Interpreter','none')

pause(0.01)
