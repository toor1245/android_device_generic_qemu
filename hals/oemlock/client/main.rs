//! Command-line client for the IOemLock HAL, standing in for OemLockService.

use android_hardware_oemlock::aidl::android::hardware::oemlock::IOemLock::IOemLock;
use std::io::Write;
use std::process::ExitCode;

const SERVICE: &str = "android.hardware.oemlock.IOemLock/default";

fn usage(out: &mut dyn Write, prog: &str) {
    let _ = write!(
        out,
        "{prog} - command-line wrapper for the OemLock HAL.

Usage:
  {prog} COMMAND

Commands:
  hal-info                       - Show info about the OemLock HAL used.
  get-status                     - Prints whether OEM unlock is allowed by
                                   the carrier and by the device.
  is-allowed-by-carrier          - Prints true/false; returns 0 only if the
                                   carrier allows OEM unlock.
  is-allowed-by-device           - Prints true/false; returns 0 only if the
                                   device allows OEM unlock.
  set-allowed-by-device VALUE    - Allow (1) or disallow (0) OEM unlock on this
                                   device, like the \"OEM unlocking\" switch in
                                   Settings > Developer options.
  help                           - Show this help.

The device flag is stored by the ta_avb trusted application in RPMB and is
read by the bootloader for 'fastboot flashing unlock'.
"
    );
}

enum Command {
    HalInfo,
    GetStatus,
    IsAllowedByCarrier,
    IsAllowedByDevice,
    SetAllowedByDevice(bool),
}

fn parse(args: &[&str]) -> Option<Command> {
    Some(match args {
        ["hal-info"] => Command::HalInfo,
        ["get-status"] => Command::GetStatus,
        ["is-allowed-by-carrier"] => Command::IsAllowedByCarrier,
        ["is-allowed-by-device"] => Command::IsAllowedByDevice,
        ["set-allowed-by-device", "1"] => Command::SetAllowedByDevice(true),
        ["set-allowed-by-device", "0"] => Command::SetAllowedByDevice(false),
        _ => return None,
    })
}

fn print_and_exit(condition: bool) -> ExitCode {
    println!("{condition}");
    if condition {
        ExitCode::SUCCESS
    } else {
        ExitCode::FAILURE
    }
}

fn run(hal: &dyn IOemLock, command: Command) -> binder::Result<ExitCode> {
    Ok(match command {
        Command::HalInfo => {
            println!("HAL name: {}", hal.getName()?);
            println!("HAL service: {SERVICE}");
            ExitCode::SUCCESS
        }
        Command::GetStatus => {
            println!("OEM unlock allowed by carrier: {}", hal.isOemUnlockAllowedByCarrier()?);
            println!("OEM unlock allowed by device:  {}", hal.isOemUnlockAllowedByDevice()?);
            ExitCode::SUCCESS
        }
        Command::IsAllowedByCarrier => print_and_exit(hal.isOemUnlockAllowedByCarrier()?),
        Command::IsAllowedByDevice => print_and_exit(hal.isOemUnlockAllowedByDevice()?),
        Command::SetAllowedByDevice(allowed) => {
            hal.setOemUnlockAllowedByDevice(allowed)?;
            ExitCode::SUCCESS
        }
    })
}

fn main() -> ExitCode {
    let args: Vec<String> = std::env::args().collect();
    let prog = args.first().map_or("oemlock-cli", String::as_str);
    let args: Vec<&str> = args.iter().skip(1).map(String::as_str).collect();

    if matches!(args[..], ["help"] | ["-h"] | ["--help"]) {
        usage(&mut std::io::stdout(), prog);
        return ExitCode::SUCCESS;
    }
    let Some(command) = parse(&args) else {
        usage(&mut std::io::stderr(), prog);
        return ExitCode::FAILURE;
    };

    let hal: binder::Strong<dyn IOemLock> = match binder::get_interface(SERVICE) {
        Ok(hal) => hal,
        Err(e) => {
            eprintln!("Error getting {SERVICE}: {e:?}");
            return ExitCode::FAILURE;
        }
    };

    run(&*hal, command).unwrap_or_else(|e| {
        eprintln!("Error: {e}");
        ExitCode::FAILURE
    })
}
