CREATE DATABASE IF NOT EXISTS organization_db;
USE organization_db;

DROP TABLE IF EXISTS data_member;
DROP TABLE IF EXISTS data_superior;

CREATE TABLE IF NOT EXISTS data_superior (
    m_branch_id VARCHAR(10) NOT NULL,
    m_rep_id VARCHAR(20) PRIMARY KEY,
    m_name VARCHAR(100) NOT NULL,
    m_current_position VARCHAR(50),
    m_manager_id VARCHAR(20),
    password VARCHAR(255) NOT NULL,
    deleted_at TIMESTAMP NULL DEFAULT NULL
);

CREATE TABLE IF NOT EXISTS data_member (
    m_branch_id VARCHAR(10) NOT NULL,
    m_rep_id VARCHAR(20) NOT NULL UNIQUE,
    m_name VARCHAR(100) NOT NULL,
    m_current_position VARCHAR(50),
    m_manager_id VARCHAR(20),
    password VARCHAR(255) NOT NULL,
    deleted_at TIMESTAMP NULL DEFAULT NULL,
    PRIMARY KEY (m_rep_id),
    FOREIGN KEY (m_manager_id) REFERENCES data_superior(m_rep_id)
        ON DELETE SET NULL
        ON UPDATE CASCADE
);
