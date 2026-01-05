
                    $p = Get-WmiObject Win32_Printer | Where-Object { $_.Name -eq 'Fax1' }
                    if ($p) { $p.SetDefaultPrinter() }
                    