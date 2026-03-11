import { lazy, Suspense, useEffect } from 'react';
import { BrowserRouter, Routes, Route, Navigate } from 'react-router-dom';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { MainLayout } from '@/components/layout';
import { useAuthStore } from '@/stores/auth.store';

// Lazy-loaded pages
const LoginPage = lazy(() => import('@/pages/auth/LoginPage'));
const DashboardPage = lazy(() => import('@/pages/dashboard/DashboardPage'));
const ProjectListPage = lazy(() => import('@/pages/projects/ProjectListPage'));
const ProjectDetailPage = lazy(() => import('@/pages/projects/ProjectDetailPage'));
const FinanceDashboardPage = lazy(() => import('@/pages/finance/FinanceDashboardPage'));
const InvoiceListPage = lazy(() => import('@/pages/finance/InvoiceListPage'));
const PurchaseOrderListPage = lazy(() => import('@/pages/finance/PurchaseOrderListPage'));
const HRDashboardPage = lazy(() => import('@/pages/hr/HRDashboardPage'));
const EmployeeListPage = lazy(() => import('@/pages/hr/EmployeeListPage'));
const LeaveManagementPage = lazy(() => import('@/pages/hr/LeaveManagementPage'));
const AppraisalPage = lazy(() => import('@/pages/hr/AppraisalPage'));
const SalaryPage = lazy(() => import('@/pages/hr/SalaryPage'));
const TimesheetPage = lazy(() => import('@/pages/timesheet/TimesheetPage'));
const ContactListPage = lazy(() => import('@/pages/contacts/ContactListPage'));
const SchedulingPage = lazy(() => import('@/pages/scheduling/SchedulingPage'));
const FilesPage = lazy(() => import('@/pages/files/FilesPage'));
const TransmittalPage = lazy(() => import('@/pages/transmittals/TransmittalPage'));
const FeedbackPage = lazy(() => import('@/pages/feedback/FeedbackPage'));
const MessagesPage = lazy(() => import('@/pages/messages/MessagesPage'));
const TargetsPage = lazy(() => import('@/pages/targets/TargetsPage'));
const AllocationPage = lazy(() => import('@/pages/allocation/AllocationPage'));
const ReportsPage = lazy(() => import('@/pages/reports/ReportsPage'));
const SearchPage = lazy(() => import('@/pages/search/SearchPage'));
const AdminPage = lazy(() => import('@/pages/admin/AdminPage'));

const queryClient = new QueryClient({
  defaultOptions: {
    queries: {
      staleTime: 5 * 60 * 1000, // 5 minutes
      retry: 1,
      refetchOnWindowFocus: false,
    },
  },
});

function Loading() {
  return (
    <div className="flex h-64 items-center justify-center">
      <div
        className="h-8 w-8 animate-spin rounded-full border-4 border-t-transparent"
        style={{ borderColor: 'var(--color-s4c-blue)', borderTopColor: 'transparent' }}
      />
    </div>
  );
}

function FullPageLoading() {
  return (
    <div className="flex min-h-screen items-center justify-center bg-gray-50">
      <div className="text-center">
        <div
          className="mx-auto h-10 w-10 animate-spin rounded-full border-4 border-t-transparent"
          style={{ borderColor: 'var(--color-s4c-blue)', borderTopColor: 'transparent' }}
        />
        <p className="mt-3 text-sm text-gray-500">Loading...</p>
      </div>
    </div>
  );
}

function ProtectedRoute({ children }: { children: React.ReactNode }) {
  const { isAuthenticated, isLoading } = useAuthStore();

  if (isLoading) {
    return <FullPageLoading />;
  }

  if (!isAuthenticated) {
    return <Navigate to="/login" replace />;
  }

  return <>{children}</>;
}

function AppRoutes() {
  const { initialize, isLoading } = useAuthStore();

  useEffect(() => {
    void initialize();
  }, [initialize]);

  if (isLoading) {
    return <FullPageLoading />;
  }

  return (
    <Routes>
      {/* Public routes */}
      <Route path="/login" element={<LoginPage />} />

      {/* Protected routes */}
      <Route
        element={
          <ProtectedRoute>
            <MainLayout />
          </ProtectedRoute>
        }
      >
        <Route index element={<DashboardPage />} />

        {/* Projects */}
        <Route path="projects" element={<ProjectListPage />} />
        <Route path="projects/:id" element={<ProjectDetailPage />} />

        {/* Finance */}
        <Route path="finance" element={<FinanceDashboardPage />} />
        <Route path="finance/invoices" element={<InvoiceListPage />} />
        <Route path="finance/purchase-orders" element={<PurchaseOrderListPage />} />

        {/* HR */}
        <Route path="hr" element={<HRDashboardPage />} />
        <Route path="hr/employees" element={<EmployeeListPage />} />
        <Route path="hr/leave" element={<LeaveManagementPage />} />
        <Route path="hr/appraisals" element={<AppraisalPage />} />
        <Route path="hr/salary" element={<SalaryPage />} />

        {/* Timesheet */}
        <Route path="timesheet" element={<TimesheetPage />} />

        {/* Contacts */}
        <Route path="contacts" element={<ContactListPage />} />

        {/* Scheduling */}
        <Route path="scheduling" element={<SchedulingPage />} />

        {/* Files */}
        <Route path="files" element={<FilesPage />} />

        {/* Transmittals */}
        <Route path="transmittals" element={<TransmittalPage />} />

        {/* Feedback */}
        <Route path="feedback" element={<FeedbackPage />} />

        {/* Messages */}
        <Route path="messages" element={<MessagesPage />} />

        {/* Targets */}
        <Route path="targets" element={<TargetsPage />} />

        {/* Allocation */}
        <Route path="allocation" element={<AllocationPage />} />

        {/* Reports */}
        <Route path="reports" element={<ReportsPage />} />

        {/* Search */}
        <Route path="search" element={<SearchPage />} />

        {/* Admin */}
        <Route path="admin" element={<AdminPage />} />
      </Route>

      {/* Catch-all */}
      <Route path="*" element={<Navigate to="/" replace />} />
    </Routes>
  );
}

export default function App() {
  return (
    <QueryClientProvider client={queryClient}>
      <BrowserRouter>
        <Suspense fallback={<Loading />}>
          <AppRoutes />
        </Suspense>
      </BrowserRouter>
    </QueryClientProvider>
  );
}
