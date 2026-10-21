import { createBrowserRouter, Navigate } from 'react-router-dom';
import { RootLayout } from '@/layouts/RootLayout';
import { MainDashboardPage } from '@/features/dashboard/MainDashboardPage';
import { PHCDashboardPage } from '@/features/phc-dashboard/PHCDashboardPage';
import { AFSupervisionPage } from '@/features/af-supervision/AFSupervisionPage';
import { ANMWorkspacePage } from '@/features/anm-workspace/ANMWorkspacePage';
import { DistrictAnalyticsPage } from '@/features/analytics/DistrictAnalyticsPage';
import { AdminConsolePage } from '@/features/admin/AdminConsolePage';
import { OsmAndMapPage } from '@/features/map/OsmAndMapPage';
import { IndiaPhcMapPage } from '@/features/map/IndiaPhcMapPage';
import { TicketPage } from '@/features/phc-dashboard/TicketPage';
import { ResourcesPage } from '@/features/phc-dashboard/ResourcesPage';
import { LoginPage } from '@/features/auth/LoginPage';

export const router = createBrowserRouter([
  {
    path: '/login',
    element: <LoginPage />,
  },
  {
    path: '/',
    element: <RootLayout />,
    children: [
      {
        index: true,
        element: <MainDashboardPage />,
      },
      {
        path: 'dashboard',
        element: <MainDashboardPage />,
      },
      {
        path: 'phc',
        element: <PHCDashboardPage />,
      },
      {
        path: 'queue',
        element: <PHCDashboardPage />,
      },
      {
        path: 'ticket/:id',
        element: <TicketPage />,
      },
      {
        path: 'map',
        element: <OsmAndMapPage />,
      },
      {
        path: 'india-map',
        element: <IndiaPhcMapPage />,
      },
      {
        path: 'heatmap',
        element: <OsmAndMapPage mode="heatmap" />,
      },
      {
        path: 'resources',
        element: <ResourcesPage />,
      },
      {
        path: 'af',
        element: <AFSupervisionPage />,
      },
      {
        path: 'supervisor',
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
        element: <Navigate to="/dashboard" replace />,
      },
    ],
  },
]);
