CREATE TABLE hris_timesheet_work_policies (
    company_name VARCHAR(100) PRIMARY KEY,
    ot_hours_per_year INT NOT NULL CHECK (ot_hours_per_year >= 0),
    working_hours_per_day DECIMAL(4 , 2 ) NOT NULL CHECK (working_hours_per_day > 0),
    lunch_hours_per_day DECIMAL(4 , 2 ) NOT NULL CHECK (lunch_hours_per_day >= 0),
    wp_created_on TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    wp_created_by VARCHAR(100) NOT NULL,
    wp_updated_on TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    wp_updated_by VARCHAR(100)
);

CREATE TABLE hris_timesheet_records (
    ts_record_id INT PRIMARY KEY AUTO_INCREMENT,
    ts_employee_email VARCHAR(100) NOT NULL,
    ts_record_date DATE NOT NULL,
    ts_company_name VARCHAR(100) NULL,
    ts_clock_in TIME NOT NULL,
    ts_clock_out TIME NOT NULL,
    ts_lunch_included INT DEFAULT 0,
    ts_ot_hours DECIMAL(4 , 2 ) DEFAULT 0.00,
    ts_ot_reason TEXT,
    ts_lead_email VARCHAR(100),
    ts_ot_rejection_reason TEXT,
    ts_ot_status ENUM('PENDING', 'APPROVED', 'REJECTED') DEFAULT 'PENDING',
    ts_created_on TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    ts_created_by VARCHAR(100) NOT NULL,
    ts_updated_on TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    ts_updated_by VARCHAR(100),
    CONSTRAINT ts_fk_wp FOREIGN KEY (ts_company_name)
        REFERENCES hris_timesheet_work_policies (company_name)
        ON DELETE SET NULL,
    CONSTRAINT unique_employee_date UNIQUE (ts_employee_email , ts_record_date)
);
