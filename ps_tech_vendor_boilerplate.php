<?php
/*
 * 2007-2023 PrestaShop
 *
 * NOTICE OF LICENSE
 *
 * This source file is subject to the Academic Free License (AFL 3.0)
 * that is bundled with this package in the file LICENSE.txt.
 * It is also available through the world-wide-web at this URL:
 * http://opensource.org/licenses/afl-3.0.php
 * If you did not receive a copy of the license and are unable to
 * obtain it through the world-wide-web, please email
 * license@prestashop.com, so we can send you a copy immediately.
 *
 * DISCLAIMER
 *
 * Do not edit or add to this file if you wish to upgrade PrestaShop to newer
 * versions in the future. If you wish to customize PrestaShop for your
 * needs please refer to http://www.prestashop.com for more information.
 *
 * @author    PrestaShop SA <contact@prestashop.com>
 * @copyright 2007-2023 PrestaShop SA
 * @license   http://opensource.org/licenses/afl-3.0.php  Academic Free License (AFL 3.0)
 * International Registered Trademark & Property of PrestaShop SA
 *
 */

use PrestaShop\ModuleLibServiceContainer\DependencyInjection\ServiceContainer;
use PrestaShop\PrestaShop\Core\Addon\Module\ModuleManagerBuilder;

if (!defined('_PS_VERSION_')) {
    exit;
}

class Ps_tech_vendor_boilerplate extends Module
{
    /**
     * @var ServiceContainer
     */
    private $serviceContainer;

    public function __construct()
    {
        $this->name = 'ps_tech_vendor_boilerplate';
        $this->tab = 'content_management';
        $this->version = 'x.y.z';
        $this->author = 'PrestaShop';
        $this->need_instance = 0;

        /*
         * Set $this->bootstrap to true if your module is compliant with bootstrap (PrestaShop 1.6)
         */
        $this->bootstrap = true;

        parent::__construct();

        $this->displayName = $this->l('PrestaShop Tech Vendor Boilerplate');
        $this->description = $this->l('This is a template module for CloudSync');

        $this->ps_versions_compliancy = ['min' => '1.6', 'max' => _PS_VERSION_];

        $this->serviceContainer = new ServiceContainer(
            $this->name,
            $this->getLocalPath()
        );
    }

    /**
     * @return bool
     *
     * @throws \PrestaShop\PrestaShop\Core\Domain\Theme\Exception\FailedToEnableThemeModuleException
     * @throws ErrorException
     */
    public function install()
    {
        $instance = ModuleManagerBuilder::getInstance();
        if ($instance == null) {
            throw new ErrorException('No ModuleManagerBuilder instance');
        }
        $moduleManager = $instance->build();

        if (!$moduleManager->isInstalled('ps_eventbus')) {
            $moduleManager->install('ps_eventbus');
        } elseif (!$moduleManager->isEnabled('ps_eventbus')) {
            $moduleManager->enable('ps_eventbus');
        }
        $moduleManager->upgrade('ps_eventbus');

        /*
        $eventbusModule =  \Module::getInstanceByName("ps_eventbus");
        $eventbusPresenterService =
            $eventbusModule->getService('PrestaShop\Module\PsEventbus\Service\PresenterService');
        $eventbusPresenterService->init();
        */
        return parent::install();
    }

    /**
     * @param string $serviceName
     *
     * @return mixed
     */
    public function getService($serviceName)
    {
        return $this->serviceContainer->getService($serviceName);
    }

    /**
     * Load the configuration form
     *
     * @return false|string
     *
     * @throws SmartyException
     * @throws ErrorException
     */
    public function getContent()
    {
        $this->context->smarty->assign('module_dir', $this->_path);

        $output = $this->context->smarty->fetch($this->local_path . 'views/templates/admin/configure.tpl');

        $instance = ModuleManagerBuilder::getInstance();
        if ($instance == null) {
            throw new ErrorException('No ModuleManagerBuilder instance');
        }
        $moduleManager = $instance->build();

        /*
        if ($moduleManager->isInstalled("ps_accounts")) {

            $accountsModule =  \Module::getInstanceByName("ps_accounts");
            $accountPresenterService =
                $accountsModule->getService('PrestaShop\Module\PsAccounts\Presenter\PsAccountsPresenter');

            Media::addJsDef([
                'contextPsAccounts' => $accountPresenterService->present($this->name),
            ]);
        }
        */
        if ($moduleManager->isInstalled('ps_eventbus')) {
            $eventbusModule = \Module::getInstanceByName('ps_eventbus');
            if (isset($eventbusModule->version) && version_compare($eventbusModule->version, '1.9.0', '>=')) {
                // also use is_callable ?
                if (!method_exists($eventbusModule, 'getService')) {
                    throw new ErrorException("getService doesn't exist on ps_eventbus");
                }
                $eventbusPresenterService =
                    $eventbusModule->getService('PrestaShop\Module\PsEventbus\Service\PresenterService');

                Media::addJsDef([
                    'contextPsEventbus' => $eventbusPresenterService->expose($this, [
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
                    ]),
                ]);
            }
        }

        return $output;
    }

    /**
     * Create the form that will be displayed in the configuration of your module.
     *
     * @return string
     */
    protected function renderForm()
    {
        $helper = new HelperForm();

        $helper->show_toolbar = false;
        $helper->table = $this->table;
        $helper->module = $this;
        $helper->default_form_language = $this->context->language->id;
        $helper->allow_employee_form_lang = Configuration::get('PS_BO_ALLOW_EMPLOYEE_FORM_LANG', 0);

        $helper->identifier = $this->identifier;

        return $helper->generateForm([$this->getConfigForm()]);
    }

    /**
     * Create the structure of your form.
     *
     * @return array
     */
    protected function getConfigForm()
    {
        return [];
    }

    /**
     * Set values for the inputs.
     *
     * @return array
     */
    protected function getConfigFormValues()
    {
        return [];
    }
}
