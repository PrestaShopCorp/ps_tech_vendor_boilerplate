# PS Tech Vendor Boilerplate

This is a boilerplate is a module example to fasten your integration of the ps_eventbus/CloudSync tools and environments.

## Install ps_accounts

You may look at [prestashop_addons_helper](https://github.com/PrestaShopCorp/prestashop_addons_helper) module to easily integrate other modules during the Merchant _onboarding time_ of your module, from the composer dependencies.

You may try this to quickly download the ps*accounts module dependency at \_install time*:

```php
$addonsHelper = new AddonsHelper();
$addonsHelper->installModule("ps_accounts")
```

## Install ps_eventbus

Using the dependency [prestashop-addons-helper](https://github.com/PrestaShopCorp/prestashop-addons-helper) in the composer of your module.

You should try this to download the ps*eventbus module dependency at \_install time*:

```php
$addonsHelper = new AddonsHelper();
$addonsHelper->installModule("ps_eventbus")
```

We recomend to let the user install dependencies through the configuration page instead of taking more time at the installation time and hidding it to the customer

## Add context for the CDC

To allow the merchant to share its data with your services, you have to pair your module with a Cross Domain Component.
You also need to expose the `addonsHelper` to allow the merchant to install the other modules in the configuration page.

You need to expose some context to your configuration page. In the `getContent()` method you have to configure the context that will be exposed to the CDC using the PresenterService of ps_eventbus:

```php
$addonsHelper = new AddonsHelper();

Media::addJsDef([
    'addonsHelper' => $addonsHelper->expose(),
]);

$eventbusModule = $addonsHelper->getModule('ps_eventbus', '1.9.0');

if ($eventbusModule) {
  $eventbusPresenterService = $eventbusModule->getService('PrestaShop\Module\PsEventbus\Service\PresenterService');

  Media::addJsDef([
    'contextPsEventbus' => $eventbusPresenterService->expose($this, ['info', 'modules', 'themes', 'orders'])
  ]);
}
```

The required consents are up to your needs, you may use:

- `info`: Shop technical data (PrestaShop version, PHP version etc).
- `modules`: List of installed modules on the shop.
- `themes`: List of installed themes on the shop.
- `carts`: Shopping cart data of the shop (current carts, abandoned carts, cart contents, product details)
- `carriers`: Characteristics of the carriers proposed by the merchant (shipping rates, shipping weight, countries, shipping zones).
- `categories`: The product categories offered by the shop.
- `orders`: The orders data (order ID, order content, order status and history).
- `products`: The products offered by the shop (products, variations, specific prices)
- `taxonomies`: Enhanced categories specific to PS Facebook (advanced categories).
- `currencies`: List of the shop currencies and conversion rates.
- `customers`: Anonymized clients known by your shop.

| `info`, `modules` and `themes` consents are mandatory.

## Add the CDC to your config page

The CDC is available at:

- integration: `https://integration-assets.prestashop3.com/ext/cloudsync-merchant-sync-consent/latest/cloudsync-cdc.js`
- preproduction: `https://preproduction-assets.prestashop3.com/ext/cloudsync-merchant-sync-consent/latest/cloudsync-cdc.js`
- production: `https://assets.prestashop3.com/ext/cloudsync-merchant-sync-consent/latest/cloudsync-cdc.js`

It will be added to the configuration page of your module for example in `/views/templates/admin/configure.tpl`. To add the CDC simply add the link to the CDC:

```html
<script src="https://assets.prestashop3.com/ext/cloudsync-merchant-sync-consent/latest/cloudsync-cdc.js"></script>
```

And where you want to display it:

```html
<div id="prestashop-cloudsync"></div>
```

Now instanciate the component:

```html
<script>
  const msc = window.cloudSyncSharingConsent;
  msc.init();
  msc.on("OnboardingCompleted", (isCompleted) => {
    console.log("OnboardingCompleted", isCompleted);
  });
  msc.isOnboardingCompleted((isCompleted) => {
    console.log("Onboarding is already Completed", isCompleted);
  });
</script>
```

_If you prefer to set the rendering into another element you can pass the querySelector to the init mehthod like : `cdc.init("#consents-box")`_

A callback function is available, it's called when the user accept the consents.
