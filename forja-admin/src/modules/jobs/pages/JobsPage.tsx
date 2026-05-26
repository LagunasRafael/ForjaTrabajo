import { useState, useEffect } from 'react';
import { toast } from 'sonner';
import { JobTable } from '../components/JobTable';
import { getJobsApi } from '../services/job.services';
import { useAutoRefresh } from '../../../hooks/useAutoRefresh';
import type { JobPost } from '../types/job.types';

export const JobsPage = () => {
  const [jobs, setJobs] = useState<JobPost[]>([]);
  const [isLoading, setIsLoading] = useState(true);

  useEffect(() => {
    loadJobs();
  }, []);

  useAutoRefresh(() => loadJobs(), 30000);

  const loadJobs = async () => {
    try {
      const data = await getJobsApi();
      setJobs(data);
    } catch (error) {
      toast.error('Error al conectar con el servidor');
    } finally {
      setIsLoading(false);
    }
  };

  return (
    <div className="space-y-6 animate-in fade-in duration-500">
      
      {/* HEADER */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
        <div>
          <h2 className="text-2xl font-bold text-white tracking-tight">Contrataciones (Jobs)</h2>
          <p className="text-sm text-slate-400 mt-1">Supervisa los trabajos que ya están en proceso o completados.</p>
        </div>
      </div>

      {/* TABLA */}
      <JobTable 
        jobs={jobs} 
        isLoading={isLoading} 
      />
      
    </div>
  );
};

export default JobsPage;