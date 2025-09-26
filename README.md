# Ecommerce-Schema

How to run:

1. Save this file as ecommerce_schema.sql.
2. Open a MySQL client (CLI, Workbench, or phpMyAdmin).
3. Run:  SOURCE path/to/ecommerce_schema.sql;
   - This will create the database and all tables.
   - Triggers are included for auto-calculating order totals.

Basic test queries:

USE ecommerce_store;
SHOW TABLES;

-- Insert sample data (uncomment section above).
-- Place an order and items, then check:
SELECT * FROM orders;
SELECT * FROM order_items;

-- Verify trigger updates total_amount automatically.
