/** @type {import('tailwindcss').Config} */
module.exports = {
  content: ['./parkingmeter/index.html'],
  theme: {
    extend: {
      colors: {
        cyan: '#00c8ff',
        cdark: '#060a10',
        cdim: '#0a1520',
        camber: '#ffa500',
        cred: '#ff3c3c',
      },
      fontFamily: {
        mono: ['"Share Tech Mono"', '"Courier New"', 'monospace'],
      },
    },
  },
  plugins: [],
};
