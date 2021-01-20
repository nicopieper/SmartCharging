%% Update title of subfigures

for n=1:length(DemoPlots)
    subplot(NumPlotsRow,NumPlotsCol,n)
    title(strcat(DemoPlots{n}.Title, " at ", datestr(Time.Demo.Vec(TimeInd),'dd.mm.yyyy HH:MM')),'Interpreter','none')
end

%% Update prediction plots

if ismember(TimeInd, TimesOfPreAlgo)
    PreAlgoTime=find(hour(Users{1}.TimeOfPreAlgo)==hour(Time.Demo.Vec(TimeInd)));

    ForcastLength=min(ForecastIntervalInd-1, length(Time.Demo.Vec)-TimeInd);
    for ForecastDuration=0:Time.Demo.StepIndForecast:min(ForecastIntervalInd-1, length(Time.Demo.Vec)-TimeInd)-(ForecastIntervalInd-size(Users{1}.ChargingMatSmart{PreAlgoTime,1},1))
        
        EndCounter=max(EndCounter,TimeInd+ForecastDuration+Time.Demo.StepIndForecast-1);
        
        for n=1:length(DemoPlots)
            subplot(NumPlotsRow,NumPlotsCol,n)
            
            for k=1:length(DemoPlots{n}.Data)
                
                if isfield(DemoPlots{n}, 'DataMat') && size(DemoPlots{n}.DataMat,2)>=k && size(DemoPlots{n}.DataMat,1)>=PreAlgoTime && ~isempty(DemoPlots{n}.DataMat{PreAlgoTime,k})
                    DemoPlots{n}.Data{k}(TimeInd+DemoPlots{n}.Time.TD{k}+ForecastDuration:TimeInd+DemoPlots{n}.Time.TD{k}+ForecastDuration+Time.Demo.StepIndForecast-1)=DemoPlots{n}.DataMat{PreAlgoTime,k}(ForecastDuration+1+(ForecastIntervalInd-size(Users{1}.ChargingMatSmart{PreAlgoTime,1},1)):ForecastDuration+(ForecastIntervalInd-size(Users{1}.ChargingMatSmart{PreAlgoTime,1},1))+Time.Demo.StepIndForecast,TimeInd+DemoPlots{n}.Time.TD{k});

                    if ForecastDuration<=ForcastLength-24*Time.Demo.StepIndForecast || PreAlgoTime~=1
                        clearpoints(DemoPlots{n}.Fig{k})
                        addpoints(DemoPlots{n}.Fig{k},Time.Demo.VecDateNum(max([Time.Demo.StartInd, TimeInd-300]):EndCounter),DemoPlots{n}.Data{k}(max([Time.Demo.StartInd+DemoPlots{n}.Time.TD{k}, TimeInd+DemoPlots{n}.Time.TD{k}-300]):EndCounter+DemoPlots{n}.Time.TD{k}))
                    else
                        addpoints(DemoPlots{n}.Fig{k},Time.Demo.VecDateNum(TimeInd+ForecastDuration:TimeInd+ForecastDuration+Time.Demo.StepIndForecast-1),DemoPlots{n}.Data{k}(TimeInd+DemoPlots{n}.Time.TD{k}+ForecastDuration:TimeInd+DemoPlots{n}.Time.TD{k}+ForecastDuration+Time.Demo.StepIndForecast-1))
                    end
                    
                end
            
                if PreAlgoTime==1
                    xlim([Time.Demo.VecDateNum(TimeInd-36*Time.StepInd+max(0,-ForecastIntervalInd+24*Time.StepInd+ForecastDuration+Time.Demo.StepIndForecast)) Time.Demo.VecDateNum(EndCounter+3)]) % Create a moving plot                 
                end
                DemoGetYLimits;
            end
            DemoUpdateYLimits; 
        end
        drawnow;
    end
end


%% Update real time plots

for n=1:length(DemoPlots)
    subplot(NumPlotsRow,NumPlotsCol,n)
    for k=1:length(DemoPlots{n}.Data)
        if ~isfield(DemoPlots{n}, 'DataMat') || size(DemoPlots{n}.DataMat,2)<k || isempty(DemoPlots{n}.DataMat{1,k})% all(all(cellfun(@isempty,DemoPlots{n}.DataMat)))
            addpoints(DemoPlots{n}.Fig{k},Time.Demo.VecDateNum(TimeInd:TimeInd+Time.Demo.StepInd-1),DemoPlots{n}.Data{k}(TimeInd+DemoPlots{n}.Time.TD{k}:TimeInd+DemoPlots{n}.Time.TD{k}+Time.Demo.StepInd-1))
            DemoGetYLimits;
        end
        if isfield(DemoPlots{n}, 'DataSource') && length(DemoPlots{n}.DataSource)>=k && ~isempty(DemoPlots{n}.DataSource{k})
            DemoPlots{n}.Data{k}(TimeInd+DemoPlots{n}.Time.TD{k}:TimeInd+DemoPlots{n}.Time.TD{k}+Time.Demo.StepInd-1)=DemoPlots{n}.DataSource{k}(TimeInd+DemoPlots{n}.Time.TD{k}:TimeInd+DemoPlots{n}.Time.TD{k}+Time.Demo.StepInd-1);
            clearpoints(DemoPlots{n}.Fig{k})
            addpoints(DemoPlots{n}.Fig{k},Time.Demo.VecDateNum(max([Time.Demo.StartInd, TimeInd-300]):EndCounter),DemoPlots{n}.Data{k}(max([Time.Demo.StartInd+DemoPlots{n}.Time.TD{k}, TimeInd+DemoPlots{n}.Time.TD{k}-300]):EndCounter+DemoPlots{n}.Time.TD{k}))
        end    
    end
    DemoUpdateYLimits;
end

drawnow;

