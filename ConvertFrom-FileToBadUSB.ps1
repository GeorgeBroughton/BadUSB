param(
    [system.io.fileinfo]$Path,
    [int]$StringLength = 100,
    [int]$Delay = 1000,
    [switch]$UseAltString,
    [switch]$Open,
    [switch]$Cleanup
)

$sb = [System.Text.StringBuilder]::new()

    # Open notepad because the keyboard buffer is dealt with efficientlyish here...
    [void]$sb.AppendLine("DELAY 500")
    [void]$sb.AppendLine("GUI r")
    [void]$sb.AppendLine("DELAY 500")
    [void]$sb.AppendLine("STRING notepad")
    [void]$sb.AppendLine("ENTER")
    [void]$sb.AppendLine("DELAY 1000")

        # Convert the file to STRING/ALTSTRING lines of the specified length (default 100)
        # This is done because stuffing hundreds of kilobytes in a single buffer for the flipper to enumerate into keyboard commands just makes it shit itself.
        # If you have this problem. Remember, BACK + LEFT to reset the flipper.
        # Also, please note that delay is used here because while the typing buffer for notepad is more efficient, it's also laggy as balls.

        if ($UseAltString) {
            [convert]::ToBase64String((Get-Content -Path $Path.FullName -AsByteStream)) -split "(\S{$StringLength})" | ForEach-Object { if ($_) {
                [void]$sb.AppendLine("ALTSTRING $_")
                [void]$sb.AppendLine("DELAY $Delay")
            }}
        } else {
            [convert]::ToBase64String((Get-Content -Path $Path.FullName -AsByteStream )) -split "(\S{$StringLength})" | ForEach-Object { if ($_) {
                [void]$sb.AppendLine("STRING $_")
                [void]$sb.AppendLine("DELAY $Delay")
            }}
        }

    # Now we save the file somewhere. %HOMEPATH% is probably good enough.
    [void]$sb.AppendLine("DELAY 2000")
    [void]$sb.AppendLine("ALT f")
    [void]$sb.AppendLine("STRING a")
    [void]$sb.AppendLine("DELAY 500")
    [void]$sb.AppendLine("ALT t")
    [void]$sb.AppendLine("STRING a")
    [void]$sb.AppendLine("CONTROL l")
    [void]$sb.AppendLine("ALTSTRING %HOMEPATH%")
    [void]$sb.AppendLine("ENTER")
    [void]$sb.AppendLine("ALT n")
    [void]$sb.AppendLine("ALTSTRING $($Path.BaseName).txt")
    [void]$sb.AppendLine("ENTER")
    [void]$sb.AppendLine("DELAY 500")
    [void]$sb.AppendLine("ALT F4")

    # Now we actually convert the file to its correct format.
    [void]$sb.AppendLine("DELAY 2000")
    [void]$sb.AppendLine("GUI r")
    [void]$sb.AppendLine("DELAY 500")
    [void]$sb.AppendLine("STRING powershell")
    [void]$sb.AppendLine("ENTER")
    [void]$sb.AppendLine("DELAY 750")
    [void]$sb.AppendLine("ALTSTRING [IO.File]::WriteAllBytes(`"`$env:homepath\$($Path.Name)`", [Convert]::FromBase64String((Get-Content -Path `"`$env:homepath\$($Path.BaseName).txt`")))")
    [void]$sb.AppendLine("ENTER")

    # Now we delete the base64 file as it shouldn't be needed.
    if ($cleanup) {
        [void]$sb.AppendLine("ALTSTRING Remove-Item -Path `"`$Env:homepath\$($Path.BaseName).txt`" -Force")
        [void]$sb.AppendLine("ENTER")
    }

    # Now let's open our file
    if ($Open) {
        [void]$sb.AppendLine("ALTSTRING & `"`$Env:homepath\$($Path.Name)`" ; Exit")
        [void]$sb.AppendLine("ENTER")
    }

return $sb.ToString()