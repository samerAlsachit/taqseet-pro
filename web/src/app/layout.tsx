import type { Metadata } from "next";
import { Tajawal } from "next/font/google";
import "./globals.css";
import { ThemeProvider } from '@/context/ThemeContext';
import { Toaster } from 'react-hot-toast';

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
      <body className={`${tajawal.className} bg-gray-50 dark:bg-gray-900 text-gray-900 dark:text-gray-200`}>
        <ThemeProvider>
          {children}
          <Toaster 
            position="top-center"
            reverseOrder={false}
            gutter={8}
            containerClassName=""
            containerStyle={{}}
            toastOptions={{
              duration: 3000,
              style: {
                background: '#ffffff',
                color: '#333333',
                border: '1px solid #e5e7eb',
                borderRadius: '12px',
                padding: '12px 16px',
                fontSize: '14px',
                fontFamily: 'Tajawal, sans-serif',
              },
              success: {
                iconTheme: {
                  primary: '#28A745',
                  secondary: 'white',
                },
              },
              error: {
                iconTheme: {
                  primary: '#DC3545',
                  secondary: 'white',
                },
              },
            }}
          />
        </ThemeProvider>
      </body>
    </html>
  );
}
