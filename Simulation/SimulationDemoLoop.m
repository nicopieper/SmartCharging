subplot(2,2,1)
title(strcat(SpotmarketLabel, " ", datestr(Time.Demo.Vec(TimeInd),'dd.mm.yyyy HH:MM')),'Interpreter','none')

subplot(2,2,2)
title(strcat(ResPoDemLabel, " ", datestr(Time.Demo.Vec(TimeInd),'dd.mm.yyyy HH:MM')),'Interpreter','none')
ylim([yminResPoDem ymaxResPoDem])

subplot(2,2,3)
title(strcat(SoCPlotLabel, " ", datestr(Time.Demo.Vec(TimeInd),'dd.mm.yyyy HH:MM')),'Interpreter','none')

if ShowPVPred
    subplot(2,2,4)
    title(strcat(PVPlotLabel, " ", datestr(Time.Demo.Vec(TimeInd),'dd.mm.yyyy HH:MM')),'Interpreter','none')
end



if hour(Time.Demo.Vec(TimeInd))==hour(TimeOfForecast) && minute(Time.Demo.Vec(TimeInd))==minute(TimeOfForecast)
    yminSpotmarket=min([SpotmarketReal(TimeInd+TD.Main-24*7*Time.Demo.StepInd:min(length(Time.Vec),TimeInd+TD.Main+24*7*Time.Demo.StepInd)); SpotmarketPred(TimeInd+TD.SpotmarketPred-24*7*Time.Demo.StepInd:min(length(Time.Vec),TimeInd+TD.SpotmarketPred+24*7*Time.Demo.StepInd))]);
    yminSpotmarket=round(yminSpotmarket-abs(yminSpotmarket)*0.1);
    ymaxSpotmarket=max([SpotmarketReal(TimeInd+TD.Main-24*7*Time.Demo.StepInd:min(length(Time.Vec),TimeInd+TD.Main+24*7*Time.Demo.StepInd)); SpotmarketPred(TimeInd+TD.SpotmarketPred-24*7*Time.Demo.StepInd:min(length(Time.Vec),TimeInd+TD.SpotmarketPred+24*7*Time.Demo.StepInd))]);
    ymaxSpotmarket=round(ymaxSpotmarket+abs(ymaxSpotmarket)*0.1);

    
%     addpoints(figSpotmarketPred{p}, Time.Demo.VecDateNum(TimeInd-400:TimeInd),SpotmarketPred(TimeInd-400:TimeInd))
%     clearpoints(figPVPred{p})
%     addpoints(figPVPred{p}, Time.Demo.VecDateNum(TimeInd-400:TimeInd),PVPredQH(TimeInd-400:TimeInd))
    
    ForcastLength=min(ForecastIntervalInd-1, length(Time.Demo.Vec)-TimeInd);
    for ForecastDuration=0:Time.Demo.StepInd:min(ForecastIntervalInd-1, length(Time.Demo.Vec)-TimeInd)
        for p=1:NumPredMethod
%             figure(11)


            subplot(2,2,1)
            EndCounter=max(EndCounter,TimeInd+ForecastDuration+Time.Demo.StepInd-1);
%             SpotmarketPred(TimeInd+ForecastDuration:TimeInd+ForecastDuration+Time.Demo.StepInd-1)=SpotmarketPredMat(ForecastDuration+1:ForecastDuration+Time.Demo.StepInd,round(days(Time.Demo.Vec(TimeInd)-Time.Demo.StartIndDay)+1));
            SpotmarketPred(TimeInd+TD.SpotmarketPred+ForecastDuration:TimeInd+TD.SpotmarketPred+ForecastDuration+Time.Demo.StepInd-1)=SpotmarketPredMat(ForecastDuration+1:ForecastDuration+Time.Demo.StepInd,TimeInd+TD.SpotmarketPred);
            if ForecastDuration<=ForcastLength-24*Time.Demo.StepInd
                clearpoints(figSpotmarketPred{p})
                addpoints(figSpotmarketPred{p},Time.Demo.VecDateNum(max([Time.Demo.StartInd, TimeInd-300]):EndCounter),SpotmarketPred(max([Time.Demo.StartInd+TD.SpotmarketPred, TimeInd+TD.SpotmarketPred-300]):EndCounter+TD.SpotmarketPred))
%                 b{end+1,1}=SpotmarketPred(max([Time.Demo.StartInd, TimeInd-300]):EndCounter);
            else
                addpoints(figSpotmarketPred{p},Time.Demo.VecDateNum(TimeInd+ForecastDuration:TimeInd+ForecastDuration+Time.Demo.StepInd-1),SpotmarketPred(TimeInd+TD.SpotmarketPred+ForecastDuration:TimeInd+TD.SpotmarketPred+ForecastDuration+Time.Demo.StepInd-1))
            end
            %title(strcat(SpotmarketLabel, " ", datestr(Time.Demo.Vec(TimeInd),'dd.mm.yyyy HH:MM')),'Interpreter','none')
            xlim([Time.Demo.VecDateNum(TimeInd-36*Time.StepInd+max(0,-ForecastIntervalInd+24*Time.StepInd+ForecastDuration+Time.Demo.StepInd)) Time.Demo.VecDateNum(EndCounter+3)]) % Create a moving plot 
            ylim([yminSpotmarket ymaxSpotmarket])

            subplot(2,2,2)
            xlim([Time.Demo.VecDateNum(TimeInd-36*Time.StepInd+max(0,-ForecastIntervalInd+24*Time.StepInd+ForecastDuration+Time.Demo.StepInd)) Time.Demo.VecDateNum(EndCounter+3)]) % Create a moving plot 

            subplot(2,2,3)
            xlim([Time.Demo.VecDateNum(TimeInd-36*Time.StepInd+max(0,-ForecastIntervalInd+24*Time.StepInd+ForecastDuration+Time.Demo.StepInd)) Time.Demo.VecDateNum(EndCounter+3)]) % Create a moving plot 

            if ShowPVPred
                subplot(2,2,4)
%                 PVPredQH(TimeInd+ForecastDuration:TimeInd+ForecastDuration+Time.Demo.StepInd-1)=PVPredMat(ForecastDuration+1:ForecastDuration+Time.Demo.StepInd,round(days(Time.Demo.Vec(TimeInd)-RangeTestDate(1))+1));
                %PVPredQH(TimeInd+ForecastDuration:TimeInd+ForecastDuration+Time.Demo.StepInd-1)=PVPredMat(ForecastDuration+1:ForecastDuration+Time.Demo.StepInd,TimeInd);
                if ForecastDuration<=ForcastLength-24*Time.Demo.StepInd
                    clearpoints(figPVPred{p})
                    addpoints(figPVPred{p},Time.Demo.VecDateNum(max([Time.Demo.StartInd, TimeInd-300]):EndCounter),PVPredQH(max([Time.Demo.StartInd+TD.Main, TimeInd+TD.Main-300]):EndCounter+TD.Main))
                else
                    addpoints(figPVPred{p},Time.Demo.VecDateNum(TimeInd+ForecastDuration:TimeInd+ForecastDuration+Time.Demo.StepInd-1),PVPredQH(TimeInd+TD.Main+ForecastDuration:TimeInd+TD.Main+ForecastDuration+Time.Demo.StepInd-1))
                end
                %title(strcat(SpotmarketLabel, " ", datestr(Time.Demo.Vec(TimeInd),'dd.mm.yyyy HH:MM')),'Interpreter','none')
                xlim([Time.Demo.VecDateNum(TimeInd-36*Time.StepInd+max(0,-ForecastIntervalInd+24*Time.Demo.StepInd+ForecastDuration+Time.Demo.StepInd)) Time.Demo.VecDateNum(EndCounter+3)]) % Create a moving plot 
            end
            
            drawnow






%             subplot(2,2,1)
%             EndCounter=max(EndCounter,TimeInd+ForecastDuration);
%             SpotmarketPred(TimeInd+ForecastDuration)=SpotmarketPredMat(ForecastDuration+1,round(days(Time.Demo.Vec(TimeInd)-RangeTestDate(1))+1));
%             figSpotmarketPred{p}.YDataSource='SpotmarketPred(max([Time.Demo.StartInd, TimeInd-300]):EndCounter,p)';
%             figSpotmarketPred{p}.XDataSource='Time.Vec(max([Time.Demo.StartInd, TimeInd-300]):EndCounter)';                   
%             %title(strcat(SpotmarketLabel, " ", datestr(Time.Demo.Vec(TimeInd),'dd.mm.yyyy HH:MM')),'Interpreter','none')
%             xlim([Time.Vec(TimeInd-36*Time.Demo.StepInd+max(0,-ForecastIntervalInd+24*Time.Demo.StepInd+ForecastDuration+1)) Time.Vec(EndCounter+3)]) % Create a moving plot 
%             ylim([yminSpotmarket ymaxSpotmarket])
% 
%             subplot(2,2,2)
%             xlim([Time.Vec(TimeInd-36*Time.Demo.StepInd+max(0,-ForecastIntervalInd+24*Time.Demo.StepInd+ForecastDuration+1)) Time.Vec(EndCounter+3)]) % Create a moving plot 
% 
%             subplot(2,2,3)
%             xlim([Time.Vec(TimeInd-36*Time.Demo.StepInd+max(0,-ForecastIntervalInd+24*Time.Demo.StepInd+ForecastDuration+1)) Time.Vec(EndCounter+3)]) % Create a moving plot 
% 
%             subplot(2,2,4)
%             PVPredQH(TimeInd+ForecastDuration)=PVPredMat(ForecastDuration+1,round(days(Time.Demo.Vec(TimeInd)-RangeTestDate(1))+1));
%             figPVPred{p}.YDataSource='PVPredQH(max([Time.Demo.StartInd, TimeInd-300]):EndCounter,p)';
%             figPVPred{p}.XDataSource='Time.Vec(max([Time.Demo.StartInd, TimeInd-300]):EndCounter)';                   
% %                 title(strcat(SpotmarketLabel, " ", datestr(Time.Demo.Vec(TimeInd),'dd.mm.yyyy HH:MM')),'Interpreter','none')
%             xlim([Time.Vec(TimeInd-36*Time.Demo.StepInd+max(0,-ForecastIntervalInd+24*Time.Demo.StepInd+ForecastDuration+1)) Time.Vec(EndCounter+3)]) % Create a moving plot 
% 
%             refreshdata(figSpotmarketPred{p}, 'caller')
%             refreshdata(figPVPred{p}, 'caller')
%             pause(0.001)
        end
    end

    yminResPoDem=min(ResPoDemRealQH(TimeInd+TD.Main-24*7*Time.Demo.StepInd:min(length(Time.Vec),TimeInd+TD.Main+24*7*Time.Demo.StepInd),:),[],'all');
    yminResPoDem=round(yminResPoDem-abs(yminResPoDem)*0.1);
    ymaxResPoDem=max(ResPoDemRealQH(TimeInd+TD.Main-24*7*Time.Demo.StepInd:min(length(Time.Vec),TimeInd+TD.Main+24*7*Time.Demo.StepInd)),[],'all');
    ymaxResPoDem=round(ymaxResPoDem+abs(ymaxResPoDem)*0.1);

end




subplot(2,2,1)
addpoints(figSpotmarketReal,Time.Demo.VecDateNum(TimeInd:TimeInd+Time.Demo.StepInd-1),SpotmarketReal(TimeInd+TD.Main:TimeInd+TD.Main+Time.Demo.StepInd-1))
ylim([yminSpotmarket ymaxSpotmarket])

subplot(2,2,2)
addpoints(figResPoDemRealNeg,Time.Demo.VecDateNum(TimeInd:TimeInd+Time.Demo.StepInd-1),ResPoDemRealQH(TimeInd+TD.Main:TimeInd+TD.Main+Time.Demo.StepInd-1,1))
addpoints(figResPoDemRealPos,Time.Demo.VecDateNum(TimeInd:TimeInd+Time.Demo.StepInd-1),ResPoDemRealQH(TimeInd+TD.Main:TimeInd+TD.Main+Time.Demo.StepInd-1,2))
ylim([yminResPoDem ymaxResPoDem])

subplot(2,2,3)
addpoints(figSoCPlot,Time.Demo.VecDateNum(TimeInd:TimeInd+Time.Demo.StepInd-1),double(Users{DemoUser}.LogbookBase(TimeInd+TD.User:TimeInd+TD.User+Time.Demo.StepInd-1,7))/double(Users{DemoUser}.BatterySize))

if ShowPVPred
    subplot(2,2,4)
    addpoints(figPVPlot,Time.Demo.VecDateNum(TimeInd:TimeInd+Time.Demo.StepInd-1),PVQH(TimeInd+TD.SpotmarketPred:TimeInd+TD.Main+Time.Demo.StepInd-1))
end
    
drawnow










% subplot(2,2,1)
% figSpotmarketReal.YDataSource='SpotmarketReal(max([Time.Demo.StartInd-30, TimeInd-300]):TimeInd)';
% figSpotmarketReal.XDataSource='Time.Vec(max([Time.Demo.StartInd-30, TimeInd-300]):TimeInd)';
% title(strcat(SpotmarketLabel, " ", datestr(Time.Demo.Vec(TimeInd),'dd.mm.yyyy HH:MM')),'Interpreter','none')
% ylim([yminSpotmarket ymaxSpotmarket])      
% refreshdata(figSpotmarketReal, 'caller')
% 
% subplot(2,2,2)
% set(figResPoDemReal, {'YData'}, {ResPoDemRealQH(max([Time.Demo.StartInd-30, TimeInd-300]):TimeInd,1); ResPoDemRealQH(max([Time.Demo.StartInd, TimeInd-300]):TimeInd,2)})
% set(figResPoDemReal, {'XData'}, {Time.Vec(max([Time.Demo.StartInd-30, TimeInd-300]):TimeInd); Time.Vec(max([Time.Demo.StartInd, TimeInd-300]):TimeInd)})
% title(strcat(ResPoDemLabel, " ", datestr(Time.Demo.Vec(TimeInd),'dd.mm.yyyy HH:MM')),'Interpreter','none')
% ylim([yminResPoDem ymaxResPoDem])   
% refreshdata(figResPoDemReal, 'caller')
% 
% subplot(2,2,3)
% set(figSoCPlot, {'YData'}, {single(Users{DemoUser}.LogbookBase(max([Time.Demo.StartInd-30, TimeInd-300]):TimeInd,7))/single(Users{DemoUser}.BatterySize)})
% set(figSoCPlot, {'XData'}, {Time.Vec(max([Time.Demo.StartInd-30, TimeInd-300]):TimeInd)})
% title(strcat(SoCPlotLabel, " ", datestr(Time.Demo.Vec(TimeInd),'dd.mm.yyyy HH:MM')),'Interpreter','none')
% refreshdata(figSoCPlot, 'caller')
% 
% subplot(2,2,4)
% set(figPVPlot, {'YData'}, {PVPlants{Users{DemoUser}.PVPlant}.Profile(max([Time.Demo.StartInd-30, TimeInd-300]):TimeInd)})
% set(figPVPlot, {'XData'}, {Time.Vec(max([Time.Demo.StartInd-30, TimeInd-300]):TimeInd)})
% title(strcat(PVPlotLabel, " ", datestr(Time.Demo.Vec(TimeInd),'dd.mm.yyyy HH:MM')),'Interpreter','none')
% refreshdata(figPVPlot, 'caller')
% pause(0.001)













% refreshdata(figure(11), 'caller')
%         refreshdata(figSpotmarketReal, 'caller')
%         refreshdata(figResPoDemReal, 'caller')
% pause(0.01)