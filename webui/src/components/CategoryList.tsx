/**
 * Category List Component
 */
import React from 'react';
import { useAppStore } from '../state/store';

export const CategoryList: React.FC = () => {
  const { categories, selectedCategory, setSelectedCategory } = useAppStore();

  return (
    <div className="category-list">
      <h3>Categories</h3>
      {categories.map((category) => (
        <div
          key={category.name}
          className={`category-item ${selectedCategory === category.name ? 'active' : ''}`}
          onClick={() => setSelectedCategory(category.name)}
        >
          <div className="category-name">
            {category.name} ({category.count})
          </div>
          <div className="category-description">{category.description}</div>
        </div>
      ))}
    </div>
  );
};
