<?php
$host = getenv('OJS_DB_HOST');
$user = getenv('OJS_DB_USER');
$pass = getenv('OJS_DB_PASSWORD');
$db = getenv('OJS_DB_NAME');

$pdo = new PDO("pgsql:host=$host;dbname=$db", $user, $pass);
$pdo->exec("DROP SCHEMA public CASCADE; CREATE SCHEMA public; GRANT ALL ON SCHEMA public TO public;");
echo "DB Wiped.\n";

$cfg = '/var/www/html/config.inc.php';
if (file_exists($cfg)) {
    $content = file_get_contents($cfg);
    $content = str_replace('installed = On', 'installed = Off', $content);
    file_put_contents($cfg, $content);
    echo "Config reset.\n";
}
?>
