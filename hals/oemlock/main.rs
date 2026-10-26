//! OemLock HAL backed by the OP-TEE ta_avb trusted application.

use android_hardware_oemlock::aidl::android::hardware::oemlock::{
    IOemLock::{BnOemLock, IOemLock},
    OemLockSecureStatus::OemLockSecureStatus,
};
use binder::{BinderFeatures, Interface, Status};

extern "C" {
    fn ta_avb_open() -> i32;
    fn ta_avb_close();
    fn ta_avb_read_oem_unlock_allowed(oem_unlock_allowed: *mut u32) -> i32;
    fn ta_avb_write_oem_unlock_allowed(oem_unlock_allowed: u32) -> i32;
}

/// The single open session to ta_avb, held by the C side.
struct TaAvb;

impl TaAvb {
    fn open_session() -> Option<Self> {
        // SAFETY: no arguments; initializes the C-side context and session.
        (unsafe { ta_avb_open() } == 0).then(|| TaAvb)
    }

    fn read_oem_unlock_allowed(&self) -> Option<bool> {
        let mut allowed = 0u32;
        // SAFETY: `allowed` is a valid u32 that the call writes to and does not keep.
        (unsafe { ta_avb_read_oem_unlock_allowed(&mut allowed) } == 0).then_some(allowed != 0)
    }

    fn write_oem_unlock_allowed(&self, allowed: bool) -> bool {
        // SAFETY: plain value argument.
        (unsafe { ta_avb_write_oem_unlock_allowed(allowed as u32) }) == 0
    }
}

impl Drop for TaAvb {
    fn drop(&mut self) {
        // SAFETY: a TaAvb exists only after ta_avb_open() succeeded.
        unsafe { ta_avb_close() }
    }
}

fn tee_error(msg: &str) -> Status {
    Status::new_service_specific_error_str(1, Some(msg))
}

struct OemLock {
    ta: TaAvb,
}

impl Interface for OemLock {}

impl IOemLock for OemLock {
    fn getName(&self) -> binder::Result<String> {
        Ok("OemLock HAL OP-TEE".to_string())
    }

    fn isOemUnlockAllowedByCarrier(&self) -> binder::Result<bool> {
        Ok(true)
    }

    fn setOemUnlockAllowedByCarrier(
        &self,
        _allowed: bool,
        _signature: &[u8],
    ) -> binder::Result<OemLockSecureStatus> {
        Ok(OemLockSecureStatus::OK)
    }

    fn isOemUnlockAllowedByDevice(&self) -> binder::Result<bool> {
        self.ta
            .read_oem_unlock_allowed()
            .ok_or_else(|| tee_error("Failed to read OEM unlock allowed"))
    }

    fn setOemUnlockAllowedByDevice(&self, allowed: bool) -> binder::Result<()> {
        if self.ta.write_oem_unlock_allowed(allowed) {
            Ok(())
        } else {
            Err(tee_error("Failed to write OEM unlock allowed"))
        }
    }
}

fn main() {
    let ta = TaAvb::open_session().expect("Failed to open ta_avb session");
    let service = BnOemLock::new_binder(OemLock { ta }, BinderFeatures::default());

    binder::ProcessState::set_thread_pool_max_thread_count(0);
    binder::add_service("android.hardware.oemlock.IOemLock/default", service.as_binder())
        .expect("Failed to register OemLock HAL");
    binder::ProcessState::join_thread_pool();
}
