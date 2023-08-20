
-- viewing the dataset

select *
from PortfolioProject#1..[covid-deaths]
order by 3,4

select *
from PortfolioProject#1..[covid-vaccination]
order by 3,4

-- testing

select location, date, population, total_cases, new_cases, total_deaths
from PortfolioProject#1..[covid-deaths]
order by location, date -- or 1,2

-- total cases vs. total deaths, from it we can develop the death percentage
-- shows the likelihood of dying if you're infected by covid 

select location, date, total_cases, total_deaths, round((cast(total_deaths as float)/cast(total_cases as float))*100, 2) as death_percentage -- problems with decimal places
from PortfolioProject#1..[covid-deaths]
where continent is not null
order by 1,2

-- total case vs total population
-- Show the percentage of population that is infected

select location, date, population, total_cases, round((cast(total_cases as float)/cast(population as float))*100, 2) as infected_population
from PortfolioProject#1..[covid-deaths]
where continent is not null
order by 1,2

-- countries with highest infection rate compared to population

select location, population, max(cast(total_cases as float)) as highest_amount_infected, round(max((total_cases/population))*100, 2) as highest_infected_percentage
from PortfolioProject#1..[covid-deaths]
where continent is not null
group by location, population
order by highest_amount_infected desc

-- let's see in each continent ^^^

select location, population, max(cast(total_cases as float)) as highest_amount_infected, round(max((total_cases/population))*100, 2) as highest_infected_percentage
from PortfolioProject#1..[covid-deaths]
where continent is null and location != 'High income' and location != 'Upper middle income' and location != 'Lower middle income' and location != 'Low income' and location != 'European Union'
group by location, population
order by highest_amount_infected desc

-- countries with highest death count per population

select location, population, max(cast(total_deaths as float)) as highest_amount_death, round(max((total_deaths/population))*100, 2) as highest_death_percentage
from PortfolioProject#1..[covid-deaths]
where continent is not null
group by location, population
order by highest_amount_death desc

-- Let's see in each continent ^^^

select location, population, max(cast(total_deaths as float)) as highest_amount_death, round(max((total_deaths/population))*100, 2) as highest_death_percentage
from PortfolioProject#1..[covid-deaths]
where continent is null and location != 'High income' and location != 'Upper middle income' and location != 'Lower middle income' and location != 'Low income' and location != 'European Union'
group by location, population
order by highest_amount_death desc

-- Let's see in each continent with date ^^^

select location, population, date, max(cast(total_deaths as float)) as highest_amount_death, round(max((total_deaths/population))*100, 2) as highest_death_percentage
from PortfolioProject#1..[covid-deaths]
where continent is null and location != 'High income' and location != 'Upper middle income' and location != 'Lower middle income' and location != 'Low income' and location != 'European Union'
group by location, population, date
order by highest_amount_death desc

-- highest new cases and new deaths per day

select date, sum(new_cases) as total_new_cases, sum(cast(new_deaths as bigint)) as total_new_deaths, round(coalesce((sum(cast(new_deaths as bigint))/nullif(sum(new_cases), 0)), 0)*100, 2) as total_death_percentage
from PortfolioProject#1..[covid-deaths]
where continent is not null and new_cases is not null and new_deaths is not null
group by date
order by 1

-- Total COVID-19 Deaths by Continent and Date, CURRENTLY TESTING THIS PART

select location, date, max(cast(total_deaths as float)) as highest_amount_death--, round(max((total_deaths/population))*100, 2) as highest_death_percentage
from PortfolioProject#1..[covid-deaths]
where continent is null and location != 'High income' and location != 'Upper middle income' and location != 'Lower middle income' and location != 'Low income' and location != 'European Union'
group by location, date
order by highest_amount_death desc

-- switching to covid vaccinations, where we will be looking at total population vs. vaccination

select d.continent, d.location, d.date, d.population, v.new_vaccinations, sum(cast(v.new_vaccinations as bigint)) over(partition by d.location order by d.location, d.date) as rolling_people_vaccinated
from PortfolioProject#1..[covid-deaths] d join PortfolioProject#1..[covid-vaccination] v on d.location = v.location and d.date = v.date
where d.continent is not null
order by 2,3

-- CTE 

with PopvsVac (Continent, Location, Date, Population, New_Vaccinations, rolling_people_vaccinated) as (
	select d.continent, d.location, d.date, d.population, v.new_vaccinations, sum(cast(v.new_vaccinations as bigint)) over(partition by d.location order by d.location, d.date) as rolling_people_vaccinated
	from PortfolioProject#1..[covid-deaths] d join PortfolioProject#1..[covid-vaccination] v on d.location = v.location and d.date = v.date
	where d.continent is not null
	--order by 2,3
) 
select *, round((rolling_people_vaccinated/Population)*100, 2) as people_vaccinated_percentage
from PopVsVac
order by Location, Date

-- temp table ^^^

drop table if exists #PercentPopulationVaccinated
create table #PercentPopulationVaccinated(
	Continent nvarchar(255),
	Location nvarchar(255),
	Date datetime,
	Population numeric,
	New_vaccinations numeric,
	rolling_people_vaccinated numeric
)

insert into #PercentPopulationVaccinated
	select d.continent, d.location, d.date, d.population, v.new_vaccinations, sum(cast(v.new_vaccinations as bigint)) over(partition by d.location order by d.location, d.date) as rolling_people_vaccinated
	from PortfolioProject#1..[covid-deaths] d join PortfolioProject#1..[covid-vaccination] v on d.location = v.location and d.date = v.date
	where d.continent is not null
	--order by 2,3

select *, round((rolling_people_vaccinated/Population)*100, 2) as people_vaccinated_percentage
from #PercentPopulationVaccinated
order by Location, Date

---- Queries for Visualization !!!

-- Total cases, total deaths, death percentage in one row

select max(cast(total_cases as bigint)) as total_cases, max(cast(total_deaths as float)) as highest_amount_death, round(max(cast(total_deaths as float))/max(cast(total_cases as bigint))*100, 2) as highest_death_percentage
from PortfolioProject#1..[covid-deaths]
where continent is null and location = 'World'

-- Getting the mortality rates for each continent
-- Higher death percentages might indicate challenges in healthcare capacity or testing availability.

select location, sum(new_cases) as total_case, sum(cast(new_deaths as bigint)) as total_deaths, round((sum(new_deaths)/sum(new_cases))*100, 2) as total_death_percentage
from PortfolioProject#1..[covid-deaths]
where continent is null and location != 'High income' and location != 'Upper middle income' and location != 'Lower middle income' and location != 'Low income' and location != 'European Union'
group by location
order by total_deaths desc

-- Proportion of population infected by COVID-19 in each country 
-- A lower proportion of infected population in some countries might indicate effective containment measures such as lockdowns, travel restrictions, and strict hygiene protocols.

select location, population, max(cast(total_cases as float)) as highest_amount_infected, round(max((total_cases/population))*100, 2) as highest_infected_percentage
from PortfolioProject#1..[covid-deaths]
where continent is not null
group by location, population
order by highest_amount_infected desc

-- Total confirmed COVID-19 deaths by geographic regions

select location, population, date, max(cast(total_deaths as float)) as highest_amount_death, round(max((total_deaths/population))*100, 2) as highest_death_percentage
from PortfolioProject#1..[covid-deaths]
where continent is null and location != 'High income' and location != 'Upper middle income' and location != 'Lower middle income' and location != 'Low income' and location != 'European Union'
group by location, population, date
order by highest_amount_death desc

-- Daily death count

select date, sum(cast(new_deaths as bigint)) as total_deaths
from PortfolioProject#1..[covid-deaths]
where continent is not null and location != 'China'
group by date
order by 1