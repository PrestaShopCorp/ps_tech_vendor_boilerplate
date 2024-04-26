<?php

/**
 * Copyright since 2007 PrestaShop SA and Contributors
 * PrestaShop is an International Registered Trademark & Property of PrestaShop SA
 *
 * NOTICE OF LICENSE
 *
 * This source file is subject to the Academic Free License version 3.0
 * that is bundled with this package in the file LICENSE.md.
 * It is also available through the world-wide-web at this URL:
 * https://opensource.org/licenses/AFL-3.0
 * If you did not receive a copy of the license and are unable to
 * obtain it through the world-wide-web, please send an email
 * to license@prestashop.com so we can send you a copy immediately.
 *
 * @author    PrestaShop SA and Contributors <contact@prestashop.com>
 * @copyright Since 2007 PrestaShop SA and Contributors
 * @license   https://opensource.org/licenses/AFL-3.0 Academic Free License version 3.0
 */

namespace PrestaShop\Module\Ps_tech_vendor_boilerplate\Controller\Admin;

use PrestaShop\PrestaShop\Core\Addon\Module\ModuleManagerBuilder;
use PrestaShopBundle\Controller\Admin\FrameworkBundleAdminController;
use PrestaShop\Module\Ps_tech_vendor_boilerplate\Config\Env;

class BoilerplateController extends FrameworkBundleAdminController
{
    /**
     * Initialize the content by loading the Twig template
     *
     * @return Response
     */
    public function renderApp()
    {
        $contextPsEventbus = null;
        $contextPsAccounts = null;


        /** @var Ps_tech_vendor_boilerplate $psTechVendorBoilerplateModule */
        $psTechVendorBoilerplateModule = \Module::getInstanceByName('ps_tech_vendor_boilerplate');
        if (!$psTechVendorBoilerplateModule) {
            throw new \PrestaShopException('Module ps_tech_vendor_boilerplate not found');
        }

        /** @var Env $envService */
        $envService = $psTechVendorBoilerplateModule->getService('PrestaShop\Module\Ps_tech_vendor_boilerplate\Config\Env');

        $instance = ModuleManagerBuilder::getInstance();
        if ($instance == null) {
            throw new \PrestaShopException('No ModuleManagerBuilder instance');
        }

        $moduleManager = $instance->build();

        if ($moduleManager->isInstalled('ps_accounts')) {
            $accountsModule = \Module::getInstanceByName('ps_accounts');
            $accountPresenterService = $accountsModule->getService('PrestaShop\Module\PsAccounts\Presenter\PsAccountsPresenter');
            $contextPsAccounts = $accountPresenterService->present($psTechVendorBoilerplateModule->name);
        }

        if ($moduleManager->isInstalled('ps_eventbus')) {
            $eventbusModule = \Module::getInstanceByName('ps_eventbus');
            if (isset($eventbusModule->version) && version_compare($eventbusModule->version, '1.9.0', '>=')) {
                // also use is_callable ?
                if (!method_exists($eventbusModule, 'getService')) {
                    throw new \PrestaShopException("getService doesn't exist on ps_eventbus");
                }
                $eventbusPresenterService = $eventbusModule->getService('PrestaShop\Module\PsEventbus\Service\PresenterService');

                $contextPsEventbus = $eventbusPresenterService->expose($psTechVendorBoilerplateModule, [
                    'carriers',
                    'carts',
                    'categories',
                    'currencies',
                    'customers',
                    'employees',
                    'images',
                    'info',
                    'languages',
                    'manufacturers',
                    'modules',
                    'orders',
                    'products',
                    'stocks',
                    'stores',
                    'suppliers',
                    'taxonomies',
                    'themes',
                    'translations',
                    'wishlists',
                ]);
            }
        }

        return $this->render(
            '@Modules/ps_tech_vendor_boilerplate/views/templates/admin/configure.html.twig',
            [
                'mboIsInstalled' => $moduleManager->isInstalled('ps_mbo'),
                'contextPsEventbus' => $contextPsEventbus,
                'contextPsAccounts' => $contextPsAccounts,
                'mscUiUrl' => $envService->get('MSC_UI_URL'),
            ]
        );
    }
}
