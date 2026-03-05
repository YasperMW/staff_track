/** @type {import('tailwindcss').Config} */
export default {
  content: [
    "./index.html",
    "./src/**/*.{js,ts,jsx,tsx}",
  ],
  darkMode: 'class',
  theme: {
    extend: {
      colors: {
        // Organization Colors - matching Flutter app
        'sky-blue': '#0284C7',
        'dark-sky-blue': '#0369A1',
        'light-gold': '#F59E0B',
        'light-gold-accent': '#FCD34D',
        'pale-red': '#EF4444',
        'pale-red-accent': '#F87171',
        
        // Theme Colors
        'background-white': '#F8FAFC',
        'surface-white': '#FFFFFF',
        'text-dark': '#0F172A',
        'text-grey': '#64748B',
        'text-light-blue': '#94A3B8',
        
        // Dark theme colors
        'background-dark': '#0F172A',
        'surface-dark': '#1E293B',
        'text-dark-light': '#F8FAFC',
        'text-grey-dark': '#94A3B8',
        'text-light-blue-dark': '#64748B',
      },
      fontFamily: {
        'poppins': ['Poppins', 'sans-serif'],
      },
      borderRadius: {
        'xl': '12px',
        '2xl': '16px',
        '3xl': '20px',
        '4xl': '24px',
      },
      boxShadow: {
        'card': '0 10px 20px rgba(0, 0, 0, 0.04)',
        'card-hover': '0 20px 40px rgba(0, 0, 0, 0.08)',
        'card-dark': '0 10px 20px rgba(0, 0, 0, 0.3)',
        'card-hover-dark': '0 20px 40px rgba(0, 0, 0, 0.5)',
      },
    },
  },
  plugins: [
    require('@tailwindcss/typography'),
  ],
}
