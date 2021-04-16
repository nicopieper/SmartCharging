%% Define plot colors

PlotColors= [0.0000, 0.4470, 0.7410; 0.8500, 0.3250, 0.0980;... 
             0.9290, 0.6940, 0.1250; 0.4940, 0.1840, 0.5560;... 
             0.4660, 0.6740, 0.1880; 0.3010, 0.7450, 0.9330;...
             0.6350, 0.0780, 0.1840; 1,      0,      0;...
             0, 1, 0               ; 0,      0,      1];     


%% Set vehicle properties figure

UserPropertiesLabels=[...
    "Vehicle model:",               Users{DemoUser}.ModelName;
    "Yearly mileage:",              strcat(num2str(Users{DemoUser}.AverageMileageYear_km), " km");
    "Battery size:",                strcat(num2str(single(Users{DemoUser}.BatterySize)/1000), " kWh");
    "Max. power private charging:", strcat(num2str(single(Users{DemoUser}.ACChargingPowerHomeCharging)/1000), " kW");
    " 14a EnWG participation:",    "yes";
    "PV peak power:",               strcat(num2str(PVPlants{Users{DemoUser}.PVPlant}.PeakPower), " kW");
    "Home location:",               erase(PVPlants{Users{DemoUser}.PVPlant}.Location, '"')];
if ~Users{DemoUser}.GridConvenientCharging
    UserPropertiesLabels(5,2)="no";
end


figure('Renderer', 'painters', 'Position', [100 100 900 400])
uicontrol('Style','text', 'units','norm', 'pos', [0.1 0.9 0.4 0.08], 'string', strcat("User ", num2str(DemoUser)), 'FontSize', 16, 'HorizontalAlignment', 'left')

for l=1:size(UserPropertiesLabels,1)
    uicontrol('Style','text', 'units','norm', 'pos', [0.1 0.8-0.1*l 0.4 0.08], 'string', UserPropertiesLabels(l,1), 'FontSize', 16, 'HorizontalAlignment', 'left')
    uicontrol('Style','text', 'units','norm', 'pos', [0.5 0.8-0.1*l 0.4 0.08], 'string', UserPropertiesLabels(l,2), 'FontSize', 16, 'HorizontalAlignment', 'left')
end


%% Initialise Plots

ForecastDuration=0;
EndCounter=TimeInd;

NumPlotsCol=ceil(sqrt(length(DemoPlots)));
NumPlotsRow=ceil(length(DemoPlots)/NumPlotsCol);
figure(11)
for n=1:length(DemoPlots)
    fig{n}=subplot(NumPlotsRow,NumPlotsCol,n);
    cla reset
    title(strcat(DemoPlots{n}.Title, " at ", datestr(Time.Demo.Vec(TimeInd),'dd.mm.yyyy HH:MM')),'Interpreter','none')
    xlabel('Time')
    grid on
    hold on
    l=legend('Interpreter','none', 'Location', DemoPlots{n}.LegendLocation);
    Yaxes=[];
    
    for k=1:length(DemoPlots{n}.Data)
        DemoGetYLimits;
        Yaxes=[Yaxes; DemoPlots{n}.YAxis{k}];
    end

    
    DemoPlots{n}.Yaxes=unique(Yaxes)';
    
    for k=1:length(DemoPlots{n}.Data)
        
        if length(DemoPlots{n}.Yaxes)>=2
            if DemoPlots{n}.YAxis{k}==1
                yyaxis left
            else
                yyaxis right
            end
        end
        
        DemoPlots{n}.Fig{k}=animatedline(Time.Demo.VecDateNum(TimeInd-24*Time.StepInd+1:TimeInd), DemoPlots{n}.Data{k}(TimeInd+DemoPlots{n}.Time.TD{k}-24*Time.StepInd+1:TimeInd+DemoPlots{n}.Time.TD{k},1), 'MaximumNumPoints',400,  'Color', PlotColors(DemoPlots{n}.PlotColor{k},:), 'LineWidth',1.3);
        legappend(l, DemoPlots{n}.Label{k});
        ylabel(DemoPlots{n}.YLabel{k})
        
    end
    
    DemoUpdateYLimits;
    
    xticks(Time.Demo.VecDateNum(TimeInd-24*Time.StepInd+1:48:end));
    xticklabels({datestr(Time.Demo.VecDateNum(TimeInd-24*Time.StepInd+1:48:end),'dd.mm HH:MM')});
    xlim([Time.Demo.VecDateNum(TimeInd-36*Time.StepInd+max(0,-ForecastIntervalInd+24*Time.StepInd+ForecastDuration+Time.StepInd)) Time.Demo.VecDateNum(EndCounter+3)]) % Create a moving plot 
    ytickformat(DemoPlots{n}.Ytickformat);
    fig{n}.YRuler.Exponent = 0;
    
end