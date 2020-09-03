function Sunday=NextSunday(Date)
    Sunday=Date+days(mod(8-weekday(Date),7));
end