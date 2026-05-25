// ---------------------------------------------------------------------------
// Source declarations for ALL external tables in rdl_raw dataset.
// These BigQuery external tables are created by Terraform and point at GCS.
// ---------------------------------------------------------------------------

// --- Boohoo Commerce ---
declare({ schema: "rdl_raw", name: "boohoo_customers_history" });
declare({ schema: "rdl_raw", name: "boohoo_man_customers_history" });
declare({ schema: "rdl_raw", name: "boohoo_orders_history" });
declare({ schema: "rdl_raw", name: "boohoo_man_orders_history" });
declare({ schema: "rdl_raw", name: "boohoo_products_history" });
declare({ schema: "rdl_raw", name: "boohoo_man_products_history" });

// --- Salesforce Commerce (PrettyLittleThing) ---
declare({ schema: "rdl_raw", name: "plt_customers_history" });
declare({ schema: "rdl_raw", name: "plt_orders_history" });
declare({ schema: "rdl_raw", name: "plt_products_history" });

// --- Shopify (NastyGal) ---
declare({ schema: "rdl_raw", name: "nastygal_customers_history" });
declare({ schema: "rdl_raw", name: "nastygal_orders_history" });
declare({ schema: "rdl_raw", name: "nastygal_products_history" });

// --- Magento (Karen Millen + Coast) ---
declare({ schema: "rdl_raw", name: "karen_millen_customers_history" });
declare({ schema: "rdl_raw", name: "karen_millen_orders_history" });
declare({ schema: "rdl_raw", name: "karen_millen_products_history" });
declare({ schema: "rdl_raw", name: "coast_customers_history" });
declare({ schema: "rdl_raw", name: "coast_orders_history" });
declare({ schema: "rdl_raw", name: "coast_products_history" });

// --- Oracle Commerce (Debenhams) ---
declare({ schema: "rdl_raw", name: "debenhams_customers_history" });
declare({ schema: "rdl_raw", name: "debenhams_orders_history" });
declare({ schema: "rdl_raw", name: "debenhams_products_history" });

// --- Marketing (all 7 brands × 6 channels = 42 tables) ---
const brands = [
  "boohoo", "boohoo_man", "prettylittlething", "nastygal",
  "karen_millen", "coast", "debenhams"
];
const channels = [
  "meta_ads", "google_ads", "tiktok_ads",
  "ga4_sessions", "email_campaigns", "influencers"
];

brands.forEach(brand => {
  channels.forEach(channel => {
    declare({ schema: "rdl_raw", name: `${brand}_${channel}_history` });
  });
});
