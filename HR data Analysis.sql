SELECT * FROM locations

select * from employees

------------------------------EXPLORATORY ANALYSIS
---Countries located in Asia
SELECT country_name, region_name
FROM countries
JOIN regions
USING(region_id)
WHERE region_name = 'Asia'


---Country with their respective state and city
SELECT city, state_province AS state, country_name AS country
FROM locations
JOIN countries
USING(country_id)
GROUP BY city, state, country
HAVING state_province IS NOT NULL


---City with the most department
SELECT city, COUNT(department_id) total_department
FROM locations
JOIN departments
USING (location_id)
GROUP BY city
ORDER BY total_department DESC


---Dependents and their country residence
SELECT CONCAT(d.first_name,' ',d.last_name) full_name, 
		country_name AS country, state_province
FROM  dependents d
JOIN employees USING(employee_id)
JOIN departments USING(department_id)
JOIN locations USING(location_id)
JOIN countries USING(country_id)
ORDER BY full_name ASC


---Location of each employee
SELECT CONCAT(e.first_name,' ',e.last_name) employee, street_address
FROM employees e
JOIN departments USING(department_id)
JOIN locations USING(location_id)
ORDER BY street_address ASC


---Managerial Hierachy Level
SELECT CONCAT(e1.first_name,' ',e1.last_name) employee, 
		CONCAT(e2.first_name,' ',e2.last_name) manager, e1.employee_id
FROM employees e1
JOIN employees e2 ON e1.manager_id = e2.employee_id


---Manager with the most employees and departments they manage
SELECT CONCAT(e2.first_name,' ',e2.last_name) manager, 
		COUNT(e.employee_id) total_employees,
		COUNT(DISTINCT d.department_id) total_departmentS
FROM employees e
JOIN employees e2 ON e.manager_id = e2.employee_id
LEFT JOIN departments d ON e.department_id = d.department_id
WHERE CONCAT(e2.first_name,' ',e2.last_name) IS NOT NULL
GROUP BY manager
ORDER BY total_employees DESC
LIMIT 1


---Country with the most department compared to other countries
WITH department_count AS(
	SELECT country_name AS country, COUNT(department_name) total_department
	FROM countries
	JOIN locations USING(country_id)
	JOIN departments USING(location_id)
	GROUP BY country
	ORDER BY total_department DESC
)
SELECT country, total_department, 
		(SELECT AVG(total_department) FROM department_count) AS avg_dept, 
		(total_department - (SELECT AVG(total_department) FROM department_count)) 
		AS diff_avg_dept
FROM department_count


---Location with Department but No Employee
SELECT location_id, city, state_province, COUNT(d.department_id) total_department, COALESCE(COUNT(e.employee_id),2) total_employee
FROM locations l
JOIN departments d USING(location_id)
LEFT JOIN employees e ON d.department_id = e.department_id
GROUP BY location_id, city, state_province
HAVING COUNT(e.employee_id) = 0


---Correlation of Job Roles with Hire Date
SELECT job_title, TO_CHAR(hire_date, 'month') hire_month, EXTRACT(year FROM hire_date) hire_date
FROM jobs
JOIN employees USING(job_id)
ORDER BY EXTRACT(year FROM hire_date), TO_CHAR(hire_date, 'month'),  job_title


--------------------------------------------------------Statistical Analysis
---Average Salary of Employees in each department
SELECT department_name AS department, ROUND(AVG(salary),2) avg_salary
FROM employees
JOIN departments USING(department_id)
GROUP BY department
ORDER BY avg_salary DESC


---Distribution of Salary Across Job Roles
SELECT job_title, COUNT(employee_id) total_employees, MIN(salary) min_salary, 
		MAX(salary) max_salary,	ROUND(AVG(salary),2) avg_salary, 
		PERCENTILE_CONT(0.5) WITHIN GROUP(ORDER BY salary) median_salary
FROM jobs
JOIN employees USING(job_id)
GROUP BY job_title
ORDER BY avg_salary DESC


---Percentage of Employees in each Department
WITH department_count AS(
	SELECT department_name, COUNT(employee_id) total_employees
	FROM departments
	JOIN employees USING(department_id)
	GROUP BY department_name
)
SELECT department_name, total_employees,
		ROUND(100.0 * total_employees / SUM(total_employees) OVER(),2) employee_percentage
FROM department_count
ORDER BY employee_percentage DESC


---Average Number of Dependents per Employee
SELECT ROUND(AVG(dep.num_dependents),2) avg_dependents
FROM	(SELECT CONCAT(e.first_name,' ',e.last_name) full_name, 
			SUM(CASE WHEN dependent_id IS NOT NULL THEN 1 ELSE 0 END) AS num_dependents
		FROM employees e
		LEFT JOIN dependents d ON e.employee_id = d.employee_id
		GROUP BY full_name) dep


---Distribution of Hire_dates by Year
SELECT EXTRACT(year FROM hire_date) hire_year, COUNT(*) AS total_hire
FROM employees
GROUP BY hire_year
ORDER BY total_hire DESC


---Distribution of Hire_Date in each Department per Year
SELECT EXTRACT(year FROM hire_date) hire_year, department_name, COUNT(*) AS total_hire
FROM employees
JOIN departments USING(department_id)
GROUP BY hire_year, department_name
ORDER BY hire_year, total_hire DESC


---Managers and Their Direct Reports
SELECT e.manager_id, CONCAT(m.first_name,' ',m.last_name) AS manager_name, 
    	COUNT(*) AS direct_reports
FROM employees e
JOIN employees m ON e.manager_id = m.employee_id
GROUP BY e.manager_id, manager_name
ORDER BY direct_reports DESC


---Salaries of Job roles > median salary
SELECT job_title, ROUND(AVG(salary),2) avg_salary,
		PERCENTILE_CONT(0.5) WITHIN GROUP(ORDER BY salary) median_salary
FROM employees
JOIN jobs USING(job_id)
GROUP BY job_title
HAVING AVG(salary) > PERCENTILE_CONT(0.5) WITHIN GROUP(ORDER BY salary)


---Percentage of Salaries of Job roles > median salary
WITH mediansalary AS(SELECT job_id,
					PERCENTILE_CONT(0.5) WITHIN GROUP(ORDER BY salary) median_salary
FROM employees
JOIN jobs USING(job_id)
GROUP BY job_id
)
SELECT ROUND(100 * 
		COUNT(CASE WHEN e.salary>m.median_salary THEN 1 END)/COUNT(*),2) percentage_above_median
FROM employees e
JOIN jobs j USING(job_id)
JOIN mediansalary m ON j.job_id = m.job_id


---Correlation Between Number of Employees Per Manager & Their Department's Average Salary
SELECT e.manager_id, CONCAT(m.first_name,' ',m.last_name) manager_name, 
		department_name, COUNT(e.employee_id) num_supervised,  
		ROUND(AVG(e.salary),2) avg_departmental_salary
FROM employees e
JOIN employees m ON e.manager_id = m.employee_id
JOIN departments d ON e.department_id = d.department_id
GROUP BY e.manager_id, manager_name, department_name
ORDER BY e.manager_id, avg_departmental_salary DESC