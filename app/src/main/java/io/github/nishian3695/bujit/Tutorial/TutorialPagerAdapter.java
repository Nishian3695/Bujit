package io.github.nishian3695.bujit.Tutorial;

import android.content.Context;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import androidx.annotation.NonNull;
import androidx.viewpager.widget.PagerAdapter;
import io.github.nishian3695.bujit.R;

public class TutorialPagerAdapter extends PagerAdapter {

    private final Context context;
    private static final int[] LAYOUTS = {
            R.layout.tutorial_page_1_main,
            R.layout.tutorial_page_2_income,
            R.layout.tutorial_page_3_credit,
            R.layout.tutorial_page_4_banking,
            R.layout.tutorial_page_5_settings
    };

    public TutorialPagerAdapter(Context context) {
        this.context = context;
    }

    @Override
    public int getCount() {
        return LAYOUTS.length;
    }

    @NonNull
    @Override
    public Object instantiateItem(@NonNull ViewGroup container, int position) {
        View view = LayoutInflater.from(context).inflate(LAYOUTS[position], container, false);
        container.addView(view);
        return view;
    }

    @Override
    public void destroyItem(@NonNull ViewGroup container, int position, @NonNull Object object) {
        container.removeView((View) object);
    }

    @Override
    public boolean isViewFromObject(@NonNull View view, @NonNull Object object) {
        return view == object;
    }
}
