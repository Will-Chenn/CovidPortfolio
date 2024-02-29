create table CovidVaccinations (iso_code VARCHAR(10),
						 		continent TEXT,
						 		location TEXT,
						 		date DATE,
						 		total_cases INT,
						 		new_cases INT,
								new_cases_smoothed FLOAT,
						 		total_deaths INT,
								new_deaths INT,
						 		new_deaths_smoothed FLOAT,
						 		total_cases_per_million FLOAT,
						 		new_cases_per_million FLOAT,
						 		new_cases_smoothed_per_million FLOAT,
						 		total_deaths_per_million FLOAT,
						 		new_deaths_per_million FLOAT,
						 		new_deaths_smoothed_per_million FLOAT,
						 		reproduction_rate FLOAT,
						 		icu_patients INT,
						 		icu_patients_per_million FLOAT,
						 		hosp_patients INT,
						 		hosp_patients_per_million FLOAT,
						 		weekly_icu_admissions INT,
						 		weekly_icu_admissions_per_million FLOAT,
						 		weekly_hosp_admissions INT,
						 		weekly_hosp_admissions_per_million FLOAT,
							    total_tests BIGINT,
								new_tests FLOAT,
								total_tests_per_thousand FLOAT,
								new_tests_per_thousand FLOAT,
								new_tests_smoothed FLOAT,
								new_tests_smoothed_per_thousand FLOAT,
								positive_rate FLOAT,
								tests_per_case FLOAT,
								tests_units TEXT,
								total_vaccinations BIGINT,
								people_vaccinated BIGINT,
								people_fully_vaccinated FLOAT, 
								total_boosters BIGINT,
								new_vaccinations INT,
								new_vaccinations_smoothed FLOAT,
								total_vaccinations_per_hundred FLOAT,
								people_vaccinated_per_hundred FLOAT,
								people_fully_vaccinated_per_hundred FLOAT,
								total_boosters_per_hundred FLOAT,
								new_vaccinations_smoothed_per_million FLOAT,
								stringency_index FLOAT,
								population_density FLOAT,
								median_age FLOAT,
								aged_65_older FLOAT, aged_70_older FLOAT, gdp_per_capita FLOAT, extreme_poverty FLOAT,
								cardiovasc_death_rate FLOAT, diabetes_prevalence FLOAT, female_smokers FLOAT, male_smokers FLOAT,
								handwashing_facilities FLOAT, hospital_beds_per_thousand FLOAT, life_expectancy FLOAT,
								human_development_index FLOAT, population BIGINT, excess_mortality_cumulative_absolute FLOAT,
								excess_mortality_cumulative FLOAT, excess_mortality FLOAT, excess_mortality_cumulative_per_million FLOAT
							    );

ALTER TABLE CovidVaccinations
ALTER COLUMN total_boosters TYPE BIGINT USING total_boosters::BIGINT;



COPY covidvaccinations FROM '/Users/willchen/Desktop/Projects/Youtube/DA Protfolio /CovidVaccinations.csv' WITH (FORMAT csv, HEADER true, NULL '');





create table CovidDeath (iso_code VARCHAR(10),
						 continent TEXT,
						 location TEXT,
						 date DATE,
						 total_cases BIGINT,
						 new_cases INT,
						 new_cases_smoothed FLOAT,
						 total_deaths INT,
						 new_deaths INT,
						 new_deaths_smoothed FLOAT,
						 population BIGINT,
						 total_cases_per_million FLOAT,
						 new_cases_per_million FLOAT,
						 new_cases_smoothed_per_million FLOAT,
						 total_deaths_per_million FLOAT,
						 new_deaths_per_million FLOAT,
						 new_deaths_smoothed_per_million FLOAT,
						 reproduction_rate FLOAT,
						 icu_patients INT,
						 icu_patients_per_million FLOAT,
						 hosp_patients INT,
						 hosp_patients_per_million FLOAT,
						 weekly_icu_admissions INT,
						 weekly_icu_admissions_per_million FLOAT,
						 weekly_hosp_admissions INT,
						 weekly_hosp_admissions_per_million FLOAT);


SELECT * FROM CovidDeath WHERE continent is not null LIMIT 10;				 


-- Select Data that we are going to be using
SELECT Location, date, total_cases, new_cases, total_deaths, population
FROM CovidDeath 
WHERE continent is not null
order by 1, 2;

-- Looking at Total Cases VS. Total Deaths
-- Shows likelihood of daying if you contract covid in your country
SELECT Location, date, total_cases, total_deaths, (total_deaths::DECIMAL/total_cases)*100 AS DeathPercentage
FROM CovidDeath 
Where location like '%Canada%' AND continent is not null
order by 1, 2;


-- Looking at Total Cases VS. Population
-- Shows what percentage of population got Covid
SELECT Location, date, total_cases, Population, (total_cases::DECIMAL/Population)*100 AS CovidPercentage
FROM CovidDeath 
-- Where location like '%Canada%'
WHERE continent is not null
order by 1, 2;


-- Looking at Countries with Highest Infection Rate compared to Population
SELECT Location, Population, MAX(total_cases) as HighestInfectionCount, 
MAX(total_cases::DECIMAL/Population)*100 AS PercentPopulationInfected
FROM CovidDeath 
-- Where location like '%Canada%'
WHERE continent is not null
GROUP BY Location, population
order by PercentPopulationInfected DESC;


-- Showing Countries with Highest Death Count per Population
SELECT Location,  MAX(cast(total_deaths as int)) as TotalDeathCount
FROM CovidDeath 
-- Where location like '%Canada%'
WHERE continent is not null
GROUP BY Location
order by TotalDeathCount DESC;


-- LET'S BREAK THINGS DOWN BY CONTINENT
-- Showing continents with the highest death count per population
SELECT continent, MAX(cast(total_deaths as int)) as TotalDeathCount
FROM CovidDeath 
-- Where location like '%Canada%'
WHERE continent is not null
GROUP BY continent
order by TotalDeathCount DESC;


-- GLOBAL NUMBERS
SELECT SUM(new_cases) AS total_cases, SUM(CAST(new_deaths as int)) as total_deaths,
SUM(CAST(new_deaths as int))/AVG(new_cases)*100 as DeathPercentage
FROM CovidDeath
WHERE continent is not null
order by 1,2;


-- Looking at Total Population VS. Vaccinations
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(CAST(vac.new_vaccinations as INT)) 
OVER 
(PARTITION by dea.location ORDER BY dea.location, dea.Date) as RollingPeopleVaccinated
FROM CovidDeath AS dea 
JOIN CovidVaccinations AS vac
ON dea.location = vac.location
AND dea.date = vac.date
WHERE dea.continent is not null -- and dea.location like '%Canada%'
order by 2,3


-- Use CTE
WITH PopvsVac (Continent, Location, Date, Population, new_vaccinations, RollingPeopleVaccinated)
AS
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(CAST(vac.new_vaccinations as INT)) 
OVER 
(PARTITION by dea.location ORDER BY dea.location, dea.Date) as RollingPeopleVaccinated
FROM CovidDeath AS dea 
JOIN CovidVaccinations AS vac
ON dea.location = vac.location
AND dea.date = vac.date
WHERE dea.continent is not null -- and dea.location like '%Canada%'
)
SELECT *, (RollingPeopleVaccinated::DECIMAL/Population)*100 as PplVaccinatedPercentage
FROM PopvsVac



-- TEMP TABLE
DROP TABLE PercentPopulationVaccinated;
CREATE TABLE PercentPopulationVaccinated
(
    Continent VARCHAR(255),
    Location VARCHAR(225),
    Date date,
    Population BIGINT,
    New_Vaccinations INT,
    RollingPeopleVaccinated BIGINT
);

INSERT INTO PercentPopulationVaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
    SUM(CAST(vac.new_vaccinations as INT)) OVER
    (PARTITION BY dea.location ORDER BY dea.location, dea.Date) as RollingPeopleVaccinated
FROM CovidDeath AS dea
JOIN CovidVaccinations AS vac
    ON dea.location = vac.location
    AND dea.date = vac.date;

SELECT *, (RollingPeopleVaccinated/Population)*100
FROM PercentPopulationVaccinated;



-- Creating View to store data for latter visualizations
DROP VIEW PercentPopulationVaccinated;
CREATE VIEW PercentPopulationVaccinated as
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
    SUM(CAST(vac.new_vaccinations as INT)) OVER
    (PARTITION BY dea.location ORDER BY dea.location, dea.Date) as RollingPeopleVaccinated
FROM CovidDeath AS dea
JOIN CovidVaccinations AS vac
    ON dea.location = vac.location
    AND dea.date = vac.date
WHERE dea.continent is not null;

SELECT * FROM PercentPopulationVaccinated LIMIT 10;




