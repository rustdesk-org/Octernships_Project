use super::*;
// Section: wire functions

#[wasm_bindgen]
pub fn wire_get_username(port_: MessagePort) {
    wire_get_username_impl(port_)
}

#[wasm_bindgen]
pub fn wire_print_root_folder(port_: MessagePort, password: String) {
    wire_print_root_folder_impl(port_, password)
}

#[wasm_bindgen]
pub fn wire_check_polkit(port_: MessagePort) {
    wire_check_polkit_impl(port_)
}

// Section: allocate functions

// Section: related functions

// Section: impl Wire2Api

impl Wire2Api<String> for String {
    fn wire2api(self) -> String {
        self
    }
}

impl Wire2Api<Vec<u8>> for Box<[u8]> {
    fn wire2api(self) -> Vec<u8> {
        self.into_vec()
    }
}
// Section: impl Wire2Api for JsValue

impl Wire2Api<String> for JsValue {
    fn wire2api(self) -> String {
        self.as_string().expect("non-UTF-8 string, or not a string")
    }
}
impl Wire2Api<u8> for JsValue {
    fn wire2api(self) -> u8 {
        self.unchecked_into_f64() as _
    }
}
impl Wire2Api<Vec<u8>> for JsValue {
    fn wire2api(self) -> Vec<u8> {
        self.unchecked_into::<js_sys::Uint8Array>().to_vec().into()
    }
}
