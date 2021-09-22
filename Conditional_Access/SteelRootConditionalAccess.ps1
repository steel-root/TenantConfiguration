<#
  .SYNOPSIS
    Adds Steel Root's Conditional Access Locations & Policies.

  .DESCRIPTION
    Requirements:
      - Account running script has tenant Global Admin permissions
      - You have "break glass" admin account(s) in a group. 
        We'll use this group to exclude from all CA policies.
        More information on what a break glass account is here:
        https://docs.microsoft.com/en-us/azure/active-directory/roles/security-emergency-access
  
    Script Overview:
      - Defines directory path of policy & location json files
      - Loops through all json files in \conditional_access\locations
        - Prompts for confirmation to install each.
      - Loops through all json files in \conditional_access\policies
        - Prompts for confirmation to install each.
        - Replaces {{ }} entries in json files with appropriate GUIDs.

  .NOTES
    Company:  Steel Root, Inc.
    Website:  steelroot.us
    Created:  2021-08-11
    Modified: 2021-09-17
    Author:   Tom Biscardi

#>

#Adds the ability to use a prompt for each policy
Add-Type -AssemblyName PresentationFramework

#Install the Public Preview of AAD's PowerShell module, if it's not already.
if (!(Get-InstalledModule | Where-Object name -Match "AzureADPreview")){
    Install-Module AzureADPreview -Scope CurrentUser -Force
}
#If the module is installed, update it
else{
    Update-Module AzureADPreview
}

#Connect to Azure Gov. For Commercial tenants, remove Azure EnvironmentName parameter and its current value.
Connect-AzureAD -AzureEnvironmentName AzureUSGovernment

#Define path for Steel Root Conditional Access Locations. Assumes conditional_access folder is in the same directory as the script.
$CALocationsPath = Get-ChildItem ("$PSScriptRoot\locations")

#Define path Steel Root Conditional Access Policies.
$CAPoliciesPath = Get-ChildItem ("$PSScriptRoot\policies")


#### NAMED LOCATIONS


#Loops through each Conditional Access Location JSON file to perform tasks on each of them.
$CALocationsPath | 
    Select-Object -ExpandProperty Name | 
    ForEach-Object {

        #build a hashtable to fill
        $params = @{}
            
        #Imports the JSON file, replaces @odata.type & converts it into a powershell object.
        $SRLocationSettings = (Get-Content ("$PSScriptRoot\locations\" + $_) -Raw | 
            Foreach-Object {
                $_.replace("@odata.type","OdataType")
            } | ConvertFrom-Json)


        if ($SRLocationSettings.OdataType -eq "#microsoft.graph.countryNamedLocation"){
        
            #select only displayname, istrusted, and ipranges (ignoring unique values of the json)
            $params = @{
                OdataType = $SRLocationSettings.OdataType
                DisplayName = $SRLocationSettings.DisplayName
                countriesAndRegions = $SRLocationSettings.countriesAndRegions
                includeUnknownCountriesAndRegions = $SRLocationSettings.includeUnknownCountriesAndRegions
            }
        }
        elseif ($SRLocationSettings.OdataType -eq "#microsoft.graph.ipNamedLocation"){

            #select only displayname, istrusted, and ipranges (ignoring unique values of the json)
            $params = @{
                OdataType = $SRLocationSettings.OdataType
                DisplayName = $SRLocationSettings.DisplayName
                isTrusted = $SRLocationSettings.isTrusted
                ipRanges = $SRLocationSettings.ipRanges.cidraddress
            }
        }
        else{
            Write-Warning "Cannot detect location json file type."
        }
        
        #save the policy name without the .json
        $policyName = $_.split(".")[0]

        #prompt for confirmation
        $Confirmation = `
            [System.Windows.MessageBox]::Show("Would you like to add the '$policyName' Location?","$policyName",'YesNo','Question')
        
        switch ($confirmation) {
            'Yes' {
                #Let the console know we're going to add this location
                Write-Host "Now adding: '$policyname' location"

                #Builds a new LocationPolicy with our parameters if yes was chosen.
                New-AzureADMSNamedLocationPolicy @params
            }
    
            'No' {
                #Skips the policy 
                Write-Host "Skipping $policyName."
            }
        }
}


##### CONDITIONAL ACCESS POLICIES


#Save {{BREAKGLASS_ADMIN_GROUP}} replacement value to a variable to a variable
$aad_BREAKGLASS_ADMIN_GROUP_GUID = (Get-AzureADMSGroup| Where-Object -Property displayname -match "break|glass").Id

#If we have two or more matching BG Admins, we'll show a popup for you to select the approproate group
 if (2 -le $aad_BREAKGLASS_ADMIN_GROUP_GUID.count){
    
    #Warn that multiple GUIDs found
    Write-Warning "Multiple matches found for Break Glass Admin Group. Please utilize the popup to select the appropriate group, then click OK"

    #If we don't find a breakglass group, prompt the user to pick one
    $aad_BREAKGLASS_ADMIN_GROUP_GUID = Get-AzureADMSGroup | 
        Out-GridView `
            -PassThru `
            -Title "Select the 'Break Glass' Group to exclude from all Conditional Access Policies, then click OK."
}

#If we don't find a breakglass admin group
if ($null -eq $aad_BREAKGLASS_ADMIN_GROUP_GUID){

    Write-Warning "No Break Glass Groups found. `
        If a group doesn't already exist, please build a group to bypass Conditional Access rules. `
        Once that is completed, press enter to continue the script."

    Pause

    $aad_BREAKGLASS_ADMIN_GROUP_GUID = Get-AzureADMSGroup | 
        Out-GridView `
            -PassThru `
            -Title "Select the 'Break Glass' Group to exclude from all Conditional Access Policies, then click OK."

}

#If we still don't have a breakglass group, exit the script. Otherwise, the object will _not_ be replaced in the template, and the script will fail.
if ($null -eq $aad_BREAKGLASS_ADMIN_GROUP_GUID){
    Write-Warning "No Break Glass Groups found. Policies will fail to be created without an exclusion group. Please build a group to bypass this Conditional Access rule, and rerun the script."
    exit
}

#Write the $aad_BREAKGLASS_ADMIN_GROUP_GUID value to the console
Write-Host "Breakglass Admin Group GUID: "$aad_BREAKGLASS_ADMIN_GROUP_GUID

#Save {{LOCATIONS_GUID}} replacement value to a variable
$ca_NonUSLOCATIONS_GUID = (Get-AzureADMSNamedLocationPolicy | Where-Object -Property displayname -match "^Non-US Countries|^NON_US_COUNTRIES").Id
Write-Host "Non-US Countries GUID: "$ca_NonUsLOCATIONS_GUID

#Save {{ZSCALER_LOCATIONS_GUID}} replacement value to a variable
$ca_ZscalerLocations_GUID = (Get-AzureADMSNamedLocationPolicy | Where-Object -Property displayname -match "Zscaler Gov").Id
Write-Host "Zscaler Gov GUID: "$ca_ZscalerLocations_GUID


#Loops through each Conditional Access Policy JSON file to perform tasks on each of them.
$CAPoliciesPath |
    Select-Object -ExpandProperty Name |
    ForEach-Object {
        
        #Import JSON file, replace odata with odatatype
        $SRPolicySettings = (Get-Content ("$PSScriptRoot\policies\" + $_) -Raw | ConvertFrom-Json)
        
        #Build objects we'll then fill.
        $CAConditionsSet = New-Object -TypeName Microsoft.Open.MSGraph.Model.ConditionalAccessConditionSet
        $CAGrantControls = New-Object -TypeName Microsoft.Open.MSGraph.Model.ConditionalAccessGrantControls
        $CASessionControls = New-Object -TypeName Microsoft.Open.MSGraph.Model.conditionalAccessSessionControls

        $CAConditionsSet = @{
            applications = $SRPolicySettings.conditions.applications
            clientAppTypes = $SRPolicySettings.conditions.clientAppTypes
            Devices = $SRPolicySettings.conditions.Devices
            locations = $SRPolicySettings.conditions.locations
            platforms = $SRPolicySettings.conditions.platforms
            SignInRiskLevels = $SRPolicySettings.conditions.SignInRiskLevels
            UserRiskLevels = $SRPolicySettings.conditions.UserRiskLevels
            users = $SRPolicySettings.conditions.users
        }

        $CAGrantControls = @{
            builtInControls = $SRPolicySettings.grantControls.builtInControls
            customAuthenticationFactors = $SRPolicySettings.grantControls.customAuthenticationFactors
            _operator = $SRPolicySettings.grantControls.operator
            termsOfUse = $SRPolicySettings.grantControls.termsOfUse
        }

        $CASessionControls = @{
            ApplicationEnforcedRestrictions = $SRPolicySettings.sessionControls.ApplicationEnforcedRestrictions
            CloudAppSecurity = $SRPolicySettings.sessionControls.CloudAppSecurity
            PersistentBrowser = $SRPolicySettings.sessionControls.PersistentBrowser
            SignInFrequency = $SRPolicySettings.sessionControls.SignInFrequency
        }

        #REPLACE {{BREAKGLASS_ADMIN_GROUP}} GUID REFERENCES
        #If the breakglass GUID variable isn't empty, and BreakGlass Admins are in the excludegroups
        if (($aad_BREAKGLASS_ADMIN_GROUP_GUID) -and ` 
            ($null -lt ($CAConditionsSet | Where-Object {$_.users.excludegroups -match "{{BreakGlass_Admin_Group}}"}).count)
        ){
            
            #replace the {{BreakGlass_Admin_Group}} in the json with its GUID
            $CAConditionsSet.users.excludeGroups = "$aad_BREAKGLASS_ADMIN_GROUP_GUID"
        }

        #REPLACE {{LOCATIONS_GUID}} (non-us locations guid)
        #If there is a location present in $params & $ca_NonUSLOCATIONS_GUID isn't empty
        if (($ca_NonUSLOCATIONS_GUID) -and ($null -lt ($CAConditionsSet | Where-Object {$_.locations.includelocations -match "{{Locations_guid}}"}))){
            
            Write-Host "Found '{{LOCATIONS_GUID}}'. Replacing with $ca_NonUSLocations_GUID"

            #replace the {{LOCATIONS_GUID}} in the json
            $CAConditionsSet.locations.includeLocations = "$ca_NonUSLOCATIONS_GUID"
        }

        #REPLACE {{ZSCALER_LOCATIONS_GUID}}
        if (($ca_ZscalerLocations_GUID) -and ($null -lt ($CAConditionsSet | Where-Object {$_.locations.excludelocations -match "{{ZSCALER_LOCATIONS_GUID}}"}))){
            
            Write-Host "Found '{{ZSCALER_LOCATIONS_GUID}}'. Replacing with $ca_ZscalerLocations_GUID"
            
            #replace the {{LOCATIONS_GUID}} in the json
            $CAConditionsSet.locations.excludelocations = "$ca_ZscalerLocations_GUID"
        }

        #Define a params variable with only the non-unique values we need.
        $Params = @{
             DisplayName = $SRPolicySettings.DisplayName
             state = $SRPolicySettings.state
        }

        #save the policy name without the .json
        $policyName = $_.split(".")[0]

        #prompt for confirmation
        $confirmation = `
            [System.Windows.MessageBox]::Show("Would you like to add the '$policyName' Policy?","$policyName",'YesNo','Question')
        
        switch  ($confirmation) {
            'Yes' {
                #Builds a new LocationPolicy with our parameters if yes was chosen.
                New-AzureADMSConditionalAccessPolicy `
                    @params `
                    -Conditions $CAConditionsSet `
                    -SessionControls $CASessionControls `
                    -GrantControls $CAGrantControls
            }
    
            'No' {
                #Skips this policy
                Write-Host "Skipping $policyName."
            }
        }
    }
