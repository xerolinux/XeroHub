// Downlevel modern CSS in dev so the tunnelled preview runs on older browsers
// (e.g. Vivaldi/Chromium < 112). Using PostCSS plugins instead of the
// lightningcss transformer avoids the vendor-prefix dedupe bug that strips
// unprefixed `backdrop-filter`.
import postcssNesting from 'postcss-nesting';
import postcssMediaMinmax from 'postcss-media-minmax';

export default {
  plugins: [
    postcssNesting(),       // selector { @media { … } }  →  @media { selector { … } }
    postcssMediaMinmax(),   // (width >= 440px)           →  (min-width: 440px)
  ],
};
