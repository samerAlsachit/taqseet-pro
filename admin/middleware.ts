import { NextResponse } from 'next/server';
import type { NextRequest } from 'next/server';

export function middleware(request: NextRequest) {
  const token = request.cookies.get('token')?.value;
  const { pathname } = request.nextUrl;

  // الصفحات العامة
  const publicPaths = ['/login'];
  const isPublicPath = publicPaths.includes(pathname);

  // إذا كان المستخدم في صفحة عامة ولديه token في الكوكيز → اذهب للـ dashboard
  if (isPublicPath && token) {
    return NextResponse.redirect(new URL('/dashboard', request.url));
  }

  // إذا كان المستخدم في صفحة محمية وليس لديه token → اذهب للـ login
  if (!isPublicPath && !token) {
    const response = NextResponse.redirect(new URL('/login', request.url));
    // حذف localStorage غير متاح في middleware، لكن نضيف redirect
    return response;
  }

  return NextResponse.next();
}

export const config = {
  matcher: ['/((?!api|_next/static|_next/image|favicon.ico).*)'],
};
