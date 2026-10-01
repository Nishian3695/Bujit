/*
Utility for formatting currency values on-the-fly as user uses EditText fields
*/
// class CurrencyTextWatcher implements TextWatcher {
//     // The EditText being monitored
//     TextEditingController _controller;
//     // TODO:  Allow updates to EditText (necessary?)
//     CurrencyTextWatcher(TextEditingController controller) {
//         this._controller = controller;
//     }

//     // After text change, enforce currency formatting
//     @override
//     void afterTextChanged(String s, int start, int count, int after) {
//         // Old code has an if statement -- we can just enforce formatting every time
//         String formattedValue = CurrencyFormat().formatToString(s);
//         _controller.text = formattedValue;
//     }
// }