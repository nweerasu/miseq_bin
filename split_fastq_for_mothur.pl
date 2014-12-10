#!/usr/bin/env perl -w
use strict;

#extract barcoded fastq format into mothur-compatible file lists
#need forward fastq, reverse fastq and samples file as input
#output is to a directory called mothur_fastq
#contains the forward and reverse fastq per barcode and a file called key_file.txt
#
#barcodes and primers are stripped
#
#key_file contains:
#sampleID1	forward1.fastq	reverse1.fastq
#sampleID2	forward2.fastq	reverse2.fastq
#etc
#mothur command is:
#make.contigs(key_file.txt, processors=4)

#argument list is:
#0 samples.txt
#1 forward fastq
#2 reverse fastq
#3 primer names, one of V4, V6, etc

my @lprimerlen = (19, 20, 19);
my @rprimerlen = (20, 31, 18);

my  $primer = 1;
if ( defined $ARGV[3]){
	$primer = 2 if $ARGV[3] eq "V6";
	$primer = 0 if $ARGV[3] eq "ITS6";
	$primer = 1 if $ARGV[3] eq "Kcnq1ot1";
}
my %samples;

#open samples.txt file and make a hash of forwardbc-reversebc  with value sampleID
open (IN, "< $ARGV[0]") or die "$!\n";
	while(my $l = <IN>){
		chomp $l;
		my @l = split/\t/, $l;
		my $bc = join("-", uc($l[0]), uc($l[1]));
		$samples{$bc} = $l[2];
	}
close IN;

#foreach(keys(%samples)){print "$_ $samples{$_}\n";}
#for (my $i = 0; $i < 10; $i++){
#	my $mod = $i % 4;
#	print "$i $mod\n";
#}
#exit;
#
my $c = 0; my $dataL = my $dataR; my $keep = "F";
my %outputL = my %outputR; my $id;
#open forward fastq and reverse fastq
open (IN1, "< $ARGV[1]") or die;
open (IN2, "< $ARGV[2]") or die;
	while(my $l1 = <IN1>){
		my $l2 = <IN2>;
		chomp $l1; chomp $l2;
		if ($c % 4 == 0 ) { #def line
			if ($keep ne "F"){
				$outputL{$keep} .= $dataL;
				$outputR{$keep}  .= $dataR;
				#my $mod = $c % 4; print "$c $mod\n$keep\n$dataL\n$dataR\n";
			}
			#empty the variables
			$keep = "F"; $id = "";
			$dataL = "$l1\n";
			$dataR = "$l2\n";
		}elsif($c % 4 == 1 ){ #seq line
			my $bc = join( "-", substr($l1, 4,8), substr($l2, 4,8) );
			#print "$c $bc \n$l1\n$l2\n";
			$keep = $bc if exists $samples{$bc};
			$dataL .= substr($l1, (12 + $lprimerlen[$primer]) ) . "\n";
			$dataR .= substr($l2, (12 + $rprimerlen[$primer]) ) . "\n";
			
		}elsif($c % 4 == 2 ){ #second def line
			$dataL .= "+\n";
			$dataR .= "+\n";
		}elsif($c % 4 == 3){ #qscore
			$dataL .= substr($l1, (12 + $lprimerlen[$primer]) ) . "\n";
			$dataR .= substr($l2, (12 + $rprimerlen[$primer]) ) . "\n";
		}
		$c++; 
	
#	if ($c > 100000){
#		last;
#		close IN1; close IN2;
#	}
	}
close IN1; close IN2;
#exit;
my @bc = keys(%samples);
my $keydata = "";
for(my $i = 0; $i < @bc; $i++){
	my $fileL = $samples{$bc[$i]} . "_" . $bc[$i] . "_R1.fastq";
	my $fileR = $samples{$bc[$i]} . "_" . $bc[$i] . "_R2.fastq";
	$keydata .= "$samples{$bc[$i]}\t$fileL\t$fileR\n";
	open (OUT, "> demultiplex/$fileL") or die;
		print OUT $outputL{$bc[$i]};
	close OUT;
	open (OUT, "> demultiplex/$fileR") or die;
		print OUT $outputR{$bc[$i]};
	close OUT;
}

open (OUT, "> demultiplex/key_data.txt") or die;
	print OUT $keydata;
close OUT;


