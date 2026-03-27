import * as XLSX from 'xlsx';
import jsPDF from 'jspdf';
import autoTable from 'jspdf-autotable';

export interface ExportData {
  headers: string[];
  rows: any[][];
  title?: string;
  filename: string;
}

// تصدير إلى Excel
export const exportToExcel = ({ headers, rows, filename }: ExportData) => {
  const worksheet = XLSX.utils.aoa_to_sheet([headers, ...rows]);
  const workbook = XLSX.utils.book_new();
  XLSX.utils.book_append_sheet(workbook, worksheet, 'التقرير');
  XLSX.writeFile(workbook, `${filename}.xlsx`);
};

// تصدير إلى PDF
export const exportToPDF = ({ headers, rows, title, filename }: ExportData) => {
  const doc = new jsPDF({
    orientation: 'landscape',
    unit: 'mm',
    format: 'a4',
  });

  // إضافة العنوان
  if (title) {
    doc.setFont('helvetica', 'bold');
    doc.setFontSize(18);
    doc.text(title, 14, 15);
    
    doc.setFontSize(10);
    doc.setTextColor(100);
    doc.text(`تاريخ التقرير: ${new Date().toLocaleDateString('ar-IQ')}`, 14, 25);
  }

  // إضافة الجدول
  autoTable(doc, {
    head: [headers],
    body: rows,
    startY: title ? 35 : 15,
    theme: 'striped',
    headStyles: {
      fillColor: [58, 134, 255],
      textColor: 255,
      fontStyle: 'bold',
    },
    styles: {
      font: 'helvetica',
      fontSize: 9,
      cellPadding: 3,
    },
    didDrawPage: (data) => {
      // إضافة رقم الصفحة
      const pageCount = doc.getNumberOfPages();
      doc.setFontSize(8);
      doc.setTextColor(150);
      doc.text(
        `الصفحة ${data.pageNumber} من ${pageCount}`,
        doc.internal.pageSize.getWidth() - 20,
        doc.internal.pageSize.getHeight() - 10
      );
    },
  });

  doc.save(`${filename}.pdf`);
};
