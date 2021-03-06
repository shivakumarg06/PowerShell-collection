﻿#requires -Version 2.0

<#
      .SYNOPSIS
      Exchange Server Logs Cleanup

      .DESCRIPTION
      Cleanup some Exchange Sevrer logs.

      .EXAMPLE
      PS C:\> .\CleanupExchangeLogs.ps1

      .NOTES
      Version: 1.0.1

      GUID: bc2b3de9-4a03-481f-94af-c1b7d9f363f0

      Author: Joerg Hochwald

      Companyname: Alright-IT GmbH

      Copyright: Copyright (c) 2019, Alright IT GmbH - All rights reserved.

      License: https://opensource.org/licenses/BSD-3-Clause

      Releasenotes:
      1.0.1 2019-07-08: Move the delete process to the dedicated Invoke-CleanupOldFiles function
      1.0.0 2019-02-04: Internal Release

      THIS CODE IS MADE AVAILABLE AS IS, WITHOUT WARRANTY OF ANY KIND. THE ENTIRE RISK OF THE USE OR THE RESULTS FROM THE USE OF THIS CODE REMAINS WITH THE USER.

      .LINK
      https://www.alright-it.com

      .LINK
      Invoke-CleanupOldFiles
#>
[CmdletBinding(ConfirmImpact = 'Low')]
param ()

begin {
   # You can change the number of days here
   $days = 30

   #region PowerShell2WorkArounds
   <#
         The following stuff is a workaround to make everything compatible to PowerShell 2.0
         Old, but some still have the old crap on the Exchaneg server runnning, sorry!
   #>
   #region RequiredModuleWorkAround
   if (Get-Module -Name webadministration -ListAvailable -ErrorAction SilentlyContinue)
   {
      try
      {
         $null = (Import-Module -Name webadministration -Force -ErrorAction Stop)
      }
      catch
      {
         #region ErrorHandler
         # get error record
         [Management.Automation.ErrorRecord]$e = $_

         # retrieve information about runtime error
         $info = @{
            Exception = $e.Exception.Message
            Reason    = $e.CategoryInfo.Reason
            Target    = $e.CategoryInfo.TargetName
            Script    = $e.InvocationInfo.ScriptName
            Line      = $e.InvocationInfo.ScriptLineNumber
            Column    = $e.InvocationInfo.OffsetInLine
         }

         $info | Out-String | Write-Verbose

         Write-Error -Message ($info.Exception) -ErrorAction Stop

         # Only here to catch a global ErrorAction overwrite
         break
         #endregion ErrorHandler
      }
   }
   else
   {
      #region ErrorHandler
      $paramWriteError = @{
         Message     = 'The required Module (webadministration) is missing!'
         Category    = 'ObjectNotFound'
         ErrorAction = 'Stop'
      }
      Write-Error @paramWriteError

      # Only here to catch a global ErrorAction overwrite
      break
      #endregion ErrorHandler
   }
   #endregion RequiredModuleWorkAround

   #region RunAsAdministrator
   function Test-Administrator
   {
      <#
            .SYNOPSIS
            Check if this is an elevated shell

            .DESCRIPTION
            Check if this is an elevated shell.

            In Powershell 4.0 it can be replaced with:
            #Requires -RunAsAdministrator

            .EXAMPLE
            PS C:\> Test-Administrator

            .NOTES
            In Powershell 4.0 it can be replaced with: Requires -RunAsAdministrator

            License: Public Domain
      #>
      [CmdletBinding(ConfirmImpact = 'None')]
      [OutputType([bool])]
      param ()

      process
      {
         $user = [Security.Principal.WindowsIdentity]::GetCurrent()
         (New-Object -TypeName Security.Principal.WindowsPrincipal -ArgumentList $user).IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)
      }
   }

   if ((Test-Administrator) -ne $true)
   {
      #region ErrorHandler
      Write-Error -Message 'The current Windows PowerShell session is not running as Administrator. Start Windows PowerShell by using the Run as Administrator option, and then try running the script again.' -Category NotEnabled -ErrorAction Stop

      # Only here to catch a global ErrorAction overwrite
      break
      #endregion ErrorHandler
   }
   #endregion RunAsAdministrator
   #endregion PowerShell2WorkArounds

   # Cleanup
   $LogDirList = $null

   # Create a new List
   $LogDirList = (New-Object -TypeName System.Collections.Generic.List[System.Object])

   # Add static Directories to the new list
   if ($env:ExchangeInstallPath)
   {
      $LogDirList.Add($env:ExchangeInstallPath + 'Logging\')

      # Another possible Directory
      #$LogDirList.Add($env:ExchangeInstallPath + 'Bin\Search\Ceres\Diagnostics\Logs\')
   }
   else
   {
      Write-Warning -Message 'This is not a Exchange Server!'
   }

   # Get a list of all IIS Websites and add to the new list
   $AllIISSites = (Get-Website)

   if ($AllIISSites)
   {
      # Loop over the IIS Site list
      foreach ($SingleWebSite in $AllIISSites)
      {
         # Cleanup
         $IISLogDirectory = $null

         # Get the Log-Directory from the IIS Info
         $IISLogDirectory = ($SingleWebSite.logfile.directory)

         <#
               Replace the returned %SystemDrive% with your Systemdrive.
               This is your BOOT Drive!!! Usualy it is C:
         #>
         if ($IISLogDirectory -match '%SystemDrive%')
         {
            Write-Verbose -Message 'Mangle the SystemDrive within the variable...'

            $IISLogDirectory = ($IISLogDirectory -replace '%SystemDrive%', 'C:')
         }

         # Add the log Directory to the List
         $LogDirList.Add($IISLogDirectory)
      }
   }
   else
   {
      Write-Warning -Message 'No IIS Log-Directory found!'
   }

   # Make all entries in the List unique
   $LogDirList = ($LogDirList | Sort-Object | Get-Unique)

   #region Invoke-CleanupOldFiles
   function Invoke-CleanupOldFiles
   {
      <#
            .SYNOPSIS
            Remove files older then a given number of days

            .DESCRIPTION
            Remove files older then a given number of days.
            Mostly used within cleanup Tasks.

            .PARAMETER Path
            Path to search.

            .PARAMETER Age
            Age of files to remove, in days.
            Defaults to 30

            .EXAMPLE
            PS C:\> Invoke-CleanupoldFiles -Path 'C:\inetpub\logs\LogFiles'

            .EXAMPLE
            PS C:\> Invoke-CleanupoldFiles -Path 'C:\inetpub\logs\LogFiles' -Age 14

            .NOTES
            Version: 1.0.1

            GUID: d79b3ac3-6d3a-475d-9825-1649720eeb69

            Author: Joerg Hochwald

            Companyname: Alright-IT GmbH

            Copyright: Copyright (c) 2019, Alright IT GmbH - All rights reserved.

            License: https://opensource.org/licenses/BSD-3-Clause

            Releasenotes:
            1.0.1 2019-07-08: Rework and splatting
            1.0.0 2019-02-04: Internal Release

            THIS CODE IS MADE AVAILABLE AS IS, WITHOUT WARRANTY OF ANY KIND. THE ENTIRE RISK OF THE USE OR THE RESULTS FROM THE USE OF THIS CODE REMAINS WITH THE USER.

            .LINK
            https://www.alright-it.com

            .LINK
            Get-ChildItem

            .LINK
            Test-Path

            .LINK
            Get-Date
      #>
      [CmdletBinding(ConfirmImpact = 'Low')]
      param
      (
         [Parameter(Mandatory = $true,
               ValueFromPipeline = $true,
               ValueFromPipelineByPropertyName = $true,
               Position = 0,
         HelpMessage = 'Path to search.')]
         [ValidateNotNullOrEmpty()]
         [Alias('TargetFolder')]
         [string]
         $Path,
         [Parameter(ValueFromPipeline = $true,
               ValueFromPipelineByPropertyName = $true,
         Position = 1)]
         [ValidateNotNullOrEmpty()]
         [Alias('Days')]
         [int]
         $Age = 30
      )

      process
      {
         if (Test-Path -Path $Path)
         {
            # Save the date to use it for the compare
            $Now = (Get-Date)

            # Today minus given days
            $LastWrite = $Now.AddDays(-$days)

            # Splatting the parameters
            $paramGetChildItem = @{
               Path    = $Path
               Include = '*.log', '*.blg'
               Recurse = $true
            }

            # Find all Files to Delete (e.g. older then the given value)
            $Files = (Get-ChildItem @paramGetChildItem | Where-Object -FilterScript {
                  (-not ($_.PSIsContainer)) -and ($_.LastWriteTime -le $LastWrite)
            } | Select-Object -ExpandProperty fullname)

            # Loop over the list of Files
            foreach ($File in $Files)
            {
               # Support for WhatIf and Verbose
               if ($pscmdlet.ShouldProcess($File, 'Remove'))
               {
                  # Splatting the parameters
                  $paramRemoveItem = @{
                     Path        = $File
                     ErrorAction = 'SilentlyContinue'
                     Force       = $true
                     WhatIf      = $false
                  }
                  # Remove the files that we found
                  $null = (Remove-Item @paramRemoveItem)
               }
            }
         }
         else
         {
            #region ErrorHandler
            # get error record
            [Management.Automation.ErrorRecord]$e = $_

            # retrieve information about runtime error
            $info = @{
               Exception = $e.Exception.Message
               Reason    = $e.CategoryInfo.Reason
               Target    = $e.CategoryInfo.TargetName
               Script    = $e.InvocationInfo.ScriptName
               Line      = $e.InvocationInfo.ScriptLineNumber
               Column    = $e.InvocationInfo.OffsetInLine
            }

            $info | Out-String | Write-Verbose

            Write-Error -Message ($info.Exception) -ErrorAction Stop

            # Only here to catch a global ErrorAction overwrite
            break
            #endregion ErrorHandler
         }
      }
   }
   #endregion Invoke-CleanupOldFiles
}

process {
   # Do we have a lif of directories?
   if ($LogDirList)
   {
      # Loop over the List of Directories
      foreach ($LogDir in $LogDirList)
      {
         Write-Verbose -Message "Removing logs from $LogDir older then $days days"

         try
         {
            # Do we have a DAY value
            if ($days)
            {
               # Splatting the parameters
               $paramInvokeCleanupoldFiles = @{
                  Path        = $LogDir
                  Age         = $days
                  ErrorAction = 'Stop'
                  verbose     = $true
               }
            }
            else
            {
               # Splatting the parameters
               $paramInvokeCleanupoldFiles = @{
                  Path        = $LogDir
                  ErrorAction = 'Stop'
                  verbose     = $true
               }
            }

            # Invoke the internal Fun
            Invoke-CleanupOldFiles @paramInvokeCleanupoldFiles
         }
         catch
         {
            #region ErrorHandler
            # get error record
            [Management.Automation.ErrorRecord]$e = $_

            # retrieve information about runtime error
            $info = @{
               Exception = $e.Exception.Message
               Reason    = $e.CategoryInfo.Reason
               Target    = $e.CategoryInfo.TargetName
               Script    = $e.InvocationInfo.ScriptName
               Line      = $e.InvocationInfo.ScriptLineNumber
               Column    = $e.InvocationInfo.OffsetInLine
            }

            $info | Out-String | Write-Verbose

            Write-Error -Message ($info.Exception) -ErrorAction Stop

            # Only here to catch a global ErrorAction overwrite
            break
            #endregion ErrorHandler
         }
      }
   }
   else
   {
      #region ErrorHandler
      $paramWriteError = @{
         Message     = 'No directories found to cleanup'
         Category    = 'ObjectNotFound'
         ErrorAction = 'Stop'
      }
      Write-Error @paramWriteError

      # Only here to catch a global ErrorAction overwrite
      break
      #endregion ErrorHandler
   }
}
