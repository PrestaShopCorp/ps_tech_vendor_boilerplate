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

namespace PrestaShop\Module\PsTechVendorBoilerplate\Controller\Admin;

use PrestaShopBundle\Controller\Admin\FrameworkBundleAdminController;
use Prestashop\ModuleLibMboInstaller\Installer as MBOInstaller;
use Symfony\Component\HttpFoundation\Request;
use Symfony\Component\HttpFoundation\Response;

class BoilerplateResolverController extends FrameworkBundleAdminController
{
    /**
     * @var \Ps_tech_vendor_boilerplate
     */
    private $module;

    public function __construct()
    {
        $this->module = \Module::getInstanceByName('ps_tech_vendor_boilerplate');
    }

    /**
     * Api endpoint
     *
     * @param Request $request
     * @param string $query
     *
     * @return Response
     *
     * @throws \Exception
     */
    public function resolve(Request $request, string $query)
    {
        try {
            if (is_callable([$this, $query])) {
                /** @var callable $args */
                $args = [$this, $query];

                /** @var Response $result */
                $result = call_user_func($args);

                return $result;
            }
        } catch (\Throwable $th) {
            throw new \Exception('#001 Message : ' . $th->getMessage());
        }

        return new Response('Not found', 404);
    }

    /**
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

    /**
     * Return dependencies information
     * 
     * @return Response
     */
    public function getModulesInformation(): Response
    {
        $moduleHelper = $this->module->get('PrestaShop\Module\PsTechVendorBoilerplate\Helper\ModuleHelper');

        if (!$moduleHelper) {
            return new Response('Module helper not found', 404);
        }

        $modulesInformation = [
            'eventBus' => $moduleHelper->buildModuleInformation(
                'ps_eventbus'
            ),
            'accounts' => $moduleHelper->buildModuleInformation(
                'ps_accounts'
            ),
        ];

        return new Response(json_encode($modulesInformation, JSON_FORCE_OBJECT), 200, [
            'Content-Type' => 'application/json',
        ]);
    }
}
