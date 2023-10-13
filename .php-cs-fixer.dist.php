<?php

$config = new PrestaShop\CodingStandards\CsFixer\Config();

/** @var \Symfony\Component\Finder\Finder $finder */
$finder = $config->setUsingCache(true)->getFinder();
$finder
    ->in(__DIR__)
    ->exclude('translations')
    ->exclude('prestashop')
    ->exclude('vendor');

return $config;
