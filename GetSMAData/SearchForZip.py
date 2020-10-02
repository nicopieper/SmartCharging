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
MinPower="3"
MaxPower="15,5"
NumPlants=1
NumPlantsSearch=200

Dl='/'
DataPath=r"C:/Users/nicop/SMAPlantData/PlantData"
DriverPath= "C:\Program Files (x86)\chromedriver.exe"
# option = webdriver.ChromeOptions() # options to avoid the loading of images. Enhances the perfomance but seems to lead to errors with some plants. May be futher investigated
# chrome_prefs = {}
# option.experimental_options["prefs"] = chrome_prefs
# chrome_prefs["profile.default_content_settings"] = {"images": 2}
# chrome_prefs["profile.managed_default_content_settings"] = {"images": 2}
# driver=webdriver.Chrome(DriverPath, chrome_options=option)
driver=webdriver.Chrome(DriverPath)
driver.get("https://www.sunnyportal.de/Templates/PublicPagesPlantList.aspx")

driver.find_element_by_id("ctl00_ContentPlaceHolder1_CountryDropDownList").send_keys("Deutschland") # enter "Deutschland" in country edit field
driver.find_element_by_id("ctl00_ContentPlaceHolder1_FromPeakPowerNumTB_numTB").send_keys(MinPower) # enter MinPower in corresponding edit field
driver.find_element_by_id("ctl00_ContentPlaceHolder1_ToPeakPowerNumTB_numTB").send_keys(MaxPower) # enter MaxPower in corresponding edit field
#driver.find_element_by_id("ctl00_ContentPlaceHolder1_CityFilterTextBox").send_keys("Basel")
driver.find_element_by_id("ctl00_ContentPlaceHolder1_FilterButton").click() # click the "Suchen" button

PlantID=[]
SuccessfulWritings=0

PropertiesList=GetPropertiesList(DataPath, Dl) # get the properties of all plants from their properties lists
IDList=[PropertiesList[i][0][3] for i in range(len(PropertiesList))]

PlantBar = tqdm(total=len(IDList), position=0)

while len(PlantID)<NumPlantsSearch: # search for the number of NumPlantsSearch new plants 
    Source=driver.page_source
    Source=Source[Source.find("Leistung (kWp)</a></td>"):Source.find("ctl00_ContentPlaceHolder1__dataGridPagerDown_PagerTable")]

    while "javascript:OpenPlant('PublicPageOverview.aspx?plant=" in Source:
        
        Index=Source.find("javascript:OpenPlant('PublicPageOverview.aspx?plant=")+52 # the plant's the ID starts after the command
        Source=Source[Index:]
        PlantID=Source[0:Source.find("splang=')")-5] # and ends before "splang="
        if PlantID in IDList: # append found ID to PlantID if it is not in IDList
            ListIndex=IDList.index(PlantID)

            Index=Source.find('td class="base-grid-item-cell"')+27
            Source=Source[Index:]
            Index=Source.find('td class="base-grid-item-cell"')+30
            Source=Source[Index:]
            End=Source.find('td>')
            ZIP=Source[1:6]

            if not ZIP.isnumeric():
                continue

            Plant=PropertiesList[ListIndex]
            if len(Plant[0])==8:
                Plant[0][7]=ZIP
            elif len(Plant[0])==7:
                Plant[0].append(ZIP)
            else:
                continue

            PlantPath=DataPath + Dl + PlantID
            WriteProperties(PlantPath, Plant, Dl)

            PlantBar.update()

    NextPageButton=driver.find_elements_by_id("ctl00_ContentPlaceHolder1__dataGridPagerDown_ClickImgNext") # if there is no "javascript:OpenPlant..." anymore within the code, jump to the next page by clicking the button
    if len(NextPageButton)==0 or NextPageButton[0].is_enabled()==False: # in case the last page is reach end the search for new plants. in this case the arrow button is not clickable
        break
    else:
        NextPageButton[0].click() # but mostly it will be clickable
        
PlantBar = tqdm(total=len(PlantID), position=0) # a usual waitbar/progressbar





driver.quit()
print("Done within: " + str(time.time()-StartSys))





