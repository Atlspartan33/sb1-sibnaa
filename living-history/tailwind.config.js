/** @type {import('tailwindcss').Config} */
export default {
  content: ['./index.html', './src/**/*.{js,ts,jsx,tsx}'],
  theme: {
    extend: {
      colors: {
        // Palette drawn from Egyptian pigments: papyrus, ochre, lapis, malachite, carbon ink.
        papyrus: {
          50: '#fbf8f1',
          100: '#f5eedd',
          200: '#ebdcb8',
          300: '#dcc28a',
        },
        ochre: {
          400: '#d08a3c',
          500: '#b8702a',
          600: '#965620',
        },
        lapis: {
          500: '#2f4f8f',
          600: '#243e73',
          700: '#1b2f57',
        },
        malachite: {
          500: '#2f7d68',
          600: '#246352',
        },
        ink: {
          700: '#2e2a25',
          800: '#211e1a',
          900: '#161412',
        },
      },
      fontFamily: {
        sans: ['Inter', 'system-ui', 'sans-serif'],
        display: ['"Cormorant Garamond"', 'Georgia', 'serif'],
      },
    },
  },
  plugins: [],
};
