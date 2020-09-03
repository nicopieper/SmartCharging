function Sunday=LastSunday(Date)
    Sunday=Date-days(weekday(Date)-1);
end