class ExpiryPredictor {
  // Returns predicted days until expiry, or null if unknown
  static int? predictDays(String itemName) {
    final input = itemName.toLowerCase().trim();

    for (final entry in _expiryTable.entries) {
      for (final keyword in entry.key) {
        if (input.contains(keyword)) {
          return entry.value;
        }
      }
    }
    return null;
  }

  static final Map<List<String>, int> _expiryTable = {
    // Dairy
    ["milk", "whole milk", "skim milk", "oat milk", "almond milk"]: 7,
    ["cheese", "cheddar", "mozzarella", "parmesan"]: 21,
    ["yogurt", "yoghurt"]: 14,
    ["butter"]: 30,
    ["cream", "heavy cream", "whipping cream"]: 7,
    ["egg", "eggs"]: 21,

    // Meat & Seafood
    ["chicken", "poultry"]: 2,
    ["beef", "steak", "ground beef", "mince"]: 3,
    ["pork", "bacon", "ham"]: 4,
    ["fish", "salmon", "tuna", "cod", "tilapia"]: 2,
    ["shrimp", "prawn"]: 2,
    ["deli", "cold cuts", "salami", "sausage"]: 5,

    // Fruits
    ["apple", "apples"]: 30,
    ["banana", "bananas"]: 5,
    ["berry", "berries", "strawberry", "blueberry", "raspberry"]: 5,
    ["grape", "grapes"]: 7,
    ["orange", "oranges", "mandarin"]: 21,
    ["lemon", "lime"]: 21,
    ["mango"]: 5,
    ["avocado"]: 4,
    ["watermelon"]: 7,
    ["peach", "nectarine", "plum"]: 5,

    // Vegetables
    ["lettuce", "spinach", "kale", "arugula"]: 7,
    ["carrot", "carrots"]: 21,
    ["broccoli", "cauliflower"]: 7,
    ["tomato", "tomatoes"]: 7,
    ["potato", "potatoes"]: 30,
    ["onion", "onions"]: 30,
    ["garlic"]: 30,
    ["cucumber"]: 7,
    ["pepper", "capsicum", "bell pepper"]: 10,
    ["zucchini", "courgette"]: 7,
    ["mushroom", "mushrooms"]: 7,
    ["corn"]: 3,
    ["celery"]: 14,

    // Cooked / Leftovers
    ["cooked rice", "leftover rice"]: 4,
    ["cooked pasta", "leftover pasta"]: 4,
    ["cooked chicken"]: 3,
    ["cooked beef"]: 3,
    ["soup", "stew", "broth"]: 4,
    ["leftovers", "leftover"]: 3,

    // Pantry / Dry goods
    ["rice"]: 365,
    ["pasta", "noodle", "noodles"]: 365,
    ["flour"]: 180,
    ["sugar"]: 730,
    ["salt"]: 1825,
    ["oil", "olive oil", "vegetable oil"]: 365,
    ["honey"]: 1825,
    ["bread"]: 7,
    ["cereal"]: 180,
    ["oats", "oatmeal"]: 180,
    ["canned", "can of"]: 730,
    ["sauce", "ketchup", "mustard", "mayonnaise"]: 180,
    ["jam", "jelly"]: 365,
    ["vinegar"]: 1825,
  };
}