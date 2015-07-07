#!/usr/bin/env perl
# ### Student No. s3407908
# ### Student Name: James Nicastri
# ### Subject: Scripting Language Programming 
# ### Study Period: SP1 2015
# ### Assignment 1
use strict;
use warnings;
use constant {
	H1_REGEX => qr /^#[^#][^#].*/,
	H2_REGEX => qr /^##[^#].*/,
	H3_REGEX => qr /^###[^#].*/,
	BOLD_REGEX => qr /.*\*\*.*\*\*.*/,
	EMPHASIS_REGEX => qr /.*\*.*\*.*/,
	CODE_BLOCK_REGEX => qr /^(    |\t).*/,
	LIST_ITEM_REGEX => qr /^( *\* .*| *[0-9] .*)/,
	UNORDERED_LIST_ITEM_REGEX => qr /^( *\* .*)/,
	ORDERED_LIST_ITEM_REGEX => qr /^( *[0-9] .*)/,
	HYPERLINK_REGEX => qr /^.*\[.*\]\(http:\/\/.*\).*/,
	QUOTES_REGEX => qr /.*\".*\".*/,
};

# Check number of command args
die "Expected two commands arguments - $0 [input file] [output file]" unless exists($ARGV[0]) && exists($ARGV[1]);

#Opening/Creating Files
open(my $inFile, $ARGV[0]) || die "Opening file $ARGV[0] has failed: $!";
open(our $outFile, ">$ARGV[1]") || die "Opening or creating file $ARGV[1] has failed: $!";

#Loop through each line in the input file and determine necessary operation
my $currentLine;
our $listsOpen = 0;
our @currentlyOpenList;
our %listDepths = (ul => 0, ol => 0);

while($currentLine = <$inFile>){
	
	if($currentLine =~ H1_REGEX){
		while($listsOpen != 0){
			closeList();
			$listsOpen -= 1;
		 }
		processH1($currentLine);
	}
	elsif($currentLine =~ H2_REGEX){
		while($listsOpen != 0){
			closeList();
			$listsOpen -= 1;
		}
		processH2($currentLine);
	}
	elsif($currentLine =~ H3_REGEX){
		while($listsOpen != 0){
			closeList();
			$listsOpen -= 1;
		}
		processH3($currentLine);
	}
	elsif($currentLine =~ CODE_BLOCK_REGEX){
		while($listsOpen != 0){
			closeList();
			$listsOpen -= 1;
		}	
		processCodeBlock($currentLine);

	}
	elsif($currentLine =~ LIST_ITEM_REGEX){
		#print $currentLine;
		processList($currentLine);	
	}
	elsif($currentLine =~ QUOTES_REGEX){
		while($listsOpen != 0){
			closeList();
			$listsOpen -= 1;
		}
		processLineWithQuote($currentLine);
	}
	elsif($currentLine =~ BOLD_REGEX){
		while($listsOpen != 0){
			closeList();
			$listsOpen -= 1;
		}
		processStrongText($currentLine); 
	}
	elsif($currentLine =~ EMPHASIS_REGEX){

		while($listsOpen != 0){
			closeList();
			$listsOpen -= 1;
		}
		processEmphasisText($currentLine);
	}
	elsif($currentLine =~ HYPERLINK_REGEX){
		while($listsOpen != 0){
			closeList();
			$listsOpen -= 1;
		}
		processHyperLink($currentLine);
	}
	else{
		while($listsOpen != 0){
			closeList();
			$listsOpen -= 1;
		}
		$currentLine =~ s/[\r\n]+$//;
		print $outFile $currentLine . "<br />\n";
	}
}

#Closing file handles
close $inFile;
close $outFile;


sub processH1{
	# remove prefix & replace with tag
	$_[0] =~ s/^#/<h1>/;
	
	# remove \n from end of line
	$_[0] =~ s/[\r\n]+$//;

	print $outFile $_[0] . "</h1>\n";	
}

sub processH2{
	
	#remove prefix, replace with opening tag
	$_[0] =~ s/^##/<h2>/;

	#remove \n from end
	$_[0] =~ s/[\r\n]+$//;

	print $outFile $_[0] . "</h2>\n";
}

sub processH3{
	
	#remove prefix, replace with opening tag
	$_[0] =~ s/^###/<h3>/;

	#remove \n from end
	$_[0] =~ s/[\r\n]+$//;

	print $outFile $_[0] . "</h3>\n";	
}

sub processStrongText{
	
	my $moreToProcess = 1;
	
	while($moreToProcess != 0){
		$_[0] =~ s/\*\*/<strong>/;
		$_[0] =~ s/\*\*/<\/strong>/;
		
		# Checking to see if there are anymore to change
		if ($_[0] !~ BOLD_REGEX){ $moreToProcess = 0; }
	}
	
	$_[0] =~ s/[\r\n]+$//;
	print $outFile $_[0] . "<br />\n";
		
}

sub processEmphasisText{
	
	my $moreToProcess = 1;
	
	while($moreToProcess != 0){
		$_[0] =~ s/\*/<em>/;
		$_[0] =~ s/\*/<\/em>/;
		
		# Checking to see if there are any more to change
		if ($_[0] !~ EMPHASIS_REGEX){ $moreToProcess = 0; }
	}
	
	$_[0] =~ s/[\r\n]+$//;
	print $outFile $_[0] . "<br />\n";
		
	}

sub processCodeBlock{
	
	# Remove tabs, leading whitepace and end of line \n, and add opening tags
	$_[0] =~ s/^(    |\t)/<pre><code>/;
	$_[0] =~ s/[\r\n]+$//;

	#add closing tags and \n
	print $outFile $_[0] . "</code></pre>\n";
	
}

sub processList{
		
	if($_[0] =~ UNORDERED_LIST_ITEM_REGEX){
		
		#Get the indent level of the current list item
		$_[0] =~ /^(\s*)/;		
		my $unorderedDepth = length($1) + 1;		
	
		#checking to see if we need to close or open a list before adding the <li>
		if(($unorderedDepth > $listDepths{ul}) || ($listDepths{ul} == 0)){
			#A new list is needed
			print $outFile "<ul>\n";
			$listsOpen += 1;
			push(@currentlyOpenList, "ul"); 
			$listDepths{ul} += 1;
		}
		elsif($unorderedDepth < $listDepths{ul}){
			#Need to close a list before adding a new <li>

			while($unorderedDepth != $listDepths{ul}){
				$listsOpen -= 1;
				$listDepths{ul} -= 1;
				closeList();
			}
		}

		$_[0] =~ s/^(\s*\* )/<li>/;
		$_[0] =~ s/[\r\n]+$//;
		print $outFile $_[0] . "</li>\n";
			
	}
	elsif($_[0] =~ ORDERED_LIST_ITEM_REGEX){
	
		# Get amount of space the list item is indented by
		$_[0] =~ /^(\s*)/;		
		my $orderedDepth = length($1) + 1;		

		#checking to see if we need to close or open a list before adding the <li>
		if(($orderedDepth > $listDepths{ol}) || ($listDepths{ol} == 0)){
			#A new nested list is needed
			print $outFile "<ol>\n";
			$listsOpen += 1;
			push(@currentlyOpenList, "ol"); 
			$listDepths{ol} += 1;
		}
		elsif($orderedDepth < $listDepths{ol}){
			#Need to close a list before adding a new <li>
			while($orderedDepth != $listDepths{ol}){
				$listsOpen -= 1;
				$listDepths{ol} -= 1;
				closeList();
			}
		}

		$_[0] =~ s/(\s*[0-9] )/<li>/;
		$_[0] =~ s/[\r\n]+$//;
		print $outFile $_[0] . "</li>\n";
			
	}

}

sub processHyperLink{

	(my $displayTitle, my $url) = $_[0] =~ m/(\[.*\])(\(http:\/\/.*\))/;
		
	$displayTitle =~ s/\[//;
	$displayTitle =~ s/\]//;
	$url =~ s/\(//;
	$url =~ s/\)//;
		
	my $anchor = "<a href=\"" . $url . "\">" . $displayTitle . "</a>";
	
	$_[0] =~ s/\[.*\]\(http:\/\/.*\)/$anchor/;
	
	
	$_[0] =~ s/[\r\n]+$//;
	print $outFile $_[0] . "<br />\n";
}

sub closeList{
	
	my $list = pop(@currentlyOpenList);
	
	if($list){
		if($list eq "ul"){
			print $outFile "</ul>\n";
		}
		elsif($list eq "ol"){
			print $outFile "</ol>\n";
		}
	}
}	

sub processLineWithQuote{

	if($_[0] !~ BOLD_REGEX && $_[0] !~ EMPHASIS_REGEX && $_[0] !~ HYPERLINK_REGEX){

		# there is no other potential tag in the string - process as normal
		$_[0] =~ s/[\r\n]+$//;
		print $outFile $_[0] . "<br />\n";
		return;
	}

	my $currentOperation = $_[0];
        $currentOperation =~ s/"(.+?)"/___QUOTE_PH___/;

	if($currentOperation =~ BOLD_REGEX){
		my $matches = 1;
		
		while($matches == 1){	
	
			$currentOperation =~ s/\*\*/<strong>/;
			$currentOperation =~ s/\*\*/<\/strong>/;
		
			# Checking to see if there are anymore to change
			if($currentOperation !~ BOLD_REGEX){ $matches = 0; }		
		}
	}

	if($currentOperation =~ EMPHASIS_REGEX){

		my $matches = 1;
		
		while($matches == 1){	
	
			$currentOperation =~ s/\*/<em>/;
			$currentOperation =~ s/\*/<\/em>/;
		
			# Checking to see if there are anymore to change
			if($currentOperation !~ EMPHASIS_REGEX){ $matches = 0; }		
		}
	}

	if($currentOperation =~ HYPERLINK_REGEX){

		my $matches = 1;
		
		while($matches == 1){	
	
			(my $displayTitle, my $url) = $currentOperation =~ m/(\[.*\])(\(http:\/\/.*\))/;
		
			$displayTitle =~ s/\[//;
			$displayTitle =~ s/\]//;
			$url =~ s/\(//;
			$url =~ s/\)//;
		
			my $anchor = "<a href=\"" . $url . "\">" . $displayTitle . "</a>";
	
			$currentOperation =~ s/\[.*\]\(http:\/\/.*\)/$anchor/;
		
			# Checking to see if there are anymore to change
			if($currentOperation !~ HYPERLINK_REGEX){ $matches = 0; }		
		}
	}
	
	(my $quotedText) = $_[0] =~ m/"(.+?)"/g;
	$currentOperation =~ s/___QUOTE_PH___/"$quotedText"/;

	
	$currentOperation =~ s/[\r\n]+$//;
	print $outFile $currentOperation . "<br />\n";

}
