"use client";

import { useState } from "react";

export default function Navbar() {
  const [mobileOpen, setMobileOpen] = useState(false);

  return (
    <nav className="bg-[#0F172A]/80 backdrop-blur-md border-b border-[#1E293B] w-full sticky top-0 z-50">
      <div className="flex justify-between items-center w-full px-6 md:px-8 py-4 max-w-[1200px] mx-auto">
        <a href="/" className="text-xl font-bold tracking-tight text-white flex items-center gap-2">
          <span className="text-[#6366F1]">⚒️</span>
          Forja Trabajo
        </a>

        <div className="hidden md:flex gap-6 items-center">
          <a href="#como-funciona" className="text-[#94A3B8] text-sm font-medium hover:text-white transition-colors">
            Cómo Funciona
          </a>
          <a href="#funcionalidades" className="text-[#94A3B8] text-sm font-medium hover:text-white transition-colors">
            Funcionalidades
          </a>
          <a href="#confianza" className="text-[#94A3B8] text-sm font-medium hover:text-white transition-colors">
            Confianza
          </a>
        </div>

        <div className="hidden md:flex gap-4 items-center">
          <a
            href="https://admin.forjatrabajo.com.mx/"
            className="text-sm font-semibold text-[#94A3B8] hover:text-white transition-colors"
          >
            Iniciar Sesión
          </a>
          <a
            href="#descargar"
            className="bg-[#6366F1] text-white text-sm font-semibold px-5 py-2.5 rounded-lg hover:bg-[#4F46E5] transition-colors"
          >
            Descargar App
          </a>
        </div>

        <button
          className="md:hidden p-2 text-white"
          onClick={() => setMobileOpen(!mobileOpen)}
        >
          <svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            {mobileOpen ? (
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" />
            ) : (
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M4 6h16M4 12h16M4 18h16" />
            )}
          </svg>
        </button>
      </div>

      {mobileOpen && (
        <div className="md:hidden bg-[#0F172A] border-t border-[#1E293B] px-6 py-4 space-y-4">
          <a href="#como-funciona" className="block text-[#94A3B8] text-sm font-medium hover:text-white" onClick={() => setMobileOpen(false)}>
            Cómo Funciona
          </a>
          <a href="#funcionalidades" className="block text-[#94A3B8] text-sm font-medium hover:text-white" onClick={() => setMobileOpen(false)}>
            Funcionalidades
          </a>
          <a href="#confianza" className="block text-[#94A3B8] text-sm font-medium hover:text-white" onClick={() => setMobileOpen(false)}>
            Confianza
          </a>
          <div className="pt-4 border-t border-[#1E293B] space-y-3">
            <a href="https://admin.forjatrabajo.com.mx/" className="block text-sm font-semibold text-[#94A3B8] hover:text-white">
              Iniciar Sesión
            </a>
            <a href="#descargar" className="block bg-[#6366F1] text-white text-sm font-semibold px-5 py-2.5 rounded-lg text-center hover:bg-[#4F46E5] transition-colors" onClick={() => setMobileOpen(false)}>
              Descargar App
            </a>
          </div>
        </div>
      )}
    </nav>
  );
}
