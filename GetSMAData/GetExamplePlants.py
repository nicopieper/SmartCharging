# This script browses through the "Freigegebenen Anlagen" of the SMA sunny portal website in order to find residential PV plants
# and download their generation data.
# After the initialisation of libraries and variables, the plants from the SMA plant list are extracted that are within a certain
# power range and are located in Germany. Then, all of the found plants that were not considered in a past execution are checked
# whether it is possible to extract suitable data from them. A plant is suitable if its webiste covers information about its
# location, is operation start and generation power and if the generation data is available in 15 minutes steps while only one
# generation power is recorded. The last criterion ensures, that unwanted records of power consumption from connected home energy
# systems are not falsly treated as PV generation data. For suitable plants, a folder structre and a properties file becomes
# created and the generation data is downloaded within the given time interval specified by DateStart and DateEnd and stored
# in a csv file. Mostly, data from only one day will be downlaoded, as the CrwalTimeInterval files continue the real screen 
# scraping process of suitable plants. The ID of unsuitable plants is stored within the ListOfUnsuitablePlants.
# 
# Main Variables:
#   DateStart:          Beginning of time interval in wich data is downloaded. Datetime (1,1)
#   DateEnd:            End of time interval in wich data is downloaded. Datetime (1,1)
#   MinPower:           Plants with lower power aren't consider in this session. Float (1,1)
#   MaxPower:           Plants higher lower power aren't consider in this session. Float (1,1)
#   Dl:                 Delimiter for directories. In Windows and Linux both it should be a slash. String (1,1)
#   DataPath:           Main path where the data shall be stored. String
#   DriverPath:         Path wehere the browser driver is stored. String
#   DateRange:          All dates between DateStart and DateEnd that are not downloaded for given plant yet. Datetime (n,1)
#   ImageButton:        Button that has to be clicked in order to open the website with the recorded data tables. Selenium object
#   PropertiesList:     The properties of all plants given by their properties file. String list:
#                           [0][0]: Plant location, [0][1]: Activation date, [0][2]: Max power in kWp, [0][3]: Plant ID, [0][4]: Plant website
#                           [0][5]: Number for the right ImageButton and OpenButton, [0][6]: Indicator for the existence of a OpenButton (>0 indicates the existence)
#                           [1][:]: All dates the data is downloaded yet (equals ExistingDates in other scripts)
#   NumPlants:          If NumPlants suitable plants are found, the execution of this script stops. Int (1,1)
#   NumPlantsSearch:    If NumPlantsSearch plants are found within the SMA plant list, the search process for more plants is terminated. Int (1,1)
#   ListOfUnsuitablePlants:     List with the IDs of all plants that were classified as unsuitable. String (n,1)
#   IDList:             List with the IDs of all plants that were either classified as unsuitable or were already found in a past execution of this script. String (n,1)
# 

from selenium import webdriver
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
from selenium.webdriver.common.by import By
from selenium.common.exceptions import TimeoutException
from DataFunctions import *
from tqdm import *

StartSys=time.time() # measure the script's execution time
DateStart=datetime(2018,1,1)
DateEnd=datetime(2020,5,31)
SuccessfulWritings=3

Dl='/'
DataPath=r"C:/Users/nicop/SMAPlantData/ExamplePlantData"
DriverPath= "C:\Program Files (x86)\chromedriver.exe"
# option = webdriver.ChromeOptions() # options to avoid the loading of images. Enhances the perfomance but seems to lead to errors with some plants. May be futher investigated
# chrome_prefs = {}
# option.experimental_options["prefs"] = chrome_prefs
# chrome_prefs["profile.default_content_settings"] = {"images": 2}
# chrome_prefs["profile.managed_default_content_settings"] = {"images": 2}
# driver=webdriver.Chrome(DriverPath, chrome_options=option)
driver=webdriver.Chrome(DriverPath)
driver.get("https://www.sunnyportal.de/Templates/ExamplePlants.aspx")

PlantID=[]
NumPlants=3
SuccessfulWritings=0

PropertiesList=[]
ListOfUnsuitablePlants=ReadListOfUnsuitablePlants(DataPath, Dl) # get the IDs of all plants that were classified as unsuitable
IDList=[PropertiesList[i][0][3] for i in range(len(PropertiesList))]
IDList.extend(ListOfUnsuitablePlants) # list with all unsuitable plants and those that do already exsist

PlantID=["4a115b2f-1fbb-4d55-9f2b-b5b34711cf40", "0abb6024-7fa2-4783-982e-38778a279a40", "64a68a1e-7b3f-47ac-825a-28c5ae1a955e"]

        
PlantBar = tqdm(total=len(PlantID), position=0) # a usual waitbar/progressbar

for ID in PlantID: # iterate through each found ID    
    PlantBar.update()

    if SuccessfulWritings>=NumPlants: # if NumPlants suitable plants were found, terminate this script
        break

    if ID not in IDList: # should always be true as it was checked before --> may be deleted but it does not harm

        # driver.get(str("https://www.sunnyportal.de/Templates/PublicPageOverview.aspx?plant=" + ID + "&splang=")) # open the plant's webpage as their URLs have a static pattern
        driver.get(str("https://www.sunnyportal.de/RedirectToPlant/" + ID)) # open the plant's webpage as their URLs have a static pattern
        try:
            Anlagensteckbrief=driver.find_elements_by_xpath('//*[@title="Anlagensteckbrief"]') # just continue considering this plant as suitable if there is a subpage called 'Anlagensteckbrief' as the information of this page is needed
            if len(Anlagensteckbrief)>0:
                Anlagensteckbrief[0].click() # if this page exists, open it
            else:
                print("No Anlagensteckbrief found")
                WriteListOfUnsuitablePlants(DataPath, ID, Dl) # if this page does not exist, add this plant to the ListOfUnsuitablePlants
                continue # and continue with the next plant

            try:
                PlantStartDate=driver.find_element_by_xpath("//*[contains(@id,'PlantProfileTableCellStartValue')]").text # extract plant's start date of opration
                PlantPower=driver.find_element_by_xpath("//*[contains(@id,'PlantProfileTableCellPowerValue')]").text # extract plant's peak generation power
                PlantLocation=driver.find_element_by_xpath("//*[contains(@id,'PlantProfileTableCellCityCountryValue')]").text # extract plant's location
            except:
                WriteListOfUnsuitablePlants(DataPath, ID, Dl) # if one of the information does not exist, add this plant to the ListOfUnsuitablePlants
                continue
            
            PlantPath=DataPath + Dl + ID

            if datetime.strptime(PlantStartDate, '%d.%m.%Y') <= DateStart: # only consider plant if the start date of operation is before DateStart

                Pages=driver.find_elements_by_xpath("//*[starts-with(@id, 'ctl00_NavigationLeftMenuControl')]") # find all subpages of the plant
                WritingSuccessful=False

                for n in range(len(Pages)): # search for a subpage that contains a diagram with PV generation data recorded in 15 minutes time steps and without other records (2 column criterion)

                    if SuccessfulWritings>NumPlants: # terminate this loop if number of needed plants is reached
                        break

                    if WritingSuccessful==True: # if a suitable subpage was found, terminate this loop and continue with the next plant
                        break

                    if Pages[n].get_attribute("title") not in ["Energiebilanz", "Energie und Leistung"]:
                        continue

                    driver.switch_to.window(driver.window_handles[0]) # a safety command to ensure that the right window is active
                    Pages[n].click() # open the first subpage
                    
                    Tabs=driver.find_elements_by_class_name("tab") # if this subpage has tabs, open the tab labeld "Tag" to get daily values
                    if len(Tabs)>0:
                        for Tab in Tabs:
                            if Tab.text=='Tag':
                                Tab.click()
                                break

                    DatePicker=driver.find_element_by_xpath("//*[contains(@id, 'ChartDatePicker_PC_DatePickerFrom')]")
                    PageURL=driver.current_url
                    Plant=[[PlantLocation, PlantStartDate, PlantPower, ID, PageURL, '-', '-'], []] # store all plant information i a variable
                    
                    Plant[1].clear()
                    DateRange=CalcDateRange(DateStart, Plant[1], DateEnd) # evaluate for which dates data shall be downloaded for
                    MakeDirectories(DateRange, PlantPath, Dl) # create all directories that will be needed to store the data depending on DateRange
                    Plant[1].extend(WriteProperties(PlantPath, Plant, Dl)) # update the existing dates
                    DateRange=CalcDateRange(DateStart, Plant[1], DateEnd) # evaluate for which dates data shall be downloaded for

                    while len(DateRange)>0:

                        try:
                            for Date in DateRange:
                                WebDriverWait(driver, 10).until(EC.element_to_be_clickable((By.ID, DatePicker.get_attribute("id")))) # wait until the OpenButton is clickable. might be unnecessary as the OpenBUtton should be clickable immediatly after the page has loaded
                                DatePicker.clear()
                                DatePicker.send_keys(datetime.strftime(Date, "%d.%m.%Y"))
                                DatePicker.send_keys(u'\ue007')
                                time.sleep(0.2)
                                driver.get("https://www.sunnyportal.de/Templates/DownloadDiagram.aspx?down=homanEnergyRedesign&chartId=mainChart")
                        except:
                            pass


                        DownloadedFiles=listdir("C:/Users/nicop/Downloads/")
                        for File in DownloadedFiles:
                            if "(1)" in File or "(2)" in File or "(3)" in File:
                                remove("C:/Users/nicop/Downloads/" + File)
                            elif "_" in File:
                                Year=File[-14:-10]
                                Month=File[-9:-7]
                                if isfile("C:/Users/nicop/Downloads/" + File) and exists(DataPath + Dl + ID + Dl + Year + Dl + Month + Dl):
                                    shutil.move("C:/Users/nicop/Downloads/" + File, DataPath + Dl + ID + Dl + Year + Dl + Month + Dl + File)
                                else:
                                    remove("C:/Users/nicop/Downloads/" + File)

                        Plant[1].clear()
                        Plant[1].extend(WriteProperties(PlantPath, Plant, Dl)) # update the existing dates
                        DateRange=CalcDateRange(DateStart, Plant[1], DateEnd) # evaluate for which dates data shall be downloaded for

                    WritingSuccessful=True

        except AssertionError as error:
            print(error)        
            
        
    


PlantBar.update()
driver.quit()
print("Done within: " + str(time.time()-StartSys))