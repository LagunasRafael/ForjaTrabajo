const API_URL = process.env.NEXT_PUBLIC_API_URL || "https://api.forjatrabajo.com.mx";

export async function deleteAccount(token: string): Promise<{ success: boolean; message: string }> {
  const response = await fetch(`${API_URL}/auth/delete-account`, {
    method: "DELETE",
    headers: {
      "Content-Type": "application/json",
      "Authorization": `Bearer ${token}`,
    },
  });

  if (!response.ok) {
    const data = await response.json().catch(() => ({}));
    throw new Error(data.detail || "No se pudo eliminar la cuenta");
  }

  return { success: true, message: "Cuenta eliminada exitosamente" };
}
