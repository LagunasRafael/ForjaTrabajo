import { createBrowserRouter, Navigate } from 'react-router-dom';
import { AdminLayout } from '../layouts/AdminLayout';
import { LoginPage } from '../modules/auth/LoginPage';
import { DashboardPage } from '../modules/dashboard/DashboardPage';
import UsersPage from '../modules/users/UsersPage';
import { CategoriesPage } from '../modules/services/pages/categoriesPage';
import { ServicesPage } from '../modules/services/pages/ServicesPage';
import { JobsPage } from '../modules/jobs/pages/JobsPage';
import { ProfilePage } from '../modules/admin/pages/ProfilePage';
import { ServiceDetail } from '../modules/services/pages/ServiceDetail';
import { FinancePage } from '../modules/finance/pages/FinancePage';
// 🟢 1. IMPORTA TU NUEVA PÁGINA AQUÍ
import { SettingsPage } from '../modules/admin/pages/SettingsPage'; // Ajusta la ruta según tu carpeta
import { DisputesPage } from '../modules/disputes/pages/DisputesPage';
import { ChatViewer } from '../modules/disputes/pages/ChatViewer';
import { VerificationsPage } from '../modules/verifications/pages/VerificationsPage';
import { ReportsPage } from '../modules/reports/pages/ReportsPage';
import { ReportedServicesPage } from '../modules/services/pages/ReportedServicesPage';

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
        path: 'settings', // 🟢 2. REGISTRA LA RUTA DE CONFIGURACIÓN
        element: <SettingsPage />,
      },
      {
        path: 'users',
        element: <UsersPage />,
      },
      {
        path: 'services',
        element: <ServicesPage />,
      },
      {
        path: 'reported-services',
        element: <ReportedServicesPage />,
      },
      { 
        path: 'services/:id', 
        element: <ServiceDetail /> 
      },
      { 
        path: 'categories', 
        element: <CategoriesPage /> 
      },
      { 
        path: 'jobs', 
        element: <JobsPage /> 
      },
      { 
        path: 'finance', 
        element: <FinancePage /> 
      },
      {
        path: 'disputes',
        element: <DisputesPage />
      },
      {
        path: 'disputes/:id',
        element: <ChatViewer />
      },
      {
        path: 'verifications',
        element: <VerificationsPage />
      },
      {
        path: 'reports',
        element: <ReportsPage />
      },

      // 🟡 3. EL COMODÍN SIEMPRE AL FINAL DE LOS CHILDREN
      // Esto atrapa cualquier ruta dentro de "/" que no exista
      { 
        path: '*', 
        element: <Navigate to="/" replace /> 
      },
    ],
  },
  
  // 🔴 4. COMODÍN GLOBAL (Fuera del layout)
  // Por si alguien escribe "/ruta-que-no-existe" fuera del admin
  { 
    path: '*', 
    element: <Navigate to="/login" replace /> 
  },
]);