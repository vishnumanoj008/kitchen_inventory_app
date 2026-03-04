import spacy
import re

# Load spaCy model
try:
    nlp = spacy.load("en_core_web_sm")
except OSError:
    print("Downloading spaCy model...")
    import subprocess
    subprocess.run(["python", "-m", "spacy", "download", "en_core_web_sm"])
    nlp = spacy.load("en_core_web_sm")

def parse_voice_command(text: str):
    """
    Parse voice command to extract action, product, and quantity
    
    Examples:
        "add 2 apples" -> [{"action": "add", "product": "apples", "quantity": 2}]
        "remove 3 oranges" -> [{"action": "remove", "product": "oranges", "quantity": 3}]
        "buy 5 bananas" -> [{"action": "buy", "product": "bananas", "quantity": 5}]
        "add 2 apples and remove 3 oranges" -> multiple commands
    
    Args:
        text: Voice command text
    
    Returns:
        List of parsed commands
    """
    text = text.lower().strip()
    commands = []
    
    # Split by "and" to handle multiple commands
    parts = re.split(r'\s+and\s+', text)
    
    for part in parts:
        part = part.strip()
        
        # Determine action
        action = None
        if any(word in part for word in ['add', 'adding', 'put', 'store']):
            action = 'add'
        elif any(word in part for word in ['remove', 'take', 'delete', 'use', 'used']):
            action = 'remove'
        elif any(word in part for word in ['buy', 'bought', 'purchase', 'purchased']):
            action = 'buy'
        
        if not action:
            continue
        
        # Extract quantity using regex
        quantity_match = re.search(r'\b(\d+)\b', part)
        quantity = int(quantity_match.group(1)) if quantity_match else 1
        
        # Use spaCy to extract nouns (products)
        doc = nlp(part)
        products = []
        
        for token in doc:
            # Look for nouns that are likely products
            if token.pos_ in ['NOUN', 'PROPN'] and token.text not in ['fridge', 'pantry', 'kitchen']:
                products.append(token.text)
        
        # If no nouns found, try to extract after action word
        if not products:
            for action_word in ['add', 'remove', 'buy', 'put', 'take', 'delete', 'use', 'store', 'purchase']:
                if action_word in part:
                    # Get everything after the action word (excluding numbers)
                    after_action = part.split(action_word, 1)[-1].strip()
                    # Remove quantity numbers
                    after_action = re.sub(r'\b\d+\b', '', after_action).strip()
                    # Remove common words
                    after_action = re.sub(r'\b(the|a|an|some|of|to|from|in)\b', '', after_action).strip()
                    if after_action:
                        products = [after_action]
                    break
        
        # Create command for each product found
        for product in products:
            if product:
                commands.append({
                    'action': action,
                    'product': product,
                    'quantity': quantity
                })
        
        # If still no product found, use the whole text minus action words
        if not products:
            product_text = part
            for word in ['add', 'remove', 'buy', 'put', 'take', 'delete', 'use', 'store', 'purchase', 'the', 'a', 'an', 'some']:
                product_text = product_text.replace(word, '')
            product_text = re.sub(r'\b\d+\b', '', product_text).strip()
            
            if product_text:
                commands.append({
                    'action': action,
                    'product': product_text,
                    'quantity': quantity
                })
    
    return commands


# Test function
if __name__ == "__main__":
    test_commands = [
        "add 2 apples",
        "remove 3 oranges",
        "buy 5 bananas",
        "add 2 apples and remove 3 oranges",
        "put 4 tomatoes in the fridge",
        "I used 2 eggs",
        "bought 3 cartons of milk"
    ]
    
    for cmd in test_commands:
        print(f"\nInput: {cmd}")
        result = parse_voice_command(cmd)
        print(f"Output: {result}")