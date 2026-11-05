export interface EmployerVerification {
  id: string;
  companyName: string;
  description?: string;
  address?: string;
  logoUrl?: string;
  taxCode?: string;
  businessLicense?: string;
  verificationStatus: 'PENDING' | 'VERIFIED' | 'REJECTED';
  rejectionReason?: string;
  user: {
    id: string;
    email: string;
    status: string;
    createdAt: string;
  };
}