function Monday=LastMonday(Date)
    Monday=Date-days(mod(weekday(Date)-2,7));
end