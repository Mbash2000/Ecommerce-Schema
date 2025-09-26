-- ecommerce_schema.sql
-- Full relational schema for an E‑Commerce Store (MySQL, InnoDB, utf8mb4)
-- Deliverable: CREATE DATABASE + CREATE TABLE statements + constraints

-- 1) Create (and use) database
DROP DATABASE IF EXISTS ecommerce_store;
CREATE DATABASE ecommerce_store
  CHARACTER SET = utf8mb4
  COLLATE = utf8mb4_unicode_ci;
USE ecommerce_store;

-- 2) Core tables
-- Customers (users of the shop)
CREATE TABLE customers (
  customer_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  email VARCHAR(255) NOT NULL UNIQUE,
  password_hash VARCHAR(255) NOT NULL,
  first_name VARCHAR(100) NOT NULL,
  last_name VARCHAR(100) NOT NULL,
  phone VARCHAR(30),
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB;

-- Addresses (one-to-many: customer -> addresses)
CREATE TABLE addresses (
  address_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  customer_id BIGINT UNSIGNED NOT NULL,
  label VARCHAR(50), -- e.g. 'Home', 'Work'
  line1 VARCHAR(255) NOT NULL,
  line2 VARCHAR(255),
  city VARCHAR(100) NOT NULL,
  state VARCHAR(100),
  postal_code VARCHAR(30),
  country VARCHAR(100) NOT NULL,
  is_default BOOLEAN NOT NULL DEFAULT FALSE,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_addresses_customer FOREIGN KEY (customer_id)
    REFERENCES customers(customer_id)
    ON DELETE CASCADE
    ON UPDATE CASCADE
) ENGINE=InnoDB;

-- Categories (hierarchical via parent_id) - one-to-many self relation
CREATE TABLE categories (
  category_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(100) NOT NULL UNIQUE,
  parent_id INT UNSIGNED,
  description TEXT,
  CONSTRAINT fk_categories_parent FOREIGN KEY (parent_id)
    REFERENCES categories(category_id)
    ON DELETE SET NULL
    ON UPDATE CASCADE
) ENGINE=InnoDB;

-- Products
CREATE TABLE products (
  product_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  sku VARCHAR(100) NOT NULL UNIQUE,
  name VARCHAR(255) NOT NULL,
  description TEXT,
  price DECIMAL(10,2) NOT NULL CHECK (price >= 0),
  active BOOLEAN NOT NULL DEFAULT TRUE,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB;

-- Many-to-many: products <-> categories
CREATE TABLE product_categories (
  product_id BIGINT UNSIGNED NOT NULL,
  category_id INT UNSIGNED NOT NULL,
  PRIMARY KEY (product_id, category_id),
  CONSTRAINT fk_pc_product FOREIGN KEY (product_id)
    REFERENCES products(product_id)
    ON DELETE CASCADE
    ON UPDATE CASCADE,
  CONSTRAINT fk_pc_category FOREIGN KEY (category_id)
    REFERENCES categories(category_id)
    ON DELETE CASCADE
    ON UPDATE CASCADE
) ENGINE=InnoDB;

-- Suppliers
CREATE TABLE suppliers (
  supplier_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(200) NOT NULL,
  contact_email VARCHAR(255),
  phone VARCHAR(50),
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

-- Inventory (track stock per product, per supplier optionally)
CREATE TABLE inventory (
  inventory_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  product_id BIGINT UNSIGNED NOT NULL,
  supplier_id INT UNSIGNED,
  quantity INT NOT NULL DEFAULT 0 CHECK (quantity >= 0),
  last_stocked_at TIMESTAMP NULL,
  CONSTRAINT fk_inventory_product FOREIGN KEY (product_id)
    REFERENCES products(product_id)
    ON DELETE CASCADE
    ON UPDATE CASCADE,
  CONSTRAINT fk_inventory_supplier FOREIGN KEY (supplier_id)
    REFERENCES suppliers(supplier_id)
    ON DELETE SET NULL
    ON UPDATE CASCADE
) ENGINE=InnoDB;

-- Orders
CREATE TABLE orders (
  order_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  customer_id BIGINT UNSIGNED NOT NULL,
  shipping_address_id BIGINT UNSIGNED NOT NULL,
  billing_address_id BIGINT UNSIGNED,
  status VARCHAR(50) NOT NULL DEFAULT 'pending',
  total_amount DECIMAL(12,2) NOT NULL CHECK (total_amount >= 0),
  placed_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_orders_customer FOREIGN KEY (customer_id)
    REFERENCES customers(customer_id)
    ON DELETE RESTRICT
    ON UPDATE CASCADE,
  CONSTRAINT fk_orders_shipping_addr FOREIGN KEY (shipping_address_id)
    REFERENCES addresses(address_id)
    ON DELETE RESTRICT
    ON UPDATE CASCADE,
  CONSTRAINT fk_orders_billing_addr FOREIGN KEY (billing_address_id)
    REFERENCES addresses(address_id)
    ON DELETE SET NULL
    ON UPDATE CASCADE
) ENGINE=InnoDB;

-- Order items (one-to-many: order -> items). composite PK.
CREATE TABLE order_items (
  order_id BIGINT UNSIGNED NOT NULL,
  order_item_id INT UNSIGNED NOT NULL AUTO_INCREMENT,
  product_id BIGINT UNSIGNED NOT NULL,
  unit_price DECIMAL(10,2) NOT NULL CHECK (unit_price >= 0),
  quantity INT UNSIGNED NOT NULL CHECK (quantity > 0),
  subtotal DECIMAL(12,2) NOT NULL CHECK (subtotal >= 0),
  PRIMARY KEY (order_id, order_item_id),
  INDEX ix_order_items_product (product_id),
  CONSTRAINT fk_order_items_order FOREIGN KEY (order_id)
    REFERENCES orders(order_id)
    ON DELETE CASCADE
    ON UPDATE CASCADE,
  CONSTRAINT fk_order_items_product FOREIGN KEY (product_id)
    REFERENCES products(product_id)
    ON DELETE RESTRICT
    ON UPDATE CASCADE
) ENGINE=InnoDB;

-- Payments (one-to-one-ish with orders, but allow multiple attempts)
CREATE TABLE payments (
  payment_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  order_id BIGINT UNSIGNED NOT NULL,
  paid_amount DECIMAL(12,2) NOT NULL CHECK (paid_amount >= 0),
  method VARCHAR(100),
  provider_transaction_id VARCHAR(255) UNIQUE,
  status VARCHAR(50) NOT NULL DEFAULT 'initiated',
  paid_at TIMESTAMP NULL,
  CONSTRAINT fk_payments_order FOREIGN KEY (order_id)
    REFERENCES orders(order_id)
    ON DELETE CASCADE
    ON UPDATE CASCADE
) ENGINE=InnoDB;

-- Product reviews (one-to-many: product -> reviews, customer -> reviews)
CREATE TABLE reviews (
  review_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  product_id BIGINT UNSIGNED NOT NULL,
  customer_id BIGINT UNSIGNED NOT NULL,
  rating TINYINT UNSIGNED NOT NULL CHECK (rating BETWEEN 1 AND 5),
  title VARCHAR(255),
  body TEXT,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_reviews_product FOREIGN KEY (product_id)
    REFERENCES products(product_id)
    ON DELETE CASCADE
    ON UPDATE CASCADE,
  CONSTRAINT fk_reviews_customer FOREIGN KEY (customer_id)
    REFERENCES customers(customer_id)
    ON DELETE CASCADE
    ON UPDATE CASCADE
) ENGINE=InnoDB;

-- Wishlists (many-to-many customer <-> product via wishlist_items)
CREATE TABLE wishlists (
  wishlist_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  customer_id BIGINT UNSIGNED NOT NULL,
  name VARCHAR(100) NOT NULL DEFAULT 'Default',
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_wishlists_customer FOREIGN KEY (customer_id)
    REFERENCES customers(customer_id)
    ON DELETE CASCADE
    ON UPDATE CASCADE
) ENGINE=InnoDB;

CREATE TABLE wishlist_items (
  wishlist_id BIGINT UNSIGNED NOT NULL,
  product_id BIGINT UNSIGNED NOT NULL,
  added_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (wishlist_id, product_id),
  CONSTRAINT fk_wi_wishlist FOREIGN KEY (wishlist_id)
    REFERENCES wishlists(wishlist_id)
    ON DELETE CASCADE
    ON UPDATE CASCADE,
  CONSTRAINT fk_wi_product FOREIGN KEY (product_id)
    REFERENCES products(product_id)
    ON DELETE CASCADE
    ON UPDATE CASCADE
) ENGINE=InnoDB;

-- Audit / Logs (simple)
CREATE TABLE change_logs (
  log_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  who VARCHAR(255),
  object_type VARCHAR(100),
  object_id VARCHAR(100),
  change_type VARCHAR(50),
  change_data JSON,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

-- Helpful indexes
CREATE INDEX idx_products_name ON products(name(100));
CREATE INDEX idx_orders_customer_placed_at ON orders(customer_id, placed_at);

-- 3) Triggers to keep orders.total_amount in sync with order_items
DELIMITER $$

CREATE TRIGGER trg_order_items_after_insert
AFTER INSERT ON order_items
FOR EACH ROW
BEGIN
  UPDATE orders
  SET total_amount = (
    SELECT COALESCE(SUM(subtotal),0) FROM order_items WHERE order_id = NEW.order_id
  )
  WHERE order_id = NEW.order_id;
END$$

CREATE TRIGGER trg_order_items_after_update
AFTER UPDATE ON order_items
FOR EACH ROW
BEGIN
  UPDATE orders
  SET total_amount = (
    SELECT COALESCE(SUM(subtotal),0) FROM order_items WHERE order_id = NEW.order_id
  )
  WHERE order_id = NEW.order_id;
END$$

CREATE TRIGGER trg_order_items_after_delete
AFTER DELETE ON order_items
FOR EACH ROW
BEGIN
  UPDATE orders
  SET total_amount = (
    SELECT COALESCE(SUM(subtotal),0) FROM order_items WHERE order_id = OLD.order_id
  )
  WHERE order_id = OLD.order_id;
END$$

DELIMITER ;

-- End of ecommerce_schema.sql
