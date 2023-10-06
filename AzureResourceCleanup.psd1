@{
	
	# Script module or binary module file associated with this manifest.
	RootModule = 'AzureResourceCleanup.psm1'
	
	# Version number of this module.
	ModuleVersion = '0.5'
	
	# ID used to uniquely identify this module
	GUID = '1e34065d-bf2b-44a0-b4bb-c8e6e6b0ec6e'
	
	# Author of this module
	Author = 'Marco Kleinert'
	
	# Company or vendor of this module
	CompanyName = 'AzureResourceCleanup'
	
	# Copyright statement for this module
	Copyright = 'Copyright (c) 2023 Marco Kleinert'
	
	# Description of the functionality provided by this module
	Description = 'This module provides extra functionality for cleanup Azure resources.'
	
	# Minimum version of the Windows PowerShell engine required by this module
	PowerShellVersion = '5.0'
	
	# Name of the Windows PowerShell host required by this module
	PowerShellHostName = ''
	
	# Minimum version of the Windows PowerShell host required by this module
	PowerShellHostVersion = ''
	
	# Minimum version of the .NET Framework required by this module
	DotNetFrameworkVersion = ''
	
	# Minimum version of the common language runtime (CLR) required by this module
	CLRVersion = ''
	
	# Modules that must be imported into the global environment prior to importing this module
	RequiredModules = @(
		@{ ModuleName = 'PSFramework'; ModuleVersion = '1.9.270' }
		@{ ModuleName = 'string'; ModuleVersion = '1.1.3' }
		@{ ModuleName='Az.Accounts'; ModuleVersion='2.13.0'}
		@{ ModuleName = 'Az.RecoveryServices'; ModuleVersion = '6.5.1'}
		)

	
	# Assemblies that must be loaded prior to importing this module
	RequiredAssemblies = @()
	
	# Script files () that are run in the caller's environment prior to importing this module
	ScriptsToProcess = @()
	
	# Type files (xml) to be loaded when importing this module
	TypesToProcess = @()
	
	# Format files (xml) to be loaded when importing this module
	# ''
	
	# Modules to import as nested modules of the module specified in ModuleToProcess
	NestedModules = @()
	
	# Functions to export from this module
	FunctionsToExport = '*'
	
	# Cmdlets to export from this module
	CmdletsToExport = ''
	
	# Variables to export from this module
	VariablesToExport = ''
	
	# Aliases to export from this module
	AliasesToExport = ''
	
	
	# List of all modules packaged with this module
	ModuleList = @()
	
	# List of all files packaged with this module
	FileList = ''
	
	PrivateData = @{
		# PSData is module packaging and gallery metadata embedded in PrivateData
		PSData = @{
			# The primary categorization of this module (from the TechNet Gallery tech tree).
			Category = 'Azure'
			
			# Keyword tags to help users find this module via navigations and search.
			Tags = @('Azure', 'resource')
			
			# The web address of an icon which can be used in galleries to represent this module
			IconUri = ''
			
			# The web address of this module's project or support homepage.
			ProjectUri = 'https://github.com/MARCO-K/AzureResourceCleanup'
			
			# The web address of this module's license. Points to a page that's embeddable and linkable.
			LicenseUri = 'http://www.gnu.org/licenses/gpl-3.0.en.html'
			
			# Release notes for this particular version of the module
			ReleaseNotes = ''
			
			# If true, the LicenseUrl points to an end-user license (not just a source license) which requires the user agreement before use.
			# RequireLicenseAcceptance = ''
			
			# Indicates this is a pre-release/testing version of the module.
			IsPrerelease = 'True'
		}
	}
}