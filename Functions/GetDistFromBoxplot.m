Low=SessionsPerDay(1,1);
Q1=SessionsPerDay(1,2);
Median=SessionsPerDay(1,3);
Q3=SessionsPerDay(1,4);
High=SessionsPerDay(1,5);
Iterations=100;

% https://stats.stackexchange.com/questions/256456/how-to-calculate-mean-and-sd-from-quartiles
MedianIt=Median;
Q1It=Q1;
Q3It=Q3;
Mu=(MedianIt+Q1It+Q3It)/3; % Wan et al. (2014)*. They build on Bland (2014)
Stdw=(Q3It-Q1It)/1.35; % Wan et al. (2014)*. They build on Bland (2014)
Skew=((Q3It-MedianIt)-(MedianIt-Q1It))/(Q3It-Q1It); % Galton skewness
Kurtosis=Mu.^4/Stdw.^4;
MedianDiff=zeros(Iterations,1);
Q1Diff=zeros(Iterations,1);
Q3Diff=zeros(Iterations,1);
Step=0.05;

for n=1:Iterations
    a=pearsrnd(Mu,Stdw,Skew,Kurtosis,[40000,1]);
    a(a>High)=[];
    a(a<Low)=[];    
    MedianDiff(n)=Median-median(a);
    Q1Diff(n)=Q1-quantile(a,0.25);
    Q3Diff(n)=Q3-quantile(a,0.75);
    
    MedianIt=MedianIt+MedianDiff(n)*Step;
    Q1It=Q1It+Q1Diff(n)*Step;
    Q3It=Q3It+Q3Diff(n)*Step;
    
    Mu=(MedianIt+Q1It+Q3It)/3;
    Stdw=(Q3It-Q1It)/1.35;
    Skew=((Q3It-MedianIt)-(MedianIt-Q1It))/(Q3It-Q1It);
    Kurtosis=Mu.^4/Stdw.^4;
    histogram(a,20)
    pause(0.2)
end
histogram(a,20)
    