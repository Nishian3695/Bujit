package io.github.nishian3695.bujit.Tutorial;

import android.os.Bundle;
import android.util.TypedValue;
import android.view.MenuItem;
import android.view.View;
import android.widget.Button;
import android.widget.LinearLayout;
import android.widget.TextView;
import androidx.appcompat.app.AppCompatActivity;
import androidx.core.graphics.Insets;
import androidx.core.view.ViewCompat;
import androidx.core.view.WindowInsetsCompat;
import androidx.viewpager.widget.ViewPager;
import io.github.nishian3695.bujit.R;
import io.github.nishian3695.bujit.ThemeHelper;

/*
Tutorial activity to help the user understand the 
app features through a series of pages.
*/
public class TutorialActivity extends AppCompatActivity {

    public static final String PREFS_NAME = "bujit_tutorial_prefs";
    public static final String KEY_SEEN = "tutorial_seen";
    private static final int PAGE_COUNT = 5;
    private ViewPager viewPager;
    private Button btnBack, btnNext;
    private LinearLayout dotsContainer;
    private TextView[] dots;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        ThemeHelper.applyAccentTheme(this);
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_tutorial);
        ThemeHelper.tintActionBar(this);

        ViewCompat.setOnApplyWindowInsetsListener(
                ((android.view.ViewGroup) findViewById(android.R.id.content)).getChildAt(0),
                (v, insets) -> {
                    Insets bars = insets.getInsets(WindowInsetsCompat.Type.systemBars());
                    v.setPadding(0, bars.top, 0, bars.bottom);
                    return WindowInsetsCompat.CONSUMED;
                });

        if (getSupportActionBar() != null) {
            getSupportActionBar().setDisplayHomeAsUpEnabled(true);
            getSupportActionBar().setTitle("Tutorial");
        }

        viewPager = findViewById(R.id.tutorial_view_pager);
        btnBack = findViewById(R.id.btn_tutorial_back);
        btnNext = findViewById(R.id.btn_tutorial_next);
        dotsContainer = findViewById(R.id.tutorial_dots_container);

        viewPager.setAdapter(new TutorialPagerAdapter(this));

        setupDots();
        updateNavButtons(0);

        viewPager.addOnPageChangeListener(new ViewPager.SimpleOnPageChangeListener() {
            @Override
            public void onPageSelected(int position) {
                updateNavButtons(position);
                updateDots(position);
            }
        });

        btnBack.setOnClickListener(v -> {
            int current = viewPager.getCurrentItem();
            if (current > 0) viewPager.setCurrentItem(current - 1);
        });

        btnNext.setOnClickListener(v -> {
            int current = viewPager.getCurrentItem();
            if (current < PAGE_COUNT - 1) {
                viewPager.setCurrentItem(current + 1);
            } else {
                finishTutorial();
            }
        });
    }

    @Override
    public boolean onOptionsItemSelected(MenuItem item) {
        if (item.getItemId() == android.R.id.home) {
            finishTutorial();
            return true;
        }
        return super.onOptionsItemSelected(item);
    }

    private void setupDots() {
        dots = new TextView[PAGE_COUNT];
        int primaryColor = resolveAttrColor(com.google.android.material.R.attr.colorPrimary);
        for (int i = 0; i < PAGE_COUNT; i++) {
            dots[i] = new TextView(this);
            dots[i].setText("●");
            dots[i].setTextSize(12f);
            dots[i].setTextColor(primaryColor);
            LinearLayout.LayoutParams params = new LinearLayout.LayoutParams(
                    LinearLayout.LayoutParams.WRAP_CONTENT,
                    LinearLayout.LayoutParams.WRAP_CONTENT);
            params.setMargins(10, 0, 10, 0);
            dots[i].setLayoutParams(params);
            dotsContainer.addView(dots[i]);
        }
        updateDots(0);
    }

    private void updateDots(int selected) {
        for (int i = 0; i < PAGE_COUNT; i++) {
            dots[i].setAlpha(i == selected ? 1f : 0.3f);
        }
    }

    private void updateNavButtons(int position) {
        btnBack.setVisibility(position == 0 ? View.INVISIBLE : View.VISIBLE);
        btnNext.setText(position == PAGE_COUNT - 1 ? "Done" : "Next");
    }

    private void finishTutorial() {
        getSharedPreferences(PREFS_NAME, MODE_PRIVATE)
                .edit().putBoolean(KEY_SEEN, true).apply();
        finish();
    }

    private int resolveAttrColor(int attr) {
        TypedValue typedValue = new TypedValue();
        getTheme().resolveAttribute(attr, typedValue, true);
        return typedValue.data;
    }
}
