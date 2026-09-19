import type { Metadata, Viewport } from 'next';
import './globals.css';
import BottomNav from '@/components/BottomNav';
import PWARegister from '@/components/PWARegister';

export const metadata: Metadata = {
  title: 'SermonHub',
  description: 'Listen to sermons, discover teaching, and stay connected.',
  icons: { icon: '/icons/favicon-32x32.png', apple: '/icons/apple-touch-icon.png' },
  manifest: '/manifest.webmanifest'
};
export const viewport: Viewport = { themeColor: '#000000', width: 'device-width', initialScale: 1 };

export default function RootLayout({children}:{children:React.ReactNode}){
  return <html lang="en"><body><PWARegister/><main className="app-shell">{children}</main><BottomNav/></body></html>;
}
