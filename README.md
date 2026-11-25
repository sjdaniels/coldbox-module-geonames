# ColdBox GeoNames Module

A ColdBox module for working with [GeoNames](https://www.geonames.org/) location data. It imports geographic hierarchies into MongoDB and provides models, handlers, and views for country, region, city, nearby-place, and address lookup features.

## Requirements

- ColdBox
- Lucee 4.5+ or Adobe ColdFusion 9.0.2+
- MongoDB with the `mongoentity` module
- The `geoIP` module
- A GeoNames username and, optionally, an API key

## Configuration

Install the module as `geonames`, then add its credentials and endpoints to your application's module settings:

```javascript
moduleSettings = {
    geonames = {
        username   = "your-geonames-username",
        apiKey     = "",
        url        = "http://api.geonames.org",
        premiumUrl = "http://ws.geonames.net"
    }
};
```

The module exposes GeoNames API services, MongoDB-backed entities, and location form/autocomplete views through the `geonames` entry point. Use the `Sync.import` event to rebuild the `geo_names` collection from GeoNames data.
