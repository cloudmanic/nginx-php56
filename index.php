<!DOCTYPE html>
<html>
<head>
<title>Cloudmanic | Nginx PHP 5.6</title>
<style>
    body {
        text-align: center;
        font-family: Tahoma, Geneva, Verdana, sans-serif;
    }
</style>
</head>
<body>
<h1>Nginx Web Server.</h1>
<p>If you see PHP info below, Nginx with PHP container works.</p>

<p>More instructions about this image is <a href="https://github.com/cloudmanic/nginx-php56" target="_blank">here</a>.<p>
<?php 
    phpinfo() 
?>
</body>
</html>