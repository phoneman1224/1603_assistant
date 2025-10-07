/**
 * Command List Component
 */
import React, { useMemo } from 'react';
import { useAppStore } from '../state/store';

export const CommandList: React.FC = () => {
  const { commands, selectedCategory, selectedCommand, setSelectedCommand } = useAppStore();

  const filteredCommands = useMemo(() => {
    if (!selectedCategory) return [];
    return commands.filter(cmd => cmd.category === selectedCategory);
  }, [commands, selectedCategory]);

  if (!selectedCategory) {
    return <div className="command-list"><p>Select a category to view commands</p></div>;
  }

  return (
    <div className="command-list">
      <h3>Commands</h3>
      {filteredCommands.map((command) => (
        <div
          key={command.id}
          className={`command-item ${selectedCommand?.id === command.id ? 'active' : ''}`}
          onClick={() => setSelectedCommand(command)}
        >
          <div className="category-name">{command.name}</div>
          <div className="category-description">{command.description}</div>
        </div>
      ))}
    </div>
  );
};
