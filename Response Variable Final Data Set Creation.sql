-------------------------------------------------------------------------------------------------
--Author: James Perry, Patrick Magnusson and Robert Steele                       Date: 07/22/2018	
--				
--                        Title: Summer MSDA Project Final Modeling Data Set 	
--

--Use: This file was generated to create the needed response variable for our project.
--	   We used the numerical address of the 1st road in the data to create a numerical response
--	   of the average accidents that occur at that specific numerical address each year. This
--     code also cleans up a lot of the formatting and reduces any columns that are duplicative 
--     after imputtation of the data.
--
--Calculation Notes:  The response variable was calculated by counting all accidents for every
--                    distinct X1st_Road_Number variable in the data set, by year. After we had
--                    the total of occurances per year, we averaged the yearly amounts by road
--                    number to come up with an average occurance throughout the dataset for 
--                    each road number. This will allow us to predict the frequency of accidents
--
--
--Formatting Notes:  The data has now been passed back and forth over multiple opperating system
--                   platforms and gone through many changes in R. Because of this, there were
--                   issues in stray characters being added and data reformatting that needed to 
--                   occur. Mainly, the formatting was correcting titles and removing " " that 
--                   somehow were placed into the file. 
--
--
--Joining Response Variable with Data:
--                                      Original File Rows: 1,780,653
--                                    Post Inner Join Rows: 1,780,653
-------------------------------------------------------------------------------------------------

--Creating the response variable
Select *
Into ResponseVariable
From (
		Select Distinct ["X1st_Road_Number"], AVG(Total_Accidents) over (Partition by ["X1st_Road_Number"]) as [Average_Accidents_Per_Year]
		From (
				Select Distinct ["X1st_Road_Number"],["year"], count(["Accident_Index"]) over (Partition by ["year"], ["X1st_Road_Number"]) as Total_Accidents
				FROM [SummerProject].[dbo].[ImputedAccident0515Data_FINAL]
		) as Main
    ) as a

--Creating the final file format to be used in modeling
Select *
Into FinalDataForModeling
From (
SELECT Distinct 
       Accident_Index = REPLACE(["Accident_Index"] , '"', '') 
      ,["Location_Easting_OSGR"] as Location_Easting_OSGR
      ,["Location_Northing_OSGR"] as Location_Northing_OSGR
      ,["Longitude"] as Longitude
      ,["Latitude"] as Latitude
      ,["Police_Force"] as Police_Force
      ,["Accident_Severity"] as Accident_Severity
      ,["Number_of_Vehicles"] as Number_of_Vehicles
      ,["Number_of_Casualties"] as Number_of_Casualties
      ,[Date] = REPLACE(["Date"], '"', '') 
      ,["Day_of_Week"] as Day_of_Week
      ,["Local_Authority_ District "] as Local_Authority_District
      ,Local_Authority_Highway = REPLACE(["Local_Authority_ Highway "] , '"', '') 
      ,["X1st_Road_Class"] as X1st_Road_Class
	  ,a.["X1st_Road_Number"] as X1st_Road_Number
      ,["Road_Type"] as Road_Type
      ,["Speed_limit"] as Speed_limit
      --,["Junction_Control"] as Junction_Control
      ,["X2nd_Road_Class"] as X2nd_Road_Class_Imputed
	  ,["X2nd_Road_Number"] as X2nd_Road_Number
      ,["Light_Conditions"] as Light_Conditions
      ,["Urban_or_Rural_Area"] as Urban_or_Rural_Area
      ,LSOA_of_Accident_Location = REPLACE(["LSOA_of_Accident_Location"] , '"', '') 
      ,["Junction_Detail"] as Junction_Detail
	  ,["Junction_Control_Imputed"] as Junction_Control_Imputed
      ,["Pedestrian_Crossing Human_Control"] as Pedestrian_Crossing_Human_Control
      ,["Pedestrian_Crossing Physical_Facilities"] as Pedestrian_Crossing_Physical_Facilities
      ,["Weather_Conditions"] as Weather_Conditions
      ,["Road_Surface_Conditions"] as Road_Surface_Conditions
      ,["Special_Conditions_at_Site"] as Special_Conditions_at_Site
      ,["Carriageway_Hazards"] as Carriageway_Hazards
      ,["Did_Police_Officer_Attend_Scene_of_Accident"] as Did_Police_Officer_Attend_Scene_of_Accident
      ,cast(["Time_of_Accident"] as Decimal(4,2)) as Time_of_Accident
      ,["year"] as [Year]
	  ,b.Average_Accidents_Per_Year 
  FROM [SummerProject].[dbo].[ImputedAccident0515Data_FINAL] as a
	Inner Join SummerProject.dbo.ResponseVariable as b on a.["X1st_Road_Number"] = b.["X1st_Road_Number"]
) as b




--Creating the binned predictors to help with model run time and aid model intuition 
Select Distinct
	 [Dummy_Column]					= '' 
	,USE_Accident_Severity			= Accident_Severity
	,USE_Number_of_Vehicles			= a.Number_of_Vehicles
	,USE_Number_of_Casualties		= a.Number_of_Casualties
	,USE_Road_Surface_Conditions	= Case When a.Road_Surface_Conditions in (2,3,4,5) Then 1 else 0 End	--Wet or damp/snow/frost or ice/flood over 3cm deep = 1 all others = 0 (only other choice in data is DRY)
	,USE_Road_Type					= Case When a.Road_Type in (2,3,6) Then 1 else 0 End					--One way street/Dual carriageway/single carriageway = 1 all others = 0
	,USE_Light_Conditions			= Case When a.Light_Conditions = 1 Then 1 else 0 End					--Daytime is 1, all situations of dark = 0
	,USE_Urban_or_Rural_Area		= Case When a.Urban_or_Rural_Area = 1 Then 1 else 0 End					--Urban = 1 Rural = 0
	,USE_Speed_limit				= Case When a.Speed_limit = 30 Then 1 else 0 End						--30MPH = 1 all others is 0
	,USE_Day_of_Week				= Case When a.Day_of_Week in (6,7) Then 1 else 0 End					--Friday/Saturday = 1 all others = 0
	,USE_Average_Accidents_Per_Year = a.Average_Accidents_Per_Year											
	,a.* 
from FinalDataForModeling as a
