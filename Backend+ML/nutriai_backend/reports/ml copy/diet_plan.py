import random

def generate_meal_plan(diet_flags):
    breakfast_options = []
    lunch_options = []
    dinner_options = []

    # LOW CARB
    if diet_flags.get("low_carb"):
        breakfast_options += [
            "Oats with nuts",
            "Vegetable omelette",
            "Greek yogurt with seeds"
        ]

        lunch_options += [
            "Grilled paneer with vegetables",
            "Chicken salad",
            "Stir-fried vegetables with tofu"
        ]

        dinner_options += [
            "Vegetable soup with salad",
            "Grilled fish with veggies",
            "Paneer bhurji with salad"
        ]

    # LOW SUGAR
    if diet_flags.get("low_sugar"):
        breakfast_options += [
            "Boiled eggs",
            "Sprouts salad",
            "Unsweetened smoothie"
        ]

        lunch_options += [
            "Brown rice with dal",
            "Multigrain roti with sabzi",
            "Quinoa with vegetables"
        ]

        dinner_options += [
            "Roti with sabzi",
            "Vegetable khichdi",
            "Lentil soup"
        ]

    # THYROID
    if diet_flags.get("thyroid_diet"):
        breakfast_options += [
            "Poha with iodized salt",
            "Boiled eggs",
            "Milk with seeds"
        ]

        lunch_options += [
            "Iodine-rich seafood",
            "Vegetable curry with iodized salt",
            "Rice with dal"
        ]

        dinner_options += [
            "Vegetables rich in iodine",
            "Soup with greens",
            "Grilled fish"
        ]

    # Remove duplicates
    breakfast_options = list(set(breakfast_options))
    lunch_options = list(set(lunch_options))
    dinner_options = list(set(dinner_options))

    # Pick 2 random options (more realistic)
    meal_plan = {
        "breakfast": random.sample(breakfast_options, min(2, len(breakfast_options))),
        "lunch": random.sample(lunch_options, min(2, len(lunch_options))),
        "dinner": random.sample(dinner_options, min(2, len(dinner_options)))
    }

    return meal_plan