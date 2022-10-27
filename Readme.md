# This is a module example for integrating ps_eventbus/CloudSync into your module.

# How to integrate Cloudsync in my PrestaShop module

## Install ps_eventbus

Your module dooesn't need any dependency, everything will by install at the same time as PrestaShop install your module.
So first in your install method of your module add this code :

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

It will install the ps_eventbus module that is required to synchronize the shop with Cloudsync.

## Add context for the CDC

Once install this module need to be paired using the Corss Domain Component, for that you need to expose some context to your configuration page. In the `getContent` method you have to configure the context that will be exposed to the CDC using the PresenterService of ps_eventbus :

```php
$moduleManager = ModuleManagerBuilder::getInstance()->build();

if ($moduleManager->isInstalled("ps_eventbus")) {
  $eventbusModule =  \Module::getInstanceByName("ps_eventbus");
  $eventbusPresenterService = $eventbusModule->getService('PrestaShop\Module\PsEventbus\Service\PresenterService');

  Media::addJsDef([
    'contextPsEventbus' => $eventbusPresenterService->expose($this->name, ['order', 'product'], ['costumer'])
  ]);
}
```

You can change the consents needed easily, all conents aaylable is : `products, carts, ...`

```php
     * @param string $moduleName
     * @param array  $requiredConsents
     * @param array  $optionalConsents
     */

$eventbusPresenterService->expose($moduleName, $requiredConsents = [], $optionalConsents = [])
```

## Add the CDC to your config page

The CDC is available at `https://integration-assets.prestashop3.com/ext/cloudsync-merchant-sync-consent/latest/cloudsync-cdc.js`, this will be added to the configuration page of your module for example in `/views/templates/admin/configure.tpl`. To add the CDC simply add the link to the CDC :

```html
<script src="https://integration-assets.prestashop3.com/ext/cloudsync-merchant-sync-consent/latest/cloudsync-cdc.js"></script>
```

And where you want to display it :

```html
<div id="ps_eventbus_installer_container"></div>
```

Now instanciate the component :

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
