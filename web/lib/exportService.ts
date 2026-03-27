import * as XLSX from 'xlsx';
import pdfMake from 'pdfmake/build/pdfmake';
import pdfFonts from 'pdfmake/build/vfs_fonts';

// تهيئة الخطوط العربية
pdfMake.vfs = pdfFonts.pdfMake.vfs;

export interface ExportData {
  headers: string[];
  rows: any[][];
  title?: string;
  filename: string;
}

export const exportToExcel = ({ headers, rows, filename }: ExportData) => {
  const worksheet = XLSX.utils.aoa_to_sheet([headers, ...rows]);
  const workbook = XLSX.utils.book_new();
  XLSX.utils.book_append_sheet(workbook, worksheet, 'التقرير');
  XLSX.writeFile(workbook, `${filename}.xlsx`);
};

export const exportToPDF = ({ headers, rows, title, filename }: ExportData) => {
  const docDefinition = {
    content: [
      { text: title, style: 'header', alignment: 'center' },
      { text: `تاريخ التقرير: ${new Date().toLocaleDateString('ar-IQ')}`, alignment: 'center', margin: [0, 0, 0, 20] },
      {
        table: {
          headerRows: 1,
          widths: Array(headers.length).fill('auto'),
          body: [headers, ...rows]
        },
        layout: 'lightHorizontalLines'
      }
    ],
    styles: {
      header: {
        fontSize: 18,
        bold: true,
        margin: [0, 0, 0, 10]
      }
    },
    defaultStyle: {
      font: 'Roboto' // أو أي خط يدعم العربية
    }
  };

  pdfMake.createPdf(docDefinition).download(`${filename}.pdf`);
};
