export interface EmployerVerification {
  id: string;
  companyName: string;
  description?: string;
  address?: string;
  logoUrl?: string;
  taxCode?: string;
  businessLicense?: string;
  verificationStatus: 'UNVERIFIED' | 'PENDING' | 'VERIFIED' | 'REJECTED';
  rejectionReason?: string;
  user: {
    id: string;
    email: string;
    status: string;
    createdAt: string;
  };
}