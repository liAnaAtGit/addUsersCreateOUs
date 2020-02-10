#function 
#
#importOrganizations
#
##Takes OUs in files, checks whether an OU with the same name exists within current structure. If they do not exist, adds them to current domain. Else, skips them.  
#
function importOrganizations ($orgfilePath) 
{
    $org = $null; 
    $orgFile = $null; 
    $newOrg = $null;
    $ouname = $null;
    $orgNames = @();  

    #dump file contents
    $orgFile = Import-Csv -Path $orgFilePath -Header Name, City, Description, DisplayName, State; 

    echo " --- OU FILE ---" 
    echo $orgFile
    echo "----------------" 
    
    foreach ($org in $orgFile)
    {
        #Process OU name.
        $ouName = $org.Name.ToString(); 

        if ($ouName -ne "Name") #skip first row
        { 
            echo "Curr. Row =  $($ouName)";
             
            #See if OU already exists (with that name)
            $newOrg = Get-ADOrganizationalUnit -Filter {Name -eq $ouName};
            
            echo " > Org exists? $($null -ne $newOrg)";

            if ($null -ne $newOrg) 
            {
                echo "OU already exists! Skipped."
            }
            else #Create OU in current structure. 
            {
                $newOrg = New-ADOrganizationalUnit -Name $org.Name -City $org.City -Description $Org.Description -DisplayName $org.DisplayName -State $org.State;
                $orgNames += $newOrg.objectGUID; 
            
                echo $newOrg;
            }
         }

         $ouName = $null; 
         $newOrg = $null; 
    }
    return $orgNames;
}

function importUsers ($userfilePath) 
{

    $user = $null; 
    $userFile = $null;
    $newUser = $null;  
    $userNames = @(); 
    $userOU = $null; 
    $potentialOU = $null;

    
    #Create users
    $userFile = Import-Csv -Path $userfilePath -Header Name, Enabled, GivenName, Organization, Surname, Title, userPrincipalName; 
   
    foreach ($user in $userFile)
    {
        echo $user | Format-Table -wrap;
        if ($user.name -ne "Name") 
        {    
            #Must Convert csv contents to string to use properly. 
            $userOU = $user.Organization.ToString();
            $potentialOU = Get-ADOrganizationalUnit -Filter {Name -eq $userOU};
            if ($user.organization -eq $potentialOU.Name) #must plan for more than 1 org having same name. May want to make include right path?
            {
                $newUser = New-ADUser -Name $user.Name -GivenName $user.GivenName -Path $potentialOU.distinguishedName -Surname $user.Surname -Title $user.Title -userPrincipalName $user.userPrincipalName;
                echo $newUser;
                $userNames += $newUser.distinguishedName; 
            }
            else {
                echo "Not added due to nonexistent organization." + $userOu; 
            }
         }

         $userOU = $null; 
         $potentialOU = $null; 
         $newUser = $null; 
    }
    echo "-------------USERNAMES--------------------" 
    echo $userNames 
    echo " -----------------------------------------" 

}

function print-UsersInOrg ($oGUID) {
    $theGUID = $oGuid;

    $organization = Get-ADOrganizationalUnit -Filter {ObjectGUID -eq $theGUID};
    Get-ADObject -SearchBase $organization.DistinguishedName -LDAPFilter '(ObjectClass=User)';
}

function isValidTextFile ($fpath) {
    #if org path exists, is .txt file, is not null, blank. 

    if ($fpath -eq $null)
    {
        Write-Host "Invalid path: Filepath is null.";
        return $false; 
    } 
    elseif ($fpath.length -le 4) {
        Write-Host "Invalid path: Filepath is too short.";
        return $false;
    }
    else 
    {
        return [System.IO.File]::Exists($fpath);
    } 
}

function main {
    $inputOrgFile = $null;
    $inputUserFile = $null; 
    $orgList = $null; 
    $singularOrg = $null; 
    
    $inputOrgFile = Read-Host  "Organization file";
    $inputUserFile = Read-Host  "User file";  

    #Assuming proper organizations included here. 
    
    if (isValidTextFile ($inputOrgFile)) 
    {
        echo "Valid Org File" 
        $orgList = importOrganizations ($inputOrgFile); 
        
        if (isValidTextFile ($inputUserFile)) 
        {
            importUsers ($inputUserFile);
        }

        foreach ($singularOrg in $orgList) 
        {
            print-UsersInOrg ($singularOrg.objectguid); 
        }
    }
    else 
    {
        Write-Host "Invalid org file"; 
    } 
}

function importUsersTests {
    $nullInputFile = $null; 
    $inputUserFile = $null; 
    
    $inputUserFile = Read-Host  "User file";  

    #Assuming proper organizations included here. 
    
        
    if (isValidTextFile ($inputUserFile)) 
    {
        importUsers ($inputUserFile);
    }
    else 
    {
        Write-Host "Invalid user file"; 
    } 
}

function importOUsTests {
    $inputOUFile = $null; 
    
    $inputOUFile = Read-Host  "OU file";  

    #Assuming proper organizations included here. 
    
        
    if (isValidTextFile ($inputOUFile)) 
    {
        importOrganizations ($inputOUFile);
    }
    else 
    {
        Write-Host "Invalid OU file"; 
    } 
}


#importOUsTests
#importUsersTests
main