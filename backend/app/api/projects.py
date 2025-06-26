from sqlalchemy import Column, Integer, String, Text, DateTime, Enum, JSON, Boolean, Float
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
from app.database import Base
import enum

class ProjectStatus(str, enum.Enum):
    CREATED = "created"
    CONFIGURED = "configured"
    RUNNING = "running"
    COMPLETED = "completed"
    FAILED = "failed"
    CANCELLED = "cancelled"

class Project(Base):
    """
    Project model representing a molecular dynamics simulation project
    """
    __tablename__ = "projects"

    id = Column(String, primary_key=True, index=True)
    name = Column(String(255), nullable=False, index=True)
    description = Column(Text, nullable=True)
    status = Column(Enum(ProjectStatus), default=ProjectStatus.CREATED, nullable=False)
    
    # Timestamps
    created_at = Column(DateTime(timezone=True), server_default=func.now(), nullable=False)
    updated_at = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now(), nullable=False)
    started_at = Column(DateTime(timezone=True), nullable=True)
    completed_at = Column(DateTime(timezone=True), nullable=True)
    
    # Configuration
    config = Column(JSON, nullable=True)  # Simulation configuration
    metadata_info = Column(JSON, nullable=True)  # Additional metadata
    
    # Progress tracking
    progress_percentage = Column(Float, default=0.0)
    current_step = Column(Integer, default=0)
    total_steps = Column(Integer, nullable=True)
    
    # Resource usage
    cpu_hours = Column(Float, default=0.0)
    memory_peak_mb = Column(Float, nullable=True)
    gpu_hours = Column(Float, default=0.0)
    
    # Error handling
    error_message = Column(Text, nullable=True)
    error_code = Column(String(50), nullable=True)
    
    # Relationships
    files = relationship("ProjectFile", back_populates="project", cascade="all, delete-orphan")
    simulations = relationship("Simulation", back_populates="project", cascade="all, delete-orphan")
    
    def __repr__(self):
        return f"<Project(id='{self.id}', name='{self.name}', status='{self.status}')>"

class ProjectFile(Base):
    """
    Files associated with a project
    """
    __tablename__ = "project_files"

    id = Column(Integer, primary_key=True, index=True)
    project_id = Column(String, nullable=False, index=True)
    filename = Column(String(255), nullable=False)
    original_filename = Column(String(255), nullable=False)
    file_type = Column(String(10), nullable=False)  # .pdb, .gro, etc.
    file_path = Column(String(512), nullable=False)
    file_size = Column(Integer, nullable=False)
    checksum = Column(String(64), nullable=True)  # MD5 hash
    
    # File metadata
    is_primary = Column(Boolean, default=False)  # Primary structure file
    file_category = Column(String(50), nullable=True)  # protein, ligand, topology, etc.
    file_description = Column(Text, nullable=True)
    
    # Timestamps
    uploaded_at = Column(DateTime(timezone=True), server_default=func.now(), nullable=False)
    
    # Validation status
    is_validated = Column(Boolean, default=False)
    validation_errors = Column(JSON, nullable=True)
    
    # Relationships
    project = relationship("Project", back_populates="files")
    
    def __repr__(self):
        return f"<ProjectFile(id={self.id}, filename='{self.filename}', type='{self.file_type}')>"

class Simulation(Base):
    """
    Simulation runs within a project
    """
    __tablename__ = "simulations"

    id = Column(String, primary_key=True, index=True)
    project_id = Column(String, nullable=False, index=True)
    name = Column(String(255), nullable=False)
    simulation_type = Column(String(50), nullable=False)  # minimization, nvt, npt, production
    
    # Configuration
    config = Column(JSON, nullable=False)  # MDP parameters
    command = Column(Text, nullable=True)  # Full GROMACS command
    
    # Status and timing
    status = Column(Enum(ProjectStatus), default=ProjectStatus.CREATED, nullable=False)
    started_at = Column(DateTime(timezone=True), nullable=True)
    completed_at = Column(DateTime(timezone=True), nullable=True)
    duration_seconds = Column(Float, nullable=True)
    
    # Progress
    progress_percentage = Column(Float, default=0.0)
    current_time_ps = Column(Float, default=0.0)
    total_time_ps = Column(Float, nullable=True)
    
    # Output files
    output_files = Column(JSON, nullable=True)  # List of generated files
    log_file = Column(String(512), nullable=True)
    
    # Performance metrics
    performance_ns_per_day = Column(Float, nullable=True)
    cpu_usage_percent = Column(Float, nullable=True)
    memory_usage_mb = Column(Float, nullable=True)
    gpu_usage_percent = Column(Float, nullable=True)
    
    # Error handling
    exit_code = Column(Integer, nullable=True)
    error_message = Column(Text, nullable=True)
    
    # Timestamps
    created_at = Column(DateTime(timezone=True), server_default=func.now(), nullable=False)
    updated_at = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now(), nullable=False)
    
    # Relationships
    project = relationship("Project", back_populates="simulations")
    
    def __repr__(self):
        return f"<Simulation(id='{self.id}', type='{self.simulation_type}', status='{self.status}')>"
