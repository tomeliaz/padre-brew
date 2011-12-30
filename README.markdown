Padre-Brew and Packaging Padre
==============================
padre-brew is a package for creating self-contained Padre directories, and also packaging them into distributions.

padre-brew consists of two parts, a padre-brew.pl, and a [cava pacager](http://www.cava.co.uk/) project.

This readme is also the instructions for building Padre distributions using cava.

Current Versions
================
These instructions will currently create packages using:

*  Padre: Latest in CPAN - 0.86
*  Perl OSX: Default padre-brew pulls 5.14.1 32bit (should work with other 32bit)
*  Perl Other Platforms: Not yet tested
*  Cava: Latest stable - 2.0.60 (should work with future 2.0 versions)
*  Current modules automatically added by padre-brew.pl:
   *  Wx::Scintilla
   *  Please open a bug to request your favorite module be added!

padre-brew
==========
*Currently only working on OSX*, you can use bin/padre-brew.pl to get a PadreApp directory that contains a complete perl + padre + cpanm which can be used to add more modules. You can run this padre directly, or use it as a base for packaging.

cava-project
============
[Cava Packager](http://www.cava.co.uk/) is a perl packager that can be used to package Padre on multiple operating systems.

The foundation of this work and the heavy lifting was done by Mark @ Cava.

NOTE
----
These instructions are currently only tested on OSX. This document will change as needed to address other platforms.

Getting a Padre & Perl to Package
---------------------------------
If you already have Padre running on your system, you could choose to package that padre. However, the instructions in this README assume you are using a base set up by the *padre-brew* script.

Use the `./bin/padre-brew.pl` script to create a sandboxed Padre.
`./bin/padre-brew.pl -v --no-test` will build a PadreApp directory with the latest Padre, latest stable Wx, and a perl 5.14.1 perl. Check the script for more options.

Common Changes
--------------
You can include more modules in your Padre sandbox by using the sandboxed cpanm `./PadreApp/bin/cpanm`.
*See the Optional Changes - Modules* sections to see how to add these modules to a Padre package.

Getting Cava
------------
*  Cava is hosted here: [http://www.cava.co.uk/](http://www.cava.co.uk/)
*  You will need to create an account before you can download Cava.
*  Also, you will have to obtain and install a non-commercial or commercial license key.
*  You will be prompted to install your license key the first time you try to open a project in Cava.

Padre Build Resources
---------------------
A cava project for Padre is found in this repository at `./cava/project/cava20.cpkgproj`

Cava First Time Setup
---------------------
A number of Cava options cannot currently be automated, and must be manually set by a builder the first time they use the cava padre package.

*  Open the `./cava/project/cava20.cpkgproj` project in Cava
   *  You may get a warning about missing scripts
   *  You may be prompted to install your license key

*  Install the license key 
   *  via Tools -menu-> Import Application Keys

*  Set the external patch binary:
   *  Open Preferences -tab-> Application Defaults
   *  Set External Patch to a reasonable patch. You can use `./bin/usr_bin_patch` which is symlinked to `/usr/bin/patch` for your convenience

*  Set the scripts directory
   *  In the package view select Padre/Scripts
   *  Click the edit (Pencil) at the top right and choose `./cava/scripts`
   *  On success, you will be prompted that both padre.pl and pperl.pl have been located

*  Import Padre-specific build rules
   *  Select Tools -menu-> Import Module Rules
   *  Select `./cava/rule/project.cavarule`
   *  Import all rules (currently 3)

*  Set the perl binary to package with Padre
   *  In the package view select Padre -tab-> Perl 
   *  Change the executable from `/usr/bin/perl` to another `perl` if needed
   *  If you used `padre-brew.pl`, you can select `./PadreApp/perl5/perls/perl5.14.1/bin/perl`
   *  Approve the re-scan request
   *  Note: If you get a warning informing you that Cava::Packager utils need updating, click the Update button in the perl information window that appears behind the warning. This will install the utils into the selected perl.

*  Set the icons for the package
   *  In the package view select Padre -tab-> Bundle Info
   *  Click the button to the right of the bundle icon and Add the `./cava/images/padre.icns`
   *  Remove the cavaauto-default.icns if it exists in the list
   *  Highlight the padre.icns entry and click Select

*  Set the version number
   *  In the package view select Padre -tab->Project Details and change the major/minor version.

Optional Changes - Add Modules
------------------------------
At times you may want to include more modules into your Padre package.

*  You must first install modules into the INC path of your perl.
   *  If you are using `padre-brew.pl` you can add new modules by:
   `./PadreApp/bin/cpanm <module>`

*  Cava includes by default:
   *  If your module is under the `Padre::` namespace it will be included into any package by default. No more changes are needed.
   *  If your module is clearly depended on (use, require) by a module that will be packaged by Cava, it will also be included. So if your Plugin uses modules, they will be included.
 
*  For modules not automatically detected, you must add them to the Padre module rules
   *  In the project view select Global Module Rules/Padre -tab-> Main Options
   *  Under Extra Includes and Files, select the Modules tab
   *  Add your module here

*  If you need to add other files, such as pod, you can use the other tabs in Extra Includes and Files

Optional Changes - Preferences Directory
----------------------------------------
If you are packaging Padre for testing, you may want to change the preferences directory so you do not clobber your personal Padre.

*  In the project view select Global Module Rules/Padre -tab-> Code Stub
*  Uncomment the PADRE_HOME line and set your desired testing PADRE_HOME

Building The Package
--------------------
Select Project -menu-> Scan and Build.

Your package and installer will be in `./cava/project/release` and `./cava/project/installer`.

Debugging
---------
You can have a packaged padre redirect all STDOUT and STDERR, as well as module load info, to a new terminal.

*  In the project view select Padre/Diagnostics and Test, open padre.pl
*  Select Output Cava Loader Diagnostic Information, and click Ok
*  Currently, there is no way to attach a debugger to Padre

Automation
----------
Coming soonish!

More Information
----------------
*  Item-by-Item details of the Padre cava project file: [https://github.com/tomeliaz/padre-brew/blob/master/README.padrecavaproject.markdown](https://github.com/tomeliaz/padre-brew/blob/master/README.padrecavaproject.markdown)
*  [More issues in packaging](https://github.com/tomeliaz/padre-brew/blob/master/ISSUES.markdown)
