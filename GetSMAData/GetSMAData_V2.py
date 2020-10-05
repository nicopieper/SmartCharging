from selenium import webdriver
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
from selenium.webdriver.common.by import By
from selenium.common.exceptions import TimeoutException
from DataFunctions import *
from tqdm import *

StartSys=time.time()

DateStart=datetime(2018,1,1)
DateEnd=datetime(2018,1,1)
MinPower="3,0"
MaxPower="3,49"
NumPlants=1
NumPlantsSearch=50

Dl='/'
DataPath=r"C:/Users/nicop/SMAPlantData"
DriverPath= "C:\Program Files (x86)\chromedriver.exe"
option = webdriver.ChromeOptions()
chrome_prefs = {}
option.experimental_options["prefs"] = chrome_prefs
chrome_prefs["profile.default_content_settings"] = {"images": 2}
chrome_prefs["profile.managed_default_content_settings"] = {"images": 2}
# driver=webdriver.Chrome(DriverPath, chrome_options=option)
driver=webdriver.Chrome(DriverPath)
driver.get("https://www.sunnyportal.de/Templates/PublicPagesPlantList.aspx")

driver.find_element_by_id("ctl00_ContentPlaceHolder1_CountryDropDownList").send_keys("Deutschland")
driver.find_element_by_id("ctl00_ContentPlaceHolder1_FromPeakPowerNumTB_numTB").send_keys(MinPower)
driver.find_element_by_id("ctl00_ContentPlaceHolder1_ToPeakPowerNumTB_numTB").send_keys(MaxPower)
# driver.find_element_by_id("ctl00_ContentPlaceHolder1_CityFilterTextBox").send_keys("Mannebach")
driver.find_element_by_id("ctl00_ContentPlaceHolder1_FilterButton").click()

PlantID=[]
SuccessfulWritings=0

PropertiesList=GetPropertiesList(DataPath, Dl)
ListOfUnsuitablePlants=ReadListOfUnsuitablePlants(DataPath, Dl)
IDList=[PropertiesList[i][0][3] for i in range(len(PropertiesList))]
IDList.extend(ListOfUnsuitablePlants)

while len(PlantID)<NumPlantsSearch:
    Source=driver.page_source
    Source=Source[Source.find("Leistung (kWp)</a></td>"):Source.find("ctl00_ContentPlaceHolder1__dataGridPagerDown_PagerTable")]

    while len(PlantID)<NumPlantsSearch and "javascript:OpenPlant('PublicPageOverview.aspx?plant=" in Source:
        Index=Source.find("javascript:OpenPlant('PublicPageOverview.aspx?plant=")+52
        ID=Source[Index:Source.find("splang=')")-5]
        if ID not in IDList:
            PlantID.append(ID)
        Source=Source[Index+80:]
    
    NextPageButton=driver.find_element_by_id("ctl00_ContentPlaceHolder1__dataGridPagerDown_ClickImgNext")
    if NextPageButton.is_enabled()==False:
        break
    else:
        NextPageButton.click()
        
PlantBar = tqdm(total=len(PlantID)+1, position=0)
PlantCounter=0

for ID in PlantID:
    PlantCounter=PlantCounter+1
    PlantBar.update(PlantCounter)

    if SuccessfulWritings>=NumPlants:
        break

    if ID not in IDList:

        driver.get(str("https://www.sunnyportal.de/Templates/PublicPageOverview.aspx?plant=" + ID + "&splang="))
        try:
            Anlagensteckbrief=driver.find_elements_by_xpath('//*[@title="Anlagensteckbrief"]')
            if len(Anlagensteckbrief)>0:
                Anlagensteckbrief[0].click()            
            else:
                print("No Anlagensteckbrief found")
                WriteListOfUnsuitablePlants(DataPath, ID, Dl)
                continue

            try:
                PlantStartDate=driver.find_element_by_xpath("//*[contains(@id,'PlantProfileTableCellStartValue')]").text
                PlantPower=driver.find_element_by_xpath("//*[contains(@id,'PlantProfileTableCellPowerValue')]").text
                PlantID=driver.current_url[driver.current_url.find("plant=")+6:driver.current_url.find("splang")-1]
                PlantDataStartDate=max(datetime.strptime(PlantStartDate, '%d.%m.%Y'), DateStart)
                PlantLocation=driver.find_element_by_xpath("//*[contains(@id,'PlantProfileTableCellCityCountryValue')]").text
            except:
                WriteListOfUnsuitablePlants(DataPath, ID, Dl)
                continue
            
            PlantPath=DataPath + Dl + PlantID

            if datetime.strptime(PlantStartDate, '%d.%m.%Y') <= DateStart:

                Pages=driver.find_elements_by_xpath("//*[starts-with(@id, 'lmiPublicPage_')]")
                WritingSuccessful=False

                for n in range(len(Pages)):

                    if SuccessfulWritings>NumPlants:
                        break

                    if WritingSuccessful==True:
                        break

                    driver.switch_to.window(driver.window_handles[0])
                    Pages=driver.find_elements_by_xpath("//*[starts-with(@id, 'lmiPublicPage_')]")
                    Pages[n].click()
                    
                    Tabs=driver.find_elements_by_class_name("tab")
                    if len(Tabs)>0:
                        for Tab in Tabs:
                            if Tab.text=='Tag':
                                Tab.click()
                                break                

                    # start=time.time()
                    ImageButtons=driver.find_elements_by_xpath("//*[contains(@id, '_ImageButtonValues')]")
                    OpenButtonsIndices=[x-1 for x in [m.start() for m in re.finditer('_OpenButtonsDivImg', driver.page_source)]]
                    OpenButtons=[driver.page_source[OpenButtonsIndices[k]] for k in range(len(OpenButtonsIndices))]

                    for k in range (len(ImageButtons)):   
                        ImageButtonNumber=ImageButtons[k].get_attribute("id")[ImageButtons[k].get_attribute("id").rfind('_')-1] # Find vhar before last underscore. Corresponds with button number. Sometimes Buttons miss a number then ImageButtonNumber=='e' which is not a problem
                        # print(ImageButtons[k].get_attribute("id") + ": " + ImageButtonNumber)
                        if ImageButtonNumber in OpenButtons:                        
                            try:
                                OpenButton=driver.find_element_by_xpath("//*[contains(@id, '" + ImageButtonNumber + '_OpenButtonsDivImg' + "')]")
                                WebDriverWait(driver, 1).until(EC.element_to_be_clickable((By.ID, OpenButton.get_attribute("id"))))
                                OpenButton.click()
                            except:
                                pass
                        try:
                            WebDriverWait(driver, 1).until(EC.element_to_be_clickable((By.ID, ImageButtons[k].get_attribute("id"))))
                        except:
                            try:
                                driver.find_element_by_xpath("//*[contains(@id, '" + ImageButtonNumber + '_OpenButtonsDivImg' + "')]").click()
                                WebDriverWait(driver, 1).until(EC.element_to_be_clickable((By.ID, ImageButtons[k].get_attribute("id"))))
                            except:
                                ImageButtons=driver.find_elements_by_xpath("//*[contains(@id, '_ImageButtonValues')]")
                        try:
                            ImageButtons=driver.find_elements_by_xpath("//*[contains(@id, '_ImageButtonValues')]")
                            ImageButtons[k].click()
                        except:
                            continue
                        
                        # start=time.time()
                        PageURL=driver.current_url
                        # print(time.time()-start)

                        driver.switch_to.window(driver.window_handles[1])
                        [NumberHeaderCells, PlantTable]=ParseValueTable(driver.page_source, datetime.today().strftime("%d.%m.%Y"))
                        
                        if (len(PlantTable)>=96 and ("00:15" in PlantTable[0][0] or "00.15" in PlantTable[0][0])) and NumberHeaderCells==2:
                            
                            Plant=[[PlantLocation, PlantStartDate, PlantPower, PlantID, PageURL, ImageButtonNumber, str(len(OpenButtons))], [datetime.strftime(DateStart, "%d.%m.%Y")]]
                            DateRange=CalcDateRange(DateStart, [], DateEnd)
                            MakeDirectories(DateRange, PlantPath, Dl)
                            [Error, TSComplete]=CrawlData(DateRange, PlantPath, Dl, driver)
                            if TSComplete==True and Error==False:
                                WriteProperties(PlantPath, Plant, Dl)
                                SuccessfulWritings=SuccessfulWritings+1
                                WritingSuccessful=True
                                break
                            else:
                                print("Plant " + Plant[0][3] + " deleted.")
                                WriteListOfUnsuitablePlants(DataPath, ID, Dl)
                                shutil.rmtree(PlantPath)

                        else:
                            Error=True
                            # if len(Values)>23:
                            #     print(Values[HeaderCells].text[0:5])

                        driver.close()
                        driver.switch_to.window(driver.window_handles[0])

                if WritingSuccessful==False:
                    WriteListOfUnsuitablePlants(DataPath, ID, Dl)    

            else:
                WriteListOfUnsuitablePlants(DataPath, ID, Dl)

        except AssertionError as error:
            print(error)    

PlantBar.update(len(PlantID)+1)
driver.quit()
print("Done within: " + str(time.time()-StartSys))