import { Anchor } from 'lucide-react';

export default function LoadingSpinner() {
  return (
    <div className="fixed inset-0 bg-[var(--bg-primary)] flex flex-col items-center justify-center z-50">
      <div className="animate-pulse">
        <Anchor className="text-electric w-16 h-16 mb-4" />
      </div>
      <div className="relative">
        <h1 className="text-3xl font-bold text-navy dark:text-white">مرساة</h1>
        <div className="absolute -bottom-2 left-0 w-full h-0.5 bg-electric animate-pulse" />
      </div>
      <p className="text-gray-500 dark:text-gray-400 mt-4 text-sm">جاري التحميل...</p>
    </div>
  );
}
