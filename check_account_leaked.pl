#!/usr/local/bin/perl
# 確認登入名單log裡的帳號，去DB查其登入時間的前後"時間區間" 有沒有寄信。
# "時間區間" 設為一個變數。
do "/usr/local/iSherlock/pub-lib.pl";
do "/usr/local/iSherlock/dbi-lib.pl";

use Time::Piece;
use Time::Seconds;  # for 計算時間
# &dbi_connect() => 連線資料庫
# &db_run_sql()  => 資料庫搜尋
print "=================================================\n";
print "         Check out account leak\n";
print "=================================================\n\n";

print "(1)輸入登入紀錄 log 檔:\n";
my $input=<STDIN>;
chomp($input);
print "--------------------------\n";
print "(2)請輸入時間區間 (分鐘) :\n";
my $minutes=<STDIN>;
chomp($minutes);


print "\n=================================================\n";
print "  loading ....\n";
print "=================================================\n";
print "[Result]:\n";
open(IN, "<$input")||die "somthing worng, can't open [$input] :$!";

############# [log parse] #################
# 1. read file & parse
my ($Stime, $Etime);
my %parse_result; # for contain parse result
foreach(<IN>){
	chomp;
    my $account=substr($_,25,index($_,"[PW]")-26);
    my $login_time=substr($_,1,19);
	#print "$account\t$login_time\n";
	$parse_result{$account}=$login_time;  # 存 hash
}
close IN;

print "-----------------------------------------------------\n";
print "MID\tSender\tRDate\n";
print "-----------------------------------------------------\n";

############ [DB query] #################
my $dbh = &dbi_connect();
foreach my $account (keys %parse_result){

	# 2. calculate time 
	my $format = '%Y-%m-%d %H:%M:%S';
	my $tp = localtime->strptime($parse_result{$account}, $format);
	my $Stime =  $tp + ONE_MINUTE * $minutes;
	my $Etime =  $tp - ONE_MINUTE * $minutes;

	$Stime=$Stime->strftime($format);
	$Etime=$Etime->strftime($format);
	
	# 3. mySQL query
	$sql="SELECT MID,Sender,RDate FROM MailInfo WHERE Sender LIKE '\%$account\%' and RDate <= '$Stime' and  RDate >= '$Etime'";
	
	#4. catch query result
	$GetSMID = &db_run_sql($dbh, $sql, 'GetSender');
		while(my $hash = $GetSMID->fetchrow_hashref){
			my $ref1=$hash->{'MID'};
			my $ref2=$hash->{'Sender'};
			my $ref3=$hash->{'RDate'};
			print $ref1."\t".$ref2."\t".$ref3."\n";
	
	}

	
}




$GetSMID->finish;

exit;



