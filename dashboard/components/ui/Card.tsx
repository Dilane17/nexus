import { type HTMLAttributes } from 'react';

interface CardProps extends HTMLAttributes<HTMLDivElement> {
  title?: string;
  action?: React.ReactNode;
}

export default function Card({ title, action, children, className = '', ...props }: CardProps) {
  return (
    <div
      className={`bg-white rounded-[8px] shadow-sm border border-gray-100 ${className}`}
      {...props}
    >
      {(title || action) && (
        <div className="flex items-center justify-between px-6 py-4 border-b border-gray-100">
          {title && <h3 className="text-base font-semibold text-[#1A3A5C]">{title}</h3>}
          {action && <div>{action}</div>}
        </div>
      )}
      <div className="p-6">{children}</div>
    </div>
  );
}
