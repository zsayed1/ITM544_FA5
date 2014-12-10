<!DOCTYPE html>

<head>
	<title>IITM 544 Cloud</title>
        <meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
    	
        <link href="design.css" rel="stylesheet" type="text/css" />
		</head>

<body>

   
<div id="page">

 	<div class="titre">
   	ITM 544 CLOUD
   	</div>  

<div class="element2">
<div class="form";">
	<p><h3>Please enter your information before uploading your file</h3></p>
	<form enctype="multipart/form-data" action="result.php" method="POST">
	<input name="login" type="text" placeholder="Your Name" size="40"><p>
	<input name="email" type="text" placeholder="Your Email" size="40"><p>
	<input name="cellphone" type="text" placeholder="Your Cellphone" size="20"><p>
	<input type="hidden" name="MAX_FILE_SIZE" value="30000000" />
	<input name="userfile" type="file" />
	<input type="submit" value="Send File" />
</form>

</div>

<footer>
Arthur CLOUET - ITM 544 CLOUD 
</footer>

</div>
</body>

</html>

