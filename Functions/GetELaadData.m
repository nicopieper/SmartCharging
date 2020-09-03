PathVehicleData=[Path 'Predictions' Dl 'VehicleData' Dl];

ArrivalWeekdays=xlsread(strcat(PathVehicleData, 'Distribution_of_arrival_times_on_weekdays.csv'));  % Private, Public, Workplace
ArrivalWeekdays=ArrivalWeekdays(:,2:4);
ArrivalWeekends=readmatrix(strcat(PathVehicleData, 'Distribution_of_arrival_times_on_weekends.csv'), 'NumHeaderLines', 1, 'OutputType', 'string');
ArrivalWeekends=str2double(strrep(ArrivalWeekends(:,2:3), ',', '.')); % Private, Public
ConnectionTime=readmatrix(strcat(PathVehicleData, 'Distribution_of_connection_time_per_charging_event.csv'), 'NumHeaderLines', 1, 'OutputType', 'string');
ConnectionTime=str2double(strrep(ConnectionTime, ',', '.')); % Length in hours, Private, Public, Workplace
EnergyDemand=readmatrix(strcat(PathVehicleData, 'Distribution_of_energy_demand_time_per_charging_event.csv'), 'NumHeaderLines', 1, 'OutputType', 'string');
EnergyDemand=str2double(strrep(EnergyDemand, ',', '.')); % Length in hours, Private, Public, Workplace
SessionsPerDay=xlsread(strcat(PathVehicleData, 'Distribution-of-charging_sessions_per_day.csv')); % private (low),	private (q1),	private (median),	private (q3),	private (high),	public (low),	public (q1),	public (median),	public (q3),	public (high),	workplace (low),	workplace (q1),	workplace (median),	workplace (q3),	workplace (high)
VehicleProperties=readmatrix(strcat(PathVehicleData, 'Vehicle_Properties.xlsx'), 'NumHeaderLines', 1, 'OutputType', 'string'); % Model Name, Fleet Share cum., Battery Capacity [kWh], Consumption [kWh/km], Share Charging Point Power