import { ReactNode } from 'react';

interface TableColumn {
  key: string;
  title: string;
  render?: (value: any, row: any) => ReactNode;
  className?: string;
}

interface TableProps {
  columns: TableColumn[];
  data: any[];
  loading?: boolean;
  className?: string;
}

export default function Table({ columns, data, loading = false, className = '' }: TableProps) {
  if (loading) {
    return (
      <div className="flex justify-center py-8">
        <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-electric"></div>
      </div>
    );
  }

  if (!data || data.length === 0) {
    return (
      <div className="text-center py-8 text-gray-500">
        لا توجد بيانات لعرضها
      </div>
    );
  }

  return (
    <div className={`overflow-x-auto ${className}`}>
      <table className="data-table">
        <thead>
          <tr>
            {columns.map((column) => (
              <th key={column.key} className={column.className}>
                {column.title}
              </th>
            ))}
          </tr>
        </thead>
        <tbody>
          {data.map((row, index) => (
            <tr key={index}>
              {columns.map((column) => (
                <td key={column.key}>
                  {column.render 
                    ? column.render(row[column.key], row)
                    : row[column.key]
                  }
                </td>
              ))}
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
}
