import type { Metadata } from "next";
import { Inter } from "next/font/google";
import "./globals.css";

const inter = Inter({
  variable: "--font-inter",
  subsets: ["latin"],
});

export const metadata: Metadata = {
  title: "Forja Trabajo - Encuentra profesionales o consigue trabajos cerca de ti",
  description: "La plataforma que conecta clientes con trabajadores verificados. Pagos seguros con escrow, chat en tiempo real y perfiles verificados.",
  keywords: "trabajo, servicios, profesionales, empleos, Mexico, forja trabajo",
  openGraph: {
    title: "Forja Trabajo",
    description: "Encuentra profesionales verificados o consigue trabajos cerca de ti.",
    type: "website",
    locale: "es_MX",
  },
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="es" className={`${inter.variable} antialiased`}>
      <body className="min-h-screen flex flex-col bg-[#020617] text-white font-sans">
        {children}
      </body>
    </html>
  );
}
