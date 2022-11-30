<?php

/**
 * 2007-2022 PrestaShop
 *
 * NOTICE OF LICENSE
 *
 * This source file is subject to the Academic Free License (AFL 3.0)
 * that is bundled with this package in the file LICENSE.txt.
 * It is also available through the world-wide-web at this URL:
 * http://opensource.org/licenses/afl-3.0.php
 * If you did not receive a copy of the license and are unable to
 * obtain it through the world-wide-web, please send an email
 * to license@prestashop.com so we can send you a copy immediately.
 *
 * DISCLAIMER
 *
 * Do not edit or add to this file if you wish to upgrade PrestaShop to newer
 * versions in the future. If you wish to customize PrestaShop for your
 * needs please refer to http://www.prestashop.com for more information.
 *
 *  @author    PrestaShop SA <contact@prestashop.com>
 *  @copyright 2007-2022 PrestaShop SA
 *  @license   http://opensource.org/licenses/afl-3.0.php  Academic Free License (AFL 3.0)
 *  International Registered Trademark & Property of PrestaShop SA
 */

use Prestashop\AddonsHelper\AddonsHelper;

if (!defined('_PS_VERSION_')) {
    exit;
}

class Ps_tech_vendor_boilerplate extends Module
{
    public function __construct()
    {
        $this->name = 'ps_tech_vendor_boilerplate';
        $this->tab = 'content_management';
        $this->version = '1.0.0';
        $this->author = 'Mika';
        $this->need_instance = 0;

        /**
         * Set $this->bootstrap to true if your module is compliant with bootstrap (PrestaShop 1.6)
         */
        $this->bootstrap = true;

        parent::__construct();

        require_once __DIR__ . '/vendor/autoload.php';

        $this->displayName = $this->l('Cloudsync module template');
        $this->description = $this->l('This is a template module for Cloudsync');

        $this->ps_versions_compliancy = array('min' => '1.6', 'max' => _PS_VERSION_);
    }

    public function install()
    {
        return parent::install();
    }

    public function uninstall()
    {
        return parent::uninstall();
    }

    /**
     * Load the configuration form
     */
    public function getContent()
    {

        $this->context->smarty->assign('module_dir', $this->_path);

        $output = $this->context->smarty->fetch($this->local_path . 'views/templates/admin/configure.tpl');

        $addonsHelper = new AddonsHelper();


        $eventbusModule = $addonsHelper->getModule('ps_eventbus', '1.9.0');
        if ($eventbusModule) {
            $eventbusPresenterService = $eventbusModule->getService('PrestaShop\Module\PsEventbus\Service\PresenterService');

            Media::addJsDef([
                'contextPsEventbus' => $eventbusPresenterService->expose($this, ['info', 'modules', 'themes', 'orders'])
            ]);
        }


        Media::addJsDef([
            'moduleInstallerHelper' => $addonsHelper->expose(),
        ]);

        return $output;
    }

    /**
     * Create the form that will be displayed in the configuration of your module.
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

        return $helper->generateForm(array($this->getConfigForm()));
    }

    /**
     * Create the structure of your form.
     */
    protected function getConfigForm()
    {
        return array();
    }

    /**
     * Set values for the inputs.
     */
    protected function getConfigFormValues()
    {
        return array();
    }
}
