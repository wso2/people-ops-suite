CREATE DATABASE timesheet_schema;

USE timesheet_schema;

CREATE TABLE
    work_policy (
        company_name VARCHAR(100) PRIMARY KEY,
        ot_hours_per_year INT NOT NULL CHECK (ot_hours_per_year >= 0),
        working_hours_per_day DECIMAL(4, 2) NOT NULL CHECK (
            working_hours_per_day > 0
            AND working_hours_per_day <= 24
        ),
        lunch_hours_per_day DECIMAL(4, 2) NOT NULL CHECK (
            lunch_hours_per_day >= 0
            AND lunch_hours_per_day <= 24
        ),
        wp_created_on TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        wp_created_by VARCHAR(100) NOT NULL,
        wp_updated_on TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
        wp_updated_by VARCHAR(100)
    );

CREATE TABLE
    time_log (
        record_id INT PRIMARY KEY AUTO_INCREMENT,
        employee_email VARCHAR(100) NOT NULL,
        record_date DATE NOT NULL,
        company_name VARCHAR(100) NULL,
        clock_in TIME NOT NULL,
        clock_out TIME NOT NULL,
        lunch_included INT DEFAULT 0,
        ot_hours DECIMAL(4, 2) DEFAULT 0.00,
        ot_reason TEXT,
        lead_email VARCHAR(100),
        ot_rejection_reason TEXT,
        time_log_status ENUM ('PENDING', 'APPROVED', 'REJECTED') DEFAULT 'PENDING',
        created_on TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        created_by VARCHAR(100) NOT NULL,
        updated_on TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
        updated_by VARCHAR(100),
        CONSTRAINT fk_wp FOREIGN KEY (company_name) REFERENCES work_policy (company_name) ON DELETE SET NULL
    );

-- Sample data for work_policy
INSERT INTO
    work_policy (
        company_name,
        ot_hours_per_year,
        working_hours_per_day,
        lunch_hours_per_day,
        wp_created_by,
        wp_updated_by
    )
VALUES
    ("WSO2 - USA", 0, 24.00, 0.50, 'admin', 'admin'),
    ("WSO2 - UK", 0, 24.00, 1.00, 'admin', 'admin'),
    ("WSO2 - UAE", 624, 8.00, 1, 'admin', 'admin'),
    ("WSO2 - SRI LANKA", 0, 24.00, 1.00, 'admin', 'admin'),
    ("WSO2 - SPAIN", 80, 8.00, 1.00, 'admin', 'admin'),
    ("WSO2 - SINGAPORE",0, 24.00, 1.00,'admin','admin'),
    ("WSO2 - NEW ZEALAND", 0, 24.00,1.00,'admin','admin'),
    ("WSO2 - MALAYSIA",0, 24.00, 1.00, 'admin','admin'),
    ("WSO2 - INDIA", 0,24.00, 1.00, 'admin', 'admin'),
    ("WSO2 - GERMANY",0, 24.00, 1.00,'admin','admin'),
    ("WSO2 - CANADA",0, 24.00, 0.50,'admin','admin'),
    ("WSO2 - BRAZIL", 0, 24.00, 1.00, 'admin','admin'),
    ("WSO2 - AUSTRALIA", 0, 24.00, 0.50, 'admin', 'admin' ),
    ("WSO2 - SWEDEN",200,8.00,1.00,'admin','admin'),
    ("WSO2 - SOUTH AFRICA",460,9.00,1.00,'admin','admin'),
    ("WSO2 - FRANCE",220,7.00,1.00,'admin','admin');
