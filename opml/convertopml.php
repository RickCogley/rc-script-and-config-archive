<?php 
	function usage(){ 
		return "Usage: php convert.php /path/to/opml_file.opml > output.html\r\n"; 
					} 
	# Print usage if need be. 
	if(count($argv) < 2) die(usage()); 
	# Grab the file path. 
	$f = $argv[1]; 
	# Load it into a SimpleXML. 
	$xml = simplexml_load_file($f); 
	# Output buffer 
	$out = ''; 
	# Run through the nodes in the OPML and buffer the Netscape output 
	foreach($xml->xpath("//outline") as $outline ){ 
		$title = htmlspecialchars($outline['title'], ENT_QUOTES); 
		$feed = htmlspecialchars($outline['xmlUrl']); 
		if($feed){ 
			$out .= "\r\n\t" . '<dt><a href="' . str_replace("http://", "feed://", $feed) . '">' . $title . '</a>'; 
		}else{ 
			$out .= "</dl><p>\r\n<dt><h3>$title</h3><dl><p>"; 
		} 
	} 
	$out .= "\r\n" 
?> 
<!DOCTYPE NETSCAPE-Bookmark-file-1> 
<title>MyBookmarks</title> 
<h1>MyBookmarks</h1> 
<dl><p> 
<?php echo $out; ?> 
</dl>
<p>