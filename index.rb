#Radsearch2 - quickly search radiology reports in a MySQL database indexed via Apache Lucene/Solr
#Copyright 2015, Ross Filice, MedStar Health (with permission via MedStar Invention Services)

#This program is free software: you can redistribute it and/or modify
#it under the terms of the GNU General Public License as published by
#the Free Software Foundation, either version 3 of the License, or
#(at your option) any later version.

#This program is distributed in the hope that it will be useful,
#but WITHOUT ANY WARRANTY; without even the implied warranty of
#MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#GNU General Public License for more details.

#You should have received a copy of the GNU General Public License
#along with this program.  If not, see <http://www.gnu.org/licenses/>.

require 'rubygems'
require 'sinatra'
require 'ldap'
require 'mysql'
require 'json'
require 'chronic'
require 'net/http'

use Rack::Session::Cookie, :key => 'rack.session',
                           :path => '/radsearch',
                           :expire_after => 2592000, # In seconds
                           :secret => '[COOKIE SECRET]'

helpers do
  #this helper determines whether the user is authenticated (username set in session)
  #and also checks to see if the timeout as expired (default is 10 minutes)
  def authorize!
    if session[:username]
      #check timeout - throw a 401 http code so the client side can pick this up and redirect
      #the entire window rather than just the Ajax response element
      now = Chronic.parse("now")
      if now > session[:timeout]
        if request.xhr?
          redirect to('/radsearch/login', :layout=>false), 401
        else
          redirect to('/radsearch/login')
        end
      end

      #default timeout is currently 10 minutes from last activity (authorize helper called on all routes)
      session[:timeout] = Chronic.parse("10 minutes from now")
    else
      puts "redirecting"
      if request.xhr?
        redirect to('/radsearch/login', :layout=>false), 401
      else
        redirect to('/radsearch/login')
      end
    end
  end

  #internal homegrown paginate function
  #don't hate - I didn't like existing paginate plugins and this one works for my purposes
  #feel free to use other paginate plugins as you see fit

  #passes current page (i.e. the page the user is currently on)
  #and numresults - the total number of results from the query
  def paginate(currentpage,numresults)
    #currently displaying 10 results per page
    #calculates total number of pages required to display all results
    numpages = (numresults/10).ceil
    
    #this will be the array that the view generates the paginate row from
    pages = []
    
    if numpages == 0
      subpages = nil
    elsif numpages<=10
      subpages = (1..numpages).to_a
    else
      if currentpage < 7
        #low use case - you are currently on a page close to #1
        subpages = (1..8).to_a
        subpages.push("...")
        subpages.push(numpages-1)
        subpages.push(numpages)
      elsif numpages-currentpage < 6
        #you are on a page close to the last page
        subpages = (1..2).to_a
        subpages.push("...")
        (numpages-7..numpages).each do |sub|
          subpages.push(sub)
        end
      else
        #you are somewhere in the middle
        subpages = (1..2).to_a
        subpages.push("...")
        (currentpage-3..currentpage+3).each do |sub|
          subpages.push(sub)
        end
        subpages.push("...")
        subpages.push(numpages-1)
        subpages.push(numpages)
      end
    end
    
    if subpages
      #push the left arrow and disable it if you are on the first page
      css = "disabled" if currentpage==1
      pages.push({:page=>'&laquo;',:idx=>(currentpage-1).to_s,:css=>css})
      #push the pages
      subpages.each do |sub|
        css = ""
        css += "active " if sub==currentpage
        css += "disabled " if sub=="..."
        active = sub==currentpage ? true : false
        pages.push({:page=>sub.to_s,:idx=>sub.to_s,:active=>active,:css=>css})
      end
      #push the right arrow and disable it if you are on the last page
      css = "disabled" if currentpage==numpages
      pages.push({:page=>'&raquo;',:idx=>(currentpage+1).to_s,:css=>css})
    end

    #return the paginate array
    pages
  end
end

#the home endpoint
get '/' do
  authorize!

  erb :radsearch
end

#this is to perform a query
post '/radsearch' do
  authorize!

  #keep track of whether your advanced menu is visible
  @advancedVisible = params[:advancedVisible]

  #raw search phrase
  solrphrase = params[:phrase]
  #add backslashes so this can be stored properly to the database for audit logging
  dbphrase = solrphrase.gsub("\"","\\\"")
  #modify the phrase so that when you spit it back to the view quotes are displayed properly
  @phrase = solrphrase.gsub("\"","&quot;")

  #get the current page and then figure out which start value to query solr with
  page = params[:page] ? params[:page].to_i : 1
  start = page ? (page-1)*10 : 0

  #date parameters
  @lower = params[:lower]
  solrlower = @lower!="" ? Chronic.parse(@lower+" 12am").utc.iso8601 : "*"
  @upper = params[:upper]
  solrupper = @upper!="" ? Chronic.parse(@upper+" 12am").utc.iso8601 : "*"

  #advanced parameters - patient, radiologist, exam, diagnosis, referring information
  @patientID = params[:patientID]
  solrPatientName = params[:patientName]
  @patientName = solrPatientName.gsub("\"","&quot;")
  @patientSex = params[:patientSex]
  @patientDOB = params[:patientDOB]
  solrDOB = @patientDOB!="" ? "\""+Chronic.parse(@patientDOB+" 12am").utc.iso8601+"\"" : "*"
  @accession = params[:accession]
  @examCode = params[:examCode]
  solrExamDescription = params[:examDescription]
  @examDescription = solrExamDescription.gsub("\"","&quot;")
  @attending = params[:attending]
  @resident = params[:resident]
  solrDiag = params[:diag]
  @diag = solrDiag.gsub("\"","&quot;")
  solrReferring = params[:referring]
  @referring = solrReferring.gsub("\"","&quot;")

  if solrphrase
    #cobble together the solr url depending on what has been passed
    preurl = "http://[YOUR SOLR URL]:8983/solr/reports/select?q="
    preurl += "report:("+solrphrase+") AND " unless solrphrase == ""
    preurl += "patient_id:("+@patientID +") AND " unless @patientID == ""
    preurl += "patient_name:("+solrPatientName +") AND " unless solrPatientName == ""
    preurl += "patient_dob:("+solrDOB +") AND " unless @patientDOB == ""
    preurl += "patient_sex:("+@patientSex +") AND " unless @patientSex == ""
    preurl += "accession_number:("+@accession +") AND " unless @accession == ""
    preurl += "procedure_id:("+@examCode +") AND " unless @examCode == ""
    preurl += "procedure_name:("+solrExamDescription +") AND " unless solrExamDescription == ""

    #here check for a doctor ID as opposed to a name - we use 6 digit numbers
    #also for weird historical reasons, our attendings are stored as "assistings" in our database while
    #residents (if they generate a report) are stored as "attendings"
    if @attending.match(/^[0-9]{6}$/)
      preurl += "assisting_id:("+@attending +") AND " unless @attending == ""
    else
      preurl += "assisting:("+@attending +") AND " unless @attending == ""
    end

    if @resident.match(/^[0-9]{6}$/)
      preurl += "attending_id:("+@resident +") AND " unless @resident == ""
    else
      preurl += "attending:("+@resident +") AND " unless @resident == ""
    end

    preurl += "diag:("+solrDiag +") AND " unless solrDiag == ""
    preurl += "requesting:("+solrReferring +") AND " unless solrReferring == ""

    #add date information
    unless solrlower=="*" && solrupper=="*"
      preurl += "date:["+solrlower+" TO "+solrupper+"]"
    end

    #remove the last AND (if it exists)
    preurl.gsub!(/ AND $/,"")

    #sort by timestamp descending and add start number depending on the page you are on
    url = preurl +
      "&sort=timestamp+desc&start=" +
      start.to_s +
      "&rows=10&wt=json"

    #we modify the solr url to include highlight snippets as such - see solr search syntax to modify
    #to your needs
    url += "&hl=true&hl.snippets=4&hl.fl=report&hl.simple.pre=<kbd>&hl.simple.post=</kbd>&hl.requireFieldMatch=true" unless solrphrase == ""

    #again modify the url with appropriate backslashes to allow storage for auditing
    dburl = url.gsub("\"","\\\"")

    #connect to MySQL database for logging purposes
    con = Mysql.new 'localhost', '[LOG DB USERNAME]', '[LOG DB PASSWORD]'
    con.select_db('[LOG DATABASE]')

    #insert the audit log information
    audit_doctor_id = session[:doctor_id] ? session[:doctor_id] : "none"
    rs = con.query("insert into searches(user,doctor_id,phrase,url) values (\""+session[:username]+"\",\""+audit_doctor_id+"\",\""+dbphrase+"\",\""+dburl+"\")")
    if(con.insert_id != 0)
      @search_id = con.insert_id
    else
      #some problem...
      halt "Error"
    end

    #make the solr request
    uri = URI(URI.encode(url))
    req = Net::HTTP::Get.new(uri.request_uri)    
    res = Net::HTTP.start(uri.host, uri.port) {|http|
      http.request(req)
    }
    @solr = JSON.parse(res.body)

    #if you get a response, paginate
    if @solr['response']
      numresults = @solr['response']['numFound'].to_f
      @pages = paginate(page,numresults)
    else
      @error = "Error in search format"
    end
  end

  erb :radsearch, :layout=>false
end

#this is to log views of reports - the view happens on the client side (display and hide)
#so we make a background call to log any view
post '/radsearch-log' do
  authorize!

  con = Mysql.new 'localhost', '[LOG DB USERNAME]', '[LOG DB PASSWORD]'
  con.select_db('[LOG DATABASE]')

  search_id = params[:search_id]
  mrn = params[:mrn]
  acc = params[:acc]
  
  rs = con.query("insert into views(search_id,mrn,acc) values("+search_id+",\""+mrn+"\",\""+acc+"\")")
end

#login page
get '/login' do
  session.clear
  erb :login
end

#we currently use our enterprise AD for authentication and then do a lookup in a local LDAP
#instance for other department specific information
post '/login' do
  #connect to enterprise AD
  conn = LDAP::Conn.new('[AD URL]', [AD PORT])
  conn.set_option( LDAP::LDAP_OPT_PROTOCOL_VERSION, 3 )
  adminstr = '[AD USER URI]'

  begin
    conn.bind(adminstr,'[AD USER PASSWORD]')
    conn.perror("bind")
    
    #does the user exist? If so, get the CN for authentication purposes
    scope = LDAP::LDAP_SCOPE_SUBTREE
    base = '[AD BASE]'
    filter = '(&(memberOf=[AD GROUP])(uid='+params[:username]+'))'
    attrs = ['cn']
    
    usercn = nil
    
    conn.search(base, scope, filter, attrs) { |entry|
      puts entry['cn'].first if entry['cn']
      usercn = entry['cn'].first if entry['cn']
    }
    
    conn.unbind if conn.bound?
    raise "Could not find user" unless usercn
    
    #now try to authenticate the user - i.e. check their password
    usercn.gsub!(",","\\,")
    puts "cn="+usercn+","+base
    conn.bind("cn="+usercn+","+base,params[:password])
    conn.perror("bind")
    puts "bound user"

    raise "Could not authenticate" unless conn.bound?
      
    #finally check local LDAP tree to get doctor id etc
    conn = LDAP::Conn.new('[LOCAL LDAP URL]', [LOCAL LDAP PORT])
    conn.set_option( LDAP::LDAP_OPT_PROTOCOL_VERSION, 3 )
    conn.bind('[LDAP USER]','[LDAP PASS]')
    
    base = '[LDAP BASE]'
    scope = LDAP::LDAP_SCOPE_SUBTREE
    filter = '(uid='+params[:username]+')'
    attrs = ['employeeNumber']
    
    conn.search(base, scope, filter, attrs) { |entry|
      session[:doctor_id] = entry['employeeNumber'].first if entry['employeeNumber']
    }

    session[:username] = params[:username]
    session[:timeout] = Chronic.parse("10 minutes from now")
    
    conn.unbind if conn.bound?
    redirect to('/radsearch')
  rescue => e
    puts e
    conn.unbind if conn.bound?
    redirect to('/radsearch/login')
  end
end

#this is the old method of authentication solely against our local LDAP instance
post '/oldlogin' do
  #connect
  conn = LDAP::Conn.new('[LDAP BASE]', [LDAP PORT])
  conn.set_option( LDAP::LDAP_OPT_PROTOCOL_VERSION, 3 )

  base = '[LDAP BASE]'
  ldapstr = "uid="+params[:username]+","+base

  begin
    #try to bind
    conn.bind(ldapstr,params[:password])
    conn.perror("bind")
    
    #find username and doctor id
    scope = LDAP::LDAP_SCOPE_SUBTREE
    filter = '(uid='+params[:username]+')'
    attrs = ['employeeNumber']
    
    begin
      conn.search(base, scope, filter, attrs) { |entry|
        session[:doctor_id] = entry['employeeNumber'].first if entry['employeeNumber']
      }
    rescue
      conn.perror("search")
      conn.unbind if conn.bound?
      redirect to('/radsearch/login')
    end

    conn.unbind if conn.bound?
    
    session[:username] = params[:username]
    session[:timeout] = Chronic.parse("10 minutes from now")

    redirect to('/radsearch')
  rescue
    conn.unbind if conn.bound?
    redirect to('/radsearch/login')
  end
end
