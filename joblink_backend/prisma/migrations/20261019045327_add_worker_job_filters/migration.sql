-- CreateEnum
CREATE TYPE "SalaryType" AS ENUM ('HOURLY', 'DAILY', 'SHIFT', 'MONTHLY', 'FIXED');

-- CreateEnum
CREATE TYPE "ShiftType" AS ENUM ('MORNING', 'AFTERNOON', 'EVENING', 'NIGHT', 'FLEXIBLE');

-- AlterTable
ALTER TABLE "jobs" ADD COLUMN     "end_time" TIME,
ADD COLUMN     "salary_type" "SalaryType" NOT NULL DEFAULT 'HOURLY',
ADD COLUMN     "shift_type" "ShiftType" NOT NULL DEFAULT 'FLEXIBLE',
ADD COLUMN     "start_time" TIME,
ADD COLUMN     "urgent" BOOLEAN NOT NULL DEFAULT false,
ADD COLUMN     "urgent_until" TIMESTAMP(3),
ADD COLUMN     "work_days" "DayOfWeek"[] DEFAULT ARRAY[]::"DayOfWeek"[];

-- AlterTable
ALTER TABLE "worker_profiles" ADD COLUMN     "max_distance_km" INTEGER,
ADD COLUMN     "preferred_min_salary" DECIMAL(15,2),
ADD COLUMN     "preferred_salary_type" "SalaryType";

-- CreateIndex
CREATE INDEX "jobs_salary_type_idx" ON "jobs"("salary_type");

-- CreateIndex
CREATE INDEX "jobs_shift_type_idx" ON "jobs"("shift_type");

-- CreateIndex
CREATE INDEX "jobs_urgent_idx" ON "jobs"("urgent");
