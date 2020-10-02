from selenium import webdriver
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
from selenium.webdriver.common.by import By
from selenium.common.exceptions import TimeoutException
from DataFunctions import *
import os
import csv
from tqdm import *

StartSys=time.time() # Measure execution time of the script

DateStart=datetime(2020,1,1)
DateEnd=datetime(2020,1,31)
MinPower=3
MaxPower=15

Dl='/'
DataPath=r"C:/Users/nicop/SMAPlantData/PlantData"
DriverPath= "C:\Program Files (x86)\chromedriver.exe"
option = webdriver.ChromeOptions()
chrome_prefs = {}
option.experimental_options["prefs"] = chrome_prefs
chrome_prefs["profile.default_content_settings"] = {"images": 2}
chrome_prefs["profile.managed_default_content_settings"] = {"images": 2}
# driver=webdriver.Chrome(DriverPath, chrome_options=option)
SuccessfulWritings=0

for p in range(3):
    
    driver=webdriver.Chrome(DriverPath)
    driver.get("https://www.sunnyportal.de/Templates/PublicPagesPlantList.aspx") # initialise the driver

    PropertiesList=GetPropertiesList(DataPath, Dl) # get the properties of all plants from their properties lists

    PlantBar = tqdm(total=len(PropertiesList)+1, position=0) # a usual waitbar/progressbar

    counter=0

    for Plant in PropertiesList:
        
        PlantBar.update() # increment the progressbar

        PlantPath=DataPath + Dl + Plant[0][3]
        if not exists(PlantPath): # in case the plant was deleted by a script that runs in parallel jump to next plant
            continue
        
        Power=float(Plant[0][2][0:Plant[0][2].find(' ')].replace(',','.')) # peak power of the plant

        if Power<=MaxPower and Power >=MinPower:       

            driver.get(Plant[0][4]) # open the plants main webpage

            Anlagensteckbrief=driver.find_elements_by_xpath('//*[@title="Anlagensteckbrief"]') # just continue considering this plant as suitable if there is a subpage called 'Anlagensteckbrief' as the information of this page is needed
            if len(Anlagensteckbrief)>0:
                Anlagensteckbrief[0].click() # if this page exists, open it
            else:
                print("No Anlagensteckbrief found")
                continue # and continue with the next plant

            try:
                Slope=driver.find_element_by_xpath("//*[contains(@id,'GradientValue')]") # extract plant's start date of opration
                Azimuth=driver.find_element_by_xpath("//*[contains(@id,'AlignmentValue')]") # extract plant's start date of opration

                counter=counter+1
                print(Slope.text + "\n")
                print(Azimuth.text + "\n")

                if Slope.text.count("°")>1 or Azimuth.text.count("°")>1:
                    continue
                else:
                    with open(PlantPath + Dl + 'AzimutSlope' + '.csv' , 'w',) as csvfile:
                        csvwriter = csv.writer(csvfile)
                        csvwriter.writerows([['Slope: ' + Slope.text + '\n' + 'Azimuth: ' + Azimuth.text]])




                # Slope4=driver.page_source.find('Neigungswinkel')
                # Slope5=driver.page_source.find('Slope')
                # Slope6=driver.page_source.find('Azimuth')
                # Slope6=driver.page_source.find('Azimut')
                # Slope7=driver.page_source.find('Elevation')
                # Slope8=driver.page_source.find('°')

                # if len(Slope1)>0 or  len(Slope2)>0 or len(Slope3)>0 or Slope4!=-1 or Slope5!=-1 or Slope6!=-1 or Slope7!=-1 or Slope8!=-1:
                #     print("Found" + Plant[0][3])
                #     counter=counter+1

            except:
                continue
            

PlantBar.update()
driver.quit()
print("Done within: " + str(time.time()-StartSys))