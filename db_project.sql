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

select * from Product
