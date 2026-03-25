/** @type {import('tailwindcss').Config} */
module.exports = {
  content: [
    "./app/**/*.{js,ts,jsx,tsx,mdx}",
    "./components/**/*.{js,ts,jsx,tsx,mdx}",
    "./src/**/*.{js,ts,jsx,tsx,mdx}", // إضافة مسار src
  ],
  theme: {
    extend: {
      colors: {
        navy: '#0A192F',
        electric: '#3A86FF',
        success: '#28A745',
        warning: '#FFC107',
        danger: '#DC3545',
        'gray-bg': '#F8F9FA',  // غير الاسم إلى kebab-case
        'text-primary': '#333333',
      },
      fontFamily: {
        arabic: ['Tajawal', 'sans-serif'],
        numbers: ['Inter', 'Tajawal', 'sans-serif'],
      },
    },
  },
  plugins: [],
}
