interface StatusBadgeProps {
  status: 'paid' | 'pending' | 'overdue' | 'active' | 'inactive' | 'expired';
  children: string;
  className?: string;
}

export default function StatusBadge({ status, children, className = '' }: StatusBadgeProps) {
  const statusStyles = {
    paid: {
      bg: 'bg-success',
      text: 'text-white',
      border: 'border-green-600'
    },
    pending: {
      bg: 'bg-warning',
      text: 'text-white',
      border: 'border-yellow-500'
    },
    overdue: {
      bg: 'bg-danger',
      text: 'text-white',
      border: 'border-red-600'
    },
    active: {
      bg: 'bg-electric',
      text: 'text-white',
      border: 'border-blue-600'
    },
    inactive: {
      bg: 'bg-[var(--bg-primary)]',
      text: 'text-gray-700',
      border: 'border-gray-300'
    },
    expired: {
      bg: 'bg-danger',
      text: 'text-white',
      border: 'border-red-600'
    }
  };

  const style = statusStyles[status];

  return (
    <span
      className={`
        inline-flex
        items-center
        px-3
        py-1
        rounded-full
        text-sm
        font-medium
        border
        ${style.bg}
        ${style.text}
        ${style.border}
        ${className}
      `}
    >
      {children}
    </span>
  );
}
