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


%% Initialise Plots
figure(11)
NumPlotsCol=ceil(sqrt(length(DemoPlots)));
NumPlotsRow=ceil(length(DemoPlots)/NumPlotsCol);
for n=1:length(DemoPlots)
    subplot(NumPlotsRow,NumPlotsCol,n)
    cla reset
    title(strcat(DemoPlots{n}.Title, " at ", datestr(Time.Demo.Vec(TimeInd),'dd.mm.yyyy HH:MM')),'Interpreter','none')
    xlabel('Time')
    grid on
    hold on
    l=legend('Interpreter','none', 'Location', 'northwest');
    Yaxes=[];
    
    DemoGetYLimits;
    
    DemoPlots{n}.Yaxes=unique(Yaxes)';
    
    for k=1:length(DemoPlots{n}.Data)
        
        if length(DemoPlots{n}.Yaxes)>=2
            if DemoPlots{n}.YAxis{k}==1
                yyaxis left
            else
                yyaxis right
            end
        end
        
        DemoPlots{n}.Fig{k}=animatedline(Time.Demo.VecDateNum(TimeInd-24*Time.StepInd+1:TimeInd), DemoPlots{n}.Data{k}(TimeInd+DemoPlots{n}.Time.TD{k}-24*Time.StepInd+1:TimeInd+DemoPlots{n}.Time.TD{k},1), 'MaximumNumPoints',400,  'Color', PlotColors(k,:));
        legappend(l, DemoPlots{n}.Label{k});
        
    end       
    
    
    
    xticks(Time.Demo.VecDateNum(TimeInd-24*Time.StepInd+1:48:end));
    xticklabels({datestr(Time.Demo.VecDateNum(TimeInd-24*Time.StepInd+1:48:end),'dd.mm HH:MM')});
    xlim([Time.Demo.VecDateNum(TimeInd-36*Time.StepInd+max(0,-ForecastIntervalInd+24*Time.StepInd+ForecastDuration+Time.StepInd)) Time.Demo.VecDateNum(EndCounter+3)]) % Create a moving plot 
    
end

%% Old
%     
% figure(11)
% subplot(2,2,1)
% cla
% title(strcat(DemoPlots{n}.Label{1}, " ", datestr(Time.Demo.Vec(TimeInd),'dd.mm.yyyy HH:MM')),'Interpreter','none')
% xlabel('Time')
% ylabel('Price [MWh/€]')
% grid on
% hold on
% 
% figDemoPlots{n}.Data = animatedline(Time.Demo.VecDateNum(TimeInd-24*Time.StepInd+1:TimeInd), DemoPlots{n}.Data(TimeInd+DemoPlots{n}.Time.TD{k}-24*Time.StepInd+1:TimeInd+DemoPlots{n}.Time.TD{k},1), 'MaximumNumPoints',400,  'Color', PlotColors(1,:));
% xticks(Time.Demo.VecDateNum(TimeInd-24*Time.StepInd+1:48:end))
% xticklabels({datestr(Time.Demo.VecDateNum(TimeInd-24*Time.StepInd+1:48:end),'dd.mm HH:MM')})
% 
% for p=1:NumPredMethod
%     figDemoPlots{n}.Data{2}{p}=animatedline(Time.Demo.VecDateNum(max(TimeInd-ForecastIntervalInd+ForecastDuration, TimeInd):TimeInd+ForecastDuration), DemoPlots{n}.Data{2}(max(TimeInd+TD.DemoPlots{n}.Data{2}-ForecastIntervalInd+ForecastDuration, TimeInd+TD.DemoPlots{n}.Data{2}):TimeInd+TD.DemoPlots{n}.Data{2}+ForecastDuration,p), 'MaximumNumPoints',400, 'Color', PlotColors(p+1,:));
% end
% 
% legend(["Real" "Prediction"],'Interpreter','none', 'Location', 'northwest')
% 
% xlim([Time.Demo.VecDateNum(TimeInd-36*Time.StepInd+max(0,-ForecastIntervalInd+24*Time.StepInd+ForecastDuration+Time.StepInd)) Time.Demo.VecDateNum(EndCounter+3)]) % Create a moving plot 
% ymin=min([DemoPlots{n}.Data(TimeInd+DemoPlots{n}.Time.TD{k}-24*7*Time.Demo.StepInd:min(length(DemoPlots{n}.Data),TimeInd+DemoPlots{n}.Time.TD{k}+24*7*Time.Demo.StepInd)); DemoPlots{n}.Data{2}(TimeInd+TD.DemoPlots{n}.Data{2}-24*7*Time.Demo.StepInd:min(length(DemoPlots{n}.Data{2}),TimeInd+TD.DemoPlots{n}.Data{2}+24*7*Time.Demo.StepInd))]);
% ymin=round(ymin-abs(ymin)*0.1);
% ymaxSpotmarket=max([DemoPlots{n}.Data(TimeInd+DemoPlots{n}.Time.TD{k}-24*7*Time.Demo.StepInd:min(length(DemoPlots{n}.Data),TimeInd+DemoPlots{n}.Time.TD{k}+24*7*Time.Demo.StepInd)); DemoPlots{n}.Data{2}(TimeInd+TD.DemoPlots{n}.Data{2}-24*7*Time.Demo.StepInd:min(length(DemoPlots{n}.Data{2}),TimeInd+TD.DemoPlots{n}.Data{2}+24*7*Time.Demo.StepInd))]);
% ymaxSpotmarket=round(ymaxSpotmarket+abs(ymaxSpotmarket)*0.1);
% 
% 
% 
% subplot(2,2,2)
% cla
% title(strcat(DemoPlots{2}.Label{1}, " ", datestr(Time.Demo.Vec(TimeInd),'dd.mm.yyyy HH:MM')),'Interpreter','none')
% xlabel('Time')
% ylabel('Demand [MW]')
% grid on
% hold on
% 
% figResPoDemRealNeg=animatedline(Time.Demo.VecDateNum(TimeInd-24*Time.StepInd+1:TimeInd), ResPoDemRealQH(TimeInd+DemoPlots{n}.Time.TD{k}-24*Time.StepInd+1:TimeInd+DemoPlots{n}.Time.TD{k},1), 'MaximumNumPoints',400, 'Color', PlotColors(1,:));
% figResPoDemRealPos=animatedline(Time.Demo.VecDateNum(TimeInd-24*Time.StepInd+1:TimeInd), ResPoDemRealQH(TimeInd+DemoPlots{n}.Time.TD{k}-24*Time.StepInd+1:TimeInd+DemoPlots{n}.Time.TD{k},2), 'MaximumNumPoints',400, 'Color', PlotColors(2,:));
% %     for p=1:NumPredMethod % Create one Figure Property for each model
% %         figPred{p}=plot(Time.Vec(max(TimeInd-ForecastIntervalInd+ForecastDuration, DemoStart):TimeInd+ForecastDuration), DemoPlots{n}.Data{2}(max(TimeInd-ForecastIntervalInd+ForecastDuration, DemoStart):TimeInd+ForecastDuration,p), 'Color', PlotColors(p,:));
% %     end
% xticks(Time.Demo.VecDateNum(TimeInd-24*Time.StepInd+1:48:end))
% xticklabels({datestr(Time.Demo.VecDateNum(TimeInd-24*Time.StepInd+1:48:end),'dd.mm HH:MM')})
% legend(["Negative" "Positive"],'Interpreter','none', 'Location', 'northwest')
% 
% xlim([Time.Demo.VecDateNum(TimeInd-36*Time.StepInd+max(0,-ForecastIntervalInd+24*Time.StepInd+ForecastDuration+Time.StepInd)) Time.Demo.VecDateNum(EndCounter+3)]) % Create a moving plot 
% yminResPoDem=min(ResPoDemRealQH(TimeInd+DemoPlots{n}.Time.TD{k}-24*7*Time.Demo.StepInd:min(length(Time.Vec),TimeInd+DemoPlots{n}.Time.TD{k}+24*7*Time.Demo.StepInd),:),[],'all');
% yminResPoDem=round(yminResPoDem-abs(yminResPoDem)*0.1);
% ymaxResPoDem=max(ResPoDemRealQH(TimeInd+DemoPlots{n}.Time.TD{k}-24*7*Time.Demo.StepInd:min(length(Time.Vec),TimeInd+DemoPlots{n}.Time.TD{k}+24*7*Time.Demo.StepInd)),[],'all');
% ymaxResPoDem=round(ymaxResPoDem+abs(ymaxResPoDem)*0.1);
% 
% 
% 
% subplot(2,2,3)
% cla
% title(strcat(DemoPlots{3}.Label{1}, " ", datestr(Time.Demo.Vec(TimeInd),'dd.mm.yyyy HH:MM')),'Interpreter','none')
% xlabel('Time')
% ylabel('SoC')
% grid on
% hold on
% 
% figSoCPlot=animatedline(Time.Demo.VecDateNum(TimeInd-24*Time.StepInd+1:TimeInd), double(Users{DemoUser}.LogbookBase(TimeInd+TD.User-24*Time.StepInd+1:TimeInd+TD.User,9))/double(Users{DemoUser}.BatterySize), 'MaximumNumPoints',400,  'Color', PlotColors(1,:));
% set(figSoCPlot, {'color'}, {[0.0000, 0.4470, 0.7410]});
% %     for p=1:NumPredMethod % Create one Figure Property for each model
% %         figPred{p}=plot(Time.Vec(max(TimeInd-ForecastIntervalInd+ForecastDuration, DemoStart):TimeInd+ForecastDuration), DemoPlots{n}.Data{2}(max(TimeInd-ForecastIntervalInd+ForecastDuration, DemoStart):TimeInd+ForecastDuration,p), 'Color', PlotColors(p,:));
% %     end
% xlim([Time.Demo.VecDateNum(TimeInd-36*Time.StepInd+max(0,-ForecastIntervalInd+24*Time.StepInd+ForecastDuration+Time.StepInd)) Time.Demo.VecDateNum(EndCounter+3)]) % Create a moving plot 
% xticks(Time.Demo.VecDateNum(TimeInd-24*Time.StepInd+1:48:end))
% xticklabels({datestr(Time.Demo.VecDateNum(TimeInd-24*Time.StepInd+1:48:end),'dd.mm HH:MM')})
% ylim([-0.1 1.1])
% legend(["SoC"],'Interpreter','none', 'Location', 'northwest')
% 
% 
% if ShowPVPred
%     subplot(2,2,4)
%     cla
%     title(strcat(PVPlotLabel, " ", datestr(Time.Demo.Vec(TimeInd),'dd.mm.yyyy HH:MM')),'Interpreter','none')
%     xlabel('Time')
%     ylabel('PV Generation Power [W]')
%     grid on
%     hold on
% 
%     PVQH=double(PVPlants{Users{DemoUser}.PVPlant}.ProfileQH);
%     figPVPlot=animatedline(Time.Demo.VecDateNum(TimeInd-24*Time.StepInd+1:TimeInd),PVQH(TimeInd+DemoPlots{n}.Time.TD{k}-24*Time.StepInd+1:TimeInd+DemoPlots{n}.Time.TD{k}), 'MaximumNumPoints',400,  'Color', PlotColors(1,:));
%     
%     PVPredQH=double(PVPlants{Users{DemoUser}.PVPlant}.PredictionQH);
%     for p=1:NumPredMethod % Create one Figure Property for each model
%         figPVPred{p}=animatedline(Time.Demo.VecDateNum(TimeInd-24*Time.StepInd+1:TimeInd), PVPredQH(TimeInd+DemoPlots{n}.Time.TD{k}-24*Time.StepInd+1:TimeInd+DemoPlots{n}.Time.TD{k},p), 'MaximumNumPoints',400, 'Color', PlotColors(p+1,:));
%     end
%     xticks(Time.Demo.VecDateNum(TimeInd-24*Time.Demo.StepInd+1:48:end))
%     xticklabels({datestr(Time.Demo.VecDateNum(TimeInd-24*Time.Demo.StepInd+1:48:end),'dd.mm HH:MM')})
%     xlim([Time.Demo.VecDateNum(TimeInd-36*Time.StepInd+max(0,-ForecastIntervalInd+24*Time.StepInd+ForecastDuration+Time.StepInd)) Time.Demo.VecDateNum(EndCounter+3)]) % Create a moving plot 
%     ylim([-round(PVPlants{Users{DemoUser}.PVPlant}.PeakPower)*10   ceil(PVPlants{Users{DemoUser}.PVPlant}.PeakPower)*1000])
%     legend(["PV Generation" "PV Prediction"],'Interpreter','none', 'Location', 'northwest')
% end
