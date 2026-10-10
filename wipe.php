<?php
$host = getenv('OJS_DB_HOST');
$user = getenv('OJS_DB_USER');
$pass = getenv('OJS_DB_PASSWORD');
$db = getenv('OJS_DB_NAME');

try {
    $pdo = new PDO("pgsql:host=$host;dbname=$db", $user, $pass);
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
    $pdo->exec("DROP SCHEMA public CASCADE; CREATE SCHEMA public; GRANT ALL ON SCHEMA public TO public;");
    echo "Database wiped successfully.\n";
    
    // Also remove the config file to force re-installation
    if (file_exists('/var/www/files/config.inc.php')) {
        unlink('/var/www/files/config.inc.php');
        echo "Config file deleted.\n";
    }
} catch (PDOException $e) {
    echo "Error wiping database: " . $e->getMessage() . "\n";
}
?>
