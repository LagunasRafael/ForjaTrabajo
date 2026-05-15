import { NavLink } from "react-router-dom";

export default function Sidebar() {
  return (
    <aside className="w-64 bg-gray-900 text-white h-screen p-4">
      <h2 className="text-xl font-bold mb-6">Forja Admin</h2>

      <nav className="flex flex-col gap-3">
        <NavLink
          to="/"
          className={({ isActive }) =>
            `p-2 rounded ${isActive ? "bg-gray-700" : "hover:bg-gray-800"}`
          }
        >
          Dashboard
        </NavLink>

        <NavLink
          to="/users"
          className={({ isActive }) =>
            `p-2 rounded ${isActive ? "bg-gray-700" : "hover:bg-gray-800"}`
          }
        >
          Usuarios
        </NavLink>

        <NavLink
          to="/verifications"
          className={({ isActive }) =>
            `p-2 rounded ${isActive ? "bg-gray-700" : "hover:bg-gray-800"}`
          }
        >
          Verificaciones
        </NavLink>
      </nav>
    </aside>
  );
}
