%% Description
% This script updates the optimal charging schedules and represents
% algorithm 2. It is executed each time step. It allocates the requested
% reserve energy to the fleet and limits the pv power demand to actualy
% available pv power (the plan was calculated using the predictions).
%
% Depended scripts / folders
%   Initialisation          Needed for the execution of this script
%   InitialiseLiveAlgo      Needed for the execution of this script (called
%                           by Simulation.m)
%   CalcDynOptVars          Needed for the execution of this script (called
%                           by Simulation.m)
%   CalcConsOptVars         Needed for the execution of this script (called
%                           by Simulation.m)
%   Simulation              This script is called by Simulation.m


%% Clip pv power consumption to actual pv power

VarCounter=0;
for n=UserNum
    if Users{n}.PVPlantExists % First set PV power consumption to min of prediction and real generation consumption via PV can be raised later on during the optimisation but it deallocates power in case of for the threatening underfulfillment of dispatched reserve power
        Users{n}.Logbook(TimeInd+TD.User,6)=min(Users{n}.Logbook(TimeInd+TD.User,6), double(PVPlants{Users{n}.PVPlant}.ProfileQH(TimeInd+TD.Main))/4); % [Wh]
    end
end


%% Caluclate Merit Order List

CalcAvailability;

if ismember(TimeInd, TimesOfResPoEval) % if in this time step a new reserve market time slice (Zeitscheibe) begins
    OfferedResPo=LastResPoOffersSuccessful4H((24*Time.StepInd-TimesOfPreAlgo(1,1)+1)/ConstantResPoPowerPeriods + floor(mod(TimeInd-1,24*Time.StepInd)/ConstantResPoPowerPeriods) + 1, floor((TimeInd-1)/(24*Time.StepInd))+1)*Time.StepInd/1000;  % [kW] successfully offered reserve power during this time slice
    
    if OfferedResPo>0 % if the reserve power offer for the current time slice was successful
        % ResOfferLists4H are the offers of the competitors fetched from  the regelleistung.net data. columns 2-3 of cell-column 2 contain the offered energy price [EUR/MWh] and the allocated power [MW] for negative reserve energy.
        % ResEnOffers are the price offers [EUR/kWh] of the simulated aggregator. OfferedResPo covers the allocated power [kW] corresponding to the price
        
        % Calculate the merit order list for the reserve energy offers and
        % include the own offer
        % ResEnMOL [EUR/kW, kW]
        ResEnMOL=[ResOfferLists4H{floor((TimeInd+TD.Main-1)/(4*Time.StepInd))+1,2}(:,2:3) .* [1/1000, 1000]; [ResEnOffers(floor(mod(TimeInd-TimesOfPreAlgo(1,1), 24*Time.StepInd)/(4*Time.StepInd))+1,1,PreAlgoCounter+1-double(ControlPeriodsIt>ControlPeriods-4*Time.StepInd)), OfferedResPo]]; % Merit-Order-List for the current Zeitscheibe. Includes offered prices in first column and allocated energy in second column. 
        ResEnMOL=[ResEnMOL, [zeros(size(ResEnMOL,1)-1,1);1]];
        [~, SortedOrder]=sort(ResEnMOL(:,1),1,'ascend');
        ResEnMOL=ResEnMOL(SortedOrder,:);
        OwnOfferMOLPos(end+1)=find(ResEnMOL(:,3)==1);
    end
    
end


%% Dispatch reserve energy to fleet

if OfferedResPo>0 % if the reserve power offer for the current time slice was successful
    
    %% Determine amount of dispatched reserve power
    
    temp=cumsum(ResEnMOL(:,2)); % cumulative reserve energy 
    TSOResPoDemand=ResPoDemRealQH(TimeInd+TD.Main,1)*1000; % Required reserve energy demanded from the TSOs [kW]
    MOLPos1(end+1)=find(temp>=TSOResPoDemand, 1); % Merit-Order-List marginal Position at which the requested demand is satisfied. All bidders with above this position (or at this position) are successful and will provide reserve energy
    if MOLPos1(end)>OwnOfferMOLPos(end) % if the aggergator's offered price is lower than the marginal price ...
        DispatchedResEn(TimeInd)=OfferedResPo*1000/Time.StepInd; % [Wh] ... the whole offered reserve power will be requested
    elseif MOLPos1(end)==OwnOfferMOLPos(end) % if the aggregators has the marginal position only a share of the offer will be requested
        if OwnOfferMOLPos(end)>1
            DispatchedResEn(TimeInd)=(TSOResPoDemand-temp(OwnOfferMOLPos(end)-1))*1000/Time.StepInd; % [Wh]
        else
            DispatchedResEn(TimeInd)=TSOResPoDemand*1000/Time.StepInd; % [Wh]
        end
    else % if the offer was not successful ...
        DispatchedResEn(TimeInd)=0; % ... no reserve energy is requested
    end
    
    
    %% Deterime amount of provideable reserve power

    if DispatchedResEn(TimeInd)>0 % if reserve energy is requested from the aggregator

        AvailableDispatchedResEn=[]; % amount of reserve energy that was planned to demanded during the last optimisation and is now actually available (might be lower than planned due to unexpected public charging processes)
        AvailableDispatchedResEnBuffer=[]; % amount of energy that can be fulfilled by all vehicles that are available for charging and were pre-planned to supply reserve energy
        AvailableDispatchedResEnMax=[]; % amount of reserve energy that can be provided by all vehicles that are available for charging

        VarCounter=0;
        for n=UserNum
            
            VarCounter=VarCounter+1;
            AvailableDispatchedResEn(VarCounter,1)=min(Users{n}.BatterySize - Users{n}.Logbook(TimeInd+TD.User,9),Users{n}.Logbook(TimeInd+TD.User,7)*Availability(1,1,VarCounter)); % [Wh]
            AvailableDispatchedResEnBuffer(VarCounter,1)=min(Users{n}.BatterySize - Users{n}.Logbook(TimeInd+TD.User,9), double(Users{n}.ACChargingPowerHomeCharging)/4 - sum(Users{n}.Logbook(TimeInd+TD.User,5:6))*Availability(1,1,VarCounter))*double(Users{n}.Logbook(TimeInd+TD.User,7)>0); % [Wh]
            AvailableDispatchedResEnMax(VarCounter,1)=min(Users{n}.BatterySize - Users{n}.Logbook(TimeInd+TD.User,9), double(Users{n}.ACChargingPowerHomeCharging)/4 - sum(Users{n}.Logbook(TimeInd+TD.User,5:6))*Availability(1,1,VarCounter)); % [Wh]
            
            Users{n}.Logbook(TimeInd+TD.User,7)=0;
        end

    
        %% Dispatch reserve power to fleet

        PriorityChargingList=[];
        
        if DispatchedResEn(TimeInd)> sum(AvailableDispatchedResEnMax)
            Exceeds(end+1)=TimeInd;
        end

        if round(DispatchedResEn(TimeInd)*100) < round(sum(AvailableDispatchedResEn)*100) % if the requested reserve energy is lower than the pre-planned supply of all available vehicles
            
            % Those cars with the lowest gap to their public charging 
            % threshold are preferred for receiving reserve energy. They 
            % are on top of the PriorityChargingList
            
            LiveAlgoCases(1,1)=LiveAlgoCases(1,1)+1;
            VarCounter=0;
            for n=UserNum
                VarCounter=VarCounter+1;
                PriorityChargingList(VarCounter,:)=[n,Users{n}.Logbook(TimeInd+TD.User,9)-Users{n}.PublicChargingThreshold_Wh]; % UserNumber, Energy left until public charging necessary [Wh]
            end
            PriorityChargingList=[PriorityChargingList, AvailableDispatchedResEn]; % UserNumber, Energy left until public charging necessary [Wh], pre dispatched reserve energy [Wh]
            PriorityChargingList=PriorityChargingList(PriorityChargingList(:,3)>0,:); % Only keep vehicles that were pre-planned for supplying reserve energy
            [~, SortedOrder]=sort(PriorityChargingList(:,2), 'ascend'); % Create a Merit-Order-List for the cars to charge energy. The car with the least energy left before public charging is needed is on top of the MOL

            temp=[0;cumsum(PriorityChargingList(:,3))];
            MOLPos=find(temp>=DispatchedResEn(TimeInd), 1)-1; % find the marginal position

            PriorityChargingList=[PriorityChargingList, [PriorityChargingList(1:MOLPos,3); zeros(size(PriorityChargingList,1)-MOLPos,1)]]; % UserNumber, Energy left until public charging necessary [Wh], pre dispatched reserve energy [Wh], now dispatched reserve power [Wh]
            PriorityChargingList(MOLPos,4)=DispatchedResEn(TimeInd)-temp(MOLPos); % now dispatched reserve power of marginal vehicle
            PriorityChargingList=PriorityChargingList(SortedOrder,[1,3,4]);
            

        elseif DispatchedResEn(TimeInd)+0.5 >= sum(AvailableDispatchedResEn) && DispatchedResEn(TimeInd)-0.5 <= sum(AvailableDispatchedResEn) % if the requested reserve energy equals the pre-planned supply of all available vehicles
            % use the pre-planned charging plan
            LiveAlgoCases(1,2)=LiveAlgoCases(1,2)+1;
            
            PriorityChargingList=[UserNum', zeros(NumUsers, 1), AvailableDispatchedResEn, AvailableDispatchedResEn];
            PriorityChargingList=PriorityChargingList(PriorityChargingList(:,4)>0,:);
            
        elseif round(DispatchedResEn(TimeInd)*100) <= round(sum(AvailableDispatchedResEnBuffer)*100) % if the requested reserve energy exceeds the pre-planned supply of all available vehicles but can be satisfied by surplus charging capacities of all vehicles pre-palanned for providing reserve energy
            % dispatch energy using the buffered energy from those cars that
            % were dispatched for reserve power but not by their full charging
            % capacity
            
            LiveAlgoCases(1,3)=LiveAlgoCases(1,3)+1;

            VarCounter=0;
            for n=UserNum
                VarCounter=VarCounter+1;
                PriorityChargingList(VarCounter,:)=[n,Users{n}.Logbook(TimeInd+TD.User,9)-Users{n}.PublicChargingThreshold_Wh]; % UserNumber, Energy left until public charging necessary [Wh], dispatched reserve energy [Wh]
            end
            PriorityChargingList=[PriorityChargingList, AvailableDispatchedResEn, AvailableDispatchedResEnBuffer];
            PriorityChargingList=PriorityChargingList(PriorityChargingList(:,4)>0,:);
            [~, SortedOrder]=sort(PriorityChargingList(:,2), 'ascend'); % Create a Merit-Order-List for the cars to charge energy. The car with the least energy left before public charging is needed is on top of the MOL
            PriorityChargingList=PriorityChargingList(SortedOrder,:);
            
            PriorityChargingList=[PriorityChargingList, PriorityChargingList(:,4)-PriorityChargingList(:,3)]; % Cols: UserNumber, energy left until public charging, pre dispatched reserve power, max reserve power, max additional dispatchable reserve power
            temp=[0;cumsum(PriorityChargingList(:,5))];
            MOLPos=find(temp>=(DispatchedResEn(TimeInd)-sum(PriorityChargingList(:,3))), 1)-1; % 
            PriorityChargingList=[PriorityChargingList, [PriorityChargingList(1:MOLPos,3)+PriorityChargingList(1:MOLPos,5); PriorityChargingList(MOLPos+1:end,3)]];
            PriorityChargingList(MOLPos,6)=PriorityChargingList(MOLPos,3) + (DispatchedResEn(TimeInd) - temp(MOLPos)-sum(PriorityChargingList(:,3)));

        elseif sum(AvailableDispatchedResEnMax)>0 % % if the requested reserve energy exceeds the pre-planned supply of all available vehicles and can not be satisfied by surplus charging capacities of all vehicles pre-palanned for providing reserve energy
            % dispatch energy using all available charging energy even from
            % those cars that were not dispatched for reserve power but are
            % currently available

            % if the demand is still not chargable, the remaining energy has to
            % be fulfilled by the VPP
            
            LiveAlgoCases(1,1)=LiveAlgoCases(1,1)+1;
            
            VarCounter=0;
            for n=UserNum
                VarCounter=VarCounter+1;
                PriorityChargingList(VarCounter,:)=[n,Users{n}.Logbook(TimeInd+TD.User,9)-Users{n}.PublicChargingThreshold_Wh]; % UserNumber, Energy left until public charging necessary [Wh], dispatched reserve energy [Wh]
            end
            PriorityChargingList=[PriorityChargingList, AvailableDispatchedResEn, AvailableDispatchedResEnBuffer, AvailableDispatchedResEnMax];
            PriorityChargingList=PriorityChargingList(PriorityChargingList(:,5)>0,:);
            [~, SortedOrder]=sort(PriorityChargingList(:,2), 'ascend'); % Create a Merit-Order-List for the cars to charge energy. The car with the least energy left before public charging is needed is on top of the MOL
            PriorityChargingList=PriorityChargingList(SortedOrder,:);
            
            PriorityChargingList=[PriorityChargingList, PriorityChargingList(:,5)-PriorityChargingList(:,4)]; % Cols: UserNumber, energy left until public charging, dispatched reserve power, max reserve power, max additional dispatchable reserve power
            temp=[0;cumsum(PriorityChargingList(:,6))];
            MOLPos=find(temp>=(DispatchedResEn(TimeInd)-sum(PriorityChargingList(:,4))), 1)-1;
            if isempty(MOLPos) 
                MOLPos=size(PriorityChargingList,1);
            end
            PriorityChargingList=[PriorityChargingList, [PriorityChargingList(1:MOLPos,4)+PriorityChargingList(1:MOLPos,6); PriorityChargingList(MOLPos+1:end,4)]];
            PriorityChargingList(MOLPos,7)=min(PriorityChargingList(MOLPos,5), PriorityChargingList(MOLPos,4) + (DispatchedResEn(TimeInd) - temp(MOLPos)-sum(PriorityChargingList(:,4))));
            
        end
        
        ProvidedResEn(TimeInd)=0;
        
        if ~isempty(PriorityChargingList)
            for n=PriorityChargingList(:,1)'
                Users{n}.Logbook(TimeInd+TD.User,7)=PriorityChargingList(PriorityChargingList(:,1)==n, end); % [Wh] final provided reserve energy without considering charging losses
                ProvidedResEn(TimeInd)=ProvidedResEn(TimeInd)+Users{n}.Logbook(TimeInd+TD.User,7); % [Wh] provided reserve energy of the fleet without considering charging losses
            end 
        end

    else % if no reserve energy is requested from the aggregator
        
        for n=UserNum
            Users{n}.Logbook(TimeInd+TD.User,7)=0;
        end
        
    end
    
else % if the reserve power was not successful
    for n=UserNum
        Users{n}.Logbook(TimeInd+TD.User,7)=0;
    end
end


% OfferedResPo          kW
% DispatchedResEn       Wh
