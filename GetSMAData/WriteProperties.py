from os import listdir
from os.path import isfile, join, isdir
import csv
from DataFunctions import *
import sys
from tqdm import *

Dl='/'
DataPath=r"C:/Users/nicop/SMAPlantData"

Folders=listdir(DataPath)

for Plant in tqdm(Folders):
    PlantFolders=listdir(DataPath + Dl + Plant)[:-1]
    PlantFiles=[]
    for PlantFolder in PlantFolders:
        PlantSubFolders=listdir(DataPath + Dl + Plant + Dl + PlantFolder)
        for PlantSubFolder in PlantSubFolders:
            Files = [f[-14:-4] for f in listdir(DataPath + Dl + Plant + Dl + PlantFolder + Dl + PlantSubFolder) if isfile(join(DataPath + Dl + Plant + Dl + PlantFolder + Dl + PlantSubFolder, f))]
            PlantFiles.extend(Files)
    if isfile(DataPath + Dl + Plant + Dl + 'PlantProperties.csv'):
        Properties=GetProperties(DataPath + Dl + Plant + Dl)[0]
        with open(DataPath + Dl + Plant + Dl + 'PlantProperties.csv', 'w', newline='') as csvfile:                          
            csvwriter = csv.writer(csvfile)
            csvwriter.writerow([Properties[0] + ";" + Properties[1] + ";" + Properties[2] + ";" + Properties[3] + ";" + Properties[4] + ";" + Properties[5] + ";" + Properties[6]])
            csvwriter.writerow(PlantFiles)