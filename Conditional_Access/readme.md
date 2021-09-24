# Intended Use
This script enables system administrators to configure some of the Azure AD Conditional Access policies that are commonly deployed as part of the Steel Root Reference Architecture, an optimized system design built on Microsoft 365 GCC High that is purpose-built for meeting the CUI safeguarding requirements in DFARS 252.204-7012 and preparing for CMMC Level 3.

Some of the policies configured by this script may not apply to your environment (e.g., do not deploy the Zscaler policy if you are not using Zscaler); the script will prompt you before configuring each policy so you can select just the policies that apply to your use case.

This script is provided "as is" and you should consult a qualified advisor to help you navigate your specific compliance requirements. For more information on the Steel Root Reference Architecture, contact us at info@steelroot.us.

# Requirements
* Account running script must be have the [Security Administrator or Global Administrator role in AAD](https://docs.microsoft.com/en-us/azure/active-directory/roles/delegate-by-task#security---conditional-access).
* You have at least one "[break glass](https://docs.microsoft.com/en-us/azure/active-directory/roles/security-emergency-access)" admin account(s) in a group, following Microsoft's best practice. 
  * This group will be excluded from all CA policies. These accounts are to be used for emergencies only, and should have an extremely long, generated password.
  * If you don't have this group configured prior to running the script, it will pause and allow you to configure the group beofre proceeding.
* Assumes the script is in a folder which contains locations and policies subfolders in the same directory.

# Overview
* Adds or Updates AzureAdPreview Module.
* Connects to AzureUSGovernment.
* Defines the path of the Locations and Policy subfolders.
  * If using a non-standard path, update these variables.
* Cycles through each of the json files in the locations subfolder.
  * Prompts for confirmation on installing each of the locations:
    * Non-US Countries Location
    * Zscaler Gov Location
* Saves the BreakGlass Admin Group GUID to a variable.
  * If it's named something other than "Break or Glass", or we find multiple results, you'll be prompted to select the correct group.
* Saves the GUID for the newly created "Non-US Countries" Location (if created)
* Saves the GUID for the newly created "Zscaler Gov" Location (if created)
* Cycles through each of the json files in the policies subfolder.
  * Prompts for confirmation on installing each of the policies:
    * Block access from Android devices
    * Block access from iOS devices
    * Block access from Linux, UNIX, and non-standard devices
    * Block access from macOS devices
    * Block access from non-US countries
    * Block access from Windows Phone devices
    * Block Non-Zscaler Connections
    * Block use of legacy protocols
    * Block web client for Azure Virtual Desktop -- (Will fail if AVD is not already configured)
    * Require device compliance on Android and iOS
    * Require device compliance on Windows 10
    * Require MFA for all internal users on all cloud apps
    * Require MFA for Azure Virtual Desktop connections -- (Will fail if AVD is not already configured)
    * Require MFA for external users (not including AIP)
    * Require use of approved apps on Android and iOS



# FAQ
### “Running Scripts is disabled on this system”:
I’m receiving an error when I run the script. It says “SteelRootConditionalAccess cannot be loaded because running scripts is disabled on this system.”

To resolve this error, run the following command:
```Set-ExecutionPolicy -ExecutionPolicy RemoteSigned```

### AVD Policies throw an error when chosen:
To resolve this error, you must first deploy AVD. The conditional access policy is utilizing an Application GUID which will not be available if AVD isn't in use.

# License
[![CC BY-NC-SA 4.0][cc-by-nc-sa-shield]][cc-by-nc-sa]

This work is licensed under a
[Creative Commons Attribution-NonCommercial-ShareAlike 4.0 International License][cc-by-nc-sa].

[![CC BY-NC-SA 4.0][cc-by-nc-sa-image]][cc-by-nc-sa]

[cc-by-nc-sa]: http://creativecommons.org/licenses/by-nc-sa/4.0/
[cc-by-nc-sa-image]: https://licensebuttons.net/l/by-nc-sa/4.0/88x31.png
[cc-by-nc-sa-shield]: https://img.shields.io/badge/License-CC%20BY--NC--SA%204.0-lightgrey.svg
