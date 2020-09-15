if hour(TimeVec(TimeInd))==hour(TimeOfForecast) && minute(TimeVec(TimeInd))==minute(TimeOfForecast)
    yminSpotmarket=min([SpotmarketReal(TimeInd-24*7*TimeStepInd:min(length(TimeVec),TimeInd+24*7*TimeStepInd)); SpotmarketPred(TimeInd-24*7*TimeStepInd:min(length(TimeVec),TimeInd+24*7*TimeStepInd))]);
    yminSpotmarket=round(yminSpotmarket-abs(yminSpotmarket)*0.1);
    ymaxSpotmarket=max([SpotmarketReal(TimeInd-24*7*TimeStepInd:min(length(TimeVec),TimeInd+24*7*TimeStepInd)); SpotmarketPred(TimeInd-24*7*TimeStepInd:min(length(TimeVec),TimeInd+24*7*TimeStepInd))]);
    ymaxSpotmarket=round(ymaxSpotmarket+abs(ymaxSpotmarket)*0.1);

    
%     addpoints(figSpotmarketPred{p}, TimeVecDateNum(TimeInd-400:TimeInd),SpotmarketPred(TimeInd-400:TimeInd))
%     clearpoints(figPVPred{p})
%     addpoints(figPVPred{p}, TimeVecDateNum(TimeInd-400:TimeInd),PVPredQH(TimeInd-400:TimeInd))
    
    ForcastLength=min(ForecastIntervalInd-1, RangeTestInd(2)-TimeInd);
    for ForecastDuration=0:TimeStepIndDemo:min(ForecastIntervalInd-1, RangeTestInd(2)-TimeInd)
        for p=1:NumPredMethod
%             figure(11)


            subplot(2,2,1)
            EndCounter=max(EndCounter,TimeInd+ForecastDuration+TimeStepIndDemo-1);
%             SpotmarketPred(TimeInd+ForecastDuration:TimeInd+ForecastDuration+TimeStepIndDemo-1)=SpotmarketPredMat(ForecastDuration+1:ForecastDuration+TimeStepIndDemo,round(days(TimeVec(TimeInd)-DemoStartDay)+1));
            SpotmarketPred(TimeInd+ForecastDuration:TimeInd+ForecastDuration+TimeStepIndDemo-1)=SpotmarketPredMat(ForecastDuration+1:ForecastDuration+TimeStepIndDemo,TimeInd);
            if ForecastDuration<=ForcastLength-24*TimeStepInd
                clearpoints(figSpotmarketPred{p})
                addpoints(figSpotmarketPred{p},TimeVecDateNum(max([DemoStart, TimeInd-300]):EndCounter),SpotmarketPred(max([DemoStart, TimeInd-300]):EndCounter))
%                 b{end+1,1}=SpotmarketPred(max([DemoStart, TimeInd-300]):EndCounter);
            else
                addpoints(figSpotmarketPred{p},TimeVecDateNum(TimeInd+ForecastDuration:TimeInd+ForecastDuration+TimeStepIndDemo-1),SpotmarketPred(TimeInd+ForecastDuration:TimeInd+ForecastDuration+TimeStepIndDemo-1))
            end
            %title(strcat(SpotmarketLabel, " ", datestr(TimeVec(TimeInd),'dd.mm.yyyy HH:MM')),'Interpreter','none')
            xlim([TimeVecDateNum(TimeInd-36*TimeStepInd+max(0,-ForecastIntervalInd+24*TimeStepInd+ForecastDuration+TimeStepIndDemo)) TimeVecDateNum(EndCounter+3)]) % Create a moving plot 
            ylim([yminSpotmarket ymaxSpotmarket])

            subplot(2,2,2)
            xlim([TimeVecDateNum(TimeInd-36*TimeStepInd+max(0,-ForecastIntervalInd+24*TimeStepInd+ForecastDuration+TimeStepIndDemo)) TimeVecDateNum(EndCounter+3)]) % Create a moving plot 

            subplot(2,2,3)
            xlim([TimeVecDateNum(TimeInd-36*TimeStepInd+max(0,-ForecastIntervalInd+24*TimeStepInd+ForecastDuration+TimeStepIndDemo)) TimeVecDateNum(EndCounter+3)]) % Create a moving plot 

            if ShowPVPred
                subplot(2,2,4)
%                 PVPredQH(TimeInd+ForecastDuration:TimeInd+ForecastDuration+TimeStepIndDemo-1)=PVPredMat(ForecastDuration+1:ForecastDuration+TimeStepIndDemo,round(days(TimeVec(TimeInd)-RangeTestDate(1))+1));
                PVPredQH(TimeInd+ForecastDuration:TimeInd+ForecastDuration+TimeStepIndDemo-1)=PVPredMat(ForecastDuration+1:ForecastDuration+TimeStepIndDemo,TimeInd);
                if ForecastDuration<=ForcastLength-24*TimeStepInd
                    clearpoints(figPVPred{p})
                    addpoints(figPVPred{p},TimeVecDateNum(max([DemoStart, TimeInd-300]):EndCounter),PVPredQH(max([DemoStart, TimeInd-300]):EndCounter))
                else
                    addpoints(figPVPred{p},TimeVecDateNum(TimeInd+ForecastDuration:TimeInd+ForecastDuration+TimeStepIndDemo-1),PVPredQH(TimeInd+ForecastDuration:TimeInd+ForecastDuration+TimeStepIndDemo-1))
                end
    %                 title(strcat(SpotmarketLabel, " ", datestr(TimeVec(TimeInd),'dd.mm.yyyy HH:MM')),'Interpreter','none')
                xlim([TimeVecDateNum(TimeInd-36*TimeStepInd+max(0,-ForecastIntervalInd+24*TimeStepInd+ForecastDuration+TimeStepIndDemo)) TimeVecDateNum(EndCounter+3)]) % Create a moving plot 
            end
            
            drawnow






%             subplot(2,2,1)
%             EndCounter=max(EndCounter,TimeInd+ForecastDuration);
%             SpotmarketPred(TimeInd+ForecastDuration)=SpotmarketPredMat(ForecastDuration+1,round(days(TimeVec(TimeInd)-RangeTestDate(1))+1));
%             figSpotmarketPred{p}.YDataSource='SpotmarketPred(max([DemoStart, TimeInd-300]):EndCounter,p)';
%             figSpotmarketPred{p}.XDataSource='TimeVec(max([DemoStart, TimeInd-300]):EndCounter)';                   
%             %title(strcat(SpotmarketLabel, " ", datestr(TimeVec(TimeInd),'dd.mm.yyyy HH:MM')),'Interpreter','none')
%             xlim([TimeVec(TimeInd-36*TimeStepInd+max(0,-ForecastIntervalInd+24*TimeStepInd+ForecastDuration+1)) TimeVec(EndCounter+3)]) % Create a moving plot 
%             ylim([yminSpotmarket ymaxSpotmarket])
% 
%             subplot(2,2,2)
%             xlim([TimeVec(TimeInd-36*TimeStepInd+max(0,-ForecastIntervalInd+24*TimeStepInd+ForecastDuration+1)) TimeVec(EndCounter+3)]) % Create a moving plot 
% 
%             subplot(2,2,3)
%             xlim([TimeVec(TimeInd-36*TimeStepInd+max(0,-ForecastIntervalInd+24*TimeStepInd+ForecastDuration+1)) TimeVec(EndCounter+3)]) % Create a moving plot 
% 
%             subplot(2,2,4)
%             PVPredQH(TimeInd+ForecastDuration)=PVPredMat(ForecastDuration+1,round(days(TimeVec(TimeInd)-RangeTestDate(1))+1));
%             figPVPred{p}.YDataSource='PVPredQH(max([DemoStart, TimeInd-300]):EndCounter,p)';
%             figPVPred{p}.XDataSource='TimeVec(max([DemoStart, TimeInd-300]):EndCounter)';                   
% %                 title(strcat(SpotmarketLabel, " ", datestr(TimeVec(TimeInd),'dd.mm.yyyy HH:MM')),'Interpreter','none')
%             xlim([TimeVec(TimeInd-36*TimeStepInd+max(0,-ForecastIntervalInd+24*TimeStepInd+ForecastDuration+1)) TimeVec(EndCounter+3)]) % Create a moving plot 
% 
%             refreshdata(figSpotmarketPred{p}, 'caller')
%             refreshdata(figPVPred{p}, 'caller')
%             pause(0.001)
        end
    end

    yminResPoDem=min(ResPoDemRealQH(TimeInd-24*7*TimeStepInd:min(length(TimeVec),TimeInd+24*7*TimeStepInd),:),[],'all');
    yminResPoDem=round(yminResPoDem-abs(yminResPoDem)*0.1);
    ymaxResPoDem=max(ResPoDemRealQH(TimeInd-24*7*TimeStepInd:min(length(TimeVec),TimeInd+24*7*TimeStepInd)),[],'all');
    ymaxResPoDem=round(ymaxResPoDem+abs(ymaxResPoDem)*0.1);

end




subplot(2,2,1)
addpoints(figSpotmarketReal,TimeVecDateNum(TimeInd:TimeInd+TimeStepIndDemo-1),SpotmarketReal(TimeInd:TimeInd+TimeStepIndDemo-1))
ylim([yminSpotmarket ymaxSpotmarket])
% title(strcat(SpotmarketLabel, " ", datestr(TimeVec(TimeInd),'dd.mm.yyyy HH:MM')),'Interpreter','none')

subplot(2,2,2)
addpoints(figResPoDemRealNeg,TimeVecDateNum(TimeInd:TimeInd+TimeStepIndDemo-1),ResPoDemRealQH(TimeInd:TimeInd+TimeStepIndDemo-1,1))
addpoints(figResPoDemRealPos,TimeVecDateNum(TimeInd:TimeInd+TimeStepIndDemo-1),ResPoDemRealQH(TimeInd:TimeInd+TimeStepIndDemo-1,2))
% title(strcat(ResPoDemLabel, " ", datestr(TimeVec(TimeInd),'dd.mm.yyyy HH:MM')),'Interpreter','none')
ylim([yminResPoDem ymaxResPoDem])

subplot(2,2,3)
addpoints(figSoCPlot,TimeVecDateNum(TimeInd:TimeInd+TimeStepIndDemo-1),double(Users{DemoUser}.LogbookBase(TimeInd:TimeInd+TimeStepIndDemo-1,7))/double(Users{DemoUser}.BatterySize))
% title(strcat(SoCPlotLabel, " ", datestr(TimeVec(TimeInd),'dd.mm.yyyy HH:MM')),'Interpreter','none')

if ShowPVPred
    subplot(2,2,4)
    addpoints(figPVPlot,TimeVecDateNum(TimeInd:TimeInd+TimeStepIndDemo-1),double(PVPlants{Users{DemoUser}.PVPlant}.Profile(TimeInd:TimeInd+TimeStepIndDemo-1)))
    % title(strcat(PVPlotLabel, " ", datestr(TimeVec(TimeInd),'dd.mm.yyyy HH:MM')),'Interpreter','none')
    % pause(0.001)
end
    
drawnow










% subplot(2,2,1)
% figSpotmarketReal.YDataSource='SpotmarketReal(max([DemoStart-30, TimeInd-300]):TimeInd)';
% figSpotmarketReal.XDataSource='TimeVec(max([DemoStart-30, TimeInd-300]):TimeInd)';
% title(strcat(SpotmarketLabel, " ", datestr(TimeVec(TimeInd),'dd.mm.yyyy HH:MM')),'Interpreter','none')
% ylim([yminSpotmarket ymaxSpotmarket])      
% refreshdata(figSpotmarketReal, 'caller')
% 
% subplot(2,2,2)
% set(figResPoDemReal, {'YData'}, {ResPoDemRealQH(max([DemoStart-30, TimeInd-300]):TimeInd,1); ResPoDemRealQH(max([DemoStart, TimeInd-300]):TimeInd,2)})
% set(figResPoDemReal, {'XData'}, {TimeVec(max([DemoStart-30, TimeInd-300]):TimeInd); TimeVec(max([DemoStart, TimeInd-300]):TimeInd)})
% title(strcat(ResPoDemLabel, " ", datestr(TimeVec(TimeInd),'dd.mm.yyyy HH:MM')),'Interpreter','none')
% ylim([yminResPoDem ymaxResPoDem])   
% refreshdata(figResPoDemReal, 'caller')
% 
% subplot(2,2,3)
% set(figSoCPlot, {'YData'}, {single(Users{DemoUser}.LogbookBase(max([DemoStart-30, TimeInd-300]):TimeInd,7))/single(Users{DemoUser}.BatterySize)})
% set(figSoCPlot, {'XData'}, {TimeVec(max([DemoStart-30, TimeInd-300]):TimeInd)})
% title(strcat(SoCPlotLabel, " ", datestr(TimeVec(TimeInd),'dd.mm.yyyy HH:MM')),'Interpreter','none')
% refreshdata(figSoCPlot, 'caller')
% 
% subplot(2,2,4)
% set(figPVPlot, {'YData'}, {PVPlants{Users{DemoUser}.PVPlant}.Profile(max([DemoStart-30, TimeInd-300]):TimeInd)})
% set(figPVPlot, {'XData'}, {TimeVec(max([DemoStart-30, TimeInd-300]):TimeInd)})
% title(strcat(PVPlotLabel, " ", datestr(TimeVec(TimeInd),'dd.mm.yyyy HH:MM')),'Interpreter','none')
% refreshdata(figPVPlot, 'caller')
% pause(0.001)













% refreshdata(figure(11), 'caller')
%         refreshdata(figSpotmarketReal, 'caller')
%         refreshdata(figResPoDemReal, 'caller')
% pause(0.01)