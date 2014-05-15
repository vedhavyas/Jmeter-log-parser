#!/usr/bin/perl
use strict;
use warnings;
my %hash;
my %hashTotal;
my %latency;
my $flag1=0;
my $flag_ini=0;
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
	if($flag_ini != 0){
		chomp $line;
		my @fields = split "," , $line;
		chop $fields[0];
		chop $fields[0];
                chop $fields[0];  
		if(!$hash{$fields[0]}){
			$hash{$fields[0]}={'sucess'=>0,'failureHttp'=>0,'failureVal'=>0,'minDelay'=>0,'maxDelay'=>0,'totalDelay'=>0,'avgDelay'=>0};
			$hash{$fields[0]}{'minDelay'} = -1;
			$hash{$fields[0]}{'maxDelay'} = -1;
#print $hash{$fields[0]}{'maxDelay'}."\n";
		}
		if($fields[3]==200){
			if($fields[7] eq "true"){
				$hash{$fields[0]}{'sucess'}++;
				$hashTotal{'total'}{'sucess'}++;
				if($hash{$fields[0]}{'minDelay'} == -1){
					$hash{$fields[0]}{'minDelay'} = $fields[10];
				}
				if($hash{$fields[0]}{'minDelay'} >  $fields[10]){
					$hash{$fields[0]}{'minDelay'} = $fields[10];
				}
				if($hash{$fields[0]}{'maxDelay'} <  $fields[10]){
					$hash{$fields[0]}{'maxDelay'} = $fields[10];
				}
				for(my $i=1;$i<$num;$i++){
					if($fields[10]<$ARGV[$i]){
						$latency{$ARGV[$i]}++;
						last;
					}
				}

				$hash{$fields[0]}{'totalDelay'} = $hash{$fields[0]}{'totalDelay'} + $fields[10];
				$hashTotal{'total'}{'totalDelay'} = $hashTotal{'total'}{'totalDelay'} + $fields[10];
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
		$flag_ini=1;
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
print "----------------------------------------\n";
print "|Total|".$hashTotal{'total'}{'sucess'}."|".$hashTotal{'total'}{'failureHttp'}."|".$hashTotal{'total'}{'failureVal'}."|".$hashTotal{'total'}{'avgDelay'}."|".$hashTotal{'total'}{'totalDelay'}."|".$hashTotal{'total'}{'minDelay'}."|".$hashTotal{'total'}{'maxDelay'}."|\n";
print "----------------------------------------\n";

for (my $i=1;$i<$num;$i++){
	print $prevK." - ".$ARGV[$i]." = ".$latency{$ARGV[$i]}."\n";
	$prevK = $ARGV[$i];
}

