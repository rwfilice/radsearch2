# radsearch2
Updated version of Radsearch - with thanks and credit to the original Radsearch team from the University of Maryland (Chris Meenan, Max Warnock, Mark Daly, Christopher Toland) and Indiana University (Marc Kohli, M.D.)

# Things you'll need

## Web Application
1. A server to host - I use Apache on Ubuntu Server 14.04
2. Ruby - I use version 2.1.5
3. The right ruby gems: sinatra, ldap, mysql, json, chronic, net/http
4. Something to run a Ruby/Sinatra application - I use [Passenger Standalone](https://www.phusionpassenger.com/documentation/Users%20guide%20Standalone.html)
5. Javascript libraries
  * [jQuery](https://jquery.com/)
  * [jQuery UI](http://jqueryui.com/download/)
  * [jQuery Validate](http://plugins.jquery.com/validation/)
  * [Bootstrap](http://getbootstrap.com/javascript/)
6. CSS libraries
  * [jQuery UI](http://jqueryui.com/download/)
  * [Bootstrap](http://getbootstrap.com/)

## Radiology Reports
1. Access to HL7 data or some other data source where you can extract radiology report data. I load this data into a MySQL database but Solr can index from many data sources
2. An instance of [Solr](http://lucene.apache.org/solr/) to index your reports - I have one running on a separate VM

# Solr config

## Database config
You'll need to create db-data-config.xml (at least that's what my config file is called) that establishes a query, a deltaQuery, and a deltaImportQuery. The query and deltaImportQuery should pull all the data you want to be indexed. The deltaQuery should identify those reports that have been updated since the last index - I do this by comparing a modified timestamp from our reports MySQL database to the Solr variable ${dih.last_index_time}. You also need to provide MySQL authentication information in this file. In my case (using Solr on a separate VM) I had to be sure to allow my MySQL server to allow access from that VM IP.

## Database connector
In solrconfig.xml I had to include this jar file to allow access to MySQL

>`<lib dir="${solr.install.dir:../../../..}/contrib/dataimporthandler/lib" rege\
x=".*\.jar" /\>`<br>
>`<lib dir="${solr.install.dir:../../../..}/dist/" regex="solr-dataimporthandle\
r-\d.*\.jar" />`
