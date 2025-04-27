CREATE DATABASE timesheet_schema;

USE timesheet_schema;

CREATE TABLE
    timesheet_work_policies (
        company_name VARCHAR(100) PRIMARY KEY,
        ot_hours_per_year INT NOT NULL CHECK (ot_hours_per_year >= 0),
        working_hours_per_day DECIMAL(4, 2) NOT NULL CHECK (working_hours_per_day > 0 AND working_hours_per_day <= 24),
        lunch_hours_per_day DECIMAL(4, 2) NOT NULL CHECK (lunch_hours_per_day >= 0 AND lunch_hours_per_day <= 24),
        system_activated BOOLEAN DEFAULT FALSE,
        wp_created_on TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        wp_created_by VARCHAR(100) NOT NULL,
        wp_updated_on TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
        wp_updated_by VARCHAR(100)
    );

CREATE TABLE
    timesheet_records (
        ts_record_id INT PRIMARY KEY AUTO_INCREMENT,
        ts_employee_email VARCHAR(100) NOT NULL,
        ts_record_date DATE NOT NULL,
        ts_company_name VARCHAR(100) NULL,
        ts_clock_in TIME NOT NULL,
        ts_clock_out TIME NOT NULL,
        ts_lunch_included INT DEFAULT 0,
        ts_ot_hours DECIMAL(4, 2) DEFAULT 0.00,
        ts_ot_reason TEXT,
        ts_lead_email VARCHAR(100),
        ts_ot_rejection_reason TEXT,
        ts_ot_status ENUM ('PENDING', 'APPROVED', 'REJECTED') DEFAULT 'PENDING',
        ts_created_on TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        ts_created_by VARCHAR(100) NOT NULL,
        ts_updated_on TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
        ts_updated_by VARCHAR(100),
        CONSTRAINT ts_fk_wp FOREIGN KEY (ts_company_name) REFERENCES timesheet_work_policies (company_name) ON DELETE SET NULL
    );

-- Sample data for timesheet_work_policies
INSERT INTO
    timesheet_work_policies (
        company_name,
        ot_hours_per_year,
        working_hours_per_day,
        lunch_hours_per_day,
        wp_created_by,
        wp_updated_by
    )
VALUES
    (
        "WSO2 - INDIA",
        200,
        8.00,
        1.00,
        0,
        'admin',
        'admin'
    ),
    (
        "WSO2 - USA",
        150,
        7.50,
        0.50,
        0,
        'hr_manager',
        'admin'
    ),
    ("WSO2 - UK", 250, 8.50, 1.00, 0, 'admin', 'admin'),
    (
        "WSO2 - BRAZIL",
        100,
        7.00,
        0.75,
        0,
        'hr_manager',
        'admin'
    ),
    (
        "WSO2 - GERMANY",
        300,
        9.00,
        1.00,
        0,
        'admin',
        'admin'
    ),
    (
        "WSO2 - AUSTRALIA",
        180,
        8.00,
        0.50,
        0,
        'admin',
        'admin'
    ),
    (
        "WSO2 - SRI LANKA",
        120,
        7.75,
        1.00,
        0,
        'hr_manager',
        'admin'
    ),
    (
        "WSO2 - UAE",
        220,
        8.25,
        0.75,
        0,
        'admin',
        'admin'
    ),
    (
        "WSO2 - SINGAPORE",
        220,
        8.25,
        0.75,
        0,
        'admin',
        'admin'
    ),
    (
        "WSO2 - MALAYSIA",
        220,
        8.25,
        0.75,
        0,
        'admin',
        'admin'
    ),
    (
        "WSO2 - CANADA",
        220,
        8.25,
        0.75,
        'admin',
        'admin'
    ),
    (
        "WSO2 - PACIFIC CONTROL SYSTEMS",
        220,
        8.25,
        0.75,
        0,
        'admin',
        'admin'
    ),
    (
        "WSO2 - SPAIN",
        220,
        8.25,
        0.75,
        0,
        'admin',
        'admin'
    ),
    (
        "WSO2 - NEW ZEALAND",
        220,
        8.25,
        0.75,
        0,
        'admin',
        'admin'
    );
