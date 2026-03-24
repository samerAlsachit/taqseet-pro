import './globals.css'
import { Inter } from 'next/font/google'

const inter = Inter({ subsets: ['arabic'] })

export const metadata = {
  title: 'تقسيط برو - نظام إدارة الأقساط',
  description: 'نظام متكامل لإدارة الأقساط للتجار والموظفين',
}

export default function RootLayout({
  children,
}: {
  children: React.ReactNode
}) {
  return (
    <html lang="ar" dir="rtl">
      <body className={inter.className}>{children}</body>
    </html>
  )
}
