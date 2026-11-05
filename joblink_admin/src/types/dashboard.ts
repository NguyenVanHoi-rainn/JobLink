export interface DashboardOverview {
  users: {
    total: number;
    active: number;
    locked: number;
    workers: number;
    employers: number;
  };
  jobs: {
    total: number;
    published: number;
    draft: number;
    closed: number;
    hidden: number;
  };
  applications: {
    total: number;
  };
  reports: {
    total: number;
    open: number;
    reviewing: number;
  };
  appointments: {
    total: number;
  };
}