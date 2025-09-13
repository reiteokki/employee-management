CREATE DATABASE IF NOT EXISTS organization_db;
USE organization_db;

-- Table: data_superior
CREATE TABLE IF NOT EXISTS data_superior (
    m_branch_id VARCHAR(10) NOT NULL,
    m_rep_id VARCHAR(20) PRIMARY KEY,
    m_name VARCHAR(100) NOT NULL,
    m_current_position VARCHAR(50),
    m_manager_id VARCHAR(20)
);

-- Table: data_member
CREATE TABLE IF NOT EXISTS data_member (
    m_branch_id VARCHAR(10) NOT NULL,
    m_rep_id VARCHAR(20) PRIMARY KEY,
    m_name VARCHAR(100) NOT NULL,
    m_current_position VARCHAR(50),
    m_manager_id VARCHAR(20),
    FOREIGN KEY (m_manager_id) REFERENCES data_superior(m_rep_id)
        ON DELETE SET NULL
        ON UPDATE CASCADE
);
