import React, { useState, useEffect } from 'react';
import './index.css';

interface Project {
  id: string;
  name: string;
  status: 'created' | 'running' | 'completed' | 'failed';
  created: string;
}

interface ApiStatus {
  status: 'checking' | 'connected' | 'disconnected';
  message: string;
}

function App() {
  const [projects, setProjects] = useState<Project[]>([
    { 
      id: '1', 
      name: 'Example Protein Study', 
      status: 'completed',
      created: new Date().toISOString().split('T')[0]
    },
    { 
      id: '2', 
      name: 'Ligand Binding Analysis', 
      status: 'created',
      created: new Date().toISOString().split('T')[0]
    }
  ]);

  const [apiStatus, setApiStatus] = useState<ApiStatus>({
    status: 'checking',
    message: 'Checking connection...'
  });

  // Test backend connection
  useEffect(() => {
    const checkBackend = async () => {
      try {
        const controller = new AbortController();
        const timeoutId = setTimeout(() => controller.abort(), 5000);
        
        const response = await fetch('http://localhost:8000/', {
          signal: controller.signal
        });
        
        clearTimeout(timeoutId);
        
        if (response.ok) {
          setApiStatus({
            status: 'connected',
            message: 'Backend connected successfully'
          });
        } else {
          setApiStatus({
            status: 'disconnected',
            message: `Backend error: ${response.status}`
          });
        }
      } catch (error) {
        setApiStatus({
          status: 'disconnected',
          message: 'Backend not responding'
        });
      }
    };

    checkBackend();
    const interval = setInterval(checkBackend, 30000);
    return () => clearInterval(interval);
  }, []);

  const createProject = () => {
    const newProject: Project = {
      id: Date.now().toString(),
      name: `Project ${projects.length + 1}`,
      status: 'created',
      created: new Date().toISOString().split('T')[0]
    };
    setProjects([newProject, ...projects]);
  };

  const deleteProject = (id: string) => {
    if (window.confirm('Are you sure you want to delete this project?')) {
      setProjects(projects.filter(p => p.id !== id));
    }
  };

  const simulateRun = (id: string) => {
    setProjects(projects.map(p => 
      p.id === id ? { ...p, status: 'running' as const } : p
    ));
    
    // Simulate completion after 3 seconds
    setTimeout(() => {
      setProjects(prev => prev.map(p => 
        p.id === id ? { ...p, status: 'completed' as const } : p
      ));
    }, 3000);
  };

  const getStatsCount = (status: string) => {
    return projects.filter(p => p.status === status).length;
  };

  return (
    <div>
      {/* Header */}
      <header className="header">
        <div className="container">
          <div className="flex items-center justify-between">
            <h1>🧬 GROMACS GUI Platform</h1>
            <div className="flex items-center gap-4">
              <div className="flex items-center">
                <span className={`status-dot status-${apiStatus.status}`}></span>
                <span style={{ fontSize: '0.875rem' }}>
                  {apiStatus.status === 'connected' ? 'Connected' :
                   apiStatus.status === 'disconnected' ? 'Disconnected' : 'Checking...'}
                </span>
              </div>
            </div>
          </div>
        </div>
      </header>

      {/* Main Content */}
      <main className="container">
        
        {/* Welcome Section */}
        <div className="text-center mb-4">
          <h2 className="text-2xl font-bold mb-2">
            Molecular Dynamics Simulation Platform
          </h2>
          <p className="text-lg" style={{ color: '#64748b' }}>
            A modern web interface for GROMACS simulations
          </p>
        </div>

        {/* Stats Cards */}
        <div className="card-grid">
          <div className="card text-center">
            <div className="text-2xl font-bold" style={{ color: '#3b82f6' }}>
              {projects.length}
            </div>
            <div>Total Projects</div>
          </div>
          <div className="card text-center">
            <div className="text-2xl font-bold" style={{ color: '#10b981' }}>
              {getStatsCount('completed')}
            </div>
            <div>Completed</div>
          </div>
          <div className="card text-center">
            <div className="text-2xl font-bold" style={{ color: '#f59e0b' }}>
              {getStatsCount('running')}
            </div>
            <div>Running</div>
          </div>
          <div className="card text-center">
            <div className="text-2xl font-bold" style={{ color: '#6b7280' }}>
              {getStatsCount('created')}
            </div>
            <div>Ready</div>
          </div>
        </div>

        {/* Action Button */}
        <div className="text-center mb-4">
          <button onClick={createProject} className="btn">
            ➕ Create New Project
          </button>
        </div>

        {/* API Status Alert */}
        {apiStatus.status === 'connected' && (
          <div className="alert alert-success">
            <strong>✅ Backend Connected!</strong> API is responding at{' '}
            <a href="http://localhost:8000" target="_blank" rel="noopener noreferrer">
              http://localhost:8000
            </a>
          </div>
        )}

        {apiStatus.status === 'disconnected' && (
          <div className="alert alert-error">
            <strong>❌ Backend Disconnected</strong><br />
            {apiStatus.message}<br />
            Make sure the backend server is running on port 8000.
          </div>
        )}

        {/* Projects List */}
        <div className="card">
          <h3 className="text-lg font-bold mb-4">
            Projects ({projects.length})
          </h3>
          
          {projects.length === 0 ? (
            <div className="text-center" style={{ padding: '2rem', color: '#64748b' }}>
              No projects yet. Create your first project to get started!
            </div>
          ) : (
            <div>
              {projects.map((project) => (
                <div key={project.id} className="project-item">
                  <div>
                    <div className="font-bold">{project.name}</div>
                    <div style={{ fontSize: '0.875rem', color: '#64748b' }}>
                      Created: {project.created} • ID: {project.id}
                    </div>
                  </div>
                  <div className="flex items-center gap-4">
                    <span className={`status-badge status-${project.status}`}>
                      {project.status.toUpperCase()}
                    </span>
                    {project.status === 'created' && (
                      <button 
                        onClick={() => simulateRun(project.id)}
                        style={{ 
                          background: '#10b981', 
                          color: 'white', 
                          border: 'none', 
                          padding: '0.25rem 0.75rem', 
                          borderRadius: '4px', 
                          cursor: 'pointer',
                          fontSize: '0.75rem'
                        }}
                      >
                        ▶ Run
                      </button>
                    )}
                    <button 
                      onClick={() => deleteProject(project.id)}
                      style={{ 
                        background: '#ef4444', 
                        color: 'white', 
                        border: 'none', 
                        padding: '0.25rem 0.75rem', 
                        borderRadius: '4px', 
                        cursor: 'pointer',
                        fontSize: '0.75rem'
                      }}
                    >
                      🗑 Delete
                    </button>
                  </div>
                </div>
              ))}
            </div>
          )}
        </div>

        {/* API Links */}
        <div className="alert alert-info">
          <strong>🔗 API Access:</strong><br />
          • Backend API: <a href="http://localhost:8000" target="_blank" rel="noopener noreferrer">http://localhost:8000</a><br />
          • API Documentation: <a href="http://localhost:8000/docs" target="_blank" rel="noopener noreferrer">http://localhost:8000/docs</a><br />
          • Interactive API: <a href="http://localhost:8000/redoc" target="_blank" rel="noopener noreferrer">http://localhost:8000/redoc</a>
        </div>

        {/* Feature Info */}
        <div className="card">
          <h3 className="text-lg font-bold mb-2">🚀 Next Steps</h3>
          <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(250px, 1fr))', gap: '1rem' }}>
            <div>
              <strong>1. Upload Files</strong><br />
              <small>Add protein structures (.pdb, .gro)</small>
            </div>
            <div>
              <strong>2. Configure</strong><br />
              <small>Set force fields and parameters</small>
            </div>
            <div>
              <strong>3. Run Simulations</strong><br />
              <small>Execute GROMACS workflows</small>
            </div>
            <div>
              <strong>4. Analyze Results</strong><br />
              <small>View plots and export data</small>
            </div>
          </div>
        </div>

      </main>

      {/* Footer */}
      <footer className="footer">
        <div className="container">
          GROMACS GUI Platform - Molecular Dynamics Made Easy
        </div>
      </footer>
    </div>
  );
}

export default App;
