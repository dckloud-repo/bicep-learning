#MSIX app attach staging sample

#region variables
$vhdSrc="\\dckloudmain.file.core.windows.net\appattach\vscode.vhdx"
$packageName = "vscode.vhdx"
$parentFolder = "vscode"
$parentFolder = "\" + $parentFolder + "\"
$volumeGuid = "c525203c-351d-42ae-bd5c-a2a65c070cfc"
$msixJunction = "C:\temp\AppAttach\"
#endregion

#region mountvhd
try
{
      Mount-Diskimage -ImagePath $vhdSrc -NoDriveLetter -Access ReadOnly
      Write-Host ("Mounting of " + $vhdSrc + " was completed!") -BackgroundColor Green
}
catch
{
      Write-Host ("Mounting of " + $vhdSrc + " has failed!") -BackgroundColor Red
}
#endregion

#region makelink
$msixDest = "\\?\Volume{" + $volumeGuid + "}\"
if (!(Test-Path $msixJunction))
{
     md $msixJunction
}

$msixJunction = $msixJunction + $packageName
cmd.exe /c mklink /j $msixJunction $msixDest
#endregion

#region stage
[Windows.Management.Deployment.PackageManager,Windows.Management.Deployment,ContentType=WindowsRuntime] | Out-Null
Add-Type -AssemblyName System.Runtime.WindowsRuntime
$asTask = ([System.WindowsRuntimeSystemExtensions].GetMethods() | Where { $_.ToString() -eq 'System.Threading.Tasks.Task`1[TResult] AsTask[TResult,TProgress](Windows.Foundation.IAsyncOperationWithProgress`2[TResult,TProgress])'})[0]
$asTaskAsyncOperation = $asTask.MakeGenericMethod([Windows.Management.Deployment.DeploymentResult], [Windows.Management.Deployment.DeploymentProgress])
$packageManager = [Windows.Management.Deployment.PackageManager]::new()
$path = $msixJunction + $parentFolder + $packageName 
$path = ([System.Uri]$path).AbsoluteUri
$asyncOperation = $packageManager.StagePackageAsync($path, $null, "StageInPlace")
$task = $asTaskAsyncOperation.Invoke($null, @($asyncOperation))
$task
#endregion