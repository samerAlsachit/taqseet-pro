import { NextResponse } from 'next/server';
import type { NextRequest } from 'next/server';

export function middleware(request: NextRequest) {
  const token = request.cookies.get('token')?.value;
  const { pathname } = request.nextUrl;

  // الصفحات العامة
  const publicPaths = ['/login', '/register-super-admin'];
  const isPublicPath = publicPaths.includes(pathname);

  // إذا كان المستخدم في صفحة عامة ولديه token
  if (isPublicPath && token) {
    // تحقق من صلاحيات المستخدم
    try {
      const payload = JSON.parse(atob(token.split('.')[1]));
      if (payload.role === 'super_admin') {
        return NextResponse.redirect(new URL('/dashboard', request.url));
      } else {
        // تاجر عادي يحاول الدخول → يمنع
        return NextResponse.redirect(new URL('/unauthorized', request.url));
      }
    } catch {
      return NextResponse.next();
    }
  }

  // إذا كان المستخدم في صفحة محمية وليس لديه token
  if (!isPublicPath && !token) {
    return NextResponse.redirect(new URL('/login', request.url));
  }

  // التحقق من صلاحيات السوبر أدمن للصفحات المحمية
  if (!isPublicPath && token) {
    try {
      const payload = JSON.parse(atob(token.split('.')[1]));
      if (payload.role !== 'super_admin') {
        return NextResponse.redirect(new URL('/unauthorized', request.url));
      }
    } catch {
      return NextResponse.redirect(new URL('/login', request.url));
    }
  }

  return NextResponse.next();
}

export const config = {
  matcher: ['/((?!api|_next/static|_next/image|favicon.ico).*)'],
};
