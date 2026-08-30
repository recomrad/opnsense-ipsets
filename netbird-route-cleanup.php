#!/usr/local/bin/php

<?php

/**
 * Remove conflicting WAN host routes.
 *
 * Problem:
 * NetBird may create /32 routes via WAN for ICE/P2P candidates.
 * If such a host belongs to a subnet routed through NetBird (wt0),
 * the /32 route wins over the subnet route due to longest-prefix match.
 *
 * This script removes only:
 *
 *   HOST routes via WAN_IF
 *
 * where destination belongs to any IPv4 CIDR routed through VPN_IF.
 */

const WAN_IF = 'pppoe0';
const VPN_IF = 'wt0';
const LOG_TAG = 'netbird-route-cleanup';

/**
 * Execute command and return output lines.
 */
function cmd(string $command): array
{
    exec($command . ' 2>&1', $output, $exitCode);

    if ($exitCode !== 0) {
        throw new RuntimeException(
            "Command failed ({$exitCode}): {$command}\n" .
            implode("\n", $output)
        );
    }

    return $output;
}

/**
 * Check whether IPv4 address belongs to CIDR network.
 */
function ipInCidr(string $ip, string $cidr): bool
{
    [$network, $prefix] = explode('/', $cidr, 2);
    $prefix = (int)$prefix;

    $ipLong = ip2long($ip);
    $networkLong = ip2long($network);

    if ($ipLong === false || $networkLong === false) {
        return false;
    }

    /*
     * ip2long() returns signed integer.
     * Convert to unsigned representation.
     */
    $ipLong = sprintf('%u', $ipLong);
    $networkLong = sprintf('%u', $networkLong);

    $ipLong = (float)$ipLong;
    $networkLong = (float)$networkLong;

    if ($prefix === 0) {
        return true;
    }

    $blockSize = pow(2, 32 - $prefix);

    return floor($ipLong / $blockSize)
        === floor($networkLong / $blockSize);
}

/**
 * Logging.
 */
function logMessage(string $message): void
{
    $tag = escapeshellarg(LOG_TAG);
    $msg = escapeshellarg($message);

    exec("/usr/bin/logger -t {$tag} {$msg}");
}

/**
 * Get routing table.
 */
$routes = cmd('/usr/bin/netstat -rn -f inet');

/*
 * Collect all IPv4 networks routed through VPN_IF.
 *
 * Expected format:
 *
 * Destination        Gateway        Flags     Netif
 */
$vpnNetworks = [];

foreach ($routes as $line) {
    $columns = preg_split('/\s+/', trim($line));

    if (count($columns) < 4) {
        continue;
    }

    $destination = $columns[0];
    $interface = end($columns);

    if ($interface !== VPN_IF) {
        continue;
    }

    /*
     * Only CIDR subnet routes.
     * Ignore host routes and default route.
     */
    if (
        preg_match(
            '/^(\d{1,3}\.){3}\d{1,3}\/([0-9]|[12][0-9]|3[0-2])$/',
            $destination
        )
    ) {
        $vpnNetworks[] = $destination;
    }
}

if (empty($vpnNetworks)) {
    logMessage(
        'No IPv4 subnet routes found via ' . VPN_IF
    );
    exit(0);
}

/*
 * Find host routes through WAN.
 *
 * Example:
 *
 * 1.2.3.4  5.6.7.8  UGH1  pppoe0
 */
$deleted = 0;

foreach ($routes as $line) {
    $columns = preg_split('/\s+/', trim($line));

    if (count($columns) < 4) {
        continue;
    }

    $destination = $columns[0];
    $gateway = $columns[1];
    $flags = $columns[2];
    $interface = end($columns);

    /*
     * Only routes via configured WAN interface.
     */
    if ($interface !== WAN_IF) {
        continue;
    }

    /*
     * Only IPv4 host routes.
     */
    if (filter_var($destination, FILTER_VALIDATE_IP, FILTER_FLAG_IPV4) === false) {
        continue;
    }

    /*
     * Must be Gateway + Host route.
     *
     * Example:
     * UGH1
     * UGHS
     *
     * Do not depend on exact flag ordering/version suffix.
     */
    if (
        strpos($flags, 'G') === false ||
        strpos($flags, 'H') === false
    ) {
        continue;
    }

    /*
     * Check whether host belongs to a network routed via NetBird.
     */
    foreach ($vpnNetworks as $network) {

        if (!ipInCidr($destination, $network)) {
            continue;
        }

        $message =
            "Removing conflicting route: " .
            "{$destination}/32 via {$gateway} dev " . WAN_IF .
            " (conflicts with {$network} via " . VPN_IF . ')';

        echo $message . PHP_EOL;
        logMessage($message);

        /*
         * Delete exact host route.
         */
        $command =
            '/sbin/route delete -host ' .
            escapeshellarg($destination) . ' ' .
            escapeshellarg($gateway);

        exec($command . ' 2>&1', $output, $exitCode);

        if ($exitCode !== 0) {
            $error =
                "Failed to delete route {$destination} via {$gateway}: " .
                implode(' ', $output);

            fwrite(STDERR, $error . PHP_EOL);
            logMessage($error);
        } else {
            $deleted++;
        }

        /*
         * One matching network is enough.
         */
        break;
    }
}

//echo "Done. Deleted conflicting routes: {$deleted}" . PHP_EOL;

exit(0);
