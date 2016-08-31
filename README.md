# Redmine License Manager

## Current To Do

### RakeTask for Setup
- Create Project that acts as Container for all the Licenses (A License will be a Data Entry of Type Issue) (Any poject that has the License Tracker can acts as License Container, Task will check if one valid container exists, otherwise one will be created)
- Create Tracker:   [License, Licenseextension]
- Create Aktivities muss angelegt werden:   [License, Maintenance]
- Create Tracker Status:                     [aktiv, inaktiv]
- Link all components/create config so that the Trackers are only allowed in the License Project, Aktivities are allowed for the given Trackers etc.

### Custom Fields (available for Issues within License Project):
- License price
- License purchase price

- Maintenance p.P.
- Maintenance purchase p.P. (p.P. means .. per Period)
- Maintenance Date
- Maintenance Paid Until
- Maintenance Invoice Received

- Period  .. in days (but 365 means year even in a leap-year)

- Customer .. lookup on Projekt (Parent Projects will show all licenses for subprojects)

optional License Information fields
- License Number
- Control Number
- LEF (license enabling file)


### Roles


## Info

This Plugin was created by Florian Eck ([EL Digital Solutions](http://www.el-digital.de)) for [akquinet finance & controlling GmbH](http://www.akquinet.de/).

It is licensed under GNU GENERAL PUBLIC LICENSE.

It has been tested with EasyRedmine, but should also work for regular Redmine installations. If you find any bugs, please file an issue or create a PR.


