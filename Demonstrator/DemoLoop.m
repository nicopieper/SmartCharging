%% Description
% This script executes the real demonstration iteratively. The
% demonstration is split into optimisation phases and time progress phases.
% During the optimisation phases the charging schedules are recalculated
% and the results are shwon using animated lines. During the time progress
% phases, the users are driving, parking and charging. Hence, their SoC
% changes and the fleet's real load profile changes.

% Depended scripts / folders
%   Initialisation.m        Needed for the execution of this script
%   Demonstration.m         This script is called by Demonstration.m


%% Update title of subfigures

for n=1:length(DemoPlots)
    subplot(NumPlotsRow,NumPlotsCol,n)
    title(strcat(DemoPlots{n}.Title, " at ", datestr(Time.Demo.Vec(TimeInd),'dd.mm.yyyy HH:MM')),'Interpreter','none')
end


%% Update prediction plots (optimisation phase)

if ismember(TimeInd, TimesOfPreAlgo) % if this time step is part of an optimisation phase 
    PreAlgoTime=find(hour(Users{1}.TimeOfPreAlgo)==hour(Time.Demo.Vec(TimeInd)));

    ForcastLength=min(ForecastIntervalInd-1, length(Time.Demo.Vec)-TimeInd);
    for ForecastDuration=0:Time.Demo.StepIndForecast:min(ForecastIntervalInd-1, length(Time.Demo.Vec)-TimeInd)-(ForecastIntervalInd-size(Users{1}.ChargingMat{PreAlgoTime,1},1))
        
        EndCounter=max(EndCounter,TimeInd+ForecastDuration+Time.Demo.StepIndForecast-1);
        
        for n=1:length(DemoPlots) % iterate through the plots
            subplot(NumPlotsRow,NumPlotsCol,n)
            
            for k=1:length(DemoPlots{n}.Data) % iterate through the graphs
                
                if isfield(DemoPlots{n}, 'DataMat') && size(DemoPlots{n}.DataMat,2)>=k && size(DemoPlots{n}.DataMat,1)>=PreAlgoTime && ~isempty(DemoPlots{n}.DataMat{PreAlgoTime,k})
                    DemoPlots{n}.Data{k}(TimeInd+DemoPlots{n}.Time.TD{k}+ForecastDuration:TimeInd+DemoPlots{n}.Time.TD{k}+ForecastDuration+Time.Demo.StepIndForecast-1)=DemoPlots{n}.DataMat{PreAlgoTime,k}(ForecastDuration+1+(ForecastIntervalInd-size(Users{1}.ChargingMat{PreAlgoTime,1},1)):ForecastDuration+(ForecastIntervalInd-size(Users{1}.ChargingMat{PreAlgoTime,1},1))+Time.Demo.StepIndForecast,TimeInd+DemoPlots{n}.Time.TD{k});

                    if ForecastDuration<=ForcastLength-24*Time.Demo.StepInd || PreAlgoTime~=1 % the optimisation phase is split into two phases: An update phase and a new values phases. During the update phase existing values are recalculated, during the new values phases values for times that were not calculated yet are calculated
                        clearpoints(DemoPlots{n}.Fig{k}) % update phase --> delete old values
                        addpoints(DemoPlots{n}.Fig{k},Time.Demo.VecDateNum(max([Time.Demo.StartInd, TimeInd-300]):EndCounter),DemoPlots{n}.Data{k}(max([Time.Demo.StartInd+DemoPlots{n}.Time.TD{k}, TimeInd+DemoPlots{n}.Time.TD{k}-300]):EndCounter+DemoPlots{n}.Time.TD{k})) % replace them by new calculated values
                    else % new values phase
                        addpoints(DemoPlots{n}.Fig{k},Time.Demo.VecDateNum(TimeInd+ForecastDuration:TimeInd+ForecastDuration+Time.Demo.StepIndForecast-1),DemoPlots{n}.Data{k}(TimeInd+DemoPlots{n}.Time.TD{k}+ForecastDuration:TimeInd+DemoPlots{n}.Time.TD{k}+ForecastDuration+Time.Demo.StepIndForecast-1)) % add new calucated values
                    end
                    
                end
            
                if PreAlgoTime==1 % update X axes limits
                    xlim([Time.Demo.VecDateNum(TimeInd-36*Time.StepInd+max(0,-ForecastIntervalInd+24*Time.StepInd+ForecastDuration+Time.Demo.StepIndForecast)) Time.Demo.VecDateNum(EndCounter+3)]) % Create a moving plot                 
                end
                DemoGetYLimits;
            end
            DemoUpdateYLimits; 
        end
        drawnow;
    end
end


%% Update real time plots (time progress phase)

for n=1:length(DemoPlots) % iterate through the plots
    subplot(NumPlotsRow,NumPlotsCol,n)
    for k=1:length(DemoPlots{n}.Data) % iterate through the graphs
        % there are two types of graphs: DataMat represents graphs which
        % values are recaluclated and updated (like the load profiles as
        % they are recalcualted each optimisation phase). DataSource
        % represents graphs which values do not change once they are
        % plotted (like the real spot market price values)
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

