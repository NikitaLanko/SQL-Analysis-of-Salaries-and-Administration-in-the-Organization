-- 1. Покажіть середню зарплату співробітників за кожен рік.

SELECT YEAR(s.from_date) AS report_year, ROUND(AVG(s.salary), 2) AS "average salary"
FROM employees.salaries AS s
GROUP BY report_year
ORDER BY report_year;

-- 2. Покажіть середню зарплату співробітників по кожному відділу. 
-- Примітка: потрібно розрахувати по поточній зарплаті, та поточному відділу співробітників.

SELECT departments.dept_no, departments.dept_name, AVG(salaries.salary) AS average_salary FROM employees
JOIN salaries ON employees.emp_no = salaries.emp_no AND CURRENT_DATE() BETWEEN salaries.from_date AND salaries.to_date
JOIN dept_emp ON employees.emp_no = dept_emp.emp_no
JOIN departments ON dept_emp.dept_no = departments.dept_no
WHERE current_date() BETWEEN dept_emp.from_date AND dept_emp.to_date
GROUP BY departments.dept_no, departments.dept_name
ORDER BY departments.dept_no;

-- 3. Покажіть середню зарплату працівників у кожному відділі за кожен рік.
-- Примітка: для середньої зарплати відділу X року Y нам потрібно взяти середнє значення всіх зарплат співробітників у році Y, які були у відділі X в році Y.

SELECT YEAR(s.from_date) AS report_year, d.dept_name AS department_name, ROUND(AVG(s.salary), 2) AS average_salary
FROM employees.salaries AS s
JOIN employees.dept_emp AS de ON s.emp_no = de.emp_no
JOIN employees.departments AS d ON de.dept_no = d.dept_no
WHERE s.from_date < current_date() AND de.from_date <= s.from_date AND de.to_date >= s.from_date
GROUP BY report_year, department_name
ORDER BY report_year, department_name;


-- 4.  Покажіть для кожного року найбільший відділ цього року та його середню зарплату.

WITH ranked_departments AS (SELECT YEAR(s.from_date) AS report_year,
		d.dept_name AS department_name, AVG(s.salary) AS average_salary,
        RANK() OVER (PARTITION BY YEAR(s.from_date) ORDER BY AVG(s.salary) DESC) AS dept_rank
    FROM employees.salaries AS s
    JOIN employees.dept_emp AS de ON s.emp_no = de.emp_no
    JOIN employees.departments AS d ON de.dept_no = d.dept_no
    WHERE s.from_date < current_date() 
        AND de.from_date <= s.from_date 
        AND de.to_date >= s.from_date
    GROUP BY report_year, department_name
)
SELECT report_year, department_name, average_salary FROM ranked_departments
WHERE dept_rank = 1
ORDER BY report_year;


-- 5.  Покажіть детальну інформацію про поточного менеджера, який найдовше виконує свої обов'язки.

WITH ranked_managers AS (SELECT dm.emp_no, d.dept_name, e.hire_date, e.last_name,
        RANK() OVER (ORDER BY TIMESTAMPDIFF(DAY, e.hire_date, CURRENT_DATE()) DESC) AS manager_rank
    FROM employees.employees AS e
    INNER JOIN employees.dept_manager AS dm ON e.emp_no = dm.emp_no
    INNER JOIN employees.departments AS d ON dm.dept_no = d.dept_no
    WHERE 
        CURRENT_DATE() BETWEEN dm.from_date AND dm.to_date
)
SELECT emp_no,dept_name,hire_date,last_name FROM ranked_managers
WHERE manager_rank = 1;


-- 6. Покажіть топ-10 діючих співробітників компанії з найбільшою різницею 
-- між їх зарплатою і середньою зарплатою в їх відділі.

WITH AvgSalaryByDept AS (SELECT dept_emp.dept_no, AVG(salaries.salary) AS average_salary FROM dept_emp
    JOIN salaries ON dept_emp.emp_no = salaries.emp_no
    WHERE current_date() BETWEEN dept_emp.from_date AND dept_emp.to_date 
    GROUP BY dept_emp.dept_no)
SELECT employees.emp_no, employees.last_name, employees.first_name, employees.hire_date, dept_emp.dept_no, AvgSalaryByDept.average_salary, 
salaries.salary - AvgSalaryByDept.average_salary AS salary_difference FROM employees
JOIN dept_emp ON employees.emp_no = dept_emp.emp_no
JOIN salaries ON employees.emp_no = salaries.emp_no
JOIN AvgSalaryByDept ON dept_emp.dept_no = AvgSalaryByDept.dept_no
WHERE current_date() BETWEEN dept_emp.from_date AND dept_emp.to_date
ORDER BY salary_difference DESC
LIMIT 10;


-- 7. Для кожного відділу покажіть другого по порядку менеджера. Необхідно вивести відділ, прізвище ім’я менеджера, 
-- дату прийому на роботу менеджера і дату коли він став менеджером відділу.

WITH RankedManagers AS (SELECT dept_no, emp_no, from_date, to_date,
RANK() OVER (PARTITION BY dept_no ORDER BY from_date) AS manager_rank FROM dept_manager)
SELECT d.dept_name, d.dept_no, e.last_name, e.first_name,
RankedManagers.from_date AS manager_start_date,
RankedManagers.to_date AS manager_end_date
FROM departments d
JOIN RankedManagers ON d.dept_no = RankedManagers.dept_no AND RankedManagers.manager_rank = 2
JOIN employees e ON RankedManagers.emp_no = e.emp_no;



-- 8. Покажіть відділи в яких зараз працює більше 15000 співробітників.

SELECT departments.dept_no, departments.dept_name, COUNT(*) AS employee_count FROM dept_emp
JOIN departments ON dept_emp.dept_no = departments.dept_no
WHERE current_date() BETWEEN dept_emp.from_date AND dept_emp.to_date
GROUP BY departments.dept_no, departments.dept_name
HAVING employee_count > 15000
ORDER BY employee_count;
