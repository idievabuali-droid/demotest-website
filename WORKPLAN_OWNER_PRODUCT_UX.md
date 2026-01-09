# Owner Add-Product Redesign (Step-by-step Workplan)

Goal: make adding products organized, predictable, and safe — without breaking the existing catalogue/cart/orders pipeline.

## What “Section B” Means (confirmed)
- **Section B = fixed product info** (not customer-selectable).
- Customers should **see** these as product information (e.g., “OLED – OEM”, “With frame”), but **not choose** them.

## Current Data Model (today)
- `products.category` (string)
- `products.specs` (string[]) – small list of “chips”
- `products.variants` (Record<string, string[]>) – option groups (Model, Color, Pack…)
- `products.inventory` (Record<string, number>) – stock per variant-key

## Proposed Model (backwards compatible, no DB schema change)
Keep `variants` as the persisted field, but allow an optional metadata object:

```js
variants = {
  __meta: {
    family: "iPhone" | "Samsung A-Series" | "Samsung S-Series" | "Accessories" | "Other",
    groups: {
      "Model": { scope: "customer", mode: "multi" },
      "Color": { scope: "customer", mode: "multi" },
      "Pack": { scope: "customer", mode: "single" },
      "Material": { scope: "info", mode: "single" }
    },
    infoGroups: {
      "Material": ["TPU"],
      "Finish": ["Matte"]
    }
  },
  Model: ["iPhone 13", "iPhone 14"],
  Color: ["Black", "Blue"],
  Pack: ["1-Pack", "2-Pack"]
};
```

Notes:
- **Only array-valued keys** are treated as customer option groups.
- `__meta` and `infoGroups` are **objects** and must be ignored by any code that iterates option arrays.
- Old products with no `__meta` remain valid; we’ll apply safe defaults.

## UX Target (Owner “Add Product”)
### Section A — Basics
- Family (chosen first)
- Category
- Name, SKU, Price, Description
- Images
- “Add new family/category” opens a **modal** (doesn’t clutter the form)

### Section B — Product info (fixed)
- Mostly single-value fields → **dropdown** or single select UI
- Sometimes multi-value info (e.g., compatibility list) → **multi select** (still not customer-selectable)

### Section C — Customer options
- Display as **visible pills/chips** (not dropdowns)
- Each option group has:
  - label
  - options list (add/remove values)
  - toggle: `Single` / `Multi`
  - toggle: `Customer option` / `Info only`
- Rule: **max 2 customer “Multi” groups**.
  - If owner tries to set a 3rd group to Multi → block + warn “Change another group back to Single first”.

## Customer UX Target (Product details)
- Show Section B info as “Product information”
- Show only Section C groups as selectable variants
- Single-mode groups behave like radio chips (choose 1)
- Multi-mode groups behave like checkbox chips (choose many) and “Add to cart” adds all requested combinations
  - Combination explosion is controlled by the **max 2 multi groups** rule.

## Step-by-step Implementation Checklist
- [x] Step 1: Add helpers that safely ignore `variants.__meta` everywhere.
- [x] Step 2: Update Customer product modal to support per-group `Single/Multi` (defaults: Model+Color multi; others single).
- [x] Step 3: Add “Product information” section (Section B) rendering from `__meta` + existing `specs`.
- [x] Step 4: Update Owner “Add product” form into 3 sections (Basics / Product information / Customer options).
- [x] Step 5: Add Owner option-group editor + max-2-multi enforcement + custom groups.
- [ ] Step 6: Smoke tests: add product → visible on customer page → add to cart → submit order → orders dashboard shows it.
- [ ] Step 7: Deploy and verify on mobile + desktop.

## Open Questions (to confirm before final polish)
- Which “family” values are definitive for now? (iPhone / Samsung A / Samsung S / Accessories / Other)
- For each category, which groups should default to “customer” vs “info”?
