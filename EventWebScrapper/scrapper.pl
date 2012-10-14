#!/usr/bin/perl
use strict;
use warnings;
use WWW::Mechanize;
use HTML::TreeBuilder::XPath;

sub ltrim($)
{
	my $string = shift;
	$string =~ s/^\s+//;
	return $string;
}

# From the timeout TKO homepage, go and find all the weeekend recommened event pages links
sub getTimeoutEventURLs
{
	my $mech = $_[0];
	
	# just scraping one webpage for now...
	my $url = "http://www.timeout.jp/en/tokyo";
	$mech->get( $url );
	# TODO: get events for all days in the weekend, not just Fri
	$mech->follow_link( text_regex => qr/30 things to do this weekend/i );
	my $html = $mech->content();
	my @links = $mech->links();
	# my @links = $html =~ m/http[/]*tokyo\/event/g;
	
	my %setoflinks;
	my $line;
	foreach $line (@links)
	{
		my $absURL = $line->url_abs();
		if(!exists $setoflinks{$absURL})
		{
			if($absURL =~ m/http.*tokyo\/event/g)
			{
				$setoflinks{$absURL}=1;
			}
		}
	}

	return %setoflinks;
}

# Go to each event page and try and pull the necessary event info
sub getTimeoutEventInfo
{
	my ($mech, $timeoutEventURLs) = @_;
	
	my $link;
	foreach $link (keys %$timeoutEventURLs)
	{
		$$mech->get( $link );
		my $title = $$mech->title();
		print "Visiting... ", $link, ", ", $title, "\n";
		
		my $content = $$mech->content();
		my $tree = HTML::TreeBuilder::XPath->new;
		$tree->parse($content);

		# print $content;

		my $eventTitle = $tree->findvalue('//meta[@property="og:title"]/@content');
		my $eventDescription = $tree->findvalue('//meta[@property="og:description"]/@content');
		
		my $eventDates = $tree->findvalue('//div[@id="event-details"]//p/strong/span[contains(.,"Open")]/../..');
		$eventDates =~ s/Open //;	

		my $eventTime = $tree->findvalue('//div[@id="event-details"]//p/strong/span[contains(.,"Time")]/../..');
		$eventTime =~ s/Time //;
		
		my $eventAdmission = $tree->findvalue('//div[@id="event-details"]//p/strong/span[contains(.,"Admission")]/../..');
		$eventAdmission =~ s/Admission //;
		$eventAdmission = ltrim($eventAdmission);

		my $eventURL = $tree->findvalue('//div[@id="event-details"]//p/strong/span[contains(.,"URL")]/../../a/@href');
		$eventURL =~ s/ //g;
		
		print "Title: ", $eventTitle, "\nDescription: ", $eventDescription, "\nDates: ", $eventDates, "\nTime: ", $eventTime, "\nAdmission Price: ", $eventAdmission, "\nURL: ", $eventURL, "\n\n";	
	}
}

# create an instance of mechanise with autochecking turned on
my $mech = WWW::Mechanize->new( autocheck => 1 );

# my %timeoutEventURLs = getTimeoutEventURLs($mech);
my %timeoutEventURLs = ( 'http://www.timeout.jp/en/tokyo/event/6211/Traxman',1);
getTimeoutEventInfo(\$mech,\%timeoutEventURLs);



# print $html;
# print "$months\n";
# print "$events\n";



