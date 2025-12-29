/** @type {import('tailwindcss').Config} */
module.exports = {
  content: ["./index.html", "./owner.html", "./src/**/*.{js,jsx}"],
  theme: {
    extend: {
      fontFamily: {
        sans: ["Inter", "ui-sans-serif", "system-ui", "sans-serif"],
      },
      colors: {
        brand: "#2563eb",
        "brand-soft": "rgba(37,99,235,0.12)",
        "brand-muted": "#1d4ed8",
        "surface-1": "#f6f7fb",
        "surface-2": "rgba(255,255,255,0.82)",
        "surface-3": "rgba(246,247,251,0.65)",
      },
      boxShadow: {
        "soft-xl": "0 18px 40px rgba(15,23,42,0.08)",
        "soft-md": "0 12px 32px rgba(15,23,42,0.08)",
      },
      backgroundImage: {
        "hero-gradient":
          "radial-gradient(120% 140% at 0% 0%, rgba(37,99,235,0.12) 0%, rgba(15,23,42,0.02) 45%, rgba(37,99,235,0.18) 100%)",
      },
      borderRadius: {
        "3xl": "1.5rem",
      },
    },
  },
};

