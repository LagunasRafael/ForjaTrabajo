import { useMemo } from 'react';
import { LineChart, Line, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer, Legend } from 'recharts';
import type { AnalyticsPoint } from '../types/finance.types';

interface RevenueChartProps {
  data: AnalyticsPoint[];
  isLoading: boolean;
}

export const RevenueChart = ({ data, isLoading }: RevenueChartProps) => {
  const formatMXN = (val: number) =>
    new Intl.NumberFormat('es-MX', { style: 'currency', currency: 'MXN' }).format(val);

  const chartData = useMemo(() => {
    return data
      .filter(d => d.gmv > 0 || d.platform_fee > 0)
      .map(d => ({
        date: new Date(d.date).toLocaleDateString('es-MX', { day: '2-digit', month: 'short' }),
        gmv: d.gmv,
        revenue: d.platform_fee,
      }));
  }, [data]);

  if (isLoading) {
    return (
      <div className="h-[300px] w-full flex items-center justify-center text-slate-500 animate-pulse">
        Cargando analytics...
      </div>
    );
  }

  if (chartData.length === 0) {
    return (
      <div className="h-[300px] w-full flex flex-col items-center justify-center text-slate-500">
        <svg xmlns="http://www.w3.org/2000/svg" width="48" height="48" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1" className="mb-4 opacity-50">
          <path d="M22 12h-4l-3 9L9 3l-3 9H2"/>
        </svg>
        <p>No hay datos de ingresos aún.</p>
      </div>
    );
  }

  return (
    <div className="h-[300px] w-full">
      <ResponsiveContainer width="100%" height="100%">
        <LineChart data={chartData}>
          <CartesianGrid strokeDasharray="3 3" stroke="#1e293b" vertical={false} />
          <XAxis dataKey="date" stroke="#94a3b8" fontSize={12} />
          <YAxis stroke="#94a3b8" fontSize={12} tickFormatter={(val) => `$${val}`} />
          <Tooltip
            contentStyle={{ backgroundColor: '#0f172a', border: '1px solid #1e293b', borderRadius: '12px' }}
            formatter={(value: number | undefined, name: string | undefined) => [formatMXN(value ?? 0), name === 'gmv' ? 'GMV' : 'Revenue Plataforma']}
          />
          <Legend />
          <Line type="monotone" dataKey="gmv" stroke="#10b981" strokeWidth={2} dot={false} name="GMV" />
          <Line type="monotone" dataKey="revenue" stroke="#8b5cf6" strokeWidth={2} dot={false} name="Revenue" />
        </LineChart>
      </ResponsiveContainer>
    </div>
  );
};
