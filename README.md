## README.md - info for Drupal Sites

Share scripts in puppet
	puppet/modules/webserver/files/drupal/
	tell someone from Library Systems to push out new vesions - not automatic

Basic setup
	check in make file - see scripts/create_svn_makefile.sh
		go to make directory then
		svn import domain https://svn.library.cornell.edu/cul-drupal/drupal_7/make/domain -m "Initial import"
		mv domain domain.old
		svn co https://svn.library.cornell.edu/cul-drupal/drupal_7/make/domain
	add template modules to Drush-make file
	chmod og-w settings.php
	add cron task

Setup files
	Drupal 7
		/admin/config/media/file-system
		set Private file system path to
			../drupal_files

Setup backup_migrate
	Destinations
		override destination 'Scheduled Backups Directory'
			/libweb/drupal/backups/backup_migrate/<<unique-site-name>>
			same directory is used on victoria01 and 02
			files written here have site prefix and date suffix
		Drupal 7
			default destination is fine
				private://backup_migrate/scheduled
	Profiles
		add 'Scheduled Backup Profile'
			Backup File Name (leave alone eg. [site-name])
			Y-m-d\TH-i-s
			GZip
			Advanced Options
				email if fails checked
				take site offline checked
	Schedules
		add Central Backups Schedule
			Enable checked
			Settings Profile: Scheduled Backup Profile
			Backup every 1 day
			3 files to keep
			Destination : Scheduled Backups Directory

Create a 'Site under maintenance' block
	This will tell users on the production site that you have the site on
		the test server for maintenance and that their changes will be lost
		when you return the site to the production server.
	Make a new page
		Title
			'Maintenance'
		Body
			This page is just to host the
			'Please postpone updates during site maintenance.'
			block when it's not in use.
		URL path settings
			'site_maintenance'
		Publishing options
			nothing checked
	Make a new block
		Go to the Site Building >> Blocks page
		Block Description
			Site under maintenance
		Block title
			Site under maintenance
		Block Body
			<div style="background-color:yellow"><h2><strong>Please postpone updates during site maintenance.</strong></h2></div>
		User specific visibility settings
			Users cannot control whether or not they see this block.
		Role specific visibility settings
			checked: authenticated user
		Page specific visibility settings
			 Show on only the listed pages.
		Pages:
			site_maintenance
	Move block to the Content area.

mySql cheats
	Username and password for general user
		look in ~/.my.cnf
	Create a database
		mysqladmin -u username -p create databasename
	Log in to mysql
		bash> mysql -u username -p
		<<MySQL prompts for the 'username' database password.>>
	Create a database from an sql dump file
		mysql < dumpfile.sql
	Create a new user
		bash> mysql
		mysql> CREATE USER joe IDENTIFIED BY 'flibberdejibbit'
	Grant priveleges
		mysql> GRANT SELECT, INSERT, UPDATE, DELETE, CREATE, DROP, INDEX, ALTER, LOCK TABLES, CREATE TEMPORARY TABLES ON `databasename`.* TO 'username'@'localhost' IDENTIFIED BY 'password';
		(note: no backticks around user and password)
	Get out of mysql
		mysql> exit
		bash>

