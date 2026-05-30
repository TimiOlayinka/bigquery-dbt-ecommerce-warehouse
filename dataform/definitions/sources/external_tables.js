// ---------------------------------------------------------------------------
// Source declarations for ALL external tables — per-brand RDL datasets.
// External tables are created by Terraform and point at GCS.
// Tables use _stg suffix (staging), Dataform models create _history views.
// ---------------------------------------------------------------------------

const brands = {
  boohoo:            { datasets: ["customers", "orders", "products"] },
  boohoo_man:        { datasets: ["customers", "orders", "products"] },
  prettylittlething: { datasets: ["customers", "orders", "products"] },
  nastygal:          { datasets: ["customers", "orders", "products"] },
  karen_millen:      { datasets: ["customers", "orders", "products"] },
  coast:             { datasets: ["customers", "orders", "products"] },
  debenhams:         { datasets: ["customers", "orders", "products"] },
};

const channels = [
  "meta_ads", "google_ads", "tiktok_ads",
  "ga4_sessions", "email_campaigns", "influencers"
];

// E-commerce external tables
Object.entries(brands).forEach(([brand, config]) => {
  config.datasets.forEach(dataset => {
    declare({ schema: `rdl_${brand}`, name: `${dataset}_stg` });
  });
});

// Marketing external tables
Object.keys(brands).forEach(brand => {
  channels.forEach(channel => {
    declare({ schema: `rdl_${brand}`, name: `${channel}_stg` });
  });
});
