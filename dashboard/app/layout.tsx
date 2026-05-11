import type { Metadata } from 'next';
import { Inter } from 'next/font/google';
import './globals.css';

const inter = Inter({ subsets: ['latin'] });

export const metadata: Metadata = {
  title: 'NEXUS Admin',
  description: 'Dashboard administrateur NEXUS P2P Lending',
};

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="fr" className={inter.className}>
      <body className="h-full">{children}</body>
    </html>
  );
}
