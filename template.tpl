___INFO___

{
  "type": "MACRO",
  "id": "cvt_temp_public_id",
  "version": 1,
  "securityGroups": [],
  "displayName": "Firestore - Cart margin value by Addingwell",
  "description": "Variable that retrieves values from Firestore for each item_id in the items array of the event data.\n\nFor more information head over to: https://github.com/google/gps_soteria",
  "containerContexts": [
    "SERVER"
  ]
}


___TEMPLATE_PARAMETERS___

[
  {
    "type": "TEXT",
    "name": "gcpProjectId",
    "displayName": "GCP Project ID (Where Firestore is located)",
    "simpleValueType": true,
    "notSetText": "projectId is retrieved from the environment variable GOOGLE_CLOUD_PROJECT",
    "help": "Google Cloud Project ID where the Firestore database with margin data is located, leave empty to read from GOOGLE_CLOUD_PROJECT environment variable",
    "canBeEmptyString": true
  },
  {
    "type": "SELECT",
    "name": "dataSource",
    "displayName": "Data Source",
    "macrosInSelect": false,
    "selectItems": [
      {
        "value": "other",
        "displayValue": "Other"
      },
      {
        "value": "shopify",
        "displayValue": "Shopify"
      }
    ],
    "simpleValueType": true,
    "help": "Choose where your event data originates from. Use \u0027Other\u0027 for general setups or \u0027Shopify\u0027 for native integrations (https://apps.shopify.com/addingwell)."
  },
  {
    "type": "TEXT",
    "name": "shopifyId",
    "displayName": "Shopify Id",
    "simpleValueType": true,
    "help": "Shopify Store ID. Required only if you selected Shopify as data source.",
    "enablingConditions": [
      {
        "paramName": "dataSource",
        "paramValue": "shopify",
        "type": "EQUALS"
      }
    ],
    "valueValidators": [
      {
        "type": "NON_EMPTY"
      }
    ]
  },
  {
    "type": "TEXT",
    "name": "collectionId",
    "displayName": "Firestore Collection ID",
    "simpleValueType": true,
    "defaultValue": "products",
    "help": "The Firestore collection containing product documents",
    "enablingConditions": [
      {
        "paramName": "dataSource",
        "paramValue": "shopify",
        "type": "NOT_EQUALS"
      }
    ]
  },
  {
    "type": "GROUP",
    "name": "data",
    "displayName": "Override default values",
    "groupStyle": "NO_ZIPPY",
    "subParams": [
      {
        "type": "LABEL",
        "name": "margin",
        "displayName": "Margin"
      },
      {
        "type": "SELECT",
        "name": "valueCalculation",
        "displayName": "Calculation",
        "macrosInSelect": false,
        "selectItems": [
          {
            "value": "valueQuantity",
            "displayValue": "Value"
          },
          {
            "value": "returnRate",
            "displayValue": "Return Rate"
          },
          {
            "value": "valueWithDiscount",
            "displayValue": "Value with Discount"
          }
        ],
        "simpleValueType": true,
        "help": "Calculation method: base margin, adjusted by return rate, or adjusted for discounts",
        "defaultValue": "valueQuantity",
        "enablingConditions": []
      },
      {
        "type": "TEXT",
        "name": "valueField",
        "displayName": "Value",
        "simpleValueType": true,
        "help": "Firestore field name that contains the margin value",
        "defaultValue": "margin",
        "notSetText": "Please set the Firestore document field for value data",
        "enablingConditions": [
          {
            "paramName": "valueCalculation",
            "paramValue": "returnRate",
            "type": "NOT_EQUALS"
          }
        ]
      },
      {
        "type": "TEXT",
        "name": "returnRateField",
        "displayName": "Return Rate Field",
        "simpleValueType": true,
        "help": "Firestore field containing the return rate for the item",
        "enablingConditions": [
          {
            "paramName": "valueCalculation",
            "paramValue": "returnRate",
            "type": "EQUALS"
          }
        ],
        "notSetText": "Please set the Firestore document field for return rate data",
        "defaultValue": "return_rate"
      },
      {
        "type": "LABEL",
        "name": "itemFields",
        "displayName": "Item Fields"
      },
      {
        "type": "TEXT",
        "name": "itemFieldId",
        "displayName": "Item id",
        "simpleValueType": true,
        "help": "Field name in the event item object for product id",
        "enablingConditions": [],
        "notSetText": "Please set the id product field",
        "defaultValue": "item_id"
      },
      {
        "type": "TEXT",
        "name": "itemFieldPrice",
        "displayName": "Item price",
        "simpleValueType": true,
        "help": "Field name in the event item object for product price",
        "enablingConditions": [],
        "notSetText": "Please set the price product field",
        "defaultValue": "price"
      },
      {
        "type": "TEXT",
        "name": "itemFieldDiscount",
        "displayName": "Item discount",
        "simpleValueType": true,
        "help": "Field name in the event item object for discount value",
        "enablingConditions": [],
        "notSetText": "Please set the discount product field",
        "defaultValue": "discount"
      },
      {
        "type": "TEXT",
        "name": "itemFieldQuantity",
        "displayName": "Item quantity",
        "simpleValueType": true,
        "help": "Field name in the event item object for quantity value",
        "enablingConditions": [],
        "notSetText": "Please set the quantity product field",
        "defaultValue": "quantity"
      }
    ],
    "enablingConditions": [
      {
        "paramName": "dataSource",
        "paramValue": "shopify",
        "type": "NOT_EQUALS"
      }
    ]
  },
  {
    "type": "GROUP",
    "name": "fallback",
    "displayName": "Fallback Value if Product Not Found",
    "groupStyle": "NO_ZIPPY",
    "subParams": [
      {
        "type": "TEXT",
        "name": "fallbackPercent",
        "displayName": "Percentage",
        "simpleValueType": true,
        "defaultValue": 0.5,
        "valueValidators": [
          {
            "type": "NON_EMPTY"
          },
          {
            "type": "DECIMAL"
          }
        ],
        "help": "Default percentage applied to the item price when no Firestore data is available.\nEnter a value between 0 and 1.\nFor example, use 0.1 to apply a 10% margin.",
        "enablingConditions": []
      }
    ]
  }
]


___SANDBOXED_JS_FOR_SERVER___

const Firestore = require('Firestore');
const Promise = require("Promise");
const getEventData = require("getEventData");
const logToConsole = require("logToConsole");
const makeNumber = require("makeNumber");
const makeString = require("makeString");
const Math = require("Math");
const getType = require("getType");

const value = getEventData("value");
const tax = getEventData("tax");
const discount = getEventData("shipping");
const safeShipping = shipping != null ? makeNumber(shipping) : 0;

const haveValueTax = value != null && tax != null;
const isShopify = data.dataSource === "shopify";

const getQuantity = (item) => {
  const quantityField = isShopify ? "quantity" : data.itemFieldQuantity;
  return item.hasOwnProperty(quantityField) ? item[quantityField] : 1;
};

const roundValue = (val) => Math.round(val * 100) / 100;

let firestorePath = '';
if (isShopify) {
    firestorePath = 'shopify/shops/shop_' + data.shopifyId + '/collections/products';
} else {
    firestorePath = data.collectionId;
}

function sumValues(values) {
    let total = 0;
    for (const value of values) {
        if (getType(value) === "number") {
            total += value;
        } else {
            logToConsole("Value is not a number");
        }
    }
  
    const rawTotal = isShopify && haveValueTax ? (value - tax - safeShipping - total) : total;
  
    return makeString(roundValue(rawTotal));
}

function getDefaultFallBackValue(item) {
    const quantity = makeNumber(getQuantity(item));
    const price = makeNumber(isShopify ? item.price : item[data.itemFieldPrice] || 0);
    const fallbackPercent = makeNumber(data.fallbackPercent || 0);
    const percent = isShopify && haveValueTax ? (1 - fallbackPercent) : fallbackPercent;
    
    return roundValue(price * percent * quantity);
}

function calculateValue(item, fsDocument) {
    const quantity = makeNumber(getQuantity(item));
    let valueField = data.valueField;
    let valueCalculation = data.valueCalculation;
    let documentValue = 0;
    
    if(isShopify) {
      valueCalculation = "valueQuantity";
      const inventoryItem = fsDocument && fsDocument.data && fsDocument.data.inventory_item;
      const unitCost = inventoryItem && inventoryItem.unitCost && inventoryItem.unitCost.amount;

      if(unitCost != null) {
         const price = makeNumber(fsDocument.data.price);
         const cost = makeNumber(unitCost);
         documentValue = haveValueTax ? cost : price - cost;
       }
    } else {
      documentValue = makeNumber(fsDocument.data[valueField] || 0);
    }

    switch (valueCalculation) {
        case "valueQuantity":
            return documentValue * quantity;
        case "returnRate":
            const returnRate = makeNumber(fsDocument.data[data.returnRateField] || 0);
            return roundValue((1 - returnRate) * documentValue * quantity);
        case "valueWithDiscount":
            const discountField = data.itemFieldDiscount;
            const discount = item.hasOwnProperty(discountField) ? item[discountField] : 0;
            return (documentValue - discount) * quantity;
        default:
            return documentValue;
    }
}

function getItemValues(items) {
  const valueRequests = [];
  for (const item of items) {
    valueRequests.push(getFirestoreValue(item));
    logToConsole("item", item);
  }
  return Promise.all(valueRequests);
}

function getFirestoreValue(item) {
    let value = getDefaultFallBackValue(item);

    if (isShopify && !(item.item_id && item.item_variant_id) || !isShopify && !item[data.itemFieldId]) {
        logToConsole("No item ID in item. Return the default fallback value");
        return value;
    }
    const itemFieldId = isShopify ? (item.item_id + "-" + item.item_variant_id) : item[data.itemFieldId];
    let path = firestorePath + "/" + itemFieldId;
    
    const firestoreInstance = getType(Firestore) == "function" ? Firestore() : Firestore;
    return Promise.create((resolve) => {
        return Firestore.read(path, { projectId: data.gcpProjectId })
            .then((fsDocument) => {
                logToConsole("Firestore item :", fsDocument);
                value = calculateValue(item, fsDocument);
            })
            .catch((error) => {
                logToConsole("Error retrieving Firestore document `" + path + "`", error);
            })
            .finally(() => {
                resolve(value);
            });
    });
}

// Entry point
const items = getEventData("items");
logToConsole(items, getType(items));
return getItemValues(items)
  .then(sumValues)
  .catch(error => logToConsole("Error", error));


___SERVER_PERMISSIONS___

[
  {
    "instance": {
      "key": {
        "publicId": "logging",
        "versionId": "1"
      },
      "param": [
        {
          "key": "environments",
          "value": {
            "type": 1,
            "string": "debug"
          }
        }
      ]
    },
    "clientAnnotations": {
      "isEditedByUser": true
    },
    "isRequired": true
  },
  {
    "instance": {
      "key": {
        "publicId": "access_firestore",
        "versionId": "1"
      },
      "param": [
        {
          "key": "allowedOptions",
          "value": {
            "type": 2,
            "listItem": [
              {
                "type": 3,
                "mapKey": [
                  {
                    "type": 1,
                    "string": "projectId"
                  },
                  {
                    "type": 1,
                    "string": "path"
                  },
                  {
                    "type": 1,
                    "string": "operation"
                  },
                  {
                    "type": 1,
                    "string": "databaseId"
                  }
                ],
                "mapValue": [
                  {
                    "type": 1,
                    "string": "*"
                  },
                  {
                    "type": 1,
                    "string": "*"
                  },
                  {
                    "type": 1,
                    "string": "read"
                  },
                  {
                    "type": 1,
                    "string": "(default)"
                  }
                ]
              }
            ]
          }
        }
      ]
    },
    "clientAnnotations": {
      "isEditedByUser": true
    },
    "isRequired": true
  },
  {
    "instance": {
      "key": {
        "publicId": "read_event_data",
        "versionId": "1"
      },
      "param": [
        {
          "key": "eventDataAccess",
          "value": {
            "type": 1,
            "string": "any"
          }
        }
      ]
    },
    "clientAnnotations": {
      "isEditedByUser": true
    },
    "isRequired": true
  }
]


___TESTS___

scenarios: []
setup: ''


___NOTES___

Created on 8/3/2022, 3:02:04 PM


