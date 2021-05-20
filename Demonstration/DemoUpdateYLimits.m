%% Description
% This script updates the Y axes limits
%
% Depended scripts / folders
%   Initialisation.m        Needed for the execution of this script
%   Demonstration.m         This script is called by Demonstration.m


%% Update Y axes limits

for l=DemoPlots{n}.Yaxes
    ymin=Inf;
    ymax=-Inf;
    for k=1:length(DemoPlots{n}.Data)
        if l==DemoPlots{n}.YAxis{k}
            ymin=min([ymin; DemoPlots{n}.ymin{k}]);
            ymax=max([ymax; DemoPlots{n}.ymax{k}]);
        end
    end

    if length(DemoPlots{n}.Yaxes)>=2
        if l==1
            yyaxis left
        else
            yyaxis right
        end
    end

    ylim([ymin ymax])
end