create database EM;
use EM;


create table Departments(
    DepartmentID int primary key auto_increment,
    DepartmentName varchar(50) not null unique
);


create table Roles(
    RoleID int primary key auto_increment,
    RoleName varchar(50) not null unique
);


create table Employees(
    EmployeeID int primary key auto_increment,
    FirstName varchar(30) not null,
    LastName varchar(30) not null,
    HireDate date not null,
    Salary decimal(10,2) check (Salary > 0),
    DepartmentID int not null,
    RoleID int not null,
    IsActive bit default 1,
    foreign key (DepartmentID) references Departments(DepartmentID),
    foreign key (RoleID) references Roles(RoleID)
);



create table Payroll (
    PayrollID int primary key auto_increment,
    EmployeeID int not null,
    PayPeriodStart date not null,
    PayPeriodEnd date not null,
    PayDate date not null,
    GrossPay decimal(12,2) not null,
    TaxDeduction decimal(12,2) not null,
    NetPay decimal(12,2) not null,
    CreatedAt timestamp default current_timestamp,
    foreign key (EmployeeID) references Employees(EmployeeID)
);



-- Users Table (for HR Manager vs Dept Head)
create table Users (
    UserID int primary key auto_increment,
    UserName varchar(50) not null unique,
    PasswordHash varchar(155) not null,
    Role varchar(20) check (Role in ('HR Manager','Department Head'))
);



insert into Departments (DepartmentName) values
('HR'),('IT'),('Finance'),('Sales');

insert into Roles (RoleName) values
('Manager'),('Developer'),('Analyst'),('Intern');

insert into Employees (FirstName, LastName, HireDate, Salary, DepartmentID, RoleID)
values
('Amit','Sharma','2023-02-01',60000,2,2),
('Priya','Verma','2024-06-15',75000,3,1),
('Rahul','Kumar','2025-01-10',40000,4,4),
('Sneha','Patel','2022-11-20',55000,1,3);

insert into Users (UserName, PasswordHash, Role) values
('hr_admin','hashed_pwd1','HR Manager'),
('sales_head','hashed_pwd2','Department Head');



-- STORED PROCEDURES

delimiter //
create procedure AddEmployee(
    in p_FirstName varchar(30),
    in p_LastName varchar(30),
    in p_HireDate date,
    in p_Salary decimal(10,2),
    in p_DepartmentID int,
    in p_RoleID int
)
begin
    insert into Employees (FirstName, LastName, HireDate, Salary, DepartmentID, RoleID)
    values (p_FirstName, p_LastName, p_HireDate, p_Salary, p_DepartmentID, p_RoleID);
end //
delimiter ;



-- Update Employee Salary


delimiter //
create procedure UpdateEmployeeSalary(
    in p_EmployeeID int,
    in p_NewSalary decimal(10,2)
)
begin
    update Employees
    set Salary = p_NewSalary
    where EmployeeID = p_EmployeeID;
end //
delimiter ;


-- Terminate Employee 


delimiter //
create procedure TerminateEmployee(
    in p_EmployeeID int
)
begin
    update Employees
    set IsActive = 0
    where EmployeeID = p_EmployeeID;
end //
delimiter ;

-- Transfer Employee 
delimiter //
create procedure TransferEmployee(
    in p_EmployeeID int,
    in p_NewDepartmentID int,
    in p_NewSalary decimal(10,2)
)
begin
    declare exit handler for sqlexception
    begin
        rollback;
    end;

    start transaction;

    update Employees
    set DepartmentID = p_NewDepartmentID,
        Salary = p_NewSalary
    where EmployeeID = p_EmployeeID;

    insert into Payroll (EmployeeID, PayPeriodStart, PayPeriodEnd, PayDate, GrossPay, TaxDeduction, NetPay)
    values (p_EmployeeID, curdate(), curdate(), curdate(), p_NewSalary, p_NewSalary*0.1, p_NewSalary*0.9);

    commit;
end //
delimiter ;




set @searchTerm = 'Amit';
select e.EmployeeID, e.FirstName, e.LastName, d.DepartmentName, r.RoleName, e.Salary
from Employees e
join Departments d on e.DepartmentID = d.DepartmentID
join Roles r on e.RoleID = r.RoleID
where (
    e.FirstName like concat('%', @searchTerm, '%')
    or e.LastName like concat('%', @searchTerm, '%')
    or r.RoleName like concat('%', @searchTerm, '%')
)
and e.IsActive = 1;

-- Filter Employees by Department
select e.EmployeeID, e.FirstName, e.LastName, d.DepartmentName, e.Salary
from Employees e
join Departments d on e.DepartmentID = d.DepartmentID
where d.DepartmentName = 'IT' and e.IsActive = 1;

-- Filter by Salary Range
select EmployeeID, FirstName, LastName, Salary
from Employees
where Salary between 40000 and 70000 and IsActive = 1;

-- Sort by HireDate 
select * from Employees order by HireDate desc;

-- Sort by Salary (highest Salary)
select * from Employees order by Salary desc limit 1;


-- REPORTS


-- Salary Distribution by Department
select d.DepartmentName, avg(e.Salary) as AvgSalary, sum(e.Salary) as TotalSalary
from Employees e
join Departments d on e.DepartmentID = d.DepartmentID
where e.IsActive = 1
group by d.DepartmentName;



-- New Hires 
select EmployeeID, FirstName, LastName, HireDate
from Employees
where HireDate between '2024-01-01' and '2025-12-31';


-- Department Headcount
select d.DepartmentName, count(e.EmployeeID) as Headcount
from Departments d
left join Employees e on d.DepartmentID = e.DepartmentID and e.IsActive = 1
group by d.DepartmentName;


-- USER ROLES



-- HR Manager: Full Access
create user if not exists 'hr_manager'@'localhost' identified by 'hr123';
grant all privileges on EM.* to 'hr_manager'@'localhost';


-- Department Head: Limited Access
create user if not exists 'dept_head'@'localhost' identified by 'dept123';
grant select on EM.Employees to 'dept_head'@'localhost';
grant select on EM.Departments to 'dept_head'@'localhost';

