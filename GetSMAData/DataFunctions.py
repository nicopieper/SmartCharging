# This script contains functions that are used by GetSMAData and CrwalTimeInterval in order to download pv generation data from several
# pv plants listed on the SMA website.
#
# Abstract:
#   CheckInternetConnection:        Checks the internet connection
#   ParseValueTable:                Extracts the pv generation data from the website
#   CrawlData:                      Iterates through DataRange in order to scrape the needed data
#   GetPropertiesList:              Reads the properties of a specific plant from its properties file
#   MakeDirectories:                Creates the missing directories within DataRange for a specific plant
#   WriteDay:                       Writes the scraped data of one day and one plant into a csv file
#   WriteProperties:                Updates the properties of a specific plant
#   GetProperties:                  Get the properties of all plants within the DataPath
#   CalcDateRange:                  Evaluate the dates for which data has to be downloaded
#   WriteCompleteData:              Writes the scraped data of multiple days and one plant into a csv file (out of use, replaced by WriteDay)


import pandas as pd
import csv
from os import listdir, makedirs, remove
from os.path import isfile, join, isdir, exists
from datetime import date, datetime, timedelta
from dateutil.relativedelta import relativedelta
import time
import re
import sys
from tqdm import *
import urllib.request
import shutil


def CheckInternetConnection(host='http://google.com'):
    try:
        urllib.request.urlopen(host) #Python 3.x
        return True
    except:
        print("No Internet Connection")
        return False

def ParseValueTable(Source, DateStr):
    # Source:   The page source of the recoreded data table website. String
    # DateStr:  The date of the downloaded data. String

    Data=[]
    NumberHeaderCells=0
    try:
        NumberHeaderCells=Source.count("base-grid-header-cell")    
        if NumberHeaderCells==2: # if there are more than two cloumns (more than one data column), delete the plant as it is unsure what the additional columns mean
            Source=Source[Source.find("base-grid-header-cell"):]
            while "base-grid-item-cell" in Source and len(Data)<96: # each date of pv generation value is stored in a seperate table cell. Iterate thorugh them and extract the content
                Source=Source[Source.find('<td class="base-grid-item-cell">')+32:]
                Data1=" ".join([DateStr, Source[0:Source.find('</td>')]]) # find the date cell
                Source=Source[Source.find('<td class="base-grid-item-cell" align="right">')+46:]
                Data2=Source[0:Source.find('</td>')] # find the value cell
                Data.append([Data1, Data2]) # store them in Data
    except:
        pass   

    return(NumberHeaderCells, Data)

def CrawlData(DateRange, PlantPath, Dl, driver):
    # DateRange:    All dates between DateStart and DateEnd that are not downloaded for given plant yet. Datetime (n,1)
    # PlantPath:    Path where the data of the specific plant is stored. String
    # Dl:           Delimiter for directories. In Windows and Linux both it should be a slash. String (1,1)
    # driver:       The selenium driver which is assigned. Selenium object

    try:
        Error=False
        TSComplete=True # indicator whether the time series could be completed. If False the whole plant data will be deleted in the CrawlTimeInterval script
        ValuesURL=driver.current_url
        StartIndex=ValuesURL.find("endTime=")        
        DateBar = tqdm(total=len(DateRange)+1, position=0)
        if len(DateRange)>1:
            print("Start to crawl data for plant " + PlantPath[PlantPath.rfind(Dl)+1:] + " from " + str(DateRange[0]) + " to " + str(DateRange[-1]))
        else:
            print("Start to crawl data for plant " + PlantPath[PlantPath.rfind(Dl)+1:] + " at " + str(DateRange[0]))

        for Date in DateRange:
            if TSComplete==False:
                break
            DateBar.update()
            DateStr=Date.strftime('%d.%m.%Y')
            RepeatLoop=True
            
            while RepeatLoop==True: # normally this loop runs only once per date. If an error occured, e. g. in case of a lost internet connection, the loop will be repeated
                RepeatLoop=False
                driver.get(ValuesURL.replace(ValuesURL[StartIndex+8:StartIndex+18],DateStr)) # open the webpage with the right date
                [NumberHeaderCells, PlantTable]=ParseValueTable(driver.page_source, DateStr) # extract the data from the webpage
                # Values=driver.find_elements_by_tag_name("td")
                # HeaderCells=len([m.start() for m in re.finditer('class="base-grid-header-cell', driver.page_source)])                

                if not (len(PlantTable)>=96 and ("00:15" in PlantTable[0][0] or "00.15" in PlantTable[0][0])) or NumberHeaderCells!=2: # all conditions are indicators for errors
                    if len(DateRange)>1:
                        print("An error occured with plant " + PlantPath[PlantPath.rfind(Dl)+1:] + " at Date " + Date.strftime("%d.%m.%Y") + ". NumberHeaderCells==" + str(NumberHeaderCells))
                        InternetConnection=CheckInternetConnection()
                        if InternetConnection==False:
                            RepeatLoop=True
                            while InternetConnection==False:            
                                time.sleep(30)
                                InternetConnection=CheckInternetConnection()
                        elif Date not in [datetime(2018,1,2), datetime(2018,1,3)] or NumberHeaderCells!=2:
                            TSComplete=False
                            break
                        else:
                            print("Search for the error")
                            break
            
                if RepeatLoop==False:                    
                    # Data=[[" ".join([DateStr, Values[(Rows+1)*HeaderCells].text]), Values[(Rows+1)*HeaderCells+1].text] for Rows in range(int(len(Values)/HeaderCells)-1-96, int(len(Values)/HeaderCells)-1)]                    
                    WriteDay(PlantPath, Dl, PlantTable) # write the extracted data to a csv file
        
    except:
        InternetConnection=CheckInternetConnection()

        while InternetConnection==False:            
            time.sleep(30)
            InternetConnection=CheckInternetConnection()
            
        Error=True

    DateBar=tqdm(position=len(DateRange)+1) 
    return(Error, TSComplete)

def MakeDirectories(DateRange, PlantPath, Dl):
    # DateRange:    All dates between DateStart and DateEnd that are not downloaded for given plant yet. Datetime (n,1)
    # PlantPath:    Path where the data of the specific plant is stored. String
    # Dl:           Delimiter for directories. In Windows and Linux both it should be a slash. String (1,1)

    for Month in DateRange:
        if not exists(PlantPath + Dl + Month.strftime('%Y') + Dl + Month.strftime('%m') + Dl):
            makedirs(PlantPath + Dl + Month.strftime('%Y') + Dl + Month.strftime('%m') + Dl)

def WriteDay(PlantPath, Dl, PlantTable):
    # PlantTable:   The extracted data from the recoreded pv generation website
    # PlantPath:    Path where the data of the specific plant is stored. String
    # Dl:           Delimiter for directories. In Windows and Linux both it should be a slash. String (1,1)

    Date=PlantTable[0][0][0:10]
    with open(PlantPath + Dl + Date[6:10] + Dl + Date[3:5] + Dl + 'PVPlantData_' + Date + '.csv' , 'w', newline='') as csvfile:
        csvwriter = csv.writer(csvfile)
        csvwriter.writerows(PlantTable)

def WriteProperties(PlantPath, Plant, Dl):
    # Plant:        Plant properties and ExistingDates
    # PlantPath:    Path where the data of the specific plant is stored. String
    # Dl:           Delimiter for directories. In Windows and Linux both it should be a slash. String (1,1)

    PlantFolders=[Path for Path in listdir(PlantPath) if not isfile(PlantPath + Dl + Path)]
    PlantFiles=[]
    for PlantFolder in PlantFolders:
        if not "PredictionData" in PlantFolder:
            PlantSubFolders=listdir(PlantPath + Dl + PlantFolder)
            for PlantSubFolder in PlantSubFolders:
                if "ExamplePlantData" in PlantPath:
                    Files = [f[-6:-4] + "." + f[-9:-7] + "." + f[-14:-10] for f in listdir(PlantPath + Dl + PlantFolder + Dl + PlantSubFolder) if isfile(join(PlantPath + Dl + PlantFolder + Dl + PlantSubFolder, f))]
                else:    
                    Files = [f[-14:-4] for f in listdir(PlantPath + Dl + PlantFolder + Dl + PlantSubFolder) if isfile(join(PlantPath + Dl + PlantFolder + Dl + PlantSubFolder, f))]
                PlantFiles.extend(Files)

    with open(PlantPath + Dl + 'PlantProperties.csv', 'w', newline='') as csvfile:                          
        csvwriter = csv.writer(csvfile)                                                
        csvwriter.writerow([";".join(Plant[0])])
        csvwriter.writerow(PlantFiles)

    return PlantFiles

def GetProperties(PlantPath):
    # PlantPath:    Path where the data of the specific plant is stored. String

    if isfile(PlantPath + 'PlantProperties.csv'):
        with open(PlantPath + 'PlantProperties.csv') as CsvFile:
            ReadCsv = csv.reader(CsvFile, delimiter=';')
            Properties=next(ReadCsv)[0].split(';')
            if len(Properties)<5:
                print("The PropertiesList of Plant " + PlantPath + " is empty")
            else:
                try:
                    ExistingDates=next(ReadCsv)[0].split(',')
                except:
                    ExistingDates=[]

        return(Properties, ExistingDates)

def GetPropertiesList(DataPath, Dl):
    # DataPath:       Main path where the data shall be stored. String
    # Dl:           Delimiter for directories. In Windows and Linux both it should be a slash. String (1,1)

    Folders=listdir(DataPath)
    PropertiesList=[]

    for Plant in Folders:
        if Plant!='ListOfUnsuitablePlants.csv':
            PlantPath=DataPath + Dl + Plant + Dl
            Properties=GetProperties(PlantPath)
            if Properties==None:
                shutil.rmtree(PlantPath)
            else:
                PropertiesList.append(Properties)
            

    return(PropertiesList)

def CalcDateRange(PlantDataStartDate, ExistingDates, DateEnd):
    # PlantDataStartDate:   Maximum of plants activation date and DateStart. Date when data collection starts
    # ExistingDates:        All dates data is already donwloaded. Equals Plant[1][:]
    # DateEnd:              Last date data shall be downloaded for

    DateRange=[PlantDataStartDate]
    ExistingDates=[datetime.strptime(ExistingDates[i], '%d.%m.%Y') for i in range(len(ExistingDates))]
    while DateRange[-1]<DateEnd:
        DateRange.append(DateRange[-1]+timedelta(days=1))
    DateRange=[ele for ele in DateRange if ele not in ExistingDates]

    return(DateRange)

def ReadListOfUnsuitablePlants(DataPath, Dl):
    if isfile(DataPath + Dl + 'ListOfUnsuitablePlants.csv'):
        with open(DataPath + Dl + 'ListOfUnsuitablePlants.csv') as CsvFile:
            ReadCsv = csv.reader(CsvFile, delimiter=';')
            try:
                ListOfUnsuitablePlants=next(ReadCsv)[0]
                ListOfUnsuitablePlants=ListOfUnsuitablePlants.split(',')
            except:
                ListOfUnsuitablePlants=[]

        return(ListOfUnsuitablePlants)

def WriteListOfUnsuitablePlants(DataPath, PlantID, Dl):
    if isfile(DataPath + Dl + 'ListOfUnsuitablePlants.csv'):
        ListOfUnsuitablePlants=ReadListOfUnsuitablePlants(DataPath, Dl)

        if PlantID not in ListOfUnsuitablePlants:
            ListOfUnsuitablePlants.append(PlantID)

            with open(DataPath + Dl + 'ListOfUnsuitablePlants.csv', 'w', newline='') as csvfile:                          
                csvwriter = csv.writer(csvfile)                                                
                csvwriter.writerow(ListOfUnsuitablePlants)

    return ListOfUnsuitablePlants


def WriteCompleteData(DateRange, PlantPath, Plant, Dl, PlantTable): # Old function, not in use anymore. Replaced by WriteDay
    for Month in DateRange:
        if not exists(PlantPath + Month.strftime('%Y') + Dl + Month.strftime('%m') + Dl):
            makedirs(PlantPath + Month.strftime('%Y') + Dl + Month.strftime('%m') + Dl)

    Days=0
    for Date in DateRange:
        if Date.strftime('%d.%m.%Y') != PlantTable[Days][0][0][0:10]:
            print("Date of File Label did not match Date of Timeseries. Program stopped.")
            sys.exit()
        with open(PlantPath + Dl + Date.strftime('%Y') + Dl + Date.strftime('%m') + Dl + 'PVPlantData_' + Date.strftime('%d.%m.%Y') + '.csv' , 'w', newline='') as csvfile:
            csvwriter = csv.writer(csvfile)
            csvwriter.writerows(PlantTable[Days])
        Days=Days+1