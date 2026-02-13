# Firestore -- Cart Margin Value (sGTM Variable)

## Overview

This Server-Side GTM variable retrieves product margin data from
**Google Firestore**, calculates the total cart margin from event
`items`, and returns the result as a string.

**Supports:**

-   Custom (non-Shopify) setups\
-   Shopify integrations\
-   Multiple calculation methods\
-   Automatic fallback when data is missing

------------------------------------------------------------------------

## How It Works

1.  Reads `items` from event data\
2.  Fetches product data from Firestore\
3.  Calculates margin per item\
4.  Applies fallback if needed\
5.  Returns total cart margin (rounded to 2 decimals)

------------------------------------------------------------------------

## Firestore Structure

### Non-Shopify

**Path**

    <collectionId>/<productId>

**Example document**

``` json
{
  "margin": 12.5,
  "return_rate": 0.1
}
```

------------------------------------------------------------------------

### Shopify

**Path**

    shopify/shops/shop_<SHOPIFY_ID>/collections/products/<item_id>-<variant_id>

**Margin logic**

    price - unitCost

------------------------------------------------------------------------

## Configuration

### Required

-   **Data Source**: `Other` or `Shopify`\
-   **Shopify ID** (if Shopify selected)\
-   **Collection ID** (if not Shopify)

### Optional

-   **GCP Project ID** (otherwise uses `GOOGLE_CLOUD_PROJECT`)\
-   Custom item field names\
-   Fallback percentage

------------------------------------------------------------------------

## Calculation Modes

### Value

    margin × quantity

### Return Rate

    (1 - return_rate) × margin × quantity

### Value with Discount

    (margin - discount) × quantity

------------------------------------------------------------------------

## Fallback Behavior

If a product is not found in Firestore:

    fallbackPercent × price × quantity

**Default value**

    0.5 (50%)

The value must be between `0` and `1`.

------------------------------------------------------------------------

## Event Requirements

**Example event structure**

``` json
{
  "items": [
    {
      "item_id": "123",
      "price": 100,
      "quantity": 2,
      "discount": 0
    }
  ]
}
```

Field names are configurable in the template.

------------------------------------------------------------------------

## Return Value

-   Returned as a **string**\
-   Rounded to **2 decimals**\
-   Represents the **total cart margin**

**Example**

    "42.37"

------------------------------------------------------------------------

## Use Cases

-   Profit-based bidding\
-   Server-side ecommerce tracking\
-   Margin reporting\
-   Advanced attribution models
