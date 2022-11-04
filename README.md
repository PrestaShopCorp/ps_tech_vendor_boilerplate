# PS Tech Vendor Boilerplate

This is a boilerplate is a module example to fasten your integration of the ps_eventbus/CloudSync tools and environments.

## Install ps_accounts

You may look at [prestashop-accounts-installer](https://github.com/PrestaShopCorp/prestashop-accounts-installer) module to easily integrate ps_accounts during the Merchant *onboarding time* of your module, from the composer dependencies.

You may try this to quickly download the ps_accounts module dependency at *install time*:

```php
if (!$moduleManager->isInstalled("ps_accounts")) {
    $moduleManager->install("ps_accounts");
} else if (!$moduleManager->isEnabled("ps_accounts")) {
    $moduleManager->enable("ps_accounts");
    $moduleManager->upgrade('ps_accounts');
} else {
    $moduleManager->upgrade('ps_accounts');
}
```

## Install ps_eventbus

There is no dependency to add in the composer of your module to support ps_eventbus and CloudSync features.

You should try this to download the ps_eventbus module dependency at *install time*:

```php
if (!$moduleManager->isInstalled("ps_eventbus")) {
    $moduleManager->install("ps_eventbus");
} else if (!$moduleManager->isEnabled("ps_eventbus")) {
    $moduleManager->enable("ps_eventbus");
    $moduleManager->upgrade('ps_eventbus');
} else {
    $moduleManager->upgrade('ps_eventbus');
}
```

## Add context for the CDC

To allow the merchant to share its data with your services, you have to pair your module with a Cross Domain Component.

You need to expose some context to your configuration page. In the `getContent()` method you have to configure the context that will be exposed to the CDC using the PresenterService of ps_eventbus:

```php
$moduleManager = ModuleManagerBuilder::getInstance()->build();

if ($moduleManager->isInstalled("ps_eventbus")) {
  $eventbusModule =  \Module::getInstanceByName("ps_eventbus");
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

\* The consents `info`, `modules` and `themes` are mandatory

## Add the CDC to your config page

The CDC is available at:

- integration: `https://integration-assets.prestashop3.com/ext/cloudsync-merchant-sync-consent/latest/cloudsync-cdc.js`
- preproduction: `https://preproduction-assets.prestashop3.com/ext/cloudsync-merchant-sync-consent/latest/cloudsync-cdc.js`
- production: `https://assets.prestashop3.com/ext/cloudsync-merchant-sync-consent/latest/cloudsync-cdc.js`

It will be added to the configuration page of your module for example in `/views/templates/admin/configure.tpl`. To add the CDC simply add the link to the CDC:

```html
<script src="https://integration-assets.prestashop3.com/ext/cloudsync-merchant-sync-consent/latest/cloudsync-cdc.js"></script>
```

And where you want to display it:

```html
<div id="ps_eventbus_installer_container"></div>
```

Now instanciate the component:

```html
<script>
  ShareConsentBar({
    context: window.contextPsEventbus,
    onConsentValidate: () => {
      console.log("User validate the consents");
    },
  }).render("#ps_eventbus_installer_container");
</script>
```

A callback function is available, it's called when the user accept the consents.
