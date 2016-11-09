# An example script demonstrating the use of BioMart API.
# This perl API representation is only available for configuration versions >=  0.5 
use strict;
use lib '/home/xin/Workspace/DisEnt/disent/common/lib/biomart/biomart-perl/lib';
use BioMart::Initializer;
use BioMart::Query;
use BioMart::QueryRunner;

my $confFile = "PATH TO YOUR REGISTRY FILE UNDER biomart-perl/conf/. For Biomart Central Registry navigate to
						http://www.biomart.org/biomart/martservice?type=registry";
#
# NB: change action to 'clean' if you wish to start a fresh configuration  
# and to 'cached' if you want to skip configuration step on subsequent runs from the same registry
#

my $action='cached';
my $initializer = BioMart::Initializer->new('registryFile'=>$confFile, 'action'=>$action);
my $registry = $initializer->getRegistry;

my $query = BioMart::Query->new('registry'=>$registry,'virtualSchemaName'=>'default');

		
	$query->setDataset("hsapiens_snp");
	$query->addFilter("variation_set_name", ["All phenotype-associated variants"]);
	$query->addFilter("phenotype_significance", ["1"]);
	$query->addAttribute("refsnp_id");
	$query->addAttribute("refsnp_source");
	$query->addAttribute("chr_name");
	$query->addAttribute("chrom_start");
	$query->addAttribute("allele");
	$query->addAttribute("refsnp_source_description");
	$query->addAttribute("study_type");
	$query->addAttribute("study_external_ref");
	$query->addAttribute("study_description");
	$query->addAttribute("source_name");
	$query->addAttribute("phenotype_description");
	$query->addAttribute("p_value");

$query->formatter("TSV");

my $query_runner = BioMart::QueryRunner->new();
############################## GET COUNT ############################
# $query->count(1);
# $query_runner->execute($query);
# print $query_runner->getCount();
#####################################################################


############################## GET RESULTS ##########################
# to obtain unique rows only
# $query_runner->uniqueRowsOnly(1);

$query_runner->execute($query);
$query_runner->printHeader();
$query_runner->printResults();
$query_runner->printFooter();
#####################################################################