# This script browses through the "Freigegebenen Anlagen" of the SMA sunny portal website in order to find residential PV plants
# and download their generation data.
# After the initialisation of libraries and variables, the plants from the SMA plant list are extracted that are within a certain
# power range and are located in Germany. Then, all of the found plants that were not considered in a past execution are checked
# whether it is possible to extract suitable data from them. A plant is suitable if its webiste covers information about its
# location, its operation start and generation power and if the generation data is available in 15 minutes steps while only one
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
DateStart=datetime(2020,5,1)
DateEnd=datetime(2020,7,31)
MinPower="3"
MaxPower="15"
NumPlants=10
NumPlantsSearch=20

Dl='/'
DataPath=r"C:/Users/EWEGo/PlantData"
DriverPath= "C:/Program Files (x86)/chromedriver.exe"


# option = webdriver.ChromeOptions() # options to avoid the loading of images. Enhances the perfomance but seems to lead to errors with some plants. May be futher investigated
# chrome_prefs = {}
# option.experimental_options["prefs"] = chrome_prefs
# chrome_prefs["profile.default_content_settings"] = {"images": 2}
# chrome_prefs["profile.managed_default_content_settings"] = {"images": 2}
# driver=webdriver.Chrome(DriverPath, chrome_options=option)
driver=webdriver.Chrome(DriverPath)
driver.get("https://www.sunnyportal.de/Templates/PublicPagesPlantList.aspx")

# driver.find_element_by_id("ctl00_ContentPlaceHolder1_CountryDropDownList").send_keys("Deutschland") # enter "Deutschland" in country edit field
driver.find_element_by_id("ctl00_ContentPlaceHolder1_FromPeakPowerNumTB_numTB").send_keys(MinPower) # enter MinPower in corresponding edit field
driver.find_element_by_id("ctl00_ContentPlaceHolder1_ToPeakPowerNumTB_numTB").send_keys(MaxPower) # enter MaxPower in corresponding edit field
driver.find_element_by_id("ctl00_ContentPlaceHolder1_CityFilterTextBox").send_keys("Basel")
driver.find_element_by_id("ctl00_ContentPlaceHolder1_FilterButton").click() # click the "Suchen" button

PlantID=[]
SuccessfulWritings=0

PropertiesList=GetPropertiesList(DataPath, Dl) # get the properties of all plants from their properties lists
ListOfUnsuitablePlants=ReadListOfUnsuitablePlants(DataPath, Dl) # get the IDs of all plants that were classified as unsuitable
if not ListOfUnsuitablePlants:
    ListOfUnsuitablePlants=[]

IDList=[PropertiesList[i][0][3] for i in range(len(PropertiesList))]
IDList.extend(ListOfUnsuitablePlants) # list with all unsuitable plants and those that do already exsist

while len(PlantID)<NumPlantsSearch: # search for the number of NumPlantsSearch new plants 
    Source=driver.page_source
    Source=Source[Source.find("Leistung (kWp)</a></td>"):Source.find("ctl00_ContentPlaceHolder1__dataGridPagerDown_PagerTable")]

    while len(PlantID)<NumPlantsSearch and "javascript:OpenPlant('PublicPageOverview.aspx?plant=" in Source: # within the source code, each "javascript:OpenPlant..." command belongs to one plant
        Index=Source.find("javascript:OpenPlant('PublicPageOverview.aspx?plant=")+52 # the plant's the ID starts after the command
        ID=Source[Index:Source.find("splang=')")-5] # and ends before "splang="
        if ID not in IDList: # append found ID to PlantID if it is not in IDList
            PlantID.append(ID)
        Source=Source[Index+80:] # jump futher in source code
    
    NextPageButton=driver.find_elements_by_id("ctl00_ContentPlaceHolder1__dataGridPagerDown_ClickImgNext") # if there is no "javascript:OpenPlant..." anymore within the code, jump to the next page by clicking the button
    if len(NextPageButton)==0 or NextPageButton[0].is_enabled()==False: # in case the last page is reach end the search for new plants. in this case the arrow button is not clickable
        break
    else:
        NextPageButton[0].click() # but mostly it will be clickable
        
PlantBar = tqdm(total=len(PlantID), position=0) # a usual waitbar/progressbar

for ID in PlantID: # iterate through each found ID    
    PlantBar.update()

    if SuccessfulWritings>=NumPlants: # if NumPlants suitable plants were found, terminate this script
        break

    if ID not in IDList: # should always be true as it was checked before --> may be deleted but it does not harm

        driver.get(str("https://www.sunnyportal.de/Templates/PublicPageOverview.aspx?plant=" + ID + "&splang=")) # open the plant's webpage as their URLs have a static pattern
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
                PlantID=ID
                PlantLocation=driver.find_element_by_xpath("//*[contains(@id,'PlantProfileTableCellCityCountryValue')]").text # extract plant's location
            except:
                WriteListOfUnsuitablePlants(DataPath, ID, Dl) # if one of the information does not exist, add this plant to the ListOfUnsuitablePlants
                continue
            
            PlantPath=DataPath + Dl + PlantID

            if datetime.strptime(PlantStartDate, '%d.%m.%Y') <= DateStart: # only consider plant if the start date of operation is before DateStart

                Pages=driver.find_elements_by_xpath("//*[starts-with(@id, 'lmiPublicPage_')]") # find all subpages of the plant
                WritingSuccessful=False

                for n in range(len(Pages)): # search for a subpage that contains a diagram with PV generation data recorded in 15 minutes time steps and without other records (2 column criterion)

                    if SuccessfulWritings>NumPlants: # terminate this loop if number of needed plants is reached
                        break

                    if WritingSuccessful==True: # if a suitable subpage was found, terminate this loop and continue with the next plant
                        break

                    driver.switch_to.window(driver.window_handles[0]) # a safety command to ensure that the right window is active
                    Pages=driver.find_elements_by_xpath("//*[starts-with(@id, 'lmiPublicPage_')]") # repetition for saftey reasons. might be not needed anymore
                    Pages[n].click() # open the first subpage
                    
                    Tabs=driver.find_elements_by_class_name("tab") # if this subpage has tabs, open the tab labeld "Tag" to get daily values
                    if len(Tabs)>0:
                        for Tab in Tabs:
                            if Tab.text=='Tag':
                                Tab.click()
                                break

                    # start=time.time()

                    # the needed pv generation data of a plant can be accessed only via a second browser window. this window can only be opened by clicking a specific button.
                    # this button has the image of an "i" surrounded by a blue dot (like an information i). there might be multiple of this buttons on the subpage or just one.
                    # thos buttons will be called ImageButtons. mostly but not always, an ImageButton is hided behind another button that has the image of a gear.
                    # those buttons will be called OpenButtons. in order to open the generation data page, the ImageButton has to be clicked. in case of an existing OpenButton,
                    # the ImageButton is only clickable if the corresponding OpenButton was clicked before. after that it takes some milli seconds until the ImageButton can be
                    # clicked.

                    ImageButtons=driver.find_elements_by_xpath("//*[contains(@id, '_ImageButtonValues')]") # search for ImageButtons
                    OpenButtonsIndices=[x-1 for x in [m.start() for m in re.finditer('_OpenButtonsDivImg', driver.page_source)]] # in the source code search for OpenButtons. find the position (position in the string) in the source code and save them in OpenButtonsIndices
                    OpenButtons=[driver.page_source[OpenButtonsIndices[k]] for k in range(len(OpenButtonsIndices))] # form the indices get the enumeration number of the OpenButtons. the enumeration might start at 0 or 1 or does not exists in this case the index should be 'e'

                    for k in range (len(ImageButtons)): # iterate through the found ImageButtons

                        ImageButtonNumber=ImageButtons[k].get_attribute("id")[ImageButtons[k].get_attribute("id").rfind('_')-1] # Find the number of the ImageButton before last underscore of its ID. Corresponds with button number. Sometimes Buttons miss a number then ImageButtonNumber=='e' which is not a problem
                        
                        if ImageButtonNumber in OpenButtons: # if the ImageButton has a corresponding OpenButton, then the OpenBUtton has the the same number. in this case click the OpenBUtton first
                            try:
                                OpenButton=driver.find_element_by_xpath("//*[contains(@id, '" + ImageButtonNumber + '_OpenButtonsDivImg' + "')]") # find the corresponding OpenButton
                                WebDriverWait(driver, 1).until(EC.element_to_be_clickable((By.ID, OpenButton.get_attribute("id")))) # wait until the OpenButton is clickable. might be unnecessary as the OpenBUtton should be clickable immediatly after the page has loaded
                                OpenButton.click() # click the button
                            except:
                                pass
                        try:
                            WebDriverWait(driver, 1).until(EC.element_to_be_clickable((By.ID, ImageButtons[k].get_attribute("id")))) # after the OpenButton was clicked it takes some time until the ImageButton appears. wait for this moment
                        except:
                            try:
                                driver.find_element_by_xpath("//*[contains(@id, '" + ImageButtonNumber + '_OpenButtonsDivImg' + "')]").click() # if the ImageButton is still not clickable, retry clicking the OpenButton
                                WebDriverWait(driver, 1).until(EC.element_to_be_clickable((By.ID, ImageButtons[k].get_attribute("id"))))
                            except:
                                ImageButtons=driver.find_elements_by_xpath("//*[contains(@id, '_ImageButtonValues')]")
                        try:
                            ImageButtons=driver.find_elements_by_xpath("//*[contains(@id, '_ImageButtonValues')]") 
                            ImageButtons[k].click() # finally, click the ImageButton
                        except:
                            continue
                        
                        # start=time.time()
                        PageURL=driver.current_url
                        # print(time.time()-start)

                        driver.switch_to.window(driver.window_handles[1]) # after the ImageButton was clicked, a second window opens. switch to this window
                        [NumberHeaderCells, PlantTable]=ParseValueTable(driver.page_source, datetime.today().strftime("%d.%m.%Y")) # this window covers data in a table. parse this table
                        
                        if (len(PlantTable)>=96 and ("00:15" in PlantTable[0][0] or "00.15" in PlantTable[0][0])) and NumberHeaderCells==2: # check whether the table fulfils the conditions. only time intervals of 15 minutes and tables with one data column shall be considered
                            
                            Plant=[[PlantLocation, PlantStartDate, PlantPower, PlantID, PageURL, ImageButtonNumber, str(len(OpenButtons))], [datetime.strftime(DateStart, "%d.%m.%Y")]] # store all plant information i a variable
                            DateRange=CalcDateRange(DateStart, [], DateEnd) # evaluate for which dates data shall be downloaded for
                            MakeDirectories(DateRange, PlantPath, Dl) # create all directories that will be needed to store the data depending on DateRange
                            WriteProperties(PlantPath, Plant, Dl) # create the properties file
                            [Error, TSComplete]=CrawlData(DateRange, PlantPath, Dl, driver) # scrape the data from the website by iterating through DateRange and store the data in seperate csv files
                            if TSComplete==True and Error==False: # if no error occured during the scraping
                                WriteProperties(PlantPath, Plant, Dl) # update the properties
                                SuccessfulWritings=SuccessfulWritings+1
                                WritingSuccessful=True
                                break
                            else:
                                print("Plant " + Plant[0][3] + " deleted.")
                                WriteListOfUnsuitablePlants(DataPath, ID, Dl) # else add plant to the ListOfUnsuitablePlants
                                shutil.rmtree(PlantPath) # delete the directories

                        else:
                            Error=True
                            # if len(Values)>23:
                            #     print(Values[HeaderCells].text[0:5])

                        driver.close() # close the browser window with the recorded generation data
                        driver.switch_to.window(driver.window_handles[0]) # switch back to the other browser window

                if WritingSuccessful==False:
                    WriteListOfUnsuitablePlants(DataPath, ID, Dl)    

            else:
                WriteListOfUnsuitablePlants(DataPath, ID, Dl)

        except AssertionError as error:
            print(error)    

PlantBar.update()
driver.quit()
print("Done within: " + str(time.time()-StartSys))