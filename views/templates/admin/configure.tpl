{*
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
*}
<script src="${MSC_UI_URL}"></script>
<div class="panel">
	<h3><i class="icon icon-credit-card"></i> CloudSync module example</h3>
	<p>
		<strong>Here is my new generic module!</strong><br />
		Thanks to PrestaShop, now I have a great module.<br />
		I can configure it using the following configuration form.
	</p>
	<br />
	<p>
		This module will boost your sales!
	</p>
</div>

<div id="prestashop-cloudsync"></div>
<script>
  const cdc = window.cloudSyncSharingConsent;

  cdc.init('#prestashop-cloudsync');
  cdc.on('OnboardingCompleted', (isCompleted) => {
    console.log('OnboardingCompleted', isCompleted);
  });
  cdc.isOnboardingCompleted((isCompleted) => {
    console.log('Onboarding is already Completed', isCompleted);
  });
</script>
