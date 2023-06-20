use super::*;
// Section: wire functions

#[wasm_bindgen]
pub fn wire_get_username(port_: MessagePort) {
    wire_get_username_impl(port_)
}

#[wasm_bindgen]
pub fn wire_determine_escalation_methods(port_: MessagePort) {
    wire_determine_escalation_methods_impl(port_)
}

#[wasm_bindgen]
pub fn wire_get_directory_listing(
    port_: MessagePort,
    method: i32,
    username: Option<String>,
    password: Option<String>,
) {
    wire_get_directory_listing_impl(port_, method, username, password)
}

// Section: allocate functions

// Section: related functions

// Section: impl Wire2Api

impl Wire2Api<String> for String {
    fn wire2api(self) -> String {
        self
    }
}

impl Wire2Api<Option<String>> for Option<String> {
    fn wire2api(self) -> Option<String> {
        self.map(Wire2Api::wire2api)
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
impl Wire2Api<EscalationMethod> for JsValue {
    fn wire2api(self) -> EscalationMethod {
        (self.unchecked_into_f64() as i32).wire2api()
    }
}
impl Wire2Api<i32> for JsValue {
    fn wire2api(self) -> i32 {
        self.unchecked_into_f64() as _
    }
}
impl Wire2Api<Option<String>> for JsValue {
    fn wire2api(self) -> Option<String> {
        (!self.is_undefined() && !self.is_null()).then(|| self.wire2api())
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
