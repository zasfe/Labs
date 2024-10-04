CREATE DATABASE sample_db;
CREATE USER 'test_user'@'%' IDENTIFIED BY 'PASSWORD';
CREATE USER 'test_user'@'%' IDENTIFIED WITH mysql_native_password BY 'PassW0rd';
GRANT ALL PRIVILEGES ON sample_db.* TO 'test_user'@'%';
FLUSH PRIVILEGES;

use sample_db;

CREATE table products
(
product_id BIGINT PRIMARY KEY AUTO_INCREMENT,
product_name VARCHAR(50),
price DOUBLE
) Engine = InnoDB;


INSERT INTO products(product_name, price) VALUES ('Virtual Private Servers', '5.00');
INSERT INTO products(product_name, price) VALUES ('Managed Databases', '15.00');
INSERT INTO products(product_name, price) VALUES ('Block Storage', '10.00');
INSERT INTO products(product_name, price) VALUES ('Managed Kubernetes', '60.00');
INSERT INTO products(product_name, price) VALUES ('Load Balancer', '10.00');

SELECT * FROM products;
