import winrm
import getpass
import sys


def manage_remote_printer_via_winrm():
    print("=== Remote Printer Manager (via WinRM) ===")

    # 1. Get Connection Details
    target_ip = input("Enter Target IP Address: ").strip()
    username = input("Enter Username: ").strip()
    password = getpass.getpass("Enter Password: ").strip()

    print(f"\nConnecting to {target_ip} via WinRM...")

    try:
        # 2. Establish Session
        # We use 'ntlm' transport which is standard for Windows
        session = winrm.Session(target_ip, auth=(username, password), transport="ntlm")

        # 3. PowerShell script to fetch printers
        # We get Name and whether it is Default
        ps_script_list = """
        Get-WmiObject -Class Win32_Printer | Select-Object Name, Default | ConvertTo-Json
        """

        result = session.run_ps(ps_script_list)

        if result.status_code != 0:
            print("[ERROR] Failed to retrieve printers.")
            print(f"Error: {result.std_err.decode('utf-8')}")
            return

        # Parse JSON output from PowerShell
        import json

        output_str = result.std_out.decode("utf-8")

        # Handle cases where no printers exist or single printer returns dict instead of list
        try:
            printers_data = json.loads(output_str)
            if isinstance(printers_data, dict):
                printers_data = [printers_data]  # Convert single dict to list
        except json.JSONDecodeError:
            print(
                "[ERROR] Could not parse printer list. Ensure PowerShell is working on target."
            )
            return

        if not printers_data:
            print("No printers found on remote machine.")
            return

        # 4. Display Printers
        print(f"\n--- Printer List for {target_ip} ---")
        printer_names = []

        for i, p in enumerate(printers_data):
            p_name = p.get("Name")
            is_def = " [CURRENT DEFAULT]" if p.get("Default") else ""
            printer_names.append(p_name)
            print(f"{i + 1}. {p_name}{is_def}")

        print("---------------------------------------")

        # 5. User Selection
        while True:
            try:
                choice_input = input("\nEnter number to set as default: ")
                choice = int(choice_input)
                if 1 <= choice <= len(printer_names):
                    target_printer_name = printer_names[choice - 1]
                    break
                else:
                    print(f"Please enter a number between 1 and {len(printer_names)}.")
            except ValueError:
                print("Invalid input. Please enter a number.")

        # 6. Set Default Printer
        print(f"\nSetting '{target_printer_name}' as default...")

        # PowerShell script to set default
        # We use Invoke-Method to bypass some WMI wrappers
        ps_script_set = f"""
        $printer = Get-WmiObject -Class Win32_Printer -Filter "Name='{target_printer_name}'"
        $printer.SetDefaultPrinter()
        """

        set_result = session.run_ps(ps_script_set)

        if set_result.status_code == 0:
            # Check for specific success code in return usually 0
            print("SUCCESS: Default printer command executed.")
            print(
                "Note: This changes the default printer for the USER logged in via this script."
            )
        else:
            print("[ERROR] Failed to set default printer.")
            print(set_result.std_err.decode("utf-8"))

    except winrm.exceptions.InvalidCredentialsError:
        print("\n[ERROR] Invalid Credentials. Please check username/password.")
    except winrm.exceptions.WinRMTransportError as e:
        print(
            f"\n[ERROR] Connection refused. Ensure WinRM is enabled on target ({target_ip})."
        )
        print("Run 'Enable-PSRemoting -Force' in PowerShell on the target machine.")
    except Exception as e:
        print(f"\n[ERROR] Unexpected error: {e}")


if __name__ == "__main__":
    manage_remote_printer_via_winrm()
