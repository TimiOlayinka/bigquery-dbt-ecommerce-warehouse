// ---------------------------------------------------------------------------
// Source declarations for ALL external tables — per-brand RDL datasets.
// External tables are created by Terraform and point at GCS.
// Tables use _stg suffix (staging), Dataform models create _history views.
// ---------------------------------------------------------------------------

const brands = {
  velvet_lane:            { datasets: ["customers", "orders", "products"] },
  velvet_mens:        { datasets: ["customers", "orders", "products"] },
  trend_pulse: { datasets: ["customers", "orders", "products"] },
  rebel_chic:          { datasets: ["customers", "orders", "products"] },
  atelier_luxe:      { datasets: ["customers", "orders", "products"] },
  riviera_mode:             { datasets: ["customers", "orders", "products"] },
  grand_heritage:         { datasets: ["customers", "orders", "products"] },
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
