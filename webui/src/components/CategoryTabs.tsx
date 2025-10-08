/**
 * Category Tabs Component
 * Implements tabbed interface for TL1 command categories
 */
import React from 'react';
import { useAppStore } from '../state/store';
import './CategoryTabs.css';

interface CategoryTabsProps {
  className?: string;
}

export const CategoryTabs: React.FC<CategoryTabsProps> = ({ className = '' }) => {
  const { categories, selectedCategory, setSelectedCategory, commands } = useAppStore();

  // Define the specific tabs mentioned in the playbook
  const tabMapping = {
    'Retrieval': ['Information Retrieval'],
    'Provisioning': ['Service Provisioning'],
    'Loopback': ['Testing & Diagnostics'],
    'Diagnostics': ['Testing & Diagnostics', 'Alarm Management'],
    'Perf Mon': ['Performance Monitoring'],
    'Switching': ['Protection & Switching'],
    'Security': ['Security & Access'],
  };

  // Get commands count for each tab
  const getTabCount = (tabCategories: string[]) => {
    return commands.filter(cmd => 
      tabCategories.some(cat => cmd.category === cat)
    ).length;
  };

  // Find which tab the selected category belongs to
  const getActiveTab = () => {
    for (const [tabName, tabCategories] of Object.entries(tabMapping)) {
      if (tabCategories.includes(selectedCategory || '')) {
        return tabName;
      }
    }
    return null;
  };

  const activeTab = getActiveTab();

  const handleTabClick = (tabCategories: string[]) => {
    // Set the first category in the tab as selected
    if (tabCategories.length > 0) {
      setSelectedCategory(tabCategories[0]);
    }
  };

  const getTabIcon = (tabName: string) => {
    const icons = {
      'Retrieval': '📊',
      'Provisioning': '🔧',
      'Loopback': '🔄',
      'Diagnostics': '🔍',
      'Perf Mon': '📈',
      'Switching': '🔀',
      'Security': '🔒',
    };
    return icons[tabName as keyof typeof icons] || '📋';
  };

  const getTabDescription = (tabName: string) => {
    const descriptions = {
      'Retrieval': 'Status, inventory, and configuration retrieval commands',
      'Provisioning': 'Cross-connects, circuits, and service configuration',
      'Loopback': 'Loopback and testing commands',
      'Diagnostics': 'Diagnostic commands and alarm management',
      'Perf Mon': 'Performance monitoring and data collection',
      'Switching': 'Protection switching and ring management',
      'Security': 'Security settings and access control',
    };
    return descriptions[tabName as keyof typeof descriptions] || '';
  };

  return (
    <div className={`category-tabs ${className}`}>
      {/* Tab Headers */}
      <div className="tab-headers">
        {Object.entries(tabMapping).map(([tabName, tabCategories]) => {
          const count = getTabCount(tabCategories);
          const isActive = activeTab === tabName;
          
          return (
            <button
              key={tabName}
              className={`tab-header ${isActive ? 'active' : ''}`}
              onClick={() => handleTabClick(tabCategories)}
              disabled={count === 0}
            >
              <div className="tab-icon">{getTabIcon(tabName)}</div>
              <div className="tab-content">
                <div className="tab-name">{tabName}</div>
                <div className="tab-count">{count} commands</div>
              </div>
            </button>
          );
        })}
      </div>

      {/* Tab Content */}
      {activeTab && (
        <div className="tab-content-area">
          <div className="tab-description">
            <h3>{getTabIcon(activeTab)} {activeTab}</h3>
            <p>{getTabDescription(activeTab)}</p>
          </div>

          {/* Show available categories within this tab */}
          <div className="tab-categories">
            <h4>Available Categories:</h4>
            {tabMapping[activeTab as keyof typeof tabMapping].map(categoryName => {
              const category = categories.find(c => c.name === categoryName);
              if (!category) return null;

              return (
                <div
                  key={categoryName}
                  className={`tab-category ${selectedCategory === categoryName ? 'selected' : ''}`}
                  onClick={() => setSelectedCategory(categoryName)}
                >
                  <div className="category-header">
                    <span className="category-name">{categoryName}</span>
                    <span className="category-count">({category.count})</span>
                  </div>
                  <div className="category-desc">{category.description}</div>
                </div>
              );
            })}
          </div>

          {/* Quick Stats */}
          <div className="tab-stats">
            <div className="stat-item">
              <strong>Total Commands:</strong> {getTabCount(tabMapping[activeTab as keyof typeof tabMapping])}
            </div>
            <div className="stat-item">
              <strong>Categories:</strong> {tabMapping[activeTab as keyof typeof tabMapping].length}
            </div>
          </div>
        </div>
      )}
    </div>
  );
};

export default CategoryTabs;