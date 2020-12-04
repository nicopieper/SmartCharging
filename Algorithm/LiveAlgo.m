% Two steps:

% 1. Allocate the demanded reserve energy to the fleet

if ismember(TimeInd, TimesOfZeitscheiben)
    OfferedResPo=LastResPoOffersSucessful4H(floor(mod(TimeInd-TimesOfPreAlgo(1,1), 24*Time.StepInd)/(4*Time.StepInd))+1, PreAlgoCounter+1-double(ControlPeriodsIt==ControlPeriods));
    
    if OfferedResPo>0
        % ResOfferLists4H are the offers of the competitors fetched from  the regelleistung.net data. columns 2-3 of cell-column 2 contain the offered energy price [€/MWh] and the allocated power [MW] for negative reserve energy.
        % ResEnOffers are the price offers [€/kWh] of the simulated aggregator.OfferedResPo covers the allocated power [kW] corresponding to the price
        ResEnMOL=[ResOfferLists4H{floor((TimeInd+TD.Main)/(4*Time.StepInd))+1,2}(:,2:3) .* [1/1000, 1000]; [ResEnOffers(floor(mod(TimeInd-TimesOfPreAlgo(1,1), 24*Time.StepInd)/(4*Time.StepInd))+1,1,PreAlgoCounter+1-double(ControlPeriodsIt==ControlPeriods)), OfferedResPo]]; % Merit-Order-List for the current Zeitscheibe. Includes offered prices in first column and allocated energy in second column. 
        ResEnMOL=[ResEnMOL, [zeros(size(ResEnMOL,1)-1,1);1]];
        [~, SortedOrder]=sort(ResEnMOL(:,1),1,'ascend');
        ResEnMOL=ResEnMOL(SortedOrder,:);
        OwnOfferMOLPos=find(ResEnMOL(:,3)==1);
    end
    
end

if OfferedResPo>0
    
    %% Determine amount of dispatched reserve power
    
    temp=cumsum(ResEnMOL(:,2));
    TSOResPoDemand=ResPoDemRealQH(TimeInd+TD.Main,1)*1000; % Required reserve energy demanded from the TSOs [kW]
    MOLPos=find(temp>=TSOResPoDemand, 1); % Merit-Order-List Position
    if MOLPos>OwnOfferMOLPos
        DispatchedResPo(TimeInd)=OfferedResPo;
    elseif MOLPos==OwnOfferMOLPos
        if OwnOfferMOLPos>1
            DispatchedResPo(TimeInd)=TSOResPoDemand-temp(OwnOfferMOLPos-1);
        else    
            DispatchedResPo(TimeInd)=TSOResPoDemand;
        end
    else
        DispatchedResPo(TimeInd)=0;
    end

    %a=[a;[OfferedResPo,DispatchedResPo(TimeInd)]];
    %[DispatchedResPo(TimeInd), double(OfferedResPo==DispatchedResPo(TimeInd))];
    
    %% Deterime amount of provideable reserve power

    if DispatchedResPo(TimeInd)>0

        AvailableDispatchedResPo=[];
        AvailableDispatchedResPoBuffer=[];
        AvailableDispatchedResPoMax=[];

        VarCounter=0;
        for n=UserNum
            VarCounter=VarCounter+1;
            AvailableDispatchedResPo(VarCounter,1)=min(Users{n}.BatterySize - Users{n}.Logbook(TimeInd+TD.User,9),Users{n}.Logbook(TimeInd+TD.User,7)*Availability(1,1,VarCounter));
            AvailableDispatchedResPoBuffer(VarCounter,1)=min(Users{n}.BatterySize - Users{n}.Logbook(TimeInd+TD.User,9), double(Users{n}.ACChargingPowerHomeCharging)/4 - sum(Users{n}.Logbook(TimeInd+TD.User,5:6))*Availability(1,1,VarCounter))*double(Users{n}.Logbook(TimeInd+TD.User,7)>0);
            AvailableDispatchedResPoMax(VarCounter,1)=min(Users{n}.BatterySize - Users{n}.Logbook(TimeInd+TD.User,9), double(Users{n}.ACChargingPowerHomeCharging)/4 - sum(Users{n}.Logbook(TimeInd+TD.User,5:6))*Availability(1,1,VarCounter));
            
            Users{n}.Logbook(TimeInd+TD.User,7)=0;
        end



        a1(TimeInd,:)=[sum(AvailableDispatchedResPo), sum(AvailableDispatchedResPoBuffer), sum(AvailableDispatchedResPoMax), DispatchedResPo(TimeInd)];
    
        %% Dispatch reserve power to fleet

        PriorityChargingList=[];

        if DispatchedResPo(TimeInd) < sum(AvailableDispatchedResPo) % 25.92%
            % Which cars should be charged at first? 
            % Those with the most chargable energy? X

            % Those with the least dispatched reserve energy? X

            % Those with the lowest remaining energy / SoC? Yes, in order to
            % avoid public charging and thus schedule shifts

            VarCounter=0;
            for n=UserNum
                VarCounter=VarCounter+1;
                PriorityChargingList(VarCounter,:)=[n,Users{n}.Logbook(TimeInd+TD.User,9)-Users{n}.PublicChargingThreshold_Wh]; % UserNumber, Energy left until public charging necessary [Wh], dispatched reserve power [W]
            end
            PriorityChargingList=[PriorityChargingList, AvailableDispatchedResPo];
            PriorityChargingList=PriorityChargingList(PriorityChargingList(:,3)>0,:);
            [~, SortedOrder]=sort(PriorityChargingList(:,2), 'ascend'); % Create a Merit-Order-List for the cars to charge energy. The car with the least energy left before public charging is needed is on top of the MOL

            temp=[0;cumsum(PriorityChargingList(:,3))];
            MOLPos=find(temp>=DispatchedResPo(TimeInd), 1)-1; % 

            PriorityChargingList=[PriorityChargingList, [PriorityChargingList(1:MOLPos,3); zeros(size(PriorityChargingList,1)-MOLPos,1)]];
            PriorityChargingList(MOLPos,4)=DispatchedResPo(TimeInd)-temp(MOLPos);
            PriorityChargingList=PriorityChargingList(SortedOrder,[1,3,4]);

%             1

        elseif DispatchedResPo(TimeInd) == sum(AvailableDispatchedResPo) % 69.18%
            % do nothing
            PriorityChargingList=[UserNum', zeros(NumUsers, 1), AvailableDispatchedResPo, AvailableDispatchedResPo];
            PriorityChargingList=PriorityChargingList(PriorityChargingList(:,4)>0,:);
        elseif DispatchedResPo(TimeInd) <= sum(AvailableDispatchedResPoBuffer) % 4.3% + 0.02% = 4.32%
            % dispatch energy using the buffered energy from those cars that
            % were dispatched for reserve power but not by their full charging
            % capacity

            VarCounter=0;
            for n=UserNum
                VarCounter=VarCounter+1;
                PriorityChargingList(VarCounter,:)=[n,Users{n}.Logbook(TimeInd+TD.User,9)-Users{n}.PublicChargingThreshold_Wh]; % UserNumber, Energy left until public charging necessary [Wh], dispatched reserve power [W]
            end
            PriorityChargingList=[PriorityChargingList, AvailableDispatchedResPo, AvailableDispatchedResPoBuffer];
            PriorityChargingList=PriorityChargingList(PriorityChargingList(:,4)>0,:);
            [~, SortedOrder]=sort(PriorityChargingList(:,2), 'ascend'); % Create a Merit-Order-List for the cars to charge energy. The car with the least energy left before public charging is needed is on top of the MOL
            PriorityChargingList=PriorityChargingList(SortedOrder,:);
            
            PriorityChargingList=[PriorityChargingList, PriorityChargingList(:,4)-PriorityChargingList(:,3)]; % Cols: UserNumber, energy left until public charging, dispatched reserve power, max reserve power, max additional dispatchable reserve power
            temp=[0;cumsum(PriorityChargingList(:,5))];
            MOLPos=find(temp>=(DispatchedResPo(TimeInd)-sum(PriorityChargingList(:,3))), 1)-1; % 
            PriorityChargingList=[PriorityChargingList, [PriorityChargingList(1:MOLPos,3)+PriorityChargingList(1:MOLPos,5); PriorityChargingList(MOLPos+1:end,3)]];
            PriorityChargingList(MOLPos,6)=PriorityChargingList(MOLPos,3) + (DispatchedResPo(TimeInd) - temp(MOLPos)-sum(PriorityChargingList(:,3)));

%             1

        else %if DispatchedResPo(TimeInd) <= sum(AvailableDispatchedResPoMax) % 0.57% + 0% = 0.57%
            % dispatch energy using all available charging energy even from
            % those cars that were not dispatched for reserve power but are
            % currently available

            % if the demand is still not chargable, the remaining energy has to
            % be fulfilled by the VPP
            
            VarCounter=0;
            for n=UserNum
                VarCounter=VarCounter+1;
                PriorityChargingList(VarCounter,:)=[n,Users{n}.Logbook(TimeInd+TD.User,9)-Users{n}.PublicChargingThreshold_Wh]; % UserNumber, Energy left until public charging necessary [Wh], dispatched reserve power [W]
            end
            PriorityChargingList=[PriorityChargingList, AvailableDispatchedResPo, AvailableDispatchedResPoBuffer, AvailableDispatchedResPoMax];
            PriorityChargingList=PriorityChargingList(PriorityChargingList(:,5)>0,:);
            [~, SortedOrder]=sort(PriorityChargingList(:,2), 'ascend'); % Create a Merit-Order-List for the cars to charge energy. The car with the least energy left before public charging is needed is on top of the MOL
            PriorityChargingList=PriorityChargingList(SortedOrder,:);
            
            PriorityChargingList=[PriorityChargingList, PriorityChargingList(:,5)-PriorityChargingList(:,4)]; % Cols: UserNumber, energy left until public charging, dispatched reserve power, max reserve power, max additional dispatchable reserve power
            temp=[0;cumsum(PriorityChargingList(:,6))];
            MOLPos=find(temp>=(DispatchedResPo(TimeInd)-sum(PriorityChargingList(:,4))), 1)-1; % 
            PriorityChargingList=[PriorityChargingList, [PriorityChargingList(1:MOLPos,3)+PriorityChargingList(1:MOLPos,6); PriorityChargingList(MOLPos+1:end,4)]];
            PriorityChargingList(MOLPos,7)=PriorityChargingList(MOLPos,4) + (DispatchedResPo(TimeInd) - temp(MOLPos)-sum(PriorityChargingList(:,4)));
            
        end
        
        for n=PriorityChargingList(:,1)'
            Users{n}.Logbook(TimeInd+TD.User,7)=PriorityChargingList(PriorityChargingList(:,1)==n, end);
        end

    end
end


% the power is limited by the allocated res po per vehicle multiplied with
% the actual availability given in this moment. Should be given by
% Availability

% NO, that is wrong. When I consider only allocated powers, I can not make
% use of the buffer power. Should I only use the buffer if I can not
% fullfil the required energy? Might be an option as it could reduce
% computational power for most cases



% Does max SoCTS has to be considered? Yes, as SoC might have changed due
% to public charging

% The allocated res pos of all vehicles must match DispatchedResPo

% MaxResPo=OptimalChargingEnergies(




% 2. Optimise the spotmarket and pv energy consumption separately using realtime pv energy production


% 
% 3. Optional: Consider e-programme balancing