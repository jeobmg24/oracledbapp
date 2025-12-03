drop table Customer;
drop TABLE employee;
drop table manages;
drop table sales;
drop table product;


-- serial is not a valid key word in oracle
-- need to replace all the times serial is used with a auto increiment trigger

create table Customer (
    customer_ID INT primary key,
    frequent_shopper BOOLEAN,
    -- personal inforamtion if they are a frequent shopper
    first_name VARCHAR(20) default null,
    last_name VARCHAR(20) default null,
    phone_number int default null,
    points INT default 0
);

create table Product (
    upc_code INT primary key,
    brand VARCHAR(20),
    p_type VARCHAR(20),
    p_name VARCHAR(20),
    p_size VARCHAR(20)
);

create table Stores (
    store_ID int primary key,
    s_hours VARCHAR(20),
    s_location VARCHAR(20) 
);

create table Vendor (
    vendor_ID INT primary key,
    upc_code int NOT NULL,
    price numeric (8,2), 
    CONSTRAINT fk_vendor_product
        FOREIGN KEY (upc_code)
        REFERENCES Product(upc_code)
);

create table Inventory (
    store_ID INT NOT NULL,
    upc_code INT NOT NULL,
    i_quantity numeric (8,2) default 0.0,
    m_price numeric (8,2) default 0.0,
    fs_price numeric (8,2) default 0.0,
    primary key (store_ID, upc_code),
    CONSTRAINT fk_inventory_store
        FOREIGN KEY (store_id)
        REFERENCES Stores(store_ID), 
    CONSTRAINT fk_inventory_product
        FOREIGN KEY (upc_code)
        REFERENCES Product(upc_code)
);

create table Orders (
    order_ID INT primary key,
    store_ID INT NOT NULL,
    upc_code INT NOT NULL,
    vendor_ID INT NOT NULL,
    o_quantity numeric (8,2) default 0.0, 
    CONSTRAINT fk_orders_store
        FOREIGN KEY (store_ID)
        REFERENCES Stores(store_ID),
    CONSTRAINT fk_orders_product                         
        FOREIGN KEY (upc_code)
        REFERENCES Product(upc_code),
    CONSTRAINT fk_orders_vendor                     
        FOREIGN KEY (vendor_ID)
        REFERENCES Vendor(vendor_ID)
);

create table Category (
    category_ID INT primary key,
    category_name VARCHAR(20),
    parent_ID INT, 
    CONSTRAINT fk_category_parent
        FOREIGN KEY (parent_ID)
        REFERENCES Category(category_ID)
);

create table Product_Category (
    upc_code INT NOT NULL, 
    category_ID INT NOT NULL,
    primary key(upc_code, category_ID), 
    CONSTRAINT fk_pc_product  
        FOREIGN KEY (upc_code)
        REFERENCES Product(upc_code),
    CONSTRAINT fk_pc_category
        FOREIGN KEY (category_ID)
        REFERENCES Category(category_ID)
);

create table Transaction_History (
    sales_ID INT primary key,
    store_ID INT NOT NULL,
    customer_ID INT NOT NULL,
    date_time TIME,
    points_used int default 0, 
    CONSTRAINT fk_th_store                             
        FOREIGN KEY (store_ID)
        REFERENCES Stores(store_ID),
    CONSTRAINT fk_th_customer     
        FOREIGN KEY (customer_ID)
        REFERENCES Customer(customer_ID)
);

create table Product_Sales_History (
    sales_ID INT NOT NULL,
    upc_code INT NOT NULL,
    s_quanitiy numeric (8,2) default 0,
    s_price numeric (8,2) default 0,
    primary key (sales_ID, upc_code), 
    CONSTRAINT fk_psh_sales  
        FOREIGN KEY (sales_ID)
        REFERENCES Transaction_History(sales_ID),
    CONSTRAINT fk_psh_product                    
        FOREIGN KEY (upc_code)
        REFERENCES Product(upc_code)
);

CREATE SEQUENCE seq_customer_id
    START WITH 1
    INCREMENT BY 1
    NOCACHE;

CREATE SEQUENCE seq_store_id
    START WITH 1
    INCREMENT BY 1
    NOCACHE;

CREATE SEQUENCE seq_vendor_id
    START WITH 1
    INCREMENT BY 1
    NOCACHE;

CREATE SEQUENCE seq_order_id
    START WITH 1
    INCREMENT BY 1
    NOCACHE;

CREATE SEQUENCE seq_category_id
    START WITH 1
    INCREMENT BY 1
    NOCACHE;

CREATE SEQUENCE seq_sales_id
    START WITH 1
    INCREMENT BY 1
    NOCACHE;
    
    
CREATE OR REPLACE TRIGGER trg_customer_bi
BEFORE INSERT ON Customer
FOR EACH ROW
BEGIN
    IF :NEW.customer_ID IS NULL THEN
        SELECT seq_customer_id.NEXTVAL
        INTO   :NEW.customer_ID
        FROM   dual;
    END IF;
END;
/

CREATE OR REPLACE TRIGGER trg_store_bi
BEFORE INSERT ON Stores
FOR EACH ROW
BEGIN
    IF :NEW.store_ID IS NULL THEN
        SELECT seq_store_id.NEXTVAL
        INTO   :NEW.store_ID
        FROM   dual;
    END IF;
END;
/

CREATE OR REPLACE TRIGGER trg_vendor_bi
BEFORE INSERT ON Vendor
FOR EACH ROW
BEGIN
    IF :NEW.vendor_ID IS NULL THEN
        SELECT seq_vendor_id.NEXTVAL
        INTO   :NEW.vendor_ID
        FROM   dual;
    END IF;
END;
/

CREATE OR REPLACE TRIGGER trg_order_bi
BEFORE INSERT ON Orders
FOR EACH ROW
BEGIN
    IF :NEW.order_ID IS NULL THEN
        SELECT seq_order_id.NEXTVAL
        INTO   :NEW.order_ID
        FROM   dual;
    END IF;
END;
/

CREATE OR REPLACE TRIGGER trg_category_bi
BEFORE INSERT ON Category
FOR EACH ROW
BEGIN
    IF :NEW.category_ID IS NULL THEN
        SELECT seq_category_id.NEXTVAL
        INTO   :NEW.category_ID
        FROM   dual;
    END IF;
END;
/

CREATE OR REPLACE TRIGGER trg_th_sales_bi
BEFORE INSERT ON Transaction_History
FOR EACH ROW
BEGIN
    IF :NEW.sales_ID IS NULL THEN
        SELECT seq_sales_id.NEXTVAL
        INTO   :NEW.sales_ID
        FROM   dual;
    END IF;
END;
/


SHOW ERRORS TRIGGER trg_customer_bi;

INSERT INTO STORES (store_id, s_hours, s_location) VALUES
(1, '8 A.M.-9 A.M.', 'Victor'),
(2, '6 A.M-9 P.M.', 'Watertown'),
(3, '7 A.M.-9 P.M.', 'Birmingham');

select * from stores;

INSERT INTO Customer (
    frequent_shopper,
    first_name,
    last_name,
    phone_number,
    points
) VALUES 
(    1,    'Jacob',    'Goldstein',    5164772490,    0),
(    1,    'Casey',    'Provitera',    987654321,    0),
(    1,    'Yuan',    'Hong',    0123456789,    0),
(    1,    'Joseph',    'Callanan',    9173456600,    0),
(    0,    'Lebron',    'James',    0001112345,    0);

select * from customer;

INSERT INTO Product (upc_code, brand, p_type, p_name, p_size)
VALUES
    (100001, 'Kelloggs', 'Cereal', 'Frosted Flakes', '18 oz'),
    (100002, 'General Mills', 'Cereal', 'Cheerios', '14 oz'),
    (100003, 'Post', 'Cereal', 'Honey Bunches', '16 oz'),
    (100004, 'Quaker', 'Oatmeal', 'Instant Oats', '12 oz'),
    (100005, 'Nature Valley', 'Snack', 'Granola Bars', '10 ct'),

    (100006, 'Pepsi', 'Beverage', 'Pepsi Cola', '12 pack'),
    (100007, 'Coca-Cola', 'Beverage', 'Coca-Cola', '20 oz'),
    (100008, 'Gatorade', 'Beverage', 'Gatorade Lemon', '32 oz'),
    (100009, 'Poland Spring', 'Water', 'Spring Water', '24 pack'),
    (100010, 'Starbucks', 'Coffee', 'Cold Brew', '11 oz'),

    (100011, 'Nestle', 'Candy', 'Crunch Bar', '1.5 oz'),
    (100012, 'Hershey', 'Candy', 'Hershey Bar', '1.6 oz'),
    (100013, 'Snickers', 'Candy', 'Snickers Bar', '1.8 oz'),
    (100014, 'M&M', 'Candy', 'Peanut M&M', '5 oz'),
    (100015, 'Reese''s', 'Candy', 'Reese''s Cups', '2 pk'),

    (100016, 'Tostitos', 'Chips', 'Tortilla Chips', '13 oz'),
    (100017, 'Lays', 'Chips', 'Classic Lays', '8 oz'),
    (100018, 'Doritos', 'Chips', 'Nacho Cheese', '9.25 oz'),
    (100019, 'Ruffles', 'Chips', 'Original', '8.5 oz'),
    (100020, 'Pringles', 'Chips', 'Original', '5.5 oz');

select * from product;

INSERT INTO Inventory (store_ID, upc_code, i_quantity, m_price, fs_price) VALUES
-- Store 1: Victor
(1, 100001, 45.00, 4.99, 4.49),
(1, 100003, 30.00, 5.49, 4.99),
(1, 100006, 120.00, 7.99, 6.99),
(1, 100009, 60.00, 4.49, 3.99),
(1, 100013, 150.00, 1.69, 1.49),
(1, 100017, 40.00, 3.99, 3.49),
(1, 100020, 25.00, 2.29, 1.99),

-- Store 2: Watertown
(2, 100002, 50.00, 4.59, 4.09),
(2, 100004, 20.00, 3.99, 3.49),
(2, 100007, 100.00, 1.99, 1.79),
(2, 100011, 90.00, 1.39, 1.19),
(2, 100016, 35.00, 4.29, 3.79),
(2, 100018, 45.00, 4.49, 3.99),

-- Store 3: Birmingham
(3, 100005, 25.00, 5.49, 4.99),
(3, 100008, 70.00, 2.49, 2.29),
(3, 100010, 40.00, 3.99, 3.49),
(3, 100012, 130.00, 1.49, 1.29),
(3, 100014, 55.00, 2.99, 2.59),
(3, 100015, 65.00, 1.79, 1.49),
(3, 100019, 50.00, 3.99, 3.49);


commit;
