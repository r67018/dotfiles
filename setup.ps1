$directories = Get-ChildItem ./.config
foreach($dir in $directories) {
    $path = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath("~/.config/$($dir.Name)")
    New-Item -Path $path -Value $dir.FullName -Type SymbolicLink
}

