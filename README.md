# PS Tech Vendor Boilerplate

This is a boilerplate is a module example to fasten your integration of the ps_eventbus/CloudSync tools and environments.
See our [Prestashop Integration Framework documentation](https://docs.cloud.prestashop.com/7-prestashop-cloudsync/) for more information on how you can use such module.

You may also be interested by another boilerplate module, including more PrestaShop buildFor services here: [builtforjsexample](https://github.com/PrestaShopCorp/builtforjsexample).

## Install ps_accounts

You may look at [prestashop-accounts-installer](https://github.com/PrestaShopCorp/prestashop-accounts-installer) module to easily integrate ps*accounts during the Merchant \_onboarding time* of your module, from the composer dependencies.

You may try this to quickly download the ps*accounts module dependency at \_install time*:

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

You should try this to download the ps*eventbus module dependency at \_install time*:

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

## Use the lib mbo_installer for managing dependencies

Remember that a depency can be uninstall, disable or not up to date. To help the store to use a full functional package it's recommended to verify that yourself.

- **First had mbo_installer on composer.json**

```json
"require": {
    //.... Your dependencies here
    "prestashop/module-lib-mbo-installer": "^0.1.0"
  },
```

This lib is necessary to install the _ps_mbo_ module.
You can forge the install link like this:

```php
/**
 * Example on ModuleHelper.php
 */
if ($moduleName === 'ps_mbo') {
    return substr(\Tools::getShopDomainSsl(true) . __PS_BASE_URI__, 0, -1) .
        $router->generate('ps_tech_vendor_boilerplate_api_resolver', [
            'query' => 'installPsMbo',
        ]);
}
```

and call it like this:

```php
/**
 * Example on BoilerplateResolverController.php
 *
 * Install ps_mbo module
 *
 * @return Response
 */
public function installPsMbo(): Response
{
    $mboInstaller = new MBOInstaller(_PS_VERSION_);

    return new Response(json_encode($mboInstaller->installModule(), JSON_FORCE_OBJECT), 200, [
        'Content-Type' => 'application/json',
    ]);
}
```

- **Verify the dependencies**

You can now access all the technical proprieties of the dependencies and return their state to your template:

```php
/**
 * Example on BoilerplateController.php
 *
 * Build informations about module
 *
 * @param string $moduleName
 *
 * @return array
 */
public function buildModuleInformation(string $moduleName)
{
    return [
        'technicalName' => $moduleName,
        'displayName' => $this->getDisplayName($moduleName),
        'isInstalled' => $this->isInstalled($moduleName),
        'isEnabled' => $this->isEnabled($moduleName),
        'isUpToDate' => $this->isUpToDate($moduleName),
        'linkInstall' => $this->getInstallLink($moduleName),
        'linkEnable' => $this->getEnableLink($moduleName),
        'linkUpdate' => $this->getUpdateLink($moduleName),
    ];
}
```

`isUpToDate` comes from the ps_mbo module:

```php
/**
 * Example on ModuleHelper.php
 *
 * returns true/false when module is out/up to date, and null when ps_mbo is not installed
 *
 * @param string $moduleName
 *
 * @return bool|null
 */
public function isUpToDate(string $moduleName)
{
    $mboModule = \Module::getInstanceByName('ps_mbo');

    if (!$mboModule) {
        return null;
    }

    try {
        $mboHelper = $mboModule->get('mbo.modules.helper');
    } catch (\Exception $e) {
        return null;
    }

    if (!$mboHelper) {
        return null;
    }

    $moduleVersionInfos = $mboHelper->findForUpdates($moduleName);

    return $moduleVersionInfos['upgrade_available'];
}
```

> [!CAUTION]
> A module not installed, not up to date or disabled must be a blocking situation to ensure the proper functioning of ps-eventbus

## Add context for the CDC

To allow the merchant to share its data with your services, you have to pair your module with a Cross Domain Component.

You need to expose some context to your configuration page. In the `getContent()` method you have to configure the context that will be exposed to the CDC using the PresenterService of ps_eventbus:

```php
$moduleManager = PrestaShop\PrestaShop\Core\Addon\Module\ModuleManagerBuilder::getInstance()->build();

if ($moduleManager->isInstalled('ps_eventbus')) {
    $eventbusModule = \Module::getInstanceByName('ps_eventbus');
    if ($eventbusModule && version_compare($eventbusModule->version, '1.9.0', '>=')) {
        $eventbusPresenterService = $eventbusModule->getService('PrestaShop\Module\PsEventbus\Service\PresenterService');

        Media::addJsDef([
            'contextPsEventbus' => $eventbusPresenterService->expose($this, ['info', 'modules', 'themes', 'orders']),
        ]);
    }
}
```

The required consents are up to your needs, you may use:

- `carriers`: The characteristics of the carriers available on the shop (read only)
- `carts`: Information about the shopping carts of the shop (read only)
- `categories`: The list of product categories of the shop (read only)
- `currencies`: The list of currencies available in the shop (read only)
- `customers`: The anonymized list of the shop customers (read only)
- `employees`: The anonymized list of the store employees (read only)
- `images`: The list of images available on your shop (read only)
- `info` (mandatory): The shop technical data such as the version of PrestaShop or PHP (read only)
- `languages`: Languages used by the shop (read only)
- `modules`: The list of modules installed on the shop (read only)
- `manufacturers`: List of manufacturers of the products sold by the shop (read only)
- `orders`: Information about orders placed on the shop (read only)
- `products`: The list of products available on the shop (read only)
- `stocks`: The list of stocks and associated movements on the shop (read only)
- `stores`: The list of stores on the shop (read only)
- `suppliers`: List of suppliers of shop (read only)
- `taxonomies`: Advanced categories available on the shop (read only)
- `themes`: The list of themes installed on the shop (read only)
- `translations`: The list of translations available on the shop (read only)
- `wishlists`: The anonymized wishlists of the customers (read only)

| `info` is mandatory.

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

Now instantiate the component:

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

_If you prefer to set the rendering into another element you can pass the querySelector to the init method like : `cdc.init("#consents-box")`_

A callback function is available, it's called when the user accept the consents.
