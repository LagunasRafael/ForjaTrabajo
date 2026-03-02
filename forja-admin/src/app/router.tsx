import { createBrowserRouter, Navigate } from 'react-router-dom';
import { AdminLayout } from '../layouts/AdminLayout';
import { LoginPage } from '../modules/auth/LoginPage'; // <--- Importar
import { DashboardPage } from '../modules/dashboard/DashboardPage';
import UsersPage from '../modules/users/UsersPage';
import { CategoriesPage } from '../modules/services/pages/categoriesPage';
import { ServicesPage } from '../modules/services/pages/ServicesPage';
import { JobsPage } from '../modules/jobs/pages/JobsPage';
import { ProfilePage } from '../modules/admin/pages/ProfilePage';
import { ServiceDetail } from '../modules/services/pages/ServiceDetail';

export const router = createBrowserRouter([
  // 1. Ruta Pública (Login)
  {
    path: '/login',
    element: <LoginPage />,
  },

  // 2. Rutas Privadas (Admin Panel)
  {
    path: '/',
    element: <AdminLayout />,
    // (Opcional) Aquí podrías envolver con un <RequireAuth> más adelante
    children: [
      {
        index: true,
        element: <DashboardPage />,
      },
      {
        path: 'profile',
        element: <ProfilePage />,
      },
      {
        path: 'users',
        element: <UsersPage />,
      },

      // Redirigir cualquier ruta desconocida al dashboard
      {
        path: '*',
        element: <Navigate to="/" replace />,
      },
      {
        path: 'services',
        element: <ServicesPage />,
      },
      // 🟢 2. AGREGA LA RUTA DINÁMICA AQUÍ
      // El ":id" es lo que permite que useService(id) funcione
      { path: 'services/:id', element: <ServiceDetail /> }, 
      
      { path: 'categories', element: <CategoriesPage /> },
      { path: 'jobs', element: <JobsPage /> },

      // 🟡 3. EL COMODÍN SIEMPRE AL FINAL
      { path: '*', element: <Navigate to="/" replace /> },
      {
        path: 'categories',
        element: <CategoriesPage />,
      },
      {
        path: 'jobs',
        element: <JobsPage />,
      },
    ],
  },
]);