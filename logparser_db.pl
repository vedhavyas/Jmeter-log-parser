#!/usr/bin/perl
use strict;
use warnings;
use DBI;
use Time::Local;

my %hashTotal;
my %hash;
my %latency;
#configurable params
my @tables=("rbt_subscriber_tone_info");
my @columnList=("Updated_Timestamp");
my @paramList=("subscriberId","toneId");
my $crossCheck=2;   
my $toneOperation=0;
#
my @mapList=(0,0);
my $sql;
my $sth;
my $dbh = DBI->connect("DBI:mysql:database=test;host=172.19.4.18;port=3306",'test', 'test123') or die "Connection Error: $DBI::errstr\n";
my $flag1=0;
my $flagIni=0;
my $flag2=0;
my $prevK=0;
my $file = $ARGV[0] or die "Need to get CSV file on the command line\n";
my $num = $#ARGV + 1;
system("dos2unix $file");

open(my $data, '<', $file) or die "Could not open '$file' $!\n";

$hashTotal{'total'}={'sucess'=>0,'failureHttp'=>0,'failureVal'=>0,'totalDelay'=>0,'avgDelay'=>0,'minDelay'=>0,'maxDelay'=>0};

for (my $i=1;$i<$num;$i++){
	$latency{$ARGV[$i]}=0;
}

while (my $line = <$data>) {
	if($flagIni != 0){
		chomp $line;
		my @fields = split(',' , $line);
		chop $fields[0];
		chop $fields[0];
		chop $fields[0];
		if(!$hash{$fields[0]}){
			$hash{$fields[0]}={'sucess'=>0,'failureHttp'=>0,'failureVal'=>0,'minDelay'=>0,'maxDelay'=>0,'totalDelay'=>0,'avgDelay'=>0};
			$hash{$fields[0]}{'minDelay'} = -1;
			$hash{$fields[0]}{'maxDelay'} = -1;
		}
		my @values = split('&', $fields[9]);

		foreach my $val (@values) {
			my @values2 = split('=', $val);
			foreach my $val2 (@values2) {
				if($val2 eq $paramList[0]){
					$mapList[0]=$values2[1];
				}
				if(@paramList == 2){
					if($val2 eq $paramList[1]){
						$mapList[1]=$values2[1];
					}
				}

			}
		}	

		if($fields[3]==200){
			if($fields[7] eq "true"){
				$hash{$fields[0]}{'sucess'}++;
				$hashTotal{'total'}{'sucess'}++;
				if($crossCheck == 2){
					$sql = "Select ".$columnList[0]." from ".$tables[0]." where subscriber_msisdn=".$mapList[0]." and rbt_tone_id=".$mapList[1];
				}
				if($crossCheck == 1){
					$sql = "Select ".$columnList[0]." from ".$tables[0]." where subscriber_msisdn=".$mapList[0];
				}
				if($toneOperation == 1){
					$sql=$sql." and Tone_Operation in (3,6)";
				}
				$sth = $dbh->prepare($sql);
				$sth->execute or die "SQL Error: $DBI::errstr\n";
				my @row = $sth->fetchrow_array;
				my @timeStamp=split(' ',$row[0]);
				my @dateSplit=split('-',$timeStamp[0]);
				my @timeSplit=split(':',$timeStamp[1]);
				my $time = timelocal($timeSplit[2],$timeSplit[1],$timeSplit[0],$dateSplit[2],$dateSplit[1],$dateSplit[0]);
				my $delay = $time - $fields[0];
				if($hash{$fields[0]}{'minDelay'} == -1){
					$hash{$fields[0]}{'minDelay'} = $delay;
				}
				if($hash{$fields[0]}{'minDelay'} >  $delay){
					$hash{$fields[0]}{'minDelay'} = $delay;
				}
				if($hash{$fields[0]}{'maxDelay'} <  $delay){
					$hash{$fields[0]}{'maxDelay'} = $delay;
				}
				for(my $i=1;$i<$num;$i++){
					if($delay<$ARGV[$i]){
						$latency{$ARGV[$i]}++;
						last;
					}
				}
				$hash{$fields[0]}{'totalDelay'} = $hash{$fields[0]}{'totalDelay'} + $delay;
				$hashTotal{'total'}{'totalDelay'} = $hashTotal{'total'}{'totalDelay'} + $delay;
			}
			else{
				$hash{$fields[0]}{'failureVal'}++;
				$hashTotal{'total'}{'failureVal'}++;
			}
		}
		else{
			$hash{$fields[0]}{'failureHttp'}++;
			$hashTotal{'total'}{'failureHttp'}++;
		}
	}
	else{
		$flagIni=1;
		next;
	}
}

foreach my $k (keys %hash){
	if($flag1 == 0){
		$hashTotal{'total'}{'minDelay'} = $hash{$k}{'minDelay'};
		$hashTotal{'total'}{'maxDelay'} = $hash{$k}{'maxDelay'};
		$flag1 = 1;
	}
	if($hashTotal{'total'}{'minDelay'} > $hash{$k}{'minDelay'}){
		$hashTotal{'total'}{'minDelay'} = $hash{$k}{'minDelay'};
	}
	if($hashTotal{'total'}{'maxDelay'} <  $hash{$k}{'maxDelay'}){
		$hashTotal{'total'}{'maxDelay'} = $hash{$k}{'maxDelay'};
	}
	if($hash{$k}{'sucess'} !=0){
		$hash{$k}{'avgDelay'} = $hash{$k}{'totalDelay'} / $hash{$k}{'sucess'};
                $hash{$k}{'avgDelay'} = sprintf("%.2f", $hash{$k}{'avgDelay'}); 
	}
	else{
		$hash{$k}{'avgDelay'} = 0;
	}
}
if($hashTotal{'total'}{'sucess'} !=0){
	$hashTotal{'total'}{'avgDelay'} = $hashTotal{'total'}{'totalDelay'} / $hashTotal{'total'}{'sucess'};
        $hashTotal{'total'}{'avgDelay'} = sprintf("%.2f", $hashTotal{'total'}{'avgDelay'});
}
else{
	$hashTotal{'total'}{'avgDelay'}=0;
}

print "----------------------------------------------------------------------------------------------------\n";
print "|Time Stamp|Sucess|Failure(HTTP)|Failure(val)|Average Delay|Total Delay|Minimum Delay|Maximum Delay| \n";
print "----------------------------------------------------------------------------------------------------\n";
foreach my $k (sort keys %hash){
        print "|".$k."|".$hash{$k}{'sucess'}."|".$hash{$k}{'failureHttp'}."|".$hash{$k}{'failureVal'}."|".$hash{$k}{'avgDelay'}."|".$hash{$k}{'totalDelay'}."|".$hash{$k}{'minDelay'}."|".$hash{$k}{'maxDelay'}."|\n";
}
print "---------------------------------------------------------------------------------------------------\n";
print "|Total|".$hashTotal{'total'}{'sucess'}."|".$hashTotal{'total'}{'failureHttp'}."|".$hashTotal{'total'}{'failureVal'}."|".$hashTotal{'total'}{'avgDelay'}."|".$hashTotal{'total'}{'totalDelay'}."|".$hashTotal{'total'}{'minDelay'}."|".$hashTotal{'total'}{'maxDelay'}."|\n";
print "---------------------------------------------------------------------------------------------------\n";

for (my $i=1;$i<$num;$i++){
        print $prevK." - ".$ARGV[$i]." = ".$latency{$ARGV[$i]}."\n";
        $prevK = $ARGV[$i];
}
