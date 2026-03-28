import type { Metadata } from "next";
import { Inter, Tajawal } from "next/font/google";
import { ThemeProvider } from '../context/ThemeContext';
import "./globals.css";

const inter = Inter({ 
  subsets: ["latin"],
  variable: '--font-inter',
});

const tajawal = Tajawal({ 
  weight: ['400', '500', '700', '800'],
  subsets: ["arabic"],
  variable: '--font-tajawal',
});

export const metadata: Metadata = {
  title: "مرساة | نظام إدارة الأقساط",
  description: "نظام متكامل لإدارة الأقساط والديون للمحلات التجارية في العراق",
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="ar" dir="rtl">
      <body className={`${inter.variable} ${tajawal.variable} antialiased bg-[var(--bg-primary)] text-[var(--text-primary)]`}>
        <ThemeProvider>
          {children}
        </ThemeProvider>
      </body>
    </html>
  );
}
