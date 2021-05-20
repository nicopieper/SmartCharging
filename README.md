# Smart Charging algorithm considering multiple revenue opportunities

## Project description 

This project proposes a smart charging algorithm based on linear programming that minimizes the charging costs of an aggregated fleet. The algorithm reduces spot market purchase costs, increases self-consumption of photovoltaics power, enables the provision of negative secondary control reserve and considers the terms of a peak load avoidance program managed by German distribution system operators. The economic potential of each revenue opportunity is examined by using simulations basing on multiple real data sources.

A two level optimization approach is used. Every four hours, a pre-planning linear programming algorithm calculates the optimal charging schedules. An operational management algorithm uses a heuristic to manage the charging processes in following the transmission system operator’s (TSO) aFRR requests and technical restrictions. Based on real driving profiles and current BEV properties, a fleet of several thousand BEVs can be modeled and simulated over one year. The developed charging optimisation approach can be compared to a base scenario, in which the users decide by themselfs when to charge. 

The following figure visualises the modeled smart charging system. A central aggregator controls the charging processes of the participants using an internet connection to the vehicles. The scheduling bases on the expected charging availability and demand, spot market prices, available PV power, and balance energy requests. Each user is modeled with an individual set of characteristics, comprising a BEV as well as its usage profile, a private charging point, an electricity contract and a public charging tariff.

<img src="https://github.com/nicopieper/SmartCharging/blob/master/ReadmeImages/3Systemaufbau.svg?raw=true" alt="alt text" height="300">

As depicted in the next figure, a two-level optimization procedure is used. On the pre-planning level, algorithm 1 uses linear optimization to calculate optimal charging schedules. Algorithm 1 is run every four hours. The execution right before 8 AM determines the aFRR market offers for the next day and the one at noon calculates the electricity demand that has to be purchased in the spot market auctions. On the operational level, algorithm 2 allocates reserve energy that is demanded by the TSOs to the fleet using a heuristic. An autoregressive model with exogenous inputs is applied to predict the day-ahead MCP and feed in nationwide power generation and grid load prediction data.

<img src="https://github.com/nicopieper/SmartCharging/blob/master/ReadmeImages/3Optimierungsprozess2.svg?raw=true" alt="alt text" height="300">

A lot of different data sources were used to model and simulate a realistic fleet of battery electric vehicles that participates in a smart charging service. The followgin figure shows how these data sources are linked in order to calculate an optimal charging schedule.

<img src="https://github.com/nicopieper/SmartCharging/blob/master/ReadmeImages/3DatasetsAlgo1.svg?raw=true" alt="alt text" heigth="300">

The results of this project are submitted as a paper for the 2021 International Conference on Smart Energy Systems and Technologies (SEST). The paper is expected to be approved by mid July 2021 and will be linked as soon as it is published. Feel free to contact me for further details.

## Demonstrator

A demonstrator visualises the results of a smart charging demonstration using 20000 users. The demonstrator can be easily examined by everyone having a modern Matlab version. Therefore, all files from the Demonstrator folder have to be downloaded. Then, the source files have to be downloaded. The source file include the spot market data, spot market prediction data as well as the modeled and simulated user data. The files can be downloaded under the following link: https://seafile.zfn.uni-bremen.de/d/8855e427c3a945db8112/

To start the demonstrator, open InitialisationDemonstrator.m and enter the path of the downloaded data from the seafile cloud. Run this script. Then run the Demonstration.m script. Two figures appear. Figure 1 lists the characteristics of a demo user, who is part of the fleet that comprises 20000 users. Figure 11 shows four plots. The first plot compares the spot market predictions to the real spot market prices. The second plot compares the predicted pv power of the demo user's plant to the real generated pv power. The third plot shows the demo user's energy demand through driving, charged energy and the resulting vehicle's SoC. Plot 4 four visualises the load profile of the fleet split into the three electricity sources.

![Image of the Demonstrator](https://github.com/nicopieper/SmartCharging/blob/master/ReadmeImages/Demonstrator.svg?raw=true)

## Further scripts of interest

### GetSmardData.m

This script downloads electricity data from the website smard.de automatically. The data comprises day-ahead spot market price, the real grid load, the predicted grid load, the real electricity generation data, the predicted electricity generation data. The real generation data distinguishes all different types of electricity source (Biomass, Wind Offshore, WindOnshore, PV, Coal, Nuclear etc.), the prediction only distinguishes Total, Wind Onshore, Wind Offshore, PV, Remaining.

### GetEnergyChartsData.m

This Script loads electricity data directly from energy-charts.de. The subjects are day-ahead spot market price and several intraday indices. In addition, data for the trade balances with other countries and CO2 Emission Allowances can the loaded. Please be aware that the data of energy-charts.de are not available under a creative commons license! Please ask the provider of the webpage for the permission to use the data.

### GetSMAData

This folder includes a Python web scraper to extract PV plant data form the [SMA Sunny Portal](https://www.sunnyportal.com/Templates/PublicPagesPlantList.aspx). The data comprises pv plant propertiers like azimuth, elevation, location, start of the operation, peak power as well as the generation covering a specifiv time period.
