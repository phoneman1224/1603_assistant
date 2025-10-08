/**
 * Console Output Component
 */
import React, { useRef, useEffect } from 'react';
import { useAppStore } from '../state/store';

export const Console: React.FC = () => {
  const { consoleLines, clearConsole } = useAppStore();
  const consoleRef = useRef<HTMLDivElement>(null);

  // Auto-scroll to bottom
  useEffect(() => {
    if (consoleRef.current) {
      consoleRef.current.scrollTop = consoleRef.current.scrollHeight;
    }
  }, [consoleLines]);

  const handleCopy = () => {
    navigator.clipboard.writeText(consoleLines.join('\n'));
  };

  const handleDownload = () => {
    const content = consoleLines.join('\n');
    const blob = new Blob([content], { type: 'text/plain' });
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = `tl1-log-${new Date().toISOString()}.txt`;
    a.click();
    URL.revokeObjectURL(url);
  };

  return (
    <div className="console-section">
      <h2>Console</h2>
      <div className="console-output" ref={consoleRef}>
        {consoleLines.length === 0 ? (
          <div style={{ color: '#888' }}>Console output will appear here...</div>
        ) : (
          consoleLines.map((line, idx) => (
            <div key={idx} className="console-line">
              {line}
            </div>
          ))
        )}
      </div>
      <div className="console-controls">
        <button onClick={clearConsole}>Clear</button>
        <button onClick={handleCopy}>Copy</button>
        <button onClick={handleDownload}>Download</button>
      </div>
    </div>
  );
};
