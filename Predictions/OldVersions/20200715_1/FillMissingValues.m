function x=FillMissingValues(x) % Replace NaN values in matrices. Depending on where the NaN occurs, either past (24h and 24*7h) or future values (24h or 24*7h) are used.
indices=find(isnan(x));

if ~isempty(indices)
    n=1;
    while n<=length(indices)
        if indices(n)>=7*24
           try
            while n<=length(indices)
                x(indices(n))=mean([x(indices(n)-24),x(indices(n)-24*7)]);
                n=n+1;
            end
           catch ME
               x(indices(n))
               mean(x(indices(n)-24),x(indices(n)-24*7))
           end
        elseif indices(n) >=24
            x(indices(n))=mean(x(indices(n)-24),x(indices(n)-1));            
        else
            if ~isnan(x(indices(n)+24))
                x(indices(n))=x(indices(n)+24);
            elseif ~isnan(x(indices(n)+24*7))
                x(indices(n))=x(indices(n)+24*7);
            else
                disp('Too many undefined values. Filling the time series failed.')
            end
        end
    end
end  

end