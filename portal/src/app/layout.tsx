import type { Metadata } from "next";
import { Inter } from "next/font/google";
import Link from "next/link";
import "./globals.css";
import { StarknetProvider } from "@/components/StarknetProvider";

const inter = Inter({ subsets: ["latin"] });

export const metadata: Metadata = {
  title: "Epicue — Equity, Privacy & Integrity on Starknet",
  description:
    "EQUISYS Epicue: A FATE-compliant, Starknet-native healthcare data registry. Built with Cairo, powered by STARK proofs.",
};

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="en" className="dark">
      <body className={`${inter.className} bg-[#0a0a12] text-white antialiased`}>
        <StarknetProvider>
          <nav className="fixed top-0 left-0 right-0 z-50 flex justify-center p-6 pointer-events-none">
            <div className="flex bg-[#11111b]/80 backdrop-blur-xl border border-white/5 rounded-2xl px-2 py-1.5 shadow-2xl pointer-events-auto">
              <Link href="/" className="px-4 py-2 rounded-xl hover:bg-white/5 transition-all text-sm font-medium text-white/40 hover:text-white">Registry</Link>
              <Link href="/submit" className="px-4 py-2 rounded-xl hover:bg-white/5 transition-all text-sm font-medium text-white/40 hover:text-white">Submit</Link>
              <Link href="/governance" className="px-4 py-2 rounded-xl hover:bg-white/5 transition-all text-sm font-medium text-white/40 hover:text-white font-semibold">Governance</Link>
            </div>
          </nav>
          <div className="pt-20">
            {children}
          </div>
        </StarknetProvider>
      </body>
    </html>
  );
}
