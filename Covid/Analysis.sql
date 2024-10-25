-- looking at what the data for each table looks like
select * from PortfolioProject..CovidDeaths
where continent is not null
Order by 3,4

select * from PortfolioProject..CovidVaccinations
Order by 3,4

-- seeing how many new cases + deaths each day in Canada
Select Location, date, total_cases, new_cases, total_deaths, population
From PortfolioProject..CovidDeaths
Where location = 'Canada'
Order by 1,2

-- Looking at Total Cases vs Total Deaths
-- Shows likelihood of dying if you contract covid in your country

Select Location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as DeathPercentage
From PortfolioProject..CovidDeaths
-- Where location like '%states%' if you wanted to see just USA
Order by 1,2

-- Looking at Total Cases vs Population
-- Shows what percentage of population got covid per day
Select Location, date, population, total_cases,(total_cases/population)*100 as PercentPopulationInfected
From PortfolioProject..CovidDeaths
--Where location like '%states%' if you wanted to see just USA
Order by 1,2


-- Looking at countries with Highest Infection Rate compared to Population.. Poor Andorra

Select Location, population, MAX(total_cases) as HighestInfectionCount, max((total_cases/population))*100 as PercentPopulationInfected
From PortfolioProject..CovidDeaths
Group by Location, Population
Order by PercentPopulationInfected desc


-- LETS	BREAK THINGS DOWN BY CONTINENT


-- Showing Countries with Highest Death Count
Select location, MAX(cast(Total_Deaths as bigint)) as TotalDeathCount
From PortfolioProject..CovidDeaths
Where continent is not null
Group by location
Order by TotalDeathCount desc

-- Showing the continents with highest death count
Select continent, MAX(cast(Total_Deaths as bigint)) as TotalDeathCount
From PortfolioProject..CovidDeaths
Where continent is not null
Group by continent
Order by TotalDeathCount desc

-- GLOBAL DEATH PERCENTAGE BY DAY
Select date, sum(new_cases) as total_cases, SUM(cast(new_deaths as int)) as total_deaths, SUM(cast(new_deaths as int))/sum(new_cases)*100 as DeathPercentage
From PortfolioProject..CovidDeaths
where continent is not null
Group by date
Order by 1,2

-- GLOBAL DEATH PERCENTAGE
Select sum(new_cases) as total_cases, SUM(cast(new_deaths as int)) as total_deaths, SUM(cast(new_deaths as int))/sum(new_cases)*100 as DeathPercentage
From PortfolioProject..CovidDeaths
where continent is not null
Order by 1,2


-- Looking at total population vs Vaccinations with CTE + Join

Select *
From PortfolioProject..CovidDeaths dea
Join  PortfolioProject..CovidVaccinations vac
	on dea.location = vac.location AND
	dea.date = vac.date;


With PopvsVac (Continent, Location, Date, Population, New_Vaccinations, RollingPeopleVaccinated)
as 
(
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CAST(vac.new_vaccinations as int)) OVER (Partition by dea.location Order by dea.location, dea.date) as RollingPeopleVaccinated
From PortfolioProject..CovidDeaths dea
Join  PortfolioProject..CovidVaccinations vac
	on dea.location = vac.location AND
	dea.date = vac.date
	where dea.continent is not null
	-- order by 2,3
	)

select *, (RollingPeopleVaccinated/Population) * 100
from PopvsVac

-- Temp Table

Drop table if exists #PercentPopulationVaccinated
Create table #PercentPopulationVaccinated
	(
	Continent nvarchar(255),
	Location nvarchar(255),
	Date datetime,
	Population numeric,
	New_vaccinations numeric,
	RollingPeopleVaccinated numeric, 
	) 
	insert into #PercentPopulationVaccinated
	Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CAST(vac.new_vaccinations as int)) OVER (Partition by dea.location Order by dea.location, dea.date) as RollingPeopleVaccinated
From PortfolioProject..CovidDeaths dea
Join  PortfolioProject..CovidVaccinations vac
	on dea.location = vac.location AND
	dea.date = vac.date
	where dea.continent is not null
	-- order by 2,3

-- Creating view to store data for later visualizations
Create View PercentPopulationVaccinated as
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CAST(vac.new_vaccinations as int)) OVER (Partition by dea.location Order by dea.location, dea.date) as RollingPeopleVaccinated
From PortfolioProject..CovidDeaths dea
Join  PortfolioProject..CovidVaccinations vac
	on dea.location = vac.location AND
	dea.date = vac.date
	where dea.continent is not null
	-- order by 2,3

Select *
From PercentPopulationVaccinated

-- seeing who got the vaccines first. this felt awesome when it ran correctly. great data to have!

create table #vaccine_recipient_table (
Location nvarchar(255),
Date datetime)

insert into #vaccine_recipient_table
select location, date from PortfolioProject..CovidVaccinations
where continent is not null and new_vaccinations is not null and new_vaccinations !=0
; 

with Vaccine_Order_Final as (
select location, date,
ROW_NUMBER () over (Partition by  location order by Date) as Vaccination_Order
from #vaccine_recipient_table
)

select * from vaccine_order_final
where vaccination_order = 1
order by date asc



-- drop table #vaccine_recipient_table if you need it









