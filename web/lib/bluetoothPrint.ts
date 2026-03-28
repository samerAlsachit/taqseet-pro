// هذه خدمة طباعة البلوتوث
// ستستخدم Web Bluetooth API للمتصفحات الحديثة

export interface BluetoothPrinter {
  device: any;
  name: string;
  id: string;
}

// طلب الاتصال بطابعة بلوتوث
export const connectToBluetoothPrinter = async (): Promise<BluetoothPrinter | null> => {
  try {
    // التحقق من توفر Web Bluetooth
    if (!navigator.bluetooth) {
      alert('المتصفح لا يدعم تقنية Bluetooth. يرجى استخدام Chrome أو Edge.');
      return null;
    }

    const device = await navigator.bluetooth.requestDevice({
      acceptAllDevices: true,
      optionalServices: ['000018f0-0000-1000-8000-00805f9b34fb'] // خدمة الطباعة العامة
    });

    const server = await device.gatt?.connect();
    if (!server) throw new Error('فشل الاتصال بالطابعة');

    return {
      device,
      name: device.name || 'طابعة بلوتوث',
      id: device.id
    };
  } catch (error) {
    console.error('خطأ في الاتصال بالطابعة:', error);
    alert('فشل الاتصال بالطابعة: ' + (error as Error).message);
    return null;
  }
};

// طباعة وصل
export const printReceipt = async (printer: BluetoothPrinter, receiptHtml: string) => {
  try {
    const device = printer.device;
    const server = await device.gatt?.connect();
    if (!server) throw new Error('فشل الاتصال بالطابعة');

    // البحث عن خدمة الطباعة
    const service = await server.getPrimaryService('000018f0-0000-1000-8000-00805f9b34fb');
    const characteristic = await service.getCharacteristic('00002af1-0000-1000-8000-00805f9b34fb');

    // تحويل HTML إلى نص للطباعة (تبسيط)
    const textToPrint = stripHtml(receiptHtml);
    const encoder = new TextEncoder();
    const data = encoder.encode(textToPrint + '\n\n\n\n');

    await characteristic.writeValue(data);
    
    return true;
  } catch (error) {
    console.error('خطأ في الطباعة:', error);
    throw error;
  }
};

// إزالة HTML tags
const stripHtml = (html: string) => {
  const tmp = document.createElement('div');
  tmp.innerHTML = html;
  return tmp.textContent || tmp.innerText || '';
};

// التحقق من توفر Bluetooth
export const isBluetoothAvailable = () => {
  return 'bluetooth' in navigator;
};
