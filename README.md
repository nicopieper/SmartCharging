# Smart Charging algorithm considering multiple revenue opportunities

## Project abstract 

This project proposes a smart charging algorithm based on linear programming that minimizes the charging costs of an aggregated fleet. The algorithm reduces spot market purchase costs, increases self-consumption of photovoltaics power, enables the provision of negative secondary control reserve and considers the terms of a peak load avoidance program managed by German distribution system operators. The economic potential of each revenue opportunity is examined by using simulations basing on multiple real data sources.

A two level optimization approach is used. Every four hours, a pre-planning linear programming algorithm calculates the optimal charging schedules. An operational management algorithm uses a heuristic to manage the charging processes in following the transmission system operator’s (TSO) aFRR requests and technical restrictions. Based on real driving profiles and current BEV properties, a fleet of several thousand BEVs can be modeled and simulated over one year. The developed charging optimisation approach can be compared to a base scenario, in which the users decide by themselfs when to charge.

## Demonstrator

A demonstrator visualises the results of a smart charging demonstration using 20000 users. The demonstrator can be easily examined by everyone having a modern Matlab version. Therefore, all files from the Demonstrator folder have to be downloaded. Then, the source files have to be downloaded. The source file include the spot market data, spot market prediction data as well as the modeled and simulated user data. The files can be downloaded under the following link: https://seafile.zfn.uni-bremen.de/d/8855e427c3a945db8112/

To start the demonstrator, open InitialisationDemonstrator.m and enter the path of the downloaded data from the seafile cloud. Run this script. Then Run the Demonstration.m script. Two figures appear. Figure 1 lists the characteristics of a demo user, who is part of the fleet comprising 20000 users. Figure 11 shows four plots. The first plot compares the spot market predictions to the real spot market prices. The second plot compares the predicted pv power of the demo user's plant to the real generated pv power. The third plot shows the demo user's energy demand through driving, charged energy and the resulting vehicle's SoC. Plot 4 four visualises the load profile of the fleet split into the three electricity sources.

![Image of the Demonstrator](https://github.com/nicopieper/SmartCharging/blob/master/ReadmeImages/Demonstrator.svg?raw=true)
