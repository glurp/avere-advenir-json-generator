#!/usr/bin/ruby
#######################################################################
# advnir.rb : envoie les charges des archices OCPP a ADVENIR
#
# Usage: 
#    > ruby advenir.rb userid dir
#    > ruby advenir.rb 9079876876 site1
#######################################################################
require 'json'
require 'pp'
require 'date'
require 'time'
require 'open-uri'
require 'timeout'
require 'net/http'
require 'net/https'

if ARGV.size!=2
 puts "Usage : >  ruby advenir.rb userid site"
 exit(1)
end

$userid="a6d0e6cf-7cac-477a-ae63-7e753c5bdda1"  # ARGV[0]
site=ARGV[1]

url="https://mon.advenir.mobi/api/operation/put"
url="https://prefixe.webservicetest.advenir.mobi/api/operation/put"
$user_http="100@servtest.advenir.mobi"
$pass_http="test123"
[$user_http,$pass_http]
dir= "data-json/#{site}"

unless Dir.exists?(dir)
 puts "site '#{site}' inconnu"
 exit(1)
end

###################################################################################
#  Traitement d'une borne
###################################################################################
def wput(url,user_passwd,data)
  puts "Sending to #{url} PUT data (size=#{data.size}) basic auth #{$user_http} '#{$pass_http}' ..."
  uri = URI(url)
  res=Net::HTTP.start(uri.host, uri.port,
            :use_ssl => true, 
            :verify_mode => OpenSSL::SSL::VERIFY_NONE,
            :open_timeout => 120) do |http|
      request = Net::HTTP::Put.new(uri.path, initheader = { 'Content-Type' => 'application/json'})
      request.basic_auth(*user_passwd)
      request.body=data
      response =  http.request(request)
      [response.code,response.code==200 ? response.body : response.body.to_s[/title>(.*?)<\/title/ , 1]]
    end
end

###################################################################################
#  Traitement d'une borne
###################################################################################
=begin
exemple de message OCPP/JSON en log_*txt  :

{"chargeBoxIdentity":"111","Action":"/StartTransaction","connectorId":"1","idTag":"8BD2C53F","timestamp":"2018-05-30T16:24:26Z","meterStart":"0","date":"2018-05-30 18:24:29"},
{"chargeBoxIdentity":"111","Action":"/MeterValues","connectorId":"1","transactionId":"889301","timestamp":"2018-05-30T16:39:26Z","value":"5223","date":"2018-05-30 18:39:29"},
{"chargeBoxIdentity":"111","Action":"/StopTransaction","transactionId":"889301","idTag":"8BD2C53F","timestamp":"2018-05-30T17:24:36Z","meterStop":"15567","date":"2018-05-30 19:24:40"},

=end
def start_cbi(cbi)
  $cdc=[]
  $opc=[]
  $ec=[]
end
def register(cbi,json)
  req=json["Action"]
  case req
  when "/StartTransaction"
   $ec=[json]
  when "/StopTransaction"
   $ec << json
   trait(cbi,$ec) if $ec.size>=2
   $ec=[]
  when "/MeterValues"
   $ec << json
  end
end
def end_cbi(cbi)
  $all_cdc << { cbi =>  $cdc } if $cdc.size>0
  $all_opc << { cbi => $opc } if $opc.size>0
end

def trait(cbi,a)
  return nil if a.first["Action"]!="/StartTransaction" || a.last["Action"]!="/StopTransaction" 
  return if  ( a.first["meterStart"].to_i - a.last["meterStop"].to_i ).abs < 3
  return if   (rfc3339(a.first["timestamp"]) - rfc3339(a.last["timestamp"])).abs < 120
  if a.size==2
    start=a.first
    eend=a.last
    $opc << {
      eend["transactionId"] =>  {
        "StartTransaction": rfc3339(a.first["timestamp"]),
        "StopTransaction": rfc3339(a.last["timestamp"]),
        "StartValue": a.first["meterStart"].to_i,
        "StopValue": a.last["meterStop"].to_i,
      }
    } 
  elsif a.size>2
    start=a.first
    eend=a.last
    atime=a.map {|el| {"timestamp": rfc3339(el["timestamp"]), "value": (el["meterStart"] || el["value"] || el["meterStop"] ).to_i } }
    $cdc << {
      eend["transactionId"] =>  atime 
    }
  else
    nil
  end
end

def rfc3339(str)
 ret=Time.xmlschema(str).to_i rescue (STDERR.puts "#{str}  #{$!}"  ; Time.now.to_i)
 #STDERR.puts "#{str}  =>  #{ret} #{Time.xmlschema(str) rescue 'error'}"
 #ret
end


def gene(type,l)
    { $userid => l.each_with_object({}) {|h,r| r[h.keys.first] = h.values.first } } 
end
###################################################################################
#         M A I N 
###################################################################################
$all_cdc=[]
$all_opc=[]
Dir.glob("#{dir}/log_*.txt").each do |fn|
 cbi= fn[/log_(.*?)\.txt/,1]
 start_cbi(cbi)
 File.foreach(fn) {|line|
   line.chomp!
   next if line=~/^\s*\[/
   next unless line =~ /(StartTransaction)|(StopTransaction)|(MeterValues)/
   register(cbi,JSON.parse(line.chomp[0..-2]))  rescue ( STDERR.puts "#{line.chomp} ::: #{$!}" )
 }
 end_cbi(cbi)
end

cdc=JSON.generate(  gene("cdc",$all_cdc) , indent: " ", array_nl: "\n")
opc=JSON.generate(  gene("opc",$all_opc) , indent: " ", array_nl: "\n" )
puts cdc if $all_cdc.size>0
puts opc if $all_opc.size>0
STDERR.puts "emission cdc: #{wput(url,[$user_http,$pass_http],cdc).inspect}" if $all_cdc.size>0
STDERR.puts "emission opc: #{wput(url,[$user_http,$pass_http],opc).inspect}" if $all_opc.size>0

