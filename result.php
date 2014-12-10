<!DOCTYPE html>
<html>
<body>
<?php

session_start ();

$_SESSION['login'] = $_POST['login'];
$_SESSION['email'] = $_POST['email'];
$_SESSION['cellphone'] = $_POST['cellphone'];

$uploaddir = '/var/www/uploads/';
$uploadfile = $uploaddir . basename($_FILES['userfile']['name']);

echo '<pre>';
if (move_uploaded_file($_FILES['userfile']['tmp_name'], $uploadfile)) {
	echo "File is valid, and was successfully uploaded.\n";
} else {
	echo "Possible file upload attack!\n";
}

echo 'Here is some more debugging info:';
print_r($_FILES);

print "</pre>";

// Include the SDK using the Composer autoloader
require 'vendor/autoload.php';

use Aws\S3\S3Client;

$client = S3Client::factory();

$bucket = uniqid("php-arthurma4-", true);
echo "Creating bucket named {$bucket}\n";
$result = $client->createBucket(array(
    'Bucket' => $bucket
));

// Wait until the bucket is created
$client->waitUntilBucketExists(array('Bucket' => $bucket));

$key = $uploadfile;
echo "Creating a new object with key {$key}";
echo "<br />";
$result = $client->putObject(array(
	'ACL' => 'public-read',
    'Bucket' => $bucket,
    'Key'    => '$key',
    'SourceFile'   => $uploadfile
));

echo $result['ObjectURL'] . "<br />";
echo "<br />";

$url = $result['ObjectURL'];

echo "Your Name is {$_SESSION['login']}";
echo "<br />";
echo "Your Email is {$_SESSION['email']}";
echo "<br />";
echo "Your Cellphone is {$_SESSION['cellphone']}";
echo "<br />";
?>

<br>
<img src="<?php echo $url; ?>" alt="picture">

</body>
</html>
