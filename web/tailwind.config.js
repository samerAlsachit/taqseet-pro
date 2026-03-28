/** @type {import('tailwindcss').Config} */
module.exports = {
  darkMode: 'class',
  content: [
    "./app/**/*.{js,ts,jsx,tsx,mdx}",
    "./components/**/*.{js,ts,jsx,tsx,mdx}",
  ],
  theme: {
    extend: {
      colors: {
        navy: '#0A192F',
        electric: '#3A86FF',
        success: '#28A745',
        warning: '#FFC107',
        danger: '#DC3545',
        'gray-bg': '#F8F9FA',
        'text-primary': '#333333',
      },
      fontFamily: {
        arabic: ['Tajawal', 'sans-serif'],
      },
    },
  },
  plugins: [],
}
