-- Nail Salon Management System Database
CREATE DATABASE IF Not exist nail_salon_management;
USE nail_salon_management;

-- 1. Customers Table
CREATE TABLE customers (
    customer_id INT AUTO_INCREMENT PRIMARY KEY,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    email VARCHAR(100) UNIQUE,
    phone VARCHAR(20) NOT NULL UNIQUE,
    date_of_birth DATE,
    join_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    notes TEXT,
    INDEX idx_customer_name (first_name, last_name),
    INDEX idx_customer_phone (phone)
);

-- 2. Services Table
CREATE TABLE services (
    service_id INT AUTO_INCREMENT PRIMARY KEY,
    service_name VARCHAR(100) NOT NULL UNIQUE,
    description TEXT,
    duration_minutes INT NOT NULL CHECK (duration_minutes > 0),
    price DECIMAL(8, 2) NOT NULL CHECK (price >= 0),
    is_active BOOLEAN DEFAULT TRUE,
    category ENUM('manicure', 'pedicure', 'nail_art', 'enhancements', 'other') NOT NULL,
    INDEX idx_service_category (category)
);

-- 3. Technicians Table
CREATE TABLE technicians (
    technician_id INT AUTO_INCREMENT PRIMARY KEY,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    email VARCHAR(100) UNIQUE,
    phone VARCHAR(20) NOT NULL UNIQUE,
    hire_date DATE NOT NULL,
    specialization ENUM('manicure', 'pedicure', 'nail_art', 'enhancements', 'all_services') NOT NULL,
    hourly_rate DECIMAL(8, 2) NOT NULL CHECK (hourly_rate >= 0),
    is_active BOOLEAN DEFAULT TRUE,
    INDEX idx_technician_name (first_name, last_name)
);

-- 4. Products Table (Nail polish, tools, etc.)
CREATE TABLE products (
    product_id INT AUTO_INCREMENT PRIMARY KEY,
    product_name VARCHAR(100) NOT NULL,
    brand VARCHAR(100),
    product_type ENUM('polish', 'gel', 'acrylic', 'tool', 'consumable', 'other') NOT NULL,
    color_code VARCHAR(20),
    quantity_in_stock INT NOT NULL CHECK (quantity_in_stock >= 0) DEFAULT 0,
    reorder_level INT NOT NULL CHECK (reorder_level >= 0) DEFAULT 5,
    unit_price DECIMAL(8, 2) NOT NULL CHECK (unit_price >= 0),
    last_restocked DATE,
    INDEX idx_product_type (product_type),
    INDEX idx_product_brand (brand)
);

-- 5. Appointments Table
CREATE TABLE appointments (
    appointment_id INT AUTO_INCREMENT PRIMARY KEY,
    customer_id INT NOT NULL,
    technician_id INT NOT NULL,
    appointment_date DATE NOT NULL,
    start_time TIME NOT NULL,
    end_time TIME NOT NULL,
    status ENUM('scheduled', 'confirmed', 'in_progress', 'completed', 'cancelled', 'no_show') DEFAULT 'scheduled',
    total_price DECIMAL(8, 2) NOT NULL CHECK (total_price >= 0),
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id) ON DELETE CASCADE,
    FOREIGN KEY (technician_id) REFERENCES technicians(technician_id) ON DELETE CASCADE,
    INDEX idx_appointment_date (appointment_date),
    INDEX idx_appointment_status (status),
    INDEX idx_technician_schedule (technician_id, appointment_date, start_time)
);

-- 6. Appointment Services Table (Many-to-Many between Appointments and Services)
CREATE TABLE appointment_services (
    appointment_service_id INT AUTO_INCREMENT PRIMARY KEY,
    appointment_id INT NOT NULL,
    service_id INT NOT NULL,
    quantity INT NOT NULL CHECK (quantity > 0) DEFAULT 1,
    service_price DECIMAL(8, 2) NOT NULL CHECK (service_price >= 0),
    FOREIGN KEY (appointment_id) REFERENCES appointments(appointment_id) ON DELETE CASCADE,
    FOREIGN KEY (service_id) REFERENCES services(service_id) ON DELETE CASCADE,
    UNIQUE KEY unique_appointment_service (appointment_id, service_id),
    INDEX idx_appointment_services (appointment_id)
);

-- 7. Appointment Products Table (Products used during appointments)
CREATE TABLE appointment_products (
    appointment_product_id INT AUTO_INCREMENT PRIMARY KEY,
    appointment_id INT NOT NULL,
    product_id INT NOT NULL,
    quantity_used INT NOT NULL CHECK (quantity_used > 0),
    FOREIGN KEY (appointment_id) REFERENCES appointments(appointment_id) ON DELETE CASCADE,
    FOREIGN KEY (product_id) REFERENCES products(product_id) ON DELETE CASCADE,
    INDEX idx_appointment_products (appointment_id)
);

-- 8. Payments Table
CREATE TABLE payments (
    payment_id INT AUTO_INCREMENT PRIMARY KEY,
    appointment_id INT NOT NULL UNIQUE,
    payment_method ENUM('cash', 'credit_card', 'debit_card', 'mobile_payment') NOT NULL,
    amount DECIMAL(8, 2) NOT NULL CHECK (amount >= 0),
    tip_amount DECIMAL(8, 2) NOT NULL CHECK (tip_amount >= 0) DEFAULT 0,
    payment_status ENUM('pending', 'completed', 'refunded') DEFAULT 'pending',
    payment_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    transaction_id VARCHAR(255),
    FOREIGN KEY (appointment_id) REFERENCES appointments(appointment_id) ON DELETE CASCADE,
    INDEX idx_payment_date (payment_date),
    INDEX idx_payment_status (payment_status)
);

-- 9. Customer Preferences Table (One-to-One with Customers)
CREATE TABLE customer_preferences (
    preference_id INT AUTO_INCREMENT PRIMARY KEY,
    customer_id INT NOT NULL UNIQUE,
    preferred_technician_id INT,
    nail_shape ENUM('round', 'square', 'oval', 'almond', 'stiletto'),
    favorite_colors TEXT,
    allergies TEXT,
    notes TEXT,
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id) ON DELETE CASCADE,
    FOREIGN KEY (preferred_technician_id) REFERENCES technicians(technician_id) ON DELETE SET NULL,
    INDEX idx_customer_preferences (customer_id)
);

-- 10. Technician Schedule Table
CREATE TABLE technician_schedule (
    schedule_id INT AUTO_INCREMENT PRIMARY KEY,
    technician_id INT NOT NULL,
    work_date DATE NOT NULL,
    start_time TIME NOT NULL,
    end_time TIME NOT NULL,
    is_available BOOLEAN DEFAULT TRUE,
    FOREIGN KEY (technician_id) REFERENCES technicians(technician_id) ON DELETE CASCADE,
    UNIQUE KEY unique_technician_schedule (technician_id, work_date),
    INDEX idx_technician_schedule (technician_id, work_date)
);

-- 11. Inventory Transactions Table
CREATE TABLE inventory_transactions (
    transaction_id INT AUTO_INCREMENT PRIMARY KEY,
    product_id INT NOT NULL,
    transaction_type ENUM('purchase', 'usage', 'adjustment', 'return') NOT NULL,
    quantity INT NOT NULL,
    transaction_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    appointment_id INT NULL,
    notes TEXT,
    FOREIGN KEY (product_id) REFERENCES products(product_id) ON DELETE CASCADE,
    FOREIGN KEY (appointment_id) REFERENCES appointments(appointment_id) ON DELETE SET NULL,
    INDEX idx_inventory_date (transaction_date),
    INDEX idx_product_transactions (product_id)
);

-- 12. Promotions Table
CREATE TABLE promotions (
    promotion_id INT AUTO_INCREMENT PRIMARY KEY,
    promotion_name VARCHAR(100) NOT NULL,
    description TEXT,
    discount_type ENUM('percentage', 'fixed_amount') NOT NULL,
    discount_value DECIMAL(8, 2) NOT NULL CHECK (discount_value >= 0),
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    is_active BOOLEAN DEFAULT TRUE,
    applicable_services JSON, -- Stores service IDs that the promotion applies to
    INDEX idx_promotion_dates (start_date, end_date)
);

-- 13. Appointment Promotions Table (Many-to-Many between Appointments and Promotions)
CREATE TABLE appointment_promotions (
    appointment_promotion_id INT AUTO_INCREMENT PRIMARY KEY,
    appointment_id INT NOT NULL,
    promotion_id INT NOT NULL,
    discount_amount DECIMAL(8, 2) NOT NULL CHECK (discount_amount >= 0),
    FOREIGN KEY (appointment_id) REFERENCES appointments(appointment_id) ON DELETE CASCADE,
    FOREIGN KEY (promotion_id) REFERENCES promotions(promotion_id) ON DELETE CASCADE,
    UNIQUE KEY unique_appointment_promotion (appointment_id, promotion_id),
    INDEX idx_appointment_discounts (appointment_id)
);

--  sample data for demonstration
INSERT INTO customers (first_name, last_name, email, phone) VALUES 
('Sarah', 'Johnson', 'sarah.j@email.com', '555-0101'),
('Maria', 'Garcia', 'maria.g@email.com', '555-0102'),
('James', 'Wilson', 'james.w@email.com', '555-0103');

INSERT INTO services (service_name, description, duration_minutes, price, category) VALUES 
('Classic Manicure', 'Basic nail shaping, cuticle care, and polish', 30, 25.00, 'manicure'),
('Gel Manicure', 'Long-lasting gel polish application', 45, 45.00, 'manicure'),
('Spa Pedicure', 'Luxurious foot soak, massage, and polish', 60, 55.00, 'pedicure'),
('Nail Art Design', 'Custom nail art designs', 20, 15.00, 'nail_art');

INSERT INTO technicians (first_name, last_name, email, phone, hire_date, specialization, hourly_rate) VALUES 
('Emily', 'Chen', 'emily.c@salon.com', '555-0201', '2023-01-15', 'all_services', 25.00),
('David', 'Kim', 'david.k@salon.com', '555-0202', '2023-03-10', 'nail_art', 28.00),
('Lisa', 'Rodriguez', 'lisa.r@salon.com', '555-0203', '2023-02-01', 'manicure', 22.00);

INSERT INTO products (product_name, brand, product_type, color_code, quantity_in_stock, unit_price) VALUES 
('Classic Red Polish', 'OPI', 'polish', 'RED101', 20, 8.50),
('Clear Gel Top Coat', 'CND', 'gel', 'CLEAR001', 15, 12.00),
('Nail File Pack', 'SalonCare', 'tool', NULL, 50, 5.00),
('Cuticle Oil', 'Essie', 'consumable', NULL, 30, 10.00);

-- triggers for inventory management
DELIMITER //

CREATE TRIGGER after_appointment_products_insert
AFTER INSERT ON appointment_products
FOR EACH ROW
BEGIN
    UPDATE products 
    SET quantity_in_stock = quantity_in_stock - NEW.quantity_used
    WHERE product_id = NEW.product_id;
    
    INSERT INTO inventory_transactions (product_id, transaction_type, quantity, appointment_id, notes)
    VALUES (NEW.product_id, 'usage', NEW.quantity_used, NEW.appointment_id, 'Used during appointment');
END//

CREATE TRIGGER after_appointment_completion
AFTER UPDATE ON appointments
FOR EACH ROW
BEGIN
    IF NEW.status = 'completed' AND OLD.status != 'completed' THEN
        UPDATE payments 
        SET payment_status = 'completed'
        WHERE appointment_id = NEW.appointment_id;
    END IF;
END//

DELIMITER ;
