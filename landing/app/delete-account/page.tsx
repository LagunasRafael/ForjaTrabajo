"use client";

import { useState, useEffect, Suspense } from "react";
import { useSearchParams } from "next/navigation";

const CONFIRMATION_TEXT = "confirmo eliminar mi cuenta";

function DeleteAccountContent() {
  const searchParams = useSearchParams();
  const token = searchParams.get("token");

  const [inputValue, setInputValue] = useState("");
  const [isValid, setIsValid] = useState(false);
  const [status, setStatus] = useState<"idle" | "loading" | "success" | "error">("idle");
  const [errorMessage, setErrorMessage] = useState("");

  useEffect(() => {
    setIsValid(inputValue.toLowerCase().trim() === CONFIRMATION_TEXT);
  }, [inputValue]);

  const handleDelete = async () => {
    if (!isValid || !token) return;

    setStatus("loading");
    setErrorMessage("");

    try {
      const response = await fetch(`${process.env.NEXT_PUBLIC_API_URL || "https://api.forjatrabajo.com.mx"}/auth/delete-account`, {
        method: "DELETE",
        headers: {
          "Content-Type": "application/json",
          "Authorization": `Bearer ${token}`,
        },
      });

      if (!response.ok) {
        const data = await response.json().catch(() => ({}));
        throw new Error(data.detail || "No se pudo eliminar la cuenta. Contacta a soporte.");
      }

      setStatus("success");
    } catch (err) {
      setStatus("error");
      setErrorMessage(err instanceof Error ? err.message : "Error desconocido");
    }
  };

  if (status === "success") {
    return (
      <div className="min-h-screen flex items-center justify-center px-6 py-20">
        <div className="max-w-md w-full text-center">
          <div className="inline-flex items-center justify-center w-16 h-16 bg-green-500/10 border border-green-500/20 rounded-full mb-4">
            <svg className="w-8 h-8 text-green-500" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M5 13l4 4L19 7" />
            </svg>
          </div>
          <h1 className="text-2xl font-bold text-white mb-2">Cuenta eliminada</h1>
          <p className="text-[#94A3B8] text-sm">
            Tu cuenta ha sido eliminada permanentemente. Todos tus datos han sido borrados de nuestros sistemas.
          </p>
          <a href="/" className="inline-block mt-6 text-[#6366F1] hover:underline text-sm">
            Volver al inicio
          </a>
        </div>
      </div>
    );
  }

  return (
    <div className="min-h-screen flex items-center justify-center px-6 py-20">
      <div className="max-w-md w-full">
        <div className="text-center mb-8">
          <div className="inline-flex items-center justify-center w-16 h-16 bg-red-500/10 border border-red-500/20 rounded-full mb-4">
            <svg className="w-8 h-8 text-red-500" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-2.5L13.732 4c-.77-.833-1.964-.833-2.732 0L4.082 16.5c-.77.833.192 2.5 1.732 2.5z" />
            </svg>
          </div>
          <h1 className="text-2xl font-bold text-white">Eliminar mi cuenta</h1>
          <p className="text-[#94A3B8] text-sm mt-2">
            Esta acción es permanente e irreversible. Todos tus datos, servicios y historial serán eliminados.
          </p>
        </div>

        <div className="bg-[#0F172A] border border-[#1E293B] rounded-xl p-6 space-y-6">
          <div className="space-y-4">
            <div className="bg-red-500/5 border border-red-500/20 rounded-lg p-4">
              <p className="text-red-400 text-sm font-medium">
                ⚠️ Al eliminar tu cuenta:
              </p>
              <ul className="text-red-400/80 text-xs mt-2 space-y-1 list-disc list-inside">
                <li>Perderás acceso a todos tus servicios activos</li>
                <li>Se eliminarán tus datos personales permanentemente</li>
                <li>Se cancelarán todas las transacciones pendientes</li>
                <li>No podrás recuperar tu cuenta ni tu historial</li>
              </ul>
            </div>

            <div>
              <label className="block text-[#94A3B8] text-xs font-semibold uppercase tracking-wider mb-2">
                Escribe exactamente:
              </label>
              <code className="block bg-[#020617] border border-[#1E293B] rounded-lg px-4 py-3 text-white text-sm font-mono">
                {CONFIRMATION_TEXT}
              </code>
            </div>

            <div>
              <label htmlFor="confirmation" className="block text-[#94A3B8] text-xs font-semibold uppercase tracking-wider mb-2">
                Tu confirmación
              </label>
              <input
                type="text"
                id="confirmation"
                value={inputValue}
                onChange={(e) => setInputValue(e.target.value)}
                placeholder="Escribe la frase exacta aquí..."
                className="w-full bg-[#020617] border border-[#1E293B] rounded-lg px-4 py-3 text-white text-sm placeholder:text-[#4B5563] focus:ring-2 focus:ring-red-500/50 focus:border-red-500 outline-none transition-all"
                autoComplete="off"
              />
              {inputValue && !isValid && (
                <p className="text-red-400 text-xs mt-2">
                  El texto no coincide. Verifica mayúsculas y espacios.
                </p>
              )}
            </div>
          </div>

          {status === "error" && (
            <div className="bg-red-500/5 border border-red-500/20 rounded-lg p-3">
              <p className="text-red-400 text-sm">{errorMessage}</p>
            </div>
          )}

          <button
            onClick={handleDelete}
            disabled={!isValid || status === "loading"}
            className={`w-full font-semibold px-6 py-3.5 rounded-lg border transition-all flex items-center justify-center gap-2 ${
              isValid && status !== "loading"
                ? "bg-red-500 text-white border-red-500 hover:bg-red-600 shadow-lg hover:shadow-red-500/25"
                : "bg-red-500/20 text-red-400 border-red-500/30 cursor-not-allowed opacity-50"
            }`}
          >
            {status === "loading" ? (
              <>
                <svg className="animate-spin w-4 h-4" viewBox="0 0 24 24" fill="none">
                  <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4" />
                  <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4z" />
                </svg>
                Eliminando...
              </>
            ) : (
              "Eliminar mi cuenta permanentemente"
            )}
          </button>

          <p className="text-[#94A3B8] text-xs text-center">
            ¿Cambiaste de opinión?{" "}
            <a href="/" className="text-[#6366F1] hover:underline">
              Volver al inicio
            </a>
          </p>
        </div>
      </div>
    </div>
  );
}

export default function DeleteAccountPage() {
  return (
    <Suspense fallback={
      <div className="min-h-screen flex items-center justify-center px-6 py-20">
        <div className="max-w-md w-full text-center">
          <div className="animate-spin w-8 h-8 border-2 border-[#6366F1] border-t-transparent rounded-full mx-auto mb-4"></div>
          <p className="text-[#94A3B8] text-sm">Cargando...</p>
        </div>
      </div>
    }>
      <DeleteAccountContent />
    </Suspense>
  );
}
