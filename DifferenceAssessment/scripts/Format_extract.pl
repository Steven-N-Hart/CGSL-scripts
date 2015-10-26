#!/usr/bin/perl -w
use Data::Dumper;
use Getopt::Long;

#Initialize values
my (@queries,@HEADER,$samples,@HEADER_OUT,$end,$samp,$stop);
GetOptions ("query|q=s" => \$queries,
	"stop|s:s", \$stop);
if(!$queries){die "Usage: FORMAT_extract.pl <VCF> -query AD,SSC 
\n\n";}
@queries = split(/,/,join(',',$queries));

open(VCF,"$ARGV[0]") or die "must specify VCF file\n\n";
while (<VCF>) {
	if($_=~/^##/){print;next}
    chomp;
	next if ($_=~/^$/);
    @line=split(/\t/,$_);
    if($line[0]=~/^#CH/){
        @SAMPLE_NAMES=();
        @SAMPLE_COL=();
        @HEADER=@line;
        print join ("\t",@HEADER)."\t";
        $i=9;       
	if (!$stop){$stop=scalar(@HEADER)};
	chomp;
        while(($line[$i]=~/^[A-Z]|^[0-9]/i)&&($i < $stop)){
            push(@SAMPLE_NAMES,$line[$i]);
            push(@SAMPLE_COL,$i);
            $i++;
        }
	my %IDs=();
        for ($j=0;$j<=scalar(@SAMPLE_COL)-1;$j++){
#	for ($j=0;$j<=scalar(@SAMPLE_COL);$j++){

            for ($y=0;$y<scalar(@queries);$y++){
		$IDs{$SAMPLE_NAMES[$j].".".$queries[$y]}=".";	
            }
        }
#print Dumper(\%IDs);

%new_hash=();
  	foreach my $sample (sort keys %IDs) {
        	print  $sample . "\t";
    #           print  "\t". $sample;     	
	}
       	print "\n";
        next;
    }
    print $_ ."\t";
#pirint Dumper(\%IDs);
#die; 
   for ($j=0;$j<scalar(@SAMPLE_COL);$j++){
        for ($y=0;$y<scalar(@queries);$y++){
            my $t=0;
            @FORMAT=split(/:/,$line[8]);
            for ($z=0;$z<scalar(@FORMAT);$z++){
                if($FORMAT[$z]=~/^$queries[$y]$/){
                    	@res=split(/:/,$line[$SAMPLE_COL[$j]]);
               		$new_hash{$SAMPLE_NAMES[$j].".".$FORMAT[$z]}=$res[$z];
               		$t++;
               		}
                if($t==0 && $z==(scalar(@FORMAT)-1)){
                	$new_hash{$SAMPLE_NAMES[$j].".".$queries[$y]}=".";
               		}
	    	}
   	}
   }
#print Dumper(\%new_hash);

#Clear all the values after printing
	my $sample="";
   foreach $sample (sort keys %new_hash) {
		if(!$new_hash{$sample}){$new_hash{$sample}="NA"};
		print $new_hash{$sample} ."\t";
              	$new_hash{$sample}=".";
        }
   print "\n";


}
close VCF;
