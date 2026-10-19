# AB Kitchen V0.5 — safe patch

- Baseline V0.4 / branch main.
- 30 original recipe IDs retained; 14 base dessert families appended; 9 reusable toppings.
- Images are AI-generated photorealistic illustrations, not original menu photography.
- New optional JSON keys: collection, topping_ids. Old recipes decode unchanged.
- SharedPreferences existing `ab_kitchen_v1` state preserved; added optional dessertSelections.
- Original saved favorites, pantry, shopping list, planning, cooking progress are not reset or migrated.
- Topping changes reset only the active recipe's cooking step because the step count changes.
- Images bundled once for offline viewing (14 optimized WebP assets).
- No old code, working data, or old photo removed.
- Reference build: Android debug only; iOS simulator only.