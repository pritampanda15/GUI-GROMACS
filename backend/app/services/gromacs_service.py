import os
import subprocess
import asyncio
import json
import shutil
from pathlib import Path
from typing import Dict, List, Optional, Tuple, AsyncGenerator
from datetime import datetime
import logging
import re

logger = logging.getLogger(__name__)

class GromacsService:
    """
    Service for executing GROMACS commands and managing simulations
    """
    
    def __init__(self):
        self.gromacs_bin = os.getenv("GROMACS_BIN_PATH", "/usr/local/gromacs/bin")
        self.gmx_command = os.path.join(self.gromacs_bin, "gmx")
        self.force_fields_path = os.getenv("GROMACS_FORCE_FIELDS_PATH", "/usr/local/gromacs/share/gromacs/top")
        self.mock_mode = os.getenv("MOCK_GROMACS", "false").lower() == "true"
        
        # Verify GROMACS installation
        if not self.mock_mode and not self._verify_gromacs():
            logger.warning("GROMACS not found, running in mock mode")
            self.mock_mode = True
    
    def _verify_gromacs(self) -> bool:
        """Verify GROMACS installation"""
        try:
            result = subprocess.run(
                [self.gmx_command, "--version"],
                capture_output=True,
                text=True,
                timeout=10
            )
            return result.returncode == 0
        except (FileNotFoundError, subprocess.TimeoutExpired):
            return False
    
    async def get_available_forcefields(self) -> List[Dict[str, str]]:
        """Get list of available force fields"""
        if self.mock_mode:
            return [
                {"name": "amber99sb-ildn", "description": "AMBER99SB-ILDN protein force field"},
                {"name": "charmm36-jul2022", "description": "CHARMM36 all-atom force field"},
                {"name": "gromos54a7", "description": "GROMOS 54A7 united-atom force field"},
                {"name": "oplsaa", "description": "OPLS-AA all-atom force field"},
                {"name": "amber14sb", "description": "AMBER14SB protein force field"}
            ]
        
        forcefields = []
        ff_path = Path(self.force_fields_path)
        
        if ff_path.exists():
            for ff_dir in ff_path.iterdir():
                if ff_dir.is_dir() and (ff_dir / "forcefield.itp").exists():
                    # Read description from forcefield.itp if available
                    description = self._read_forcefield_description(ff_dir / "forcefield.itp")
                    forcefields.append({
                        "name": ff_dir.name,
                        "description": description or f"{ff_dir.name} force field"
                    })
        
        return forcefields
    
    def _read_forcefield_description(self, itp_file: Path) -> Optional[str]:
        """Read force field description from .itp file"""
        try:
            with open(itp_file, 'r') as f:
                for line in f:
                    if line.strip().startswith(';') and 'description' in line.lower():
                        return line.strip()[1:].strip()
            return None
        except Exception:
            return None
    
    async def prepare_system(self, project_dir: str, config: Dict) -> Dict[str, str]:
        """
        Prepare system for simulation
        Returns dict with generated files
        """
        project_path = Path(project_dir)
        results = {}
        
        try:
            # Step 1: Generate topology
            topology_result = await self._generate_topology(project_path, config)
            results.update(topology_result)
            
            # Step 2: Define box and solvate
            if config.get("add_solvent", True):
                solvation_result = await self._solvate_system(project_path, config)
                results.update(solvation_result)
            
            # Step 3: Add ions
            if config.get("add_ions", True):
                ions_result = await self._add_ions(project_path, config)
                results.update(ions_result)
            
            # Step 4: Generate MDP files
            mdp_result = await self._generate_mdp_files(project_path, config)
            results.update(mdp_result)
            
            logger.info(f"System preparation completed for {project_dir}")
            return results
            
        except Exception as e:
            logger.error(f"System preparation failed: {str(e)}")
            raise
    
    async def _generate_topology(self, project_path: Path, config: Dict) -> Dict[str, str]:
        """Generate topology file using pdb2gmx"""
        if self.mock_mode:
            # Create mock topology file
            top_file = project_path / "topol.top"
            gro_file = project_path / "conf.gro"
            
            with open(top_file, 'w') as f:
                f.write("; Mock topology file\n[ system ]\nProtein\n\n[ molecules ]\nProtein_chain_A    1\n")
            
            with open(gro_file, 'w') as f:
                f.write("Mock structure\n1\n1ALA      N    1   1.000   1.000   1.000\n1.0 1.0 1.0\n")
            
            await asyncio.sleep(1)  # Simulate processing time
            return {"topology": str(top_file), "structure": str(gro_file)}
        
        # Find input PDB file
        pdb_files = list(project_path.glob("*.pdb"))
        if not pdb_files:
            raise ValueError("No PDB file found in project directory")
        
        input_pdb = pdb_files[0]
        forcefield = config.get("forcefield", "amber99sb-ildn")
        
        # Run pdb2gmx
        command = [
            self.gmx_command, "pdb2gmx",
            "-f", str(input_pdb),
            "-o", "conf.gro",
            "-p", "topol.top",
            "-ff", forcefield,
            "-water", "tip3p"
        ]
        
        await self._run_command(command, cwd=project_path)
        
        return {
            "topology": str(project_path / "topol.top"),
            "structure": str(project_path / "conf.gro")
        }
    
    async def _solvate_system(self, project_path: Path, config: Dict) -> Dict[str, str]:
        """Solvate the system"""
        if self.mock_mode:
            await asyncio.sleep(1)
            return {"solvated_structure": str(project_path / "solv.gro")}
        
        # Define box
        await self._run_command([
            self.gmx_command, "editconf",
            "-f", "conf.gro",
            "-o", "newbox.gro",
            "-c", "-d", "1.0",
            "-bt", "cubic"
        ], cwd=project_path)
        
        # Solvate
        await self._run_command([
            self.gmx_command, "solvate",
            "-cp", "newbox.gro",
            "-cs", "spc216.gro",
            "-o", "solv.gro",
            "-p", "topol.top"
        ], cwd=project_path)
        
        return {"solvated_structure": str(project_path / "solv.gro")}
    
    async def _add_ions(self, project_path: Path, config: Dict) -> Dict[str, str]:
        """Add ions to neutralize the system"""
        if self.mock_mode:
            await asyncio.sleep(1)
            return {"ions_structure": str(project_path / "ions.gro")}
        
        # Generate TPR file for ion addition
        mdp_content = """
; ions.mdp - for adding ions
integrator  = steep
emtol       = 1000.0
emstep      = 0.01
nsteps      = 50000
nstlist     = 1
cutoff-scheme   = Verlet
ns_type     = grid
coulombtype = cutoff
rcoulomb    = 1.0
rvdw        = 1.0
pbc         = xyz
"""
        
        with open(project_path / "ions.mdp", 'w') as f:
            f.write(mdp_content)
        
        # Create TPR
        await self._run_command([
            self.gmx_command, "grompp",
            "-f", "ions.mdp",
            "-c", "solv.gro",
            "-p", "topol.top",
            "-o", "ions.tpr"
        ], cwd=project_path)
        
        # Add ions
        process = await asyncio.create_subprocess_exec(
            self.gmx_command, "genion",
            "-s", "ions.tpr",
            "-o", "ions.gro",
            "-p", "topol.top",
            "-pname", "NA",
            "-nname", "CL",
            "-neutral",
            cwd=project_path,
            stdin=asyncio.subprocess.PIPE,
            stdout=asyncio.subprocess.PIPE,
            stderr=asyncio.subprocess.PIPE
        )
        
        # Select solvent group (usually 13 for SOL)
        stdout, stderr = await process.communicate(input="13\n".encode())
        
        if process.returncode != 0:
            raise subprocess.CalledProcessError(process.returncode, "genion", stderr.decode())
        
        return {"ions_structure": str(project_path / "ions.gro")}
    
    async def _generate_mdp_files(self, project_path: Path, config: Dict) -> Dict[str, str]:
        """Generate MDP files for different simulation phases"""
        
        mdp_templates = {
            "minimization": """
; minim.mdp - Energy minimization
integrator  = steep         ; Algorithm (steep = steepest descent minimization)
emtol       = 1000.0        ; Stop minimization when max force < 1000.0 kJ/mol/nm
emstep      = 0.01          ; Minimization step size
nsteps      = 50000         ; Maximum number of (minimization) steps

nstlist     = 1             ; Frequency to update neighbor list
cutoff-scheme   = Verlet    ; Buffered neighbor searching
ns_type     = grid          ; Search neighboring grid cells
coulombtype = PME           ; Treatment of long range electrostatic interactions
rcoulomb    = 1.0           ; Short-range electrostatic cut-off
rvdw        = 1.0           ; Short-range Van der Waals cut-off
pbc         = xyz           ; Periodic Boundary Conditions in all 3 dimensions
""",
            
            "nvt": f"""
; nvt.mdp - NVT equilibration
define                  = -DPOSRES     ; position restrain the protein
integrator              = md           ; leap-frog integrator
nsteps                  = 50000        ; 2 * 50000 = 100 ps
dt                      = 0.002        ; 2 fs
nstxout                 = 500          ; save coordinates every 1.0 ps
nstvout                 = 500          ; save velocities every 1.0 ps
nstenergy               = 500          ; save energies every 1.0 ps
nstlog                  = 500          ; update log file every 1.0 ps
nstxout-compressed      = 500          ; save compressed coordinates every 1.0 ps

cutoff-scheme           = Verlet       ; Buffered neighbor searching
ns_type                 = grid         ; search neighboring grid cells
nstlist                 = 10           ; 20 fs, largely irrelevant with Verlet
rcoulomb                = 1.0          ; short-range electrostatic cutoff (in nm)
rvdw                    = 1.0          ; short-range van der Waals cutoff (in nm)

coulombtype             = PME          ; Particle Mesh Ewald for long-range electrostatics
pme_order               = 4            ; cubic interpolation
fourierspacing          = 0.16         ; grid spacing for FFT

tcoupl                  = V-rescale    ; modified Berendsen thermostat
tc-grps                 = Protein Non-Protein ; two coupling groups - more accurate
tau_t                   = 0.1     0.1  ; time constant, in ps
ref_t                   = {config.get('temperature', 300)}    {config.get('temperature', 300)}  ; reference temperature, K

pcoupl                  = no           ; no pressure coupling in NVT
pbc                     = xyz          ; 3-D PBC
""",
            
            "npt": f"""
; npt.mdp - NPT equilibration
define                  = -DPOSRES     ; position restrain the protein
integrator              = md           ; leap-frog integrator
nsteps                  = 50000        ; 2 * 50000 = 100 ps
dt                      = 0.002        ; 2 fs
nstxout                 = 500          ; save coordinates every 1.0 ps
nstvout                 = 500          ; save velocities every 1.0 ps
nstenergy               = 500          ; save energies every 1.0 ps
nstlog                  = 500          ; update log file every 1.0 ps
nstxout-compressed      = 500          ; save compressed coordinates every 1.0 ps

cutoff-scheme           = Verlet       ; Buffered neighbor searching
ns_type                 = grid         ; search neighboring grid cells
nstlist                 = 10           ; 20 fs, largely irrelevant with Verlet scheme
rcoulomb                = 1.0          ; short-range electrostatic cutoff (in nm)
rvdw                    = 1.0          ; short-range van der Waals cutoff (in nm)

coulombtype             = PME          ; Particle Mesh Ewald for long-range electrostatics
pme_order               = 4            ; cubic interpolation
fourierspacing          = 0.16         ; grid spacing for FFT

tcoupl                  = V-rescale    ; modified Berendsen thermostat
tc-grps                 = Protein Non-Protein ; two coupling groups - more accurate
tau_t                   = 0.1     0.1  ; time constant, in ps
ref_t                   = {config.get('temperature', 300)}    {config.get('temperature', 300)}  ; reference temperature, K

pcoupl                  = Parrinello-Rahman ; Pressure coupling on in NPT
pcoupltype              = isotropic    ; uniform scaling of box vectors
tau_p                   = 2.0          ; time constant, in ps
ref_p                   = {config.get('pressure', 1.0)}          ; reference pressure, bar
compressibility         = 4.5e-5      ; isothermal compressibility of water, bar^-1

pbc                     = xyz          ; 3-D PBC
""",
            
            "production": f"""
; md.mdp - Production MD simulation
integrator              = md           ; leap-frog integrator
nsteps                  = {int(config.get('total_time', 10) * 500000)} ; total simulation time
dt                      = {config.get('time_step', 0.002)}        ; time step
nstxout                 = 0            ; suppress bulky .trr file by setting to 0
nstvout                 = 0            ; suppress bulky .trr file by setting to 0
nstfout                 = 0            ; suppress bulky .trr file by setting to 0
nstenergy               = 5000         ; save energies every 10.0 ps
nstlog                  = 5000         ; update log file every 10.0 ps
nstxout-compressed      = 5000         ; save compressed coordinates every 10.0 ps

cutoff-scheme           = Verlet       ; Buffered neighbor searching
ns_type                 = grid         ; search neighboring grid cells
nstlist                 = 10           ; 20 fs, largely irrelevant with Verlet scheme
rcoulomb                = 1.0          ; short-range electrostatic cutoff (in nm)
rvdw                    = 1.0          ; short-range van der Waals cutoff (in nm)

coulombtype             = PME          ; Particle Mesh Ewald for long-range electrostatics
pme_order               = 4            ; cubic interpolation
fourierspacing          = 0.16         ; grid spacing for FFT

tcoupl                  = V-rescale    ; modified Berendsen thermostat
tc-grps                 = Protein Non-Protein ; two coupling groups - more accurate
tau_t                   = 0.1     0.1  ; time constant, in ps
ref_t                   = {config.get('temperature', 300)}    {config.get('temperature', 300)}  ; reference temperature, K

pcoupl                  = Parrinello-Rahman ; Pressure coupling on
pcoupltype              = isotropic    ; uniform scaling of box vectors
tau_p                   = 2.0          ; time constant, in ps
ref_p                   = {config.get('pressure', 1.0)}          ; reference pressure, bar
compressibility         = 4.5e-5      ; isothermal compressibility of water, bar^-1

pbc                     = xyz          ; 3-D PBC
gen_vel                 = no           ; Velocity generation is off
"""
        }
        
        generated_files = {}
        for phase, content in mdp_templates.items():
            filename = f"{phase}.mdp"
            filepath = project_path / filename
            
            with open(filepath, 'w') as f:
                f.write(content)
            
            generated_files[f"{phase}_mdp"] = str(filepath)
        
        return generated_files
    
    async def run_simulation_phase(
        self, 
        project_path: str, 
        phase: str, 
        config: Dict,
        progress_callback=None
    ) -> AsyncGenerator[str, None]:
        """
        Run a specific simulation phase (minimization, nvt, npt, production)
        Yields log output in real-time
        """
        project_dir = Path(project_path)
        
        if self.mock_mode:
            yield f"Starting {phase} simulation (mock mode)\n"
            for i in range(10):
                await asyncio.sleep(1)
                progress = (i + 1) * 10
                yield f"Step {i*100}, Progress: {progress}%\n"
                if progress_callback:
                    await progress_callback(progress)
            yield f"{phase} simulation completed successfully\n"
            return
        
        # Phase-specific configurations
        phase_configs = {
            "minimization": {
                "mdp": "minimization.mdp",
                "input_gro": "ions.gro" if (project_dir / "ions.gro").exists() else "conf.gro",
                "output_prefix": "em"
            },
            "nvt": {
                "mdp": "nvt.mdp", 
                "input_gro": "em.gro",
                "output_prefix": "nvt"
            },
            "npt": {
                "mdp": "npt.mdp",
                "input_gro": "nvt.gro", 
                "output_prefix": "npt"
            },
            "production": {
                "mdp": "production.mdp",
                "input_gro": "npt.gro",
                "output_prefix": "md"
            }
        }
        
        if phase not in phase_configs:
            raise ValueError(f"Unknown simulation phase: {phase}")
        
        phase_config = phase_configs[phase]
        
        # Step 1: grompp (preprocessing)
        yield f"Preprocessing {phase} simulation...\n"
        
        grompp_cmd = [
            self.gmx_command, "grompp",
            "-f", phase_config["mdp"],
            "-c", phase_config["input_gro"],
            "-p", "topol.top",
            "-o", f"{phase_config['output_prefix']}.tpr"
        ]
        
        try:
            await self._run_command(grompp_cmd, cwd=project_dir)
            yield f"Preprocessing completed successfully\n"
        except subprocess.CalledProcessError as e:
            yield f"Preprocessing failed: {e}\n"
            raise
        
        # Step 2: mdrun (actual simulation)
        yield f"Starting {phase} simulation...\n"
        
        mdrun_cmd = [
            self.gmx_command, "mdrun",
            "-s", f"{phase_config['output_prefix']}.tpr",
            "-o", f"{phase_config['output_prefix']}.trr",
            "-c", f"{phase_config['output_prefix']}.gro",
            "-e", f"{phase_config['output_prefix']}.edr",
            "-g", f"{phase_config['output_prefix']}.log",
            "-v"  # Verbose output
        ]
        
        # Add GPU/CPU specific flags
        if config.get("gpu_enabled", True):
            mdrun_cmd.extend(["-nb", "gpu"])
        else:
            mdrun_cmd.extend(["-nb", "cpu"])
        
        # Add threading options
        if config.get("ntomp"):
            mdrun_cmd.extend(["-ntomp", str(config["ntomp"])])
        
        if config.get("ntmpi"):
            mdrun_cmd.extend(["-ntmpi", str(config["ntmpi"])])
        
        # Run mdrun with real-time output
        async for line in self._run_command_with_output(mdrun_cmd, cwd=project_dir):
            yield line
            
            # Parse progress from GROMACS output
            if progress_callback:
                progress = self._parse_progress_from_output(line)
                if progress is not None:
                    await progress_callback(progress)
        
        yield f"{phase} simulation completed successfully\n"
    
    async def _run_command(self, command: List[str], cwd: Path) -> str:
        """Run a command and return output"""
        process = await asyncio.create_subprocess_exec(
            *command,
            cwd=cwd,
            stdout=asyncio.subprocess.PIPE,
            stderr=asyncio.subprocess.PIPE
        )
        
        stdout, stderr = await process.communicate()
        
        if process.returncode != 0:
            error_msg = stderr.decode() if stderr else "Unknown error"
            raise subprocess.CalledProcessError(process.returncode, command, error_msg)
        
        return stdout.decode()
    
    async def _run_command_with_output(self, command: List[str], cwd: Path) -> AsyncGenerator[str, None]:
        """Run a command and yield output line by line"""
        process = await asyncio.create_subprocess_exec(
            *command,
            cwd=cwd,
            stdout=asyncio.subprocess.PIPE,
            stderr=asyncio.subprocess.STDOUT
        )
        
        while True:
            line = await process.stdout.readline()
            if not line:
                break
            yield line.decode()
        
        await process.wait()
        
        if process.returncode != 0:
            raise subprocess.CalledProcessError(process.returncode, command)
    
    def _parse_progress_from_output(self, line: str) -> Optional[float]:
        """Parse simulation progress from GROMACS output"""
        # Look for progress indicators in GROMACS output
        # Example: "Step 12500, time 25.000 (ps), lambda 0"
        step_match = re.search(r'Step\s+(\d+)', line)
        if step_match:
            current_step = int(step_match.group(1))
            # This is a simplified progress calculation
            # In real implementation, you'd need to know total steps
            return min(100.0, (current_step / 50000) * 100)
        
        return None
