# application file

import oracledb
from flask import Flask, request, render_template, redirect, url_for, session

def connect_to_database():

    user = "system"
    password = "oracle"
    dsn = "localhost:1521/FREE" # e.g., "localhost:1521/ORCL"

    try:
        connection = oracledb.connect(user=user, password=password, dsn=dsn)
        print("Successfully connected to Oracle Database")
        return connection
    except oracledb.Error as e:
        print(f"Error connecting to Oracle Database: {e}")
        return None
    
app = Flask(__name__)
app.secret_key = "change-me"  # required for Flask session; replace for production


def get_cart():
    return session.get('cart', [])


def save_cart(cart):
    session['cart'] = cart
    session.modified = True

@app.route('/')
def home():
    # get all store locations for user to choose from
    cursor.execute("Select s_location from Stores")
    store_options = cursor.fetchall()
    return render_template('db_app.html', options=store_options)

@app.route("/submit_form", methods=["POST"])
def handle_form_submission():
    # store selection saved in session for later product lookup
    store = request.form.get('store')
    store = store[2:-3]
    session['store'] = store
    user = request.form.get('Users')

    print(f'At store {store} as user {user}')

    # depending on what type of user they are show different webpage
    if user == 'Employee':
        cursor.execute(f"select store_ID from stores where s_location = '{store}'")
        store_id = cursor.fetchall()[0][0]
        session['store_id'] = store_id

        cursor.execute(f"SELECT i.upc_code, p.brand, p.p_name, i.m_price, i.fs_price, i.i_quantity FROM Inventory i JOIN \
                   Product p ON i.upc_code = p.upc_code WHERE i.store_ID = \'{store_id}\'")
        prods = cursor.fetchall()

        return render_template('employee_page.html', options=prods, store_loc=store)
    else:
        cursor.execute("select customer_id from customer")
        customers = cursor.fetchall()
        
        return render_template('cust_page.html', options=customers)

@app.route("/customer_id", methods=['POST'])
def handle_id():
    global ID # make it so we can query the customer later
    ID = request.form.get('C_ID')
    ID = ID[1]
    print(f'Loged in as {ID}')
    # start a fresh cart for this customer session
    session.pop('cart', None)
    session['customer_id'] = ID

    store = session.get('store')
    if not store:
        return redirect(url_for('home'))

    cursor.execute(f"select store_ID from stores where s_location = '{store}'")
    store_id = cursor.fetchall()[0][0]
    session['store_id'] = store_id

    cursor.execute(f"SELECT i.upc_code, p.brand, p.p_name, p.p_size, i.m_price, i.i_quantity FROM Inventory i JOIN \
                   Product p ON i.upc_code = p.upc_code WHERE i.store_ID = \'{store_id}\'")


    prods = cursor.fetchall()

    return render_template('prod_page.html', options=prods)

@app.route("/products", methods=['GET'])
def products():
    store = session.get('store')
    store_id = session.get('store_id')
    if not store or not store_id:
        return redirect(url_for('home'))

    cursor.execute(f"SELECT i.upc_code, p.brand, p.p_name, p.p_size, i.m_price, i.i_quantity FROM Inventory i JOIN \
                   Product p ON i.upc_code = p.upc_code WHERE i.store_ID = \'{store_id}\'")
    prods = cursor.fetchall()
    return render_template('prod_page.html', options=prods)

@app.route("/cart", methods=['GET'])
def view_cart():
    cart = get_cart()
    print(cart)
    return render_template('cart.html', cart=cart)

@app.route("/cart/add", methods=['POST'])
def add_to_cart():
    upc = request.form.get('upc')
    name = request.form.get('name')
    brand = request.form.get('brand')
    size = request.form.get('size')
    price_raw = request.form.get('price', 0)
    available_raw = request.form.get('available', 0)
    qty_raw = request.form.get('qty', 1)

    try:
        price = float(price_raw)
    except (TypeError, ValueError):
        price = 0
    try:
        available = int(float(available_raw))
    except (TypeError, ValueError):
        available = 0
    try:
        qty = int(float(qty_raw))
    except (TypeError, ValueError):
        qty = 1

    qty = max(1, qty)
    if available:
        qty = min(qty, available)

    key = f"{upc}"
    cart = get_cart()
    existing = next((item for item in cart if item['key'] == key), None)

    if existing:
        new_qty = existing['qty'] + qty
        if available:
            new_qty = min(new_qty, available)
        existing['qty'] = new_qty
    else:
        cart.append({
            'key': key,
            'upc': upc,
            'name': name,
            'brand': brand,
            'size': size,
            'price': price,
            'available': available,
            'qty': qty,
        })

    save_cart(cart)
    # stay on products page after adding
    return redirect(url_for('products'))

@app.route("/cart/update", methods=['POST'])
def update_cart():
    key = request.form.get('key')
    qty_raw = request.form.get('qty', 1)
    try:
        qty = int(float(qty_raw))
    except (TypeError, ValueError):
        qty = 1
    cart = get_cart()
    updated = []

    for item in cart:
        if item['key'] == key:
            if qty <= 0:
                continue
            if item.get('available'):
                qty = min(qty, item['available'])
            item['qty'] = qty
        updated.append(item)

    save_cart(updated)
    return redirect(url_for('view_cart'))

@app.route("/cart/remove", methods=['POST'])
def remove_from_cart():
    key = request.form.get('key')
    cart = [item for item in get_cart() if item['key'] != key]
    save_cart(cart)
    return redirect(url_for('view_cart'))

@app.route("/checkout", methods=['POST'])
def checkout():
    store_id = session.get('store_id')
    customer_id = session.get('customer_id')
    cart = get_cart()

    if not store_id or not customer_id:
        return redirect(url_for('home'))
    if not cart:
        return redirect(url_for('view_cart'))

    cur = connection.cursor()

    try:
        # get a new sales id from sequence (avoids trigger dependency)
        cur.execute("SELECT seq_sales_id.NEXTVAL FROM dual")
        sales_id = cur.fetchone()[0]
        cur.execute(
            "INSERT INTO Transaction_History (sales_ID, store_ID, customer_ID, date_time, points_used) "
            "VALUES (:sid, :store, :customer, SYSTIMESTAMP, 0)",
            sid=sales_id,
            store=store_id,
            customer=customer_id,
        )

        for item in cart:
            upc = int(item.get('upc', 0))
            qty = int(float(item.get('qty', 0) or 0))
            price = float(item.get('price', 0) or 0)

            # lock the inventory row to avoid race
            cur.execute(
                "SELECT i_quantity FROM Inventory WHERE store_ID = :store AND upc_code = :upc FOR UPDATE",
                store=store_id,
                upc=upc,
            )
            row = cur.fetchone()
            if not row:
                raise ValueError(f"Item {item.get('name')} not found in inventory.")
            available = float(row[0])
            if qty <= 0 or qty > available:
                raise ValueError(f"Insufficient quantity for {item.get('name')}. Requested {qty}, available {available}.")

            cur.execute(
                "UPDATE Inventory SET i_quantity = i_quantity - :qty WHERE store_ID = :store AND upc_code = :upc",
                qty=qty,
                store=store_id,
                upc=upc,
            )
            cur.execute(
                "INSERT INTO Product_Sales_History (sales_ID, upc_code, s_quanitiy, s_price) "
                "VALUES (:sid, :upc, :qty, :price)",
                sid=sales_id,
                upc=upc,
                qty=qty,
                price=price,
            )

        connection.commit()
        # clear cart after successful checkout
        session['cart'] = []
        session.modified = True
        return redirect(url_for('view_cart'))
    except Exception as e:
        connection.rollback()
        return f"Checkout failed: {e}", 400

@app.route("/previous_orders", methods=["GET"])
def view_previous_orders():
    customer_id = session.get('customer_id')
    if not customer_id:
        return redirect(url_for('home'))

    cur = connection.cursor()
    cur.execute("""
        SELECT th.sales_ID,
               th.date_time,
               th.store_ID,
               p.p_name,
               p.upc_code,
               psh.s_quanitiy,
               psh.s_price
        FROM Transaction_History th
        JOIN product_sales_history psh ON th.sales_ID = psh.sales_ID
        JOIN product p ON psh.upc_code = p.upc_code
        WHERE th.customer_ID = :cid
        ORDER BY th.date_time DESC, th.sales_ID DESC
    """, cid=customer_id)

    orders_map = {}
    for sid, dt, store_id, name, upc, qty, price in cur.fetchall():
        if sid not in orders_map:
            orders_map[sid] = {
                "sales_id": sid,
                "date": dt,
                "store_id": store_id,
                "lines": []
            }
        orders_map[sid]["lines"].append({
            "name": name,
            "upc": upc,
            "qty": qty,
            "price": price,
        })

    orders = list(orders_map.values())
    return render_template("previous_orders.html", orders=orders)


# employee side pages and functions
@app.route('/save_inventory', methods=['POST'])
def save_inventory():
    global cart 
    cart = {}

    for key, value in request.form.items():
        if key.startswith("q_"):
            upc = key.replace("q_", "")
            try:
                qty = int(value)
            except (TypeError, ValueError):
                qty = 0

            if qty > 0:
                cart[upc] = qty

    # nothing selected to restock
    if not cart:
        return "No items selected to restock.", 400

    keys = list(cart.keys())
    print(f"[restock] selected UPCs and quantities: {cart}")
    placeholders = ",".join([f":u{i}" for i in range(len(keys))])
    bind_params = {f"u{i}": keys[i] for i in range(len(keys))}

    # run query to get all vendors that sell all items the employee wants to restock
    print(f"[restock] vendor lookup for UPCs {keys}")
    cursor.execute(
        f"select * from vendor where upc_code in ({placeholders}) order by upc_code",
        bind_params,
    )
    vendors = cursor.fetchall()
    print(f"[restock] vendors fetched: {len(vendors)} rows")

    return render_template('vendor.html', v=vendors)


@app.route("/buy_from_v", methods=['POST'])
def add_to_inventory():
    store = session.get('store')
    store_id = session.get('store_id')
    if not store_id:
        return redirect(url_for('home'))
    global cart
    print(f"[restock] store_id={store_id}, store={store}")
    print(f"[restock] cart before purchase: {cart}")
    checked = request.form.items()
    purchase_num = {x:0 for x in cart.keys()}
    for i in checked:
        print(f"[restock] vendor checkbox: {i}")
        key = i[0].split('_')[2]
        purchase_num[key] += 1
    print(f"[restock] purchase_num (times vendor checked per UPC): {purchase_num}")

    q1 = f"select upc_code, i_quantity from inventory where store_id = {store_id} order by upc_code"
    cursor.execute(q1)
    before = cursor.fetchall()
    print(f"[restock] inventory before updates: {before}")

    for i in purchase_num.items():
        q = f"update inventory set i_quantity = i_quantity \
            + {i[1]*cart[i[0]]} where upc_code = '{i[0]}' \
                and store_id = '{store_id}'"
        cursor.execute(q)
        print(f"[restock] ran update: {q}")

    cursor.execute(q1)
    after = cursor.fetchall()
    print(f"[restock] inventory after updates: {after}")

    connection.commit()
    print("[restock] commit complete")

    return render_template('complete.html', loc=store)








if __name__ == '__main__':
    global connection
    connection = connect_to_database()
    global cursor
    cursor = connection.cursor()

    app.run(debug=True)
    

    '''
    cursor = connection.cursor()

    q1 = "INSERT INTO PRODUCT(upc_code, brand, p_type, p_name, p_size) values (2, 'Pepsi', 'Drink', 'Pepsi Free', 'Large')"
    cursor.execute(q1)

    q2 = "SELECT * FROM PRODUCT"
    cursor.execute(q2)
    rows = cursor.fetchall()
    for row in rows:
        print(row)

    q3 = "Delete from product where p_name in ('Pepsi Free')"
    cursor.execute(q3)

    print('Product table after delete')
    cursor.execute(q2)
    rows = cursor.fetchall()
    for row in rows:
        print(row)

    connection.commit()
    print('Commited')
    '''