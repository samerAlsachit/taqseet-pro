import type { Metadata } from "next";
import { Tajawal } from "next/font/google";
import "./globals.css";
import { ThemeProvider } from '@/context/ThemeContext';

const tajawal = Tajawal({ 
  weight: ['400', '500', '700', '800'],
  subsets: ["latin"],
});

export const metadata: Metadata = {
  title: "مرساة | نظام إدارة الأقساط",
  description: "نظام متكامل لإدارة الأقساط والديون للمحلات التجارية في العراق",
};

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="ar" dir="rtl" suppressHydrationWarning>
      <body className={`${tajawal.className} bg-gray-bg text-text-primary dark:bg-gray-900 dark:text-gray-200`}>
        <ThemeProvider>
          {children}
        </ThemeProvider>
      </body>
    </html>
  );
}
