
----------Total number of attacks per year, month-------------
SELECT 
	   Year_event, 
	   Month_event, 
	   COUNT(Event_ID) AS Attacks
FROM dbo.Events
GROUP BY Year_event, Month_event
ORDER BY Year_event, Month_event;

----------Total number of attacks per Country, Region----------
WITH AttacksCR (Region, Country, AttacksPerCountry, AttacksPerRegion)
as
(
SELECT  
	   R.Region_name,
	   C.Country_name,
	   COUNT(Event_ID) OVER (partition by Region_name, Country_name) AS AttacksPerCountry,
	   COUNT(Event_ID) OVER (partition by Region_name) AS AttacksPerRegion
FROM dbo.Events E
     JOIN dbo.Country C ON C.Country_ID = E.Country_ID
     JOIN dbo.Region R ON R.Region_ID=C.Region_ID
)

SELECT *, CONCAT(ROUND(CAST(AttacksPerCountry AS float)/CAST(AttacksPerRegion AS float)*100,3),'%') AS '% of Region attacks'
FROM AttacksCR 


----------Detailed analysis of attacks: characteristics of attacks----------
SELECT 
	  C.Country_name,
	  COUNT(Event_ID) AS 'Total number of attacks',
	  SUM(
		  CASE WHEN Extended = 1 THEN 1
		                         ELSE 0
		  END) AS 'Number of attacks >24h',
      SUM(
		  CASE WHEN PERS_crit = 1 THEN 1
		                          ELSE 0
		  END) AS 'Number of attacks due to political, economical, social, religious reasons',
	  SUM(
		  CASE WHEN Doubt = 0 THEN 1
		                      ELSE 0
		  END) AS 'Number of terroristic acts',
	  SUM(
		  CASE WHEN Multiple = 0 THEN 1
		                         ELSE 0
	      END) AS 'Number of single attacks',
	  SUM(
		  CASE WHEN Multiple = 1 THEN 1
		                         ELSE 0
	      END) AS 'Number of multiple attacks',
	  SUM(
		  CASE WHEN Success = 1 THEN 1
		                        ELSE 0
	      END) AS 'Number of successful attacks',
	  SUM(
		  CASE WHEN Suicide = 1 THEN 1
		                        ELSE 0
	      END) AS 'Number of suicide attacks',
	  SUM(
		  CASE WHEN Suspected = 1 THEN 1
		                          ELSE 0
	      END) AS 'Number attacks which could be prevented'
FROM dbo.Events E
     JOIN dbo.Country C ON C.Country_ID = E.Country_ID
GROUP BY C.Country_name
ORDER BY [Total number of attacks] desc

----------Analysis of attacks by death during attacks by Region----------
SELECT 
	   R.Region_name,
	   SUM(E.TotalKill) AS PeopleKill,
	   SUM(E.AttackersKill) AS AttackersKill,
	   SUM(E.Injured) AS PeopleInjured,
	   SUM(E.AttackersInjured) AS AttackersInjured
FROM dbo.Events E
     JOIN dbo.Country C ON C.Country_ID = E.Country_ID
     JOIN dbo.Region R ON R.Region_ID=C.Region_ID
GROUP BY R.Region_name
ORDER By PeopleKill,PeopleInjured,AttackersKill,AttackersInjured

----------Analysis of attacks by death during attacks by Region, Country, Year----------
DROP table if exists #DeathInAttacks
CREATE table #DeathInAttacks
            (
			Year int,
			Region varchar(50),
			Country varchar(100),
			PeopleKill numeric,
			AttakersKill numeric,
			PeopleInjured numeric,
			AttackersInjured numeric
			);
INSERT INTO #DeathInAttacks
SELECT 
	   E.Year_event,
	   R.Region_name,
	   C.Country_name,
	   SUM(E.TotalKill) AS PeopleKill,
	   SUM(E.AttackersKill) AS AttackersKill,
	   SUM(E.Injured) AS PeopleInjured,
	   SUM(E.AttackersInjured) AS AttackersInjured
FROM dbo.Events E
     JOIN dbo.Country C ON C.Country_ID = E.Country_ID
     JOIN dbo.Region R ON R.Region_ID=C.Region_ID
GROUP BY C.Country_name, R.Region_name, E.Year_event

SELECT 
	  Year, 
	  Region, 
	  Country,
	  PeopleKill AS TotalPeopleKilled,
	  AttakersKill,
	   CASE 
		  WHEN PeopleKill = 0 THEN 0
		                      ELSE (ROUND((AttakersKill/PeopleKill),2))*100 
	   END AS '% of Attackers Kill',
	  PeopleKill - AttakersKill as CivilianKilled,
	   CASE 
		  WHEN PeopleKill = 0 THEN 0
		                      ELSE ROUND(((PeopleKill - AttakersKill)/PeopleKill)*100,2)
	   END AS '% of Civilian Kill',
	  PeopleInjured,
	  AttackersInjured,
	   CASE 
		  WHEN PeopleInjured = 0 THEN 0
		                      ELSE ROUND((AttackersInjured/PeopleInjured)*100,2)
	   END AS '% of Attackers Injured',
	  PeopleInjured - AttackersInjured as CivilianInjured,
	   CASE 
		  WHEN PeopleInjured = 0 THEN 0
		                      ELSE ROUND(((PeopleInjured - AttackersInjured)/PeopleInjured)*100,2) 
	   END AS '% of Civilian Injured'
FROM #DeathInAttacks 


----------Weapon analysis: most used----------
SELECT 
	  Weapon_name,
	  Weapon_cat_name,
	  COUNT(Event_ID) AS AttacksPerformed
FROM dbo.Events E
     JOIN dbo.Weapon_cat WC ON WC.Weapon_cat_ID=E.Weapon_cat_ID
	 JOIN dbo.Weapon W ON W.Weapo_ID=WC.Weapo_ID
WHERE WC.Weapon_cat_name not like 'None'
GROUP BY Weapon_name, Weapon_cat_name
ORDER BY AttacksPerformed DESC

----------Weapon analysis: most striking----------
SELECT 
	  Weapon_name,
	  Weapon_cat_name,
	  SUM(TotalKill) AS KilledPeople
FROM dbo.Events E
     JOIN dbo.Weapon_cat WC ON WC.Weapon_cat_ID=E.Weapon_cat_ID
	 JOIN dbo.Weapon W ON W.Weapo_ID=WC.Weapo_ID
WHERE WC.Weapon_cat_name not like 'None'
GROUP BY Weapon_name, Weapon_cat_name
ORDER BY KilledPeople DESC



---------- Analysis of organizators : 10 the most dangerous Groups----------
SELECT TOP (10) G.Group_name, 
                COUNT(Event_ID) AS NumberAttacks, 
				SUM(TotalKill-AttackersKill) AS CivilianKilled
FROM dbo.Events E
     LEFT JOIN dbo.Groups G ON G.Group_ID = E.Group_ID
WHERE Group_name not like '%Unknown%'
GROUP BY Group_name
ORDER BY CivilianKilled DESC,NumberAttacks


---------- Analysis of attacks : location and property damage----------
DROP table if exists #LocationProp
CREATE table #LocationProp
            (
			Year int,
			Country varchar(100),
			Attacks numeric,
			AttacksPropertyDam numeric,
			AttacksCity numeric,
			AttacksAdmRegion numeric,
			AttacksUnidenTer numeric,
			Damage varchar(30)
			);
INSERT INTO #LocationProp
SELECT
	  E.Year_event, 
	  C.Country_name,
	  COUNT(Event_ID) AS 'Total number of attacks',
      COUNT(E.PropertyDam) AS 'Number of attacks with property damage',
	  SUM(
	      CASE WHEN E.Specificity in (1,2) THEN 1
		                                   ELSE 0
          END) AS 'Attacks occurred in city/village/town',
	  SUM(
	      CASE WHEN E.Specificity in (3,4)   THEN 1
		                                     ELSE 0
          END) AS 'Attacks occurred in administrative region',
      SUM(
	      CASE WHEN E.Specificity = 5 THEN 1
		                              ELSE 0
          END) AS 'Attacks occurred on unidentified territory',
	 CASE WHEN
	         SUM(
	      CASE WHEN P.PropertyDM = 1 THEN 1
		                              ELSE 0 END) >=1 
		  THEN 'Catastropic damage'
		  ELSE 'Unknown'
	 END AS 'Damage'
FROM dbo.Events E
     JOIN dbo.Country C ON C.Country_ID=E.Country_ID
     LEFT JOIN dbo.Property P ON P.PropertyDM=E.PropertyDam
GROUP BY Year_event,Country_name
ORDER BY Year_event,Country_name

SELECT 
	  Year,
	  Country,
	  Attacks AS 'Total number of attacks',
	  AttacksPropertyDam AS 'Number of attacks with property damage',
	  (AttacksPropertyDam/Attacks)*100 AS '% property damage attacks from total attacks',
	  AttacksCity AS 'Attacks occurred in city/village/town',
	  (AttacksCity/Attacks)*100 AS '% city attacks from total attacks',
	  AttacksAdmRegion AS 'Attacks occurred in administrative region',
	  (AttacksAdmRegion/Attacks)*100 AS '% admin.region attacks from total attacks',
	  AttacksUnidenTer AS 'Attacks occurred on unidentified territory',
	  (AttacksUnidenTer/Attacks)*100 AS '% unidentified attacks from total attacks',
	  Damage
FROM #LocationProp
ORDER BY Year,Country

------Analysis of targets by year -----
SELECT 
	  Year_event,
	  T.Target_type,
	  COUNT(Event_ID) AS 'Attacks',
	  SUM(TotalKill) AS KilledPeople
FROM dbo.Events E
 JOIN dbo.[Target] T ON T.Target_ID=E.Target_ID
GROUP BY Year_event, Target_type


----Analysis of attack types: by country, year
SELECT 
	  Year_event,
	  Country_name,
	  A.Attack_type,
	  COUNT(Event_ID) AS 'Attacks',
	  SUM(TotalKill) AS KilledPeople,
	  IIF(SUM(Hostkid)>0,'Yes','No') AS 'The victims were taken hostage or kidnapped' 
FROM dbo.Events E
 JOIN dbo.Country C ON C.Country_ID=E.Country_ID
 JOIN dbo.Attacks A ON A.Attack_ID=E.Attack_ID
GROUP BY Year_event, Country_name, Attack_type
