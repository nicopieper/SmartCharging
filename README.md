# Smart Charging algorithm considering multiple revenue opportunities

This project proposes a smart charging algorithm based on linear programming that minimizes the charging costs of an aggregated fleet. The algorithm reduces spot market purchase costs, increases self-consumption of photovoltaics power, enables the provision of negative secondary control reserve and considers the terms of a peak load avoidance program managed by German distribution system operators. The economic potential of each revenue opportunity is examined by using simulations basing on multiple real data sources.

A two level optimization approach is used. Every four hours, a pre-planning linear programming algorithm calculates the optimal charging schedules. An operational management algorithm uses a heuristic to manage the charging processes in following the transmission system operator’s (TSO) aFRR requests and technical restrictions. Based on real driving profiles and current BEV properties, a fleet of several thousand BEVs can be modeled and simulated over one year. The developed charging optimisation approach can be compared to a base scenario, in which the users decide by themselfs when to charge.

![alt text](https://github.com/nicopieper/SmartCharging/blob/SimulationExtendParallel/ReadmeImages/3Systemaufbau.pdf?raw=true)
