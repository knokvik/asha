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
import { ClinicalProgramsPage } from '@/features/clinical-programs/ClinicalProgramsPage';
import { NotificationsPage } from '@/features/notifications/NotificationsPage';
import { AshaWorkerDetailPage } from '@/features/af-supervision/AshaWorkerDetailPage';
import { LiveTriagePage } from '@/features/af-supervision/LiveTriagePage';
import { SystemLogsPage } from '@/features/system-logs/SystemLogsPage';
import { HouseholdsPage } from '@/features/households/HouseholdsPage';
import { ClinicalProgramDetailPage } from '@/features/clinical-programs/ClinicalProgramDetailPage';
import { PHCTicketsPage } from '@/features/tickets/PHCTicketsPage';

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
        path: 'tickets',
        element: <PHCTicketsPage />,
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
        path: 'clinical-programs',
        element: <ClinicalProgramsPage />,
      },
      {
        path: 'clinical-programs/:program',
        element: <ClinicalProgramDetailPage />,
      },
      {
        path: 'households',
        element: <HouseholdsPage />,
      },
      {
        path: 'notifications',
        element: <NotificationsPage />,
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
        path: 'af/worker/:name',
        element: <AshaWorkerDetailPage />,
      },
      {
        path: 'af/live-triage',
        element: <LiveTriagePage />,
      },
      {
        path: 'logs',
        element: <SystemLogsPage />,
      },
      {
        path: 'system-logs',
        element: <SystemLogsPage />,
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
