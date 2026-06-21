package io.github.nishian3695.bujit.Interfaces;

/*
Callback interface for RecyclerView item tap and long-press events.
Adapters receive a ClickListener at construction time and delegate
user gestures back to the host Activity or Fragment through it.
*/
public interface ClickListener {

    // Called when the user taps an item at the given adapter position
    void onPositionClicked(int position);

    // Called when the user long-presses an item at the given adapter position
    void onLongClicked(int position);
}
