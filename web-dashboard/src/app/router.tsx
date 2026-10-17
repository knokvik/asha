import { createBrowserRouter, Navigate } from 'react-router-dom';
import { RootLayout } from '@/layouts/RootLayout';
import { PHCDashboardPage } from '@/features/phc-dashboard/PHCDashboardPage';
import { AFSupervisionPage } from '@/features/af-supervision/AFSupervisionPage';
import { ANMWorkspacePage } from '@/features/anm-workspace/ANMWorkspacePage';
import { DistrictAnalyticsPage } from '@/features/analytics/DistrictAnalyticsPage';
import { AdminConsolePage } from '@/features/admin/AdminConsolePage';

export const router = createBrowserRouter([
  {
    path: '/',
    element: <RootLayout />,
    children: [
      {
        index: true,
        element: <Navigate to="/phc" replace />,
      },
      {
        path: 'phc',
        element: <PHCDashboardPage />,
      },
      {
        path: 'af',
        element: <AFSupervisionPage />,
      },
      {
        path: 'anm',
        element: <ANMWorkspacePage />,
      },
      {
        path: 'district',
        element: <DistrictAnalyticsPage />,
      },
      {
        path: 'admin',
        element: <AdminConsolePage />,
      },
      {
        path: '*',
        element: <Navigate to="/phc" replace />,
      },
    ],
  },
]);
