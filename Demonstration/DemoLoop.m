%% New

for n=1:length(DemoPlots)
    subplot(NumPlotsRow,NumPlotsCol,n)
    title(strcat(DemoPlots{n}.Title, " at ", datestr(Time.Demo.Vec(TimeInd),'dd.mm.yyyy HH:MM')),'Interpreter','none')
end

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



%%
% 
% subplot(2,2,1)
% addpoints(figDemoPlots{1}.Data,Time.Demo.VecDateNum(TimeInd:TimeInd+Time.Demo.StepIndForecast-1),DemoPlots{1}.Data(TimeInd+TD.Main:TimeInd+TD.Main+Time.Demo.StepIndForecast-1))
% ylim([yminSpotmarket ymaxSpotmarket])
% 
% subplot(2,2,2)
% addpoints(figResPoDemRealNeg,Time.Demo.VecDateNum(TimeInd:TimeInd+Time.Demo.StepIndForecast-1),ResPoDemRealQH(TimeInd+TD.Main:TimeInd+TD.Main+Time.Demo.StepIndForecast-1,1))
% addpoints(figResPoDemRealPos,Time.Demo.VecDateNum(TimeInd:TimeInd+Time.Demo.StepIndForecast-1),ResPoDemRealQH(TimeInd+TD.Main:TimeInd+TD.Main+Time.Demo.StepIndForecast-1,2))
% ylim([yminResPoDem ymaxResPoDem])
% 
% subplot(2,2,3)
% addpoints(figSoCPlot,Time.Demo.VecDateNum(TimeInd:TimeInd+Time.Demo.StepIndForecast-1),double(Users{DemoUser}.LogbookBase(TimeInd+TD.User:TimeInd+TD.User+Time.Demo.StepIndForecast-1,9))/double(Users{DemoUser}.BatterySize))
% 
% if ShowPVPred
%     subplot(2,2,4)
%     addpoints(figPVPlot,Time.Demo.VecDateNum(TimeInd:TimeInd+Time.Demo.StepIndForecast-1),PVQH(TimeInd+TD.Main:TimeInd+TD.Main+Time.Demo.StepIndForecast-1))
% end
%     
% drawnow
% 
%     
%     
% 
% subplot(2,2,1)
% title(strcat(DemoPlots{1}.Label{1}, " ", datestr(Time.Demo.Vec(TimeInd),'dd.mm.yyyy HH:MM')),'Interpreter','none')
% 
% subplot(2,2,2)
% title(strcat(DemoPlots{2}.Label{1}, " ", datestr(Time.Demo.Vec(TimeInd),'dd.mm.yyyy HH:MM')),'Interpreter','none')
% ylim([yminResPoDem ymaxResPoDem])
% 
% subplot(2,2,3)
% title(strcat(DemoPlots{3}.Label{1}, " ", datestr(Time.Demo.Vec(TimeInd),'dd.mm.yyyy HH:MM')),'Interpreter','none')
% 
% if ShowPVPred
%     subplot(2,2,4)
%     title(strcat(PVPlotLabel, " ", datestr(Time.Demo.Vec(TimeInd),'dd.mm.yyyy HH:MM')),'Interpreter','none')
% end
% 
% 
% 
% 
% 
% 
% 
% 
% 
% 
% if hour(Time.Demo.Vec(TimeInd))==hour(TimeOfForecast) && minute(Time.Demo.Vec(TimeInd))==minute(TimeOfForecast)
%     yminSpotmarket=min([DemoPlots{1}.Data(TimeInd+TD.Main-24*7*Time.Demo.StepIndForecast:min(length(Time.Vec),TimeInd+TD.Main+24*7*Time.Demo.StepIndForecast)); DemoPlots{1}.Data{2}(TimeInd+TD.DemoPlots{1}.Data{2}-24*7*Time.Demo.StepIndForecast:min(length(Time.Vec),TimeInd+TD.DemoPlots{1}.Data{2}+24*7*Time.Demo.StepIndForecast))]);
%     yminSpotmarket=round(yminSpotmarket-abs(yminSpotmarket)*0.1);
%     ymaxSpotmarket=max([DemoPlots{1}.Data(TimeInd+TD.Main-24*7*Time.Demo.StepIndForecast:min(length(Time.Vec),TimeInd+TD.Main+24*7*Time.Demo.StepIndForecast)); DemoPlots{1}.Data{2}(TimeInd+TD.DemoPlots{1}.Data{2}-24*7*Time.Demo.StepIndForecast:min(length(Time.Vec),TimeInd+TD.DemoPlots{1}.Data{2}+24*7*Time.Demo.StepIndForecast))]);
%     ymaxSpotmarket=round(ymaxSpotmarket+abs(ymaxSpotmarket)*0.1);
% 
%     
% %     addpoints(figDemoPlots{1}.Data{2}{p}, Time.Demo.VecDateNum(TimeInd-400:TimeInd),DemoPlots{1}.Data{2}(TimeInd-400:TimeInd))
% %     clearpoints(figPVPred{p})
% %     addpoints(figPVPred{p}, Time.Demo.VecDateNum(TimeInd-400:TimeInd),PVPredQH(TimeInd-400:TimeInd))
%     
%     ForcastLength=min(ForecastIntervalInd-1, length(Time.Demo.Vec)-TimeInd);
%     for ForecastDuration=0:Time.Demo.StepIndForecast:min(ForecastIntervalInd-1, length(Time.Demo.Vec)-TimeInd)
%         for p=1:NumPredMethod
% %             figure(11)
% 
% 
%             subplot(2,2,1)
%             EndCounter=max(EndCounter,TimeInd+ForecastDuration+Time.Demo.StepIndForecast-1);
% %             DemoPlots{1}.Data{2}(TimeInd+ForecastDuration:TimeInd+ForecastDuration+Time.Demo.StepIndForecast-1)=DemoPlots{1}.DataMat{2}(ForecastDuration+1:ForecastDuration+Time.Demo.StepIndForecast,round(days(Time.Demo.Vec(TimeInd)-Time.Demo.StartIndDay)+1));
%             DemoPlots{1}.Data{2}(TimeInd+TD.DemoPlots{1}.Data{2}+ForecastDuration:TimeInd+TD.DemoPlots{1}.Data{2}+ForecastDuration+Time.Demo.StepIndForecast-1)=DemoPlots{1}.DataMat{2}(ForecastDuration+1:ForecastDuration+Time.Demo.StepIndForecast,TimeInd+TD.DemoPlots{1}.Data{2});
%             if ForecastDuration<=ForcastLength-24*Time.Demo.StepIndForecast
%                 clearpoints(figDemoPlots{1}.Data{2}{p})
%                 addpoints(figDemoPlots{1}.Data{2}{p},Time.Demo.VecDateNum(max([Time.Demo.StartInd, TimeInd-300]):EndCounter),DemoPlots{1}.Data{2}(max([Time.Demo.StartInd+TD.DemoPlots{1}.Data{2}, TimeInd+TD.DemoPlots{1}.Data{2}-300]):EndCounter+TD.DemoPlots{1}.Data{2}))
% %                 b{end+1,1}=DemoPlots{1}.Data{2}(max([Time.Demo.StartInd, TimeInd-300]):EndCounter);
%             else
%                 addpoints(figDemoPlots{1}.Data{2}{p},Time.Demo.VecDateNum(TimeInd+ForecastDuration:TimeInd+ForecastDuration+Time.Demo.StepIndForecast-1),DemoPlots{1}.Data{2}(TimeInd+TD.DemoPlots{1}.Data{2}+ForecastDuration:TimeInd+TD.DemoPlots{1}.Data{2}+ForecastDuration+Time.Demo.StepIndForecast-1))
%             end
%             %title(strcat(DemoPlots{1}.Label{1}, " ", datestr(Time.Demo.Vec(TimeInd),'dd.mm.yyyy HH:MM')),'Interpreter','none')
%             xlim([Time.Demo.VecDateNum(TimeInd-36*Time.StepInd+max(0,-ForecastIntervalInd+24*Time.StepInd+ForecastDuration+Time.Demo.StepIndForecast)) Time.Demo.VecDateNum(EndCounter+3)]) % Create a moving plot 
%             ylim([yminSpotmarket ymaxSpotmarket])
% 
%             subplot(2,2,2)
%             xlim([Time.Demo.VecDateNum(TimeInd-36*Time.StepInd+max(0,-ForecastIntervalInd+24*Time.StepInd+ForecastDuration+Time.Demo.StepIndForecast)) Time.Demo.VecDateNum(EndCounter+3)]) % Create a moving plot 
% 
%             subplot(2,2,3)
%             xlim([Time.Demo.VecDateNum(TimeInd-36*Time.StepInd+max(0,-ForecastIntervalInd+24*Time.StepInd+ForecastDuration+Time.Demo.StepIndForecast)) Time.Demo.VecDateNum(EndCounter+3)]) % Create a moving plot 
% 
%             if ShowPVPred
%                 subplot(2,2,4)
% %                 PVPredQH(TimeInd+ForecastDuration:TimeInd+ForecastDuration+Time.Demo.StepIndForecast-1)=PVPredMat(ForecastDuration+1:ForecastDuration+Time.Demo.StepIndForecast,round(days(Time.Demo.Vec(TimeInd)-RangeTestDate(1))+1));
%                 %PVPredQH(TimeInd+ForecastDuration:TimeInd+ForecastDuration+Time.Demo.StepIndForecast-1)=PVPredMat(ForecastDuration+1:ForecastDuration+Time.Demo.StepIndForecast,TimeInd);
%                 if ForecastDuration<=ForcastLength-24*Time.Demo.StepIndForecast
%                     clearpoints(figPVPred{p})
%                     addpoints(figPVPred{p},Time.Demo.VecDateNum(max([Time.Demo.StartInd, TimeInd-300]):EndCounter),PVPredQH(max([Time.Demo.StartInd+TD.Main, TimeInd+TD.Main-300]):EndCounter+TD.Main))
%                 else
%                     addpoints(figPVPred{p},Time.Demo.VecDateNum(TimeInd+ForecastDuration:TimeInd+ForecastDuration+Time.Demo.StepIndForecast-1),PVPredQH(TimeInd+TD.Main+ForecastDuration:TimeInd+TD.Main+ForecastDuration+Time.Demo.StepIndForecast-1))
%                 end
%                 %title(strcat(DemoPlots{1}.Label{1}, " ", datestr(Time.Demo.Vec(TimeInd),'dd.mm.yyyy HH:MM')),'Interpreter','none')
%                 xlim([Time.Demo.VecDateNum(TimeInd-36*Time.StepInd+max(0,-ForecastIntervalInd+24*Time.Demo.StepIndForecast+ForecastDuration+Time.Demo.StepIndForecast)) Time.Demo.VecDateNum(EndCounter+3)]) % Create a moving plot 
%             end
%             
%             drawnow
% 
% 
% 
% 
% 
% 
% %             subplot(2,2,1)
% %             EndCounter=max(EndCounter,TimeInd+ForecastDuration);
% %             DemoPlots{1}.Data{2}(TimeInd+ForecastDuration)=DemoPlots{1}.DataMat{2}(ForecastDuration+1,round(days(Time.Demo.Vec(TimeInd)-RangeTestDate(1))+1));
% %             figDemoPlots{1}.Data{2}{p}.YDataSource='DemoPlots{1}.Data{2}(max([Time.Demo.StartInd, TimeInd-300]):EndCounter,p)';
% %             figDemoPlots{1}.Data{2}{p}.XDataSource='Time.Vec(max([Time.Demo.StartInd, TimeInd-300]):EndCounter)';                   
% %             %title(strcat(DemoPlots{1}.Label{1}, " ", datestr(Time.Demo.Vec(TimeInd),'dd.mm.yyyy HH:MM')),'Interpreter','none')
% %             xlim([Time.Vec(TimeInd-36*Time.Demo.StepIndForecast+max(0,-ForecastIntervalInd+24*Time.Demo.StepIndForecast+ForecastDuration+1)) Time.Vec(EndCounter+3)]) % Create a moving plot 
% %             ylim([yminSpotmarket ymaxSpotmarket])
% % 
% %             subplot(2,2,2)
% %             xlim([Time.Vec(TimeInd-36*Time.Demo.StepIndForecast+max(0,-ForecastIntervalInd+24*Time.Demo.StepIndForecast+ForecastDuration+1)) Time.Vec(EndCounter+3)]) % Create a moving plot 
% % 
% %             subplot(2,2,3)
% %             xlim([Time.Vec(TimeInd-36*Time.Demo.StepIndForecast+max(0,-ForecastIntervalInd+24*Time.Demo.StepIndForecast+ForecastDuration+1)) Time.Vec(EndCounter+3)]) % Create a moving plot 
% % 
% %             subplot(2,2,4)
% %             PVPredQH(TimeInd+ForecastDuration)=PVPredMat(ForecastDuration+1,round(days(Time.Demo.Vec(TimeInd)-RangeTestDate(1))+1));
% %             figPVPred{p}.YDataSource='PVPredQH(max([Time.Demo.StartInd, TimeInd-300]):EndCounter,p)';
% %             figPVPred{p}.XDataSource='Time.Vec(max([Time.Demo.StartInd, TimeInd-300]):EndCounter)';                   
% % %                 title(strcat(DemoPlots{1}.Label{1}, " ", datestr(Time.Demo.Vec(TimeInd),'dd.mm.yyyy HH:MM')),'Interpreter','none')
% %             xlim([Time.Vec(TimeInd-36*Time.Demo.StepIndForecast+max(0,-ForecastIntervalInd+24*Time.Demo.StepIndForecast+ForecastDuration+1)) Time.Vec(EndCounter+3)]) % Create a moving plot 
% % 
% %             refreshdata(figDemoPlots{1}.Data{2}{p}, 'caller')
% %             refreshdata(figPVPred{p}, 'caller')
% %             pause(0.001)
%         end
%     end
% 
%     yminResPoDem=min(ResPoDemRealQH(TimeInd+TD.Main-24*7*Time.Demo.StepIndForecast:min(length(Time.Vec),TimeInd+TD.Main+24*7*Time.Demo.StepIndForecast),:),[],'all');
%     yminResPoDem=round(yminResPoDem-abs(yminResPoDem)*0.1);
%     ymaxResPoDem=max(ResPoDemRealQH(TimeInd+TD.Main-24*7*Time.Demo.StepIndForecast:min(length(Time.Vec),TimeInd+TD.Main+24*7*Time.Demo.StepIndForecast)),[],'all');
%     ymaxResPoDem=round(ymaxResPoDem+abs(ymaxResPoDem)*0.1);
% 
% end
% 
% 
% 
% 
% subplot(2,2,1)
% addpoints(figDemoPlots{1}.Data,Time.Demo.VecDateNum(TimeInd:TimeInd+Time.Demo.StepIndForecast-1),DemoPlots{1}.Data(TimeInd+TD.Main:TimeInd+TD.Main+Time.Demo.StepIndForecast-1))
% ylim([yminSpotmarket ymaxSpotmarket])
% 
% subplot(2,2,2)
% addpoints(figResPoDemRealNeg,Time.Demo.VecDateNum(TimeInd:TimeInd+Time.Demo.StepIndForecast-1),ResPoDemRealQH(TimeInd+TD.Main:TimeInd+TD.Main+Time.Demo.StepIndForecast-1,1))
% addpoints(figResPoDemRealPos,Time.Demo.VecDateNum(TimeInd:TimeInd+Time.Demo.StepIndForecast-1),ResPoDemRealQH(TimeInd+TD.Main:TimeInd+TD.Main+Time.Demo.StepIndForecast-1,2))
% ylim([yminResPoDem ymaxResPoDem])
% 
% subplot(2,2,3)
% addpoints(figSoCPlot,Time.Demo.VecDateNum(TimeInd:TimeInd+Time.Demo.StepIndForecast-1),double(Users{DemoUser}.LogbookBase(TimeInd+TD.User:TimeInd+TD.User+Time.Demo.StepIndForecast-1,9))/double(Users{DemoUser}.BatterySize))
% 
% if ShowPVPred
%     subplot(2,2,4)
%     addpoints(figPVPlot,Time.Demo.VecDateNum(TimeInd:TimeInd+Time.Demo.StepIndForecast-1),PVQH(TimeInd+TD.Main:TimeInd+TD.Main+Time.Demo.StepIndForecast-1))
% end
%     
% drawnow
% 
% 
% 
% 
% 
% 
% 
% 
% 
% 
% % subplot(2,2,1)
% % figDemoPlots{1}.Data.YDataSource='DemoPlots{1}.Data(max([Time.Demo.StartInd-30, TimeInd-300]):TimeInd)';
% % figDemoPlots{1}.Data.XDataSource='Time.Vec(max([Time.Demo.StartInd-30, TimeInd-300]):TimeInd)';
% % title(strcat(DemoPlots{1}.Label{1}, " ", datestr(Time.Demo.Vec(TimeInd),'dd.mm.yyyy HH:MM')),'Interpreter','none')
% % ylim([yminSpotmarket ymaxSpotmarket])      
% % refreshdata(figDemoPlots{1}.Data, 'caller')
% % 
% % subplot(2,2,2)
% % set(figResPoDemReal, {'YData'}, {ResPoDemRealQH(max([Time.Demo.StartInd-30, TimeInd-300]):TimeInd,1); ResPoDemRealQH(max([Time.Demo.StartInd, TimeInd-300]):TimeInd,2)})
% % set(figResPoDemReal, {'XData'}, {Time.Vec(max([Time.Demo.StartInd-30, TimeInd-300]):TimeInd); Time.Vec(max([Time.Demo.StartInd, TimeInd-300]):TimeInd)})
% % title(strcat(DemoPlots{2}.Label{1}, " ", datestr(Time.Demo.Vec(TimeInd),'dd.mm.yyyy HH:MM')),'Interpreter','none')
% % ylim([yminResPoDem ymaxResPoDem])   
% % refreshdata(figResPoDemReal, 'caller')
% % 
% % subplot(2,2,3)
% % set(figSoCPlot, {'YData'}, {single(Users{DemoUser}.LogbookBase(max([Time.Demo.StartInd-30, TimeInd-300]):TimeInd,7))/single(Users{DemoUser}.BatterySize)})
% % set(figSoCPlot, {'XData'}, {Time.Vec(max([Time.Demo.StartInd-30, TimeInd-300]):TimeInd)})
% % title(strcat(DemoPlots{3}.Label{1}, " ", datestr(Time.Demo.Vec(TimeInd),'dd.mm.yyyy HH:MM')),'Interpreter','none')
% % refreshdata(figSoCPlot, 'caller')
% % 
% % subplot(2,2,4)
% % set(figPVPlot, {'YData'}, {PVPlants{Users{DemoUser}.PVPlant}.Profile(max([Time.Demo.StartInd-30, TimeInd-300]):TimeInd)})
% % set(figPVPlot, {'XData'}, {Time.Vec(max([Time.Demo.StartInd-30, TimeInd-300]):TimeInd)})
% % title(strcat(PVPlotLabel, " ", datestr(Time.Demo.Vec(TimeInd),'dd.mm.yyyy HH:MM')),'Interpreter','none')
% % refreshdata(figPVPlot, 'caller')
% % pause(0.001)
% 
% 
% 
% 
% 
% 
% 
% 
% 
% 
% 
% 
% 
% % refreshdata(figure(11), 'caller')
% %         refreshdata(figDemoPlots{1}.Data, 'caller')
% %         refreshdata(figResPoDemReal, 'caller')
% % pause(0.01)