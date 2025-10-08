/**
 * System/Platform Selector Component
 */
import React from 'react';
import { useAppStore } from '../state/store';

export const SystemSelector: React.FC = () => {
  const { selectedPlatform, setSelectedPlatform } = useAppStore();

  return (
    <div className="platform-selector">
      <label htmlFor="platform">Platform:</label>
      <select
        id="platform"
        value={selectedPlatform}
        onChange={(e) => setSelectedPlatform(e.target.value)}
      >
        <option value="1603 SM">1603 SM</option>
        <option value="1603 SMX">1603 SMX</option>
      </select>
    </div>
  );
};
