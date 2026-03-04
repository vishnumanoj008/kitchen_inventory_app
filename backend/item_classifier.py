"""
Item classification system to automatically determine if items belong in fridge or pantry
"""

# Items that should be stored in the fridge
FRIDGE_ITEMS = {
    # Dairy
    'milk', 'cheese', 'butter', 'yogurt', 'cream', 'sour cream', 'cottage cheese',
    'ice cream', 'whipped cream', 'eggnog', 'kefir', 'paneer'
    
    # Meat & Seafood
    'chicken', 'beef', 'pork', 'lamb', 'turkey', 'duck', 'bacon', 'sausage',
    'ham', 'fish', 'salmon', 'tuna', 'shrimp', 'crab', 'lobster', 'mussels',
    
    # Fruits (refrigerated)
    'strawberry', 'strawberries', 'blueberry', 'blueberries', 'raspberry',
    'raspberries', 'blackberry', 'blackberries', 'grape', 'grapes',
    'cherry', 'cherries', 'apple', 'apples', 'pear', 'pears',
    'orange', 'oranges', 'lemon', 'lemons', 'lime', 'limes',
    'watermelon', 'cantaloupe', 'honeydew', 'kiwi',
    
    # Vegetables
    'lettuce', 'spinach', 'kale', 'arugula', 'cabbage', 'broccoli',
    'cauliflower', 'carrot', 'carrots', 'celery', 'cucumber', 'cucumbers',
    'bell pepper', 'peppers', 'tomato', 'tomatoes', 'zucchini', 'squash',
    'eggplant', 'asparagus', 'green beans', 'peas', 'corn', 'mushroom',
    'mushrooms', 'radish', 'radishes', 'beet', 'beets',
    
    # Condiments (refrigerated after opening)
    'ketchup', 'mustard', 'mayonnaise', 'mayo', 'salad dressing',
    'bbq sauce', 'hot sauce', 'soy sauce', 'worcestershire sauce',
    'pickles', 'relish', 'jam', 'jelly', 'jello',
    
    # Beverages
    'juice', 'orange juice', 'apple juice', 'soda', 'beer', 'wine',
    'almond milk', 'soy milk', 'oat milk',
    
    # Leftovers
    'leftovers', 'leftover', 'pizza', 'sandwich', 'salad', 'curry', 'stew', 'soup',
    'pasta', 'noodles', 'cooked rice',
    
    # Eggs
    'egg', 'eggs',
    
    # Fresh herbs
    'parsley', 'cilantro', 'basil', 'dill', 'mint', 'chives',
}

# Items that should be stored in the pantry
PANTRY_ITEMS = {
    # Grains & Bread
    'bread', 'bagel', 'bagels', 'roll', 'rolls', 'bun', 'buns',
    'rice', 'pasta', 'noodles', 'spaghetti', 'macaroni', 'quinoa',
    'oats', 'oatmeal', 'cereal', 'granola', 'crackers',
    
    # Canned goods
    'beans', 'chickpeas', 'lentils', 'soup', 'tuna can', 'canned tuna',
    'tomato sauce', 'tomato paste', 'corn', 'peas',
    
    # Baking
    'flour', 'sugar', 'brown sugar', 'baking powder', 'baking soda',
    'yeast', 'vanilla extract', 'cocoa powder', 'chocolate chips',
    'honey', 'syrup', 'maple syrup', 'molasses',
    
    # Snacks
    'chips', 'popcorn', 'pretzels', 'cookies', 'crackers', 'nuts',
    'almonds', 'peanuts', 'cashews', 'walnuts', 'trail mix',
    'candy', 'chocolate', 'granola bar', 'granola bars',
    
    # Oils & Vinegars
    'olive oil', 'vegetable oil', 'coconut oil', 'vinegar',
    'balsamic vinegar', 'apple cider vinegar',
    
    # Spices & Seasonings
    'salt', 'pepper', 'paprika', 'cumin', 'oregano', 'thyme',
    'rosemary', 'cinnamon', 'nutmeg', 'ginger', 'garlic powder',
    'onion powder', 'chili powder', 'turmeric',
    
    # Dried fruits
    'raisins', 'dates', 'dried cranberries', 'dried apricots',
    
    # Fruits (room temp)
    'banana', 'bananas', 'potato', 'potatoes', 'onion', 'onions',
    'garlic', 'sweet potato', 'sweet potatoes', 'avocado', 'avocados',
    'mango', 'mangoes', 'pineapple', 'papaya',
    
    # Coffee & Tea
    'coffee', 'tea', 'green tea', 'black tea', 'herbal tea',
    
    # Other
    'peanut butter', 'nutella', 'jam', 'preserves',
}

def classify_item_location(item_name: str) -> str:
    """
    Automatically classify item into fridge or pantry based on item name
    
    Args:
        item_name: Name of the item (cleaned and lowercase)
    
    Returns:
        'fridge' or 'pantry'
    """
    item_lower = item_name.lower().strip()
    
    # Check for exact matches first
    if item_lower in FRIDGE_ITEMS:
        return 'fridge'
    if item_lower in PANTRY_ITEMS:
        return 'pantry'
    
    # Check for partial matches (e.g., "chicken breast" contains "chicken")
    for fridge_item in FRIDGE_ITEMS:
        if fridge_item in item_lower or item_lower in fridge_item:
            return 'fridge'
    
    for pantry_item in PANTRY_ITEMS:
        if pantry_item in item_lower or item_lower in pantry_item:
            return 'pantry'
    
    # Default to pantry for unknown items (non-perishable is safer)
    return 'pantry'

def get_item_category(item_name: str) -> str:
    """
    Get category for an item based on classification
    
    Args:
        item_name: Name of the item
    
    Returns:
        Category name
    """
    item_lower = item_name.lower().strip()
    
    # Dairy
    dairy = {'milk', 'cheese', 'butter', 'yogurt', 'cream', 'ice cream'}
    if any(d in item_lower for d in dairy):
        return 'Dairy'
    
    # Meat
    meat = {'chicken', 'beef', 'pork', 'lamb', 'turkey', 'bacon', 'sausage', 'ham'}
    if any(m in item_lower for m in meat):
        return 'Meat'
    
    # Seafood
    seafood = {'fish', 'salmon', 'tuna', 'shrimp', 'crab', 'lobster'}
    if any(s in item_lower for s in seafood):
        return 'Seafood'
    
    # Fruits
    fruits = {'apple', 'banana', 'orange', 'grape', 'berry', 'lemon', 'lime', 
              'watermelon', 'mango', 'pineapple', 'kiwi', 'pear', 'cherry'}
    if any(f in item_lower for f in fruits):
        return 'Fruits'
    
    # Vegetables
    vegetables = {'lettuce', 'spinach', 'carrot', 'tomato', 'cucumber', 'pepper',
                  'broccoli', 'cauliflower', 'celery', 'onion', 'garlic', 'potato'}
    if any(v in item_lower for v in vegetables):
        return 'Vegetables'
    
    # Grains
    grains = {'bread', 'rice', 'pasta', 'cereal', 'oats', 'quinoa'}
    if any(g in item_lower for g in grains):
        return 'Grains'
    
    # Snacks
    snacks = {'chips', 'cookies', 'candy', 'chocolate', 'nuts', 'popcorn'}
    if any(s in item_lower for s in snacks):
        return 'Snacks'
    
    # Beverages
    beverages = {'juice', 'soda', 'beer', 'wine', 'milk', 'coffee', 'tea'}
    if any(b in item_lower for b in beverages):
        return 'Beverages'
    
    return 'General'