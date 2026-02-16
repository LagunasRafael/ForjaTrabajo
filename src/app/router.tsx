import { createBrowserRouter, Navigate } from 'react-router-dom';
import { AdminLayout } from '../layouts/AdminLayout';
import { LoginPage } from '../modules/auth/LoginPage'; // <--- Importar
import { DashboardPage } from '../modules/dashboard/DashboardPage';
import UsersPage from '../modules/users/UsersPage';
import { CategoriesPage } from '../modules/services/pages/categoriesPage';
import { ServicesPage } from '../modules/services/pages/ServicesPage';
import { JobsPage } from '../modules/jobs/pages/JobsPage';

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