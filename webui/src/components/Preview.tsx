/**
 * Command Preview Component
 */
import React from 'react';
import { useAppStore } from '../state/store';

export const Preview: React.FC = () => {
  const { preview, warnings } = useAppStore();

  if (!preview) return null;

  return (
    <div className="preview-section">
      <h3>Command Preview</h3>
      <div className="preview-command">{preview}</div>
      {warnings.length > 0 && (
        <div className="warnings">
          {warnings.map((warning, idx) => (
            <div key={idx} className="warning-item">
              ⚠️ {warning}
            </div>
          ))}
        </div>
      )}
    </div>
  );
};
