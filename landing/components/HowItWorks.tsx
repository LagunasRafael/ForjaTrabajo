"use client";

import { useState } from "react";

const steps = {
  client: [
    {
      icon: "📝",
      title: "Publica tu necesidad",
      description: "Describe el trabajo que necesitas, agrega fotos y establece tu presupuesto.",
    },
    {
      icon: "👥",
      title: "Elige al mejor profesional",
      description: "Recibe propuestas de trabajadores verificados, compara precios y calificaciones.",
    },
    {
      icon: "🔒",
      title: "Paga seguro con escrow",
      description: "Tu dinero se mantiene protegido hasta que el trabajo esté completado a tu satisfacción.",
    },
    {
      icon: "⭐",
      title: "Califica el servicio",
      description: "Deja una reseña para ayudar a la comunidad y mantener la calidad del servicio.",
    },
  ],
  worker: [
    {
      icon: "📱",
      title: "Postúlate a trabajos",
      description: "Explora servicios cerca de ti y envía tu propuesta con precio y descripción.",
    },
    {
      icon: "🤝",
      title: "Acepta el trabajo",
      description: "Cuando el cliente te elija, comienza el trabajo con toda la información del servicio.",
    },
    {
      icon: "💰",
      title: "Cobra al instante",
      description: "Al completar el trabajo, recibe el pago directamente en tu cuenta de forma segura.",
    },
    {
      icon: "📈",
      title: "Crece tu reputación",
      description: "Acumula calificaciones positivas y aparece en los primeros resultados de búsqueda.",
    },
  ],
};

export default function HowItWorks() {
  const [activeTab, setActiveTab] = useState<"client" | "worker">("client");

  return (
    <section id="como-funciona" className="max-w-[1200px] mx-auto px-6 md:px-8 py-20 md:py-24">
      <div className="text-center mb-12">
        <span className="text-[#6366F1] text-xs font-semibold tracking-[0.2em] uppercase">
          Proceso Simple
        </span>
        <h2 className="text-3xl md:text-4xl font-bold text-white mt-4 leading-tight">
          ¿Cómo funciona?
        </h2>
        <p className="text-[#94A3B8] text-lg mt-4 max-w-2xl mx-auto">
          Ya sea que busques un profesional o quieras conseguir trabajos, el proceso es simple y seguro.
        </p>
      </div>

      <div className="flex justify-center mb-12">
        <div className="inline-flex bg-[#0F172A] border border-[#1E293B] rounded-lg p-1">
          <button
            onClick={() => setActiveTab("client")}
            className={`px-6 py-2.5 rounded-md text-sm font-semibold transition-all ${
              activeTab === "client"
                ? "bg-[#6366F1] text-white shadow-lg"
                : "text-[#94A3B8] hover:text-white"
            }`}
          >
            Para Clientes
          </button>
          <button
            onClick={() => setActiveTab("worker")}
            className={`px-6 py-2.5 rounded-md text-sm font-semibold transition-all ${
              activeTab === "worker"
                ? "bg-[#6366F1] text-white shadow-lg"
                : "text-[#94A3B8] hover:text-white"
            }`}
          >
            Para Trabajadores
          </button>
        </div>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
        {steps[activeTab].map((step, index) => (
          <div
            key={index}
            className="bg-[#0F172A] border border-[#1E293B] rounded-xl p-6 hover:border-[#6366F1]/50 transition-all group"
          >
            <div className="flex items-center gap-3 mb-4">
              <span className="text-2xl">{step.icon}</span>
              <span className="text-[#6366F1] text-xs font-bold">
                PASO {index + 1}
              </span>
            </div>
            <h3 className="text-white font-semibold text-lg mb-2 group-hover:text-[#818CF8] transition-colors">
              {step.title}
            </h3>
            <p className="text-[#94A3B8] text-sm leading-relaxed">
              {step.description}
            </p>
          </div>
        ))}
      </div>
    </section>
  );
}
