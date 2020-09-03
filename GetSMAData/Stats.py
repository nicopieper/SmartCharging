from os import listdir
from os.path import isfile, join, isdir, exists
from tqdm import *
from DataFunctions import *
import shutil

Dl='/'
DataPath=r"C:/Users/nicop/SMAPlantData"
DataPathBackups=r"C:/Users/nicop/MATLAB/Masterarbeit/Predictions/SMAData/Sicherung"
DateStart=datetime(2018,1,1)
DateEnd=datetime(2020,5,31)
DateRange=[DateStart]
while DateRange[-1]<DateEnd:
        DateRange.append(DateRange[-1]+timedelta(days=1))


# Number of folders with completed data sets

Folders=listdir(DataPath)

CompletePlants=0
Plants=0
NumMissingDates=0

for Plant in tqdm(Folders):
    if not isfile(DataPath + Dl + Plant):
        PlantFolders=listdir(DataPath + Dl + Plant)[:-1]
        PlantFiles=[]
        for PlantFolder in PlantFolders:
            if PlantFolder[-4:]!='.mat':
                PlantSubFolders=listdir(DataPath + Dl + Plant + Dl + PlantFolder)
                for PlantSubFolder in PlantSubFolders:
                        Files = [f[-14:-4] for f in listdir(DataPath + Dl + Plant + Dl + PlantFolder + Dl + PlantSubFolder) if isfile(join(DataPath + Dl + Plant + Dl + PlantFolder + Dl + PlantSubFolder, f))]
                        PlantFiles.extend(Files)
        if isfile(DataPath + Dl + Plant + Dl + 'PlantProperties.csv'):
            [Properties, ExistingDates]=GetProperties(DataPath + Dl + Plant + Dl)
            MissingDates=CalcDateRange(DateStart, ExistingDates, DateEnd)
            NumMissingDates=NumMissingDates+len(MissingDates)
            if len(MissingDates)==0:
                CompletePlants=CompletePlants+1
            Plants=Plants+1

print("Plants: " + str(Plants))
print("Complete Plants: " + str(CompletePlants))
print("Share of complete Plants: " + str(CompletePlants/Plants*100))
print("Share of complete Data: " + str(100- 100*NumMissingDates/(Plants*len(DateRange))))

# OldFolders=listdir(DataPathBackups)

# CopyFolders=list(set(OldFolders).difference(Folders))
# Counter=0

# for CopyFolder in OldFolders:
#     if CopyFolder not in Folders:
#         shutil.copytree(DataPathBackups + Dl + CopyFolder, DataPath + Dl + CopyFolder)
#         Counter=Counter+1

# print(Counter)


# DeletedPlantsList=[]
# ListOfUnsuitablePlants=ReadListOfUnsuitablePlants(DataPath, Dl)
# print(len(ListOfUnsuitablePlants))

# f = open("C:/Users/nicop/Desktop/GetSMAData/DeletedFolders.txt", "r")
# ItemList=f.read().split(' ')
# for n in range(len(ItemList)):
#     if len(ItemList[n])==len("9f046f84-b2d8-4112-ac1b-198f349f161b") and ItemList[n-1]=='plant' and ItemList[n-2]=='with' and ItemList[n-3]=='occured':
#         DeletedPlantsList.append(ItemList[n])

# print(len(DeletedPlantsList))

# SourcePath=r"C:/Users/nicop/MATLAB/Masterarbeit/Predictions/SMAData/Sicherung/"
# for Plant in DeletedPlantsList:
#     try:
#         if not exists(DataPath + Dl + Plant):
#             shutil.copytree(SourcePath + Plant, DataPath + Dl + Plant)
#         if Plant in ListOfUnsuitablePlants:
#             ListOfUnsuitablePlants.remove(Plant)
#     except:
#         pass

# print(len(ListOfUnsuitablePlants))


# with open(DataPath + Dl + 'ListOfUnsuitablePlants.csv', 'w', newline='') as csvfile:                          
#     csvwriter = csv.writer(csvfile)                                                
#     csvwriter.writerow(ListOfUnsuitablePlants)