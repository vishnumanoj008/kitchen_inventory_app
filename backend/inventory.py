import sqlite3
from datetime import datetime, timedelta
import re
from item_classifier import classify_item_location, get_item_category

DB_PATH = "kitchen.db"

def get_db_connection():
    """Create and return database connection"""
    conn = sqlite3.connect(DB_PATH)
    conn.row_factory = sqlite3.Row
    return conn

def init_db():
    """Initialize database with items table if it doesn't exist"""
    conn = get_db_connection()
    cursor = conn.cursor()
    cursor.execute('''
        CREATE TABLE IF NOT EXISTS items (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            location TEXT NOT NULL,
            expiry TEXT,
            quantity INTEGER,
            category TEXT,
            UNIQUE(name, location)
        )
    ''')
    conn.commit()
    conn.close()

def clean_product_name(name: str) -> str:
    """
    Clean product name by removing punctuation and capitalizing
    """
    # Remove punctuation (periods, commas, etc.)
    cleaned = re.sub(r'[.,!?;:\-]', '', name)
    # Remove extra whitespace
    cleaned = ' '.join(cleaned.split())
    # Capitalize each word
    cleaned = cleaned.title()
    return cleaned

def get_expiry_date(product_name: str) -> str:
    """
    Get appropriate expiry date based on item type
    """
    product_lower = product_name.lower()
    
    # Dairy: 5-7 days
    if any(word in product_lower for word in ['milk', 'yogurt', 'cheese', 'cream']):
        days = 7
    # Meat/Seafood: 2-3 days
    elif any(word in product_lower for word in ['chicken', 'beef', 'pork', 'fish', 'meat', 'seafood']):
        days = 2
    # Vegetables: 5-7 days
    elif any(word in product_lower for word in ['lettuce', 'spinach', 'broccoli', 'carrot']):
        days = 5
    # Fruits: 5-10 days
    elif any(word in product_lower for word in ['apple', 'orange', 'banana', 'grape']):
        days = 7
    # Bread: 3-5 days
    elif any(word in product_lower for word in ['bread', 'bagel', 'roll']):
        days = 4
    # Default: 3 days
    else:
        days = 3
    
    return (datetime.now() + timedelta(days=days)).isoformat()

def update_inventory(product: str, quantity: int, action: str, location: str = None):
    """
    Update inventory based on action (add, remove, buy)
    Auto-classifies location if not provided
    
    Args:
        product: Item name
        quantity: Number of items
        action: "add", "remove", or "buy"
        location: "fridge" or "pantry" (optional - will auto-classify if not provided)
    
    Returns:
        Updated inventory status
    """
    # Clean the product name
    product = clean_product_name(product)
    
    # Auto-classify location if not provided
    if location is None or location == "":
        location = classify_item_location(product)
        auto_classified = True
    else:
        auto_classified = False
    
    # Get appropriate category
    category = get_item_category(product)
    
    conn = get_db_connection()
    cursor = conn.cursor()
    
    # Get appropriate expiry date based on item type
    expiry = get_expiry_date(product)
    
    try:
        if action == "add":
            # Check if item already exists
            cursor.execute(
                'SELECT id, quantity, expiry FROM items WHERE name = ? AND location = ?',
                (product, location.lower())
            )
            existing = cursor.fetchone()
            
            if existing:
                # Item exists - update quantity and extend expiry if needed
                new_quantity = existing['quantity'] + quantity
                existing_expiry = datetime.fromisoformat(existing['expiry'])
                new_expiry_date = datetime.fromisoformat(expiry)
                
                # Use the later expiry date
                final_expiry = max(existing_expiry, new_expiry_date).isoformat()
                
                cursor.execute('''
                    UPDATE items 
                    SET quantity = ?, expiry = ?
                    WHERE name = ? AND location = ?
                ''', (new_quantity, final_expiry, product, location.lower()))
                
                conn.commit()
                
                message = f"Updated {product}: added {quantity}, now have {new_quantity}"
                if auto_classified:
                    message += f" (auto-stored in {location})"
                
                return {
                    "status": "success",
                    "action": "updated",
                    "product": product,
                    "quantity": quantity,
                    "total_quantity": new_quantity,
                    "location": location,
                    "category": category,
                    "expiry": final_expiry,
                    "auto_classified": auto_classified,
                    "message": message
                }
            else:
                # New item - insert
                cursor.execute('''
                    INSERT INTO items (name, location, expiry, quantity, category)
                    VALUES (?, ?, ?, ?, ?)
                ''', (product, location.lower(), expiry, quantity, category))
                
                conn.commit()
                
                message = f"Added new item: {product} ({quantity})"
                if auto_classified:
                    message += f" to {location}"
                
                return {
                    "status": "success",
                    "action": "added",
                    "product": product,
                    "quantity": quantity,
                    "total_quantity": quantity,
                    "location": location,
                    "category": category,
                    "expiry": expiry,
                    "auto_classified": auto_classified,
                    "message": message
                }
        
        elif action == "remove":
            cursor.execute('SELECT quantity FROM items WHERE name = ? AND location = ?', 
                          (product, location.lower()))
            row = cursor.fetchone()
            
            if not row:
                return {
                    "status": "error",
                    "message": f"Product '{product}' not found in {location}"
                }
            
            current_qty = row[0]
            if current_qty <= quantity:
                cursor.execute('DELETE FROM items WHERE name = ? AND location = ?', 
                              (product, location.lower()))
                message = f"Removed all {product} from {location}"
            else:
                new_qty = current_qty - quantity
                cursor.execute('UPDATE items SET quantity = ? WHERE name = ? AND location = ?',
                              (new_qty, product, location.lower()))
                message = f"Removed {quantity} {product}, {new_qty} remaining"
            
            conn.commit()
            
            return {
                "status": "success",
                "action": "removed",
                "product": product,
                "quantity": quantity,
                "location": location,
                "message": message
            }
        
        elif action == "buy":
            cursor.execute('SELECT quantity FROM items WHERE name = ? AND location = ?', 
                          (product, location.lower()))
            row = cursor.fetchone()
            
            if not row:
                return {
                    "status": "error",
                    "message": f"Product '{product}' not found in {location}"
                }
            
            current_qty = row[0]
            if current_qty <= quantity:
                cursor.execute('DELETE FROM items WHERE name = ? AND location = ?', 
                              (product, location.lower()))
                message = f"Bought all {product} from {location}"
            else:
                new_qty = current_qty - quantity
                cursor.execute('UPDATE items SET quantity = ? WHERE name = ? AND location = ?',
                              (new_qty, product, location.lower()))
                message = f"Bought {quantity} {product}, {new_qty} remaining"
            
            conn.commit()
            
            return {
                "status": "success",
                "action": "purchased",
                "product": product,
                "quantity": quantity,
                "location": location,
                "message": message
            }
        
        else:
            return {
                "status": "error",
                "message": "Unknown action"
            }
    
    except Exception as e:
        conn.rollback()
        return {
            "status": "error",
            "message": str(e)
        }
    
    finally:
        conn.close()


def get_all_items():
    """
    Get all items from inventory
    """
    conn = get_db_connection()
    cursor = conn.cursor()
    
    try:
        cursor.execute('SELECT * FROM items ORDER BY location, name')
        rows = cursor.fetchall()
        
        items = []
        for row in rows:
            items.append({
                "id": row["id"],
                "name": row["name"],
                "location": row["location"],
                "expiry": row["expiry"],
                "quantity": row["quantity"],
                "category": row["category"]
            })
        
        return items
    
    finally:
        conn.close()