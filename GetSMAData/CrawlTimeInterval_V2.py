# This script downloads pv generation data from the SMA website of plants that were found by the Get_SMAData scripts.
# First, from the properties csv file of all found plants it identifies all plants within a specific power range whose 
# data set is incomplete regarding the given time range specified by DateStart and DateEnd and checked by the CalcDateRange 
# function. Then, all missing dates are downloaded. Therefore at first, the plants website is opened. Then the button that
# opens the website with the recorded data tables is clicked. The (mostly two) button numbers are given by the properties
# file. If necessary, the directories needed for storing the downloaded data is created by the MakeDirectories function.
# The CrawlData function iterates through all Dates of DateRange and saves the data for each day in a seperate csv file.
# 
# Main Variables:
#   DateStart:      Beginning of time interval in wich data is downloaded. Datetime (1,1)
#   DateEnd:        End of time interval in wich data is downloaded. Datetime (1,1)
#   MinPower:       Plants with lower power aren't consider in this session. Float (1,1)
#   MaxPower:       Plants higher lower power aren't consider in this session. Float (1,1)
#   Dl:             Delimiter for directories. In Windows and Linux both it should be a slash. String (1,1)
#   DataPath:       Main path where the data shall be stored. String
#   DriverPath:     Path wehere the browser driver is stored. String
#   DateRange:      All dates between DateStart and DateEnd that are not downloaded for given plant yet. Datetime (n,1)
#   ImageButton:    Button that has to be clicked in order to open the website with the recorded data tables. Selenium object
#   PropertiesList: The properties of all plants given by their properties file. String list:
#                           [0][0]: Plant location, [0][1]: Activation date, [0][2]: Max power in kWp, [0][3]: Plant ID, [0][4]: Plant website
#                           [0][5]: Number for the right ImageButton and OpenButton, [0][6]: Indicator for the existence of a OpenButton (>0 indicates the existence)
#                           [1][:]: All dates the data is downloaded yet (equals ExistingDates in other scripts)

from selenium import webdriver
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
from selenium.webdriver.common.by import By
from selenium.common.exceptions import TimeoutException
from DataFunctions import *
import os
import csv
from tqdm import *
import shutil

StartSys=time.time() # Measure execution time of the script

DateStart=datetime(2018,1,1)
DateEnd=datetime(2020,8,20)
MinPower=6
MaxPower=8.999

Dl='/'
DataPath=r"C:/Users/nicop/SMAPlantData/PlantData"
DriverPath= "C:\Program Files (x86)\chromedriver.exe"
option = webdriver.ChromeOptions()
chrome_prefs = {}
option.experimental_options["prefs"] = chrome_prefs
chrome_prefs["profile.default_content_settings"] = {"images": 2}
chrome_prefs["profile.managed_default_content_settings"] = {"images": 2}
# driver=webdriver.Chrome(DriverPath, chrome_options=option)

for p in range(3):
    
    driver=webdriver.Chrome(DriverPath)
    driver.get("https://www.sunnyportal.de/Templates/PublicPagesPlantList.aspx") # initialise the driver

    PropertiesList=GetPropertiesList(DataPath, Dl) # get the properties of all plants from their properties lists

    PlantBar = tqdm(total=len(PropertiesList)+1, position=0) # a usual waitbar/progressbar

    for Plant in PropertiesList:
        
        PlantBar.update() # increment the progressbar

        PlantPath=DataPath + Dl + Plant[0][3]
        if not exists(PlantPath): # in case the plant was deleted by a script that runs in parallel jump to next plant
            continue
        
        Power=float(Plant[0][2][0:Plant[0][2].find(' ')].replace(',','.')) # peak power of the plant

        if Power<=MaxPower and Power >=MinPower:        

            Plant[1].clear()
            Plant[1].extend(WriteProperties(PlantPath, Plant, Dl)) # update the existing dates
            PlantDataStartDate=max(datetime.strptime(Plant[0][1], '%d.%m.%Y'), DateStart)
            DateRange=CalcDateRange(PlantDataStartDate, Plant[1], DateEnd) # evaluate which dates are missing in existing dates

            if len(DateRange)>0:

                driver.get(Plant[0][4]) # open the plants main webpage

                Tabs=driver.find_elements_by_class_name("tab") # if there are tabs choose the one labeld with 'Tag'
                if len(Tabs)>0:
                    for Tab in Tabs:
                        if Tab.text=='Tag':
                            Tab.click()
                            break

                if Plant[0][6]!='0': # if there is a OpenButton (graphically represented by a gearwheel)
                    try:
                        driver.find_element_by_xpath("//*[contains(@id, '" + Plant[0][5] + '_OpenButtonsDivImg' + "')]").click() # click the one with the number indicated by Plant[0][5]
                    except:
                        pass
                
                try:
                    ImageButton=driver.find_element_by_xpath("//*[contains(@id,  '" + Plant[0][5] +  '_ImageButtonValues' + "')]") # find the right ImageButton (graphically represented by an "i" sourrounded by a blue circle)
                    WebDriverWait(driver, 1).until(EC.element_to_be_clickable((By.ID, ImageButton.get_attribute("id")))) # wait until the ImageButton appears
                    ImageButton.click() # click the ImageButton so that the recorded values table opens in a seperate window
                except:
                    print("An error occured during clicking the buttons.")
                    continue
                
                try:
                    driver.switch_to.window(driver.window_handles[1]) # switch to the newly opened window
                                
                    MakeDirectories(DateRange, PlantPath, Dl) # create all directories that will be needed to store the data depending on DateRange
                    [Error, TSComplete]=CrawlData(DateRange, PlantPath, Dl, driver) # scrape the data from the website by iterating through DateRange and store the data in seperate csv files
                    if TSComplete==True: # if no error occured during the scraping
                        WriteProperties(PlantPath, Plant, Dl) # update the properties
                    else:
                        print("Plant " + Plant[0][3] + " deleted.")
                        WriteListOfUnsuitablePlants(DataPath, Plant[0][3], Dl)
                        shutil.rmtree(PlantPath)  # if there was a serious error then deleted the plant's folder


                    driver.close() # when done with scraping the data for the plant, close the seperate window
                    driver.switch_to.window(driver.window_handles[0]) # and switch back to the plant's website
                    
                except:
                    print("An error occured during data crawling.")
                    for n in range(1, len(driver.window_handles)):
                        driver.switch_to.window(driver.window_handles[n])
                        driver.close()
                    driver.switch_to.window(driver.window_handles[0])
                    continue

    PlantBar.update()
    driver.quit()
    print("Done within: " + str(time.time()-StartSys))