Details of the Padre Cava Project
=================================
The goal of this document is to describe all the pieces of the cava project used to package Padre. Future builders can use these details to 

*  Update the cava project
*  Solve complex packaging problems
*  Use a different packager
*  Consider changes to Padre to better support packaging

It is assumed you have read the README and are familiar with packaging Padre with Cava. This guide will go through the Cava project item by item.

Credit
------
The first version of the cava package was created by Mark @ (Cava)[http://www.cava.co.uk/], and this guide describes his work or builds upon it.

Lets get down to it...

Project Layout and Files
========================
The Padre Cava project consists of a few scripts, modules rules & patches, and some support files.

Scripts And Executables - ./cava/scripts
--------------------------------------
On OSX, Cava produces DMGs that expose only the Padre.app to the external and internal environment.

This causes problems for Padre because it, at times, tries to make use of an executable perl by looking through the filesystem (as a sibling to the Padre executable). This is done in Padre::Perl.

To correctly bundle the current code, a new script was written called pperl.pl. This is a simple wrapper that is invoked in Padre::Perl, and runs perl expressions as if they were running in an external perl.

*  `./cava/scripts/pperl.pl`
   * Invoked by Padre::Perl, it runs perl in the same process as the existing padre.
   * Can be removed when no more such calls are made in Padre

*  `./cava/scripts/padre.pl`
   * Almost identical to the existing padre.pl in CPAN
   * Removes the call to `wxPerl` in OSX, since this is harmful in OSX

Adding these scripts to the Cava Scripts allows the Cava handler: Cava::Packager::GetScriptCommand to locate them. [I beieve they also work with `do` if added to INC - needs confirmation] See the Padre::Perl patch.

Module Rules - ./cava/rule/padre.cavarule
---------------------------------------
Rules are instructions for Cava on how to handle certain modules. They have options, code stubs, and patches.Once imported, they can be found under the project view/Cava Packager/Global Module Rules.

We have three rules in the project:

*  `Padre`
   * This rule for the main Padre modules has a few components:
   * Main Options
     * Include Sub Modules : All Levels
     * This setting tells Cava to include all Padre::* namespaced modules in the final package if they are in the INC of our perl. This is great because it means that normal Padre plugins are included by default.
     * Cava automatically packages dependencies, so any modules that plugins depend on will also be included.
     
     * Extra Includes and Files : Modules
     * This list provides other modules that we want bundled with Padre. It includes things like Wx::Sintilla, which would not automatically be found by the dependency scanner or the namespace inclusion.
     
     * Extra Includes and Files : Additional Files
     * Padre uses perldiag (more on that later) to provide diagnostics. perldiag, in turn, uses its pod files.
     * Cava by default strips pod from its packages
     * Here we force Cava to include the pod needed by perldiag. Note that on windows, the files is pods/perldiag.pod. (Once again I want to give credit to Mark for doing all this hard work).
     
     * Extra Includes and Files : Directory Slurp
     * To catch all files such as migration data files, we tell Cava to include any files placed under the Padre module directory in our lib. (TBConfirmed this is where migration files are located)

   * Code Stub
      * These are automatically included by Cava at the start of the module.
      * This one first sets up the environment in case we are running under activestate perl, which tries to invoke all scripts using the activestate perldebugger.
      * It then includes a commented out line allowing developers to produce packages that use a non-standard PADRE_HOME, to not clobber their personal config files with the development configs.
      * This could be made a run-time option by detecting if we are running under Cava using Cava::Packager::IfPackaged
      * Setting Apply From Module Version - Default tells Cava to include this in all versions of the module

   *   `Padre::DB::Migrate`
      * Note: This documentation section is currently unclear, and needs more understanding and work.
      * We have a patch for the Padre::DB::Migrate. Migrate tries to access the migration data files, and normally this is not available to the packaged Padre. However, the patch unshifts the name into INC, making it available at runtime..
      * Cava knows about the File-ShareDir and plays nice.
      * Migration is set to apply to All versions of the module.

   *   `Padre::Perl`
      * Our patch returns the pperl.pl script as a perl. The script masquerades as a perl, but runs commands in the same perl as the running Padre, as described in the Scripts section.
      * Migration is set to apply to All versions of the module.

Module Images - ./cava/images/padre.icns
----------------------------------------
This file contains a bundle (details) of padre icons.

Cava Packager Usage Details
===========================
     
External Patch
--------------
* Setting an external patch program is required because we apply source patches to Padre in Cava, and external patch allows slightly fuzzy application of patches. We created `./bin/usr_bin_patch` as a symlink to the /usr/bin/patch, for easy access if it applies.

Padre Project
-------------
The main settings of the padre project can be found in the project tree Padre item.

*  Tab Project Details
   * The project type is OSX App Bundle on OSX
   * Other fields are set reasonably, and the version must be carefully set before each production release
   
*  Tab Build Options
   * Package Method is set to Plain Text Perl Code, since we do not need any obfuscation
   * Default Package Location is set to Standard INC to aid clarity

*  Bundle Info
   * Bundle Executable is set to Padre
   * Bundle Name and Icon are set properly
   
* Perl Interpreter
   * Essential - this is the perl we'll be including in our Padre package, and also the perl from which we find and pull modules (by default)
   
Padre/Executables
-----------------
These are set to match the scripts, and in non-DMG packages these (need confirmation) will be the two executables that are installed with the package.

* padre
   * mapped to padre.pl script
   * type is GUI so that, when packaged, it interacts properly with OSX GUI
   
* pperl
   * mapped to the pperl.pl script
   * type console
   
Padre/Scripts
-------------
Here we include the padre.pl and pperl.pl scripts describe earlier.
