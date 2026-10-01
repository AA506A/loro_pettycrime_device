/** @type {import('tailwindcss').Config} */
module.exports = {
  content: ['./vending/index.html'],
  theme: {
    extend: {
      colors: {
        hgreen: '#00ff41',
        hdark: '#0a0a0a',
        hamber: '#ffb000',
        hred: '#ff2020',
      },
      fontFamily: {
        mono: ['"Courier New"', 'monospace'],
      },
    },
  },
  plugins: [],
};
