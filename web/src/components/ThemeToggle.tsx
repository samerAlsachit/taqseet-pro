'use client';
import { useTheme } from './ThemeProvider';

export function ThemeToggle() {
  const { dark, toggle } = useTheme();
  return (
    <button
      onClick={toggle}
      className="px-4 py-2 rounded-lg bg-gray-100 dark:bg-gray-800 text-gray-900 dark:text-gray-100 transition-colors"
    >
      {dark ? '☀️ Light' : '🌙 Dark'}
    </button>
  );
}
