-- Looking total cases vs total deaths
-- Shows likelihood of dying if you contract covid in your country
select
	location
	, date
	, total_cases
	, total_deaths
	, round(((total_deaths*1.0) / (total_cases*1.0))*100, 2) as death_percentage
from covid_data
where 
	total_deaths is not null 
	and location = 'Brazil' 
	and continent is not null
order by 1, 2

-- Looking at total cases vs population
-- Shows what percentage of population got Covid
select
	location
	, date
	, total_cases
	, population
	, round(((total_cases*1.0) / (population*1.0))*100, 4) as cases_percentage
from covid_data
where 
	total_deaths is not null 
	and location = 'Brazil' 
	and continent is not null
order by 1, 2

-- Looking at countries with highest infection rate comparted to population
select
	location
	, population
	, max(total_cases) as highest_infection
	, max(round(((total_cases*1.0) / (population*1.0))*100, 2)) as max_percentage
from covid_data
where 
	total_deaths is not null 
	and population is not null 
	and continent is not null
group by location, population
order by max_percentage desc

-- Looking at countries with highest death count by population
select
	location
	, max(total_deaths) as highest_deaths
from covid_data
where 
	total_deaths is not null 
	and continent is not null
group by location
order by 2 desc

-- Showing continents with the highest death count
select
	location
	, max(total_deaths) as highest_deaths
from covid_data
where 
	total_deaths is not null 
	and continent is null
	and location != 'World'
	and location != 'International'
group by location
order by 2 desc

-- Global total numbers
select
	sum(new_cases) as new_cases_total
	, sum(new_deaths) as new_deaths_total
	, round((sum(new_deaths*1.0) / sum(new_cases*1.0))*100, 4) as death_percentage
from covid_data
where 
	total_deaths is not null 
	and continent is not null
order by 1, 2

-- Looking at total population vs vaccinations
select
	cov.continent
	, cov.location
	, cov.date
	, cov.population
	, vac.new_vaccinations
	, sum(vac.new_vaccinations) over (
		partition by cov.location
			order by vac.location
			, vac.date
	) as vaccinations_total
from covid_data cov
join covid_vaccinations vac 
	on cov.location = vac.location
	and cov.date = vac.date
where 
	cov.continent is not null
	and vac.new_vaccinations is not null
order by 2, 3

-- Using CTE to perform calculation and partition by in previous query
with population_vs_vaccination (continent, location, date, population, new_vaccinations, vaccinations_total)
as (
select
	cov.continent
	, cov.location
	, cov.date
	, cov.population
	, vac.new_vaccinations
	, sum(vac.new_vaccinations) over (
		partition by cov.location
			order by vac.location
			, vac.date
	) as vaccinations_total
from covid_data cov
join covid_vaccinations vac 
	on cov.location = vac.location
	and cov.date = vac.date
where 
	cov.continent is not null
	and vac.new_vaccinations is not null
)
select 
	*
	, round((vaccinations_total/population)*100, 2) as vaccination_percentage
from population_vs_vaccination

-- Using a temp table to perform calculation on partition by in previous query
drop table if exists percent_population_vaccinated;

create table percent_population_vaccinated (
    continent varchar(255),
    location varchar(255),
    date timestamp,
    population numeric,
    new_vaccinations numeric,
    rolling_people_vaccinated numeric
);

insert into percent_population_vaccinated (continent, location, date, population, new_vaccinations, rolling_people_vaccinated)
select 
    dea.continent, 
    dea.location, 
    dea.date, 
    dea.population, 
    vac.new_vaccinations,
    sum(vac.new_vaccinations::numeric) over (
        partition by dea.location 
        order by dea.date
    ) as rolling_people_vaccinated
from covid_data dea
join covid_vaccinations vac
    on dea.location = vac.location
    and dea.date = vac.date;

select *, 
    round((rolling_people_vaccinated / population) * 100, 2) as vaccination_percentage
from percent_population_vaccinated;

-- Creating view to store data for later visualizations
create view view_test as
select 
    dea.continent, 
    dea.location, 
    dea.date, 
    dea.population, 
    vac.new_vaccinations,
    sum(vac.new_vaccinations::numeric) over (
        partition by dea.location 
        order by dea.date
    ) as rolling_people_vaccinated
from covid_data dea
join covid_vaccinations vac
    on dea.location = vac.location
    and dea.date = vac.date;