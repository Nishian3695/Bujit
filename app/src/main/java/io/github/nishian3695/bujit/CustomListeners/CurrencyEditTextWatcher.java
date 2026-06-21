package io.github.nishian3695.bujit.CustomListeners;

import android.text.Editable;
import android.text.TextWatcher;
import android.widget.EditText;

/*
TextWatcher that enforces a maximum of two decimal places on a currency EditText.
When the user types a third digit after the decimal point, the extra character
is immediately stripped and the cursor is moved to the end of the field.
*/
public class CurrencyEditTextWatcher implements TextWatcher {

    // EditText being monitored
    private EditText editText;
    public CurrencyEditTextWatcher(EditText editText) {
        this.editText = editText;
    }

    // No action needed before text changes
    @Override
    public void beforeTextChanged(CharSequence charSequence, int i, int i1, int i2) {

    }

    // On text change, ensure currency format
    @Override
    public void onTextChanged(CharSequence charSequence, int i, int i1, int i2) {
        String currencyText = charSequence.toString();
        if (currencyText.contains(".") &&
                currencyText.substring(currencyText.indexOf(".") + 1).length() > 2) {
            editText.setText(currencyText.substring(0, currencyText.length() - 1));
            editText.setSelection(editText.getText().length());
        }
    }

    @Override
    public void afterTextChanged(Editable editable) {

    }
}
