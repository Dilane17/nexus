module.exports = {
  content: ["./app/**/*.{js,jsx,ts,tsx}", "./src/**/*.{js,jsx,ts,tsx}"],
  theme: {
    extend: {
      colors: {
        primary: { DEFAULT: '#003336', container: '#004b50' },
        secondary: { DEFAULT: '#735c00', container: '#fed65b', fixed: '#ffe088' },
        tertiary: { DEFAULT: '#003608' },
        background: '#f8f9fa',
        surface: {
          container_lowest: '#ffffff',
          container_low: '#f1f4f5', // Approximation pour le contraste sans ligne
          container: '#ecefec',
          container_high: '#e6e9e6',
          container_highest: '#e0e3e0'
        },
        on_surface: '#191c1d',
        on_surface_variant: '#404849',
        on_primary: '#ffffff',
        error: { DEFAULT: '#ba1a1a', container: '#ffdad6' },
      },
      fontFamily: {
        display: ['Manrope_700Bold', 'sans-serif'],
        headline: ['Manrope_600SemiBold', 'sans-serif'],
        sans: ['PublicSans_400Regular', 'sans-serif'],
        label: ['PublicSans_500Medium', 'sans-serif'],
      },
      boxShadow: {
        'ambient': '0 12px 40px rgba(25, 28, 29, 0.06)',
      },
      borderRadius: {
        'md': '6px',
        'xl': '12px',
      }
    },
  },
  plugins: [],
}
