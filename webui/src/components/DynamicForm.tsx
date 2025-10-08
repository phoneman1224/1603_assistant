/**
 * Dynamic Form Component
 * Renders form fields based on command paramSchema
 */
import React, { useEffect } from 'react';
import { useAppStore } from '../state/store';
import { commandsApi } from '../api/commands';

export const DynamicForm: React.FC = () => {
  const {
    selectedCommand,
    tid,
    aid,
    ctag,
    optionalParams,
    setTID,
    setAID,
    setCTAG,
    setOptionalParams,
    setPreview,
  } = useAppStore();

  // Update preview when any field changes
  useEffect(() => {
    if (!selectedCommand) {
      setPreview('', []);
      return;
    }

    const updatePreview = async () => {
      try {
        const response = await commandsApi.preview({
          id: selectedCommand.id,
          TID: tid,
          AID: aid,
          CTAG: ctag,
          optional: optionalParams,
        });
        setPreview(response.command, response.warnings);
      } catch (error) {
        console.error('Preview error:', error);
      }
    };

    updatePreview();
  }, [selectedCommand, tid, aid, ctag, optionalParams, setPreview]);

  if (!selectedCommand) {
    return (
      <div className="command-builder">
        <p>Select a command to configure parameters...</p>
      </div>
    );
  }

  const handleOptionalChange = (key: string, value: string) => {
    setOptionalParams({ ...optionalParams, [key]: value });
  };

  return (
    <div className="command-builder">
      <h2>{selectedCommand.name}</h2>
      <p>{selectedCommand.description}</p>

      <div className="form-row">
        <div className="form-group">
          <label htmlFor="tid">TID (Target ID):</label>
          <input
            id="tid"
            type="text"
            value={tid}
            onChange={(e) => setTID(e.target.value)}
            placeholder="Leave empty if not required"
          />
        </div>

        <div className="form-group">
          <label htmlFor="aid">AID (Access ID):</label>
          <input
            id="aid"
            type="text"
            value={aid}
            onChange={(e) => setAID(e.target.value)}
            placeholder="Leave empty if not required"
          />
        </div>

        <div className="form-group">
          <label htmlFor="ctag">CTAG (Correlation Tag):</label>
          <input
            id="ctag"
            type="text"
            value={ctag}
            onChange={(e) => setCTAG(e.target.value)}
            placeholder="1"
          />
        </div>
      </div>

      {selectedCommand.optional.length > 0 && (
        <>
          <h3>Optional Parameters</h3>
          <div className="form-row">
            {selectedCommand.optional.map((param) => {
              const schema = selectedCommand.paramSchema[param];
              return (
                <div key={param} className="form-group">
                  <label htmlFor={param}>
                    {param}:
                    {schema?.description && (
                      <span style={{ fontWeight: 'normal', fontSize: '0.9em', color: '#666' }}>
                        {' '}({schema.description})
                      </span>
                    )}
                  </label>
                  {schema?.enum ? (
                    <select
                      id={param}
                      value={optionalParams[param] || ''}
                      onChange={(e) => handleOptionalChange(param, e.target.value)}
                    >
                      <option value="">-- Select --</option>
                      {schema.enum.map((opt: string) => (
                        <option key={opt} value={opt}>
                          {opt}
                        </option>
                      ))}
                    </select>
                  ) : (
                    <input
                      id={param}
                      type="text"
                      value={optionalParams[param] || ''}
                      onChange={(e) => handleOptionalChange(param, e.target.value)}
                      placeholder={schema?.type || 'string'}
                    />
                  )}
                </div>
              );
            })}
          </div>
        </>
      )}
    </div>
  );
};
