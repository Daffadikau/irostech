# Irostech Internship - Setup Guide

## Your Workspace Structure
```
~/Irostech-Workspace/
├── requirements.txt          # Python packages
├── venv/                     # Virtual environment (create this)
├── projects/                 # Your work projects
├── learning/                 # Learning notes & experiments
├── daily-logs/               # Daily progress logs
└── templates/                # Code templates
```

## Quick Start

### 1. Create Virtual Environment
```bash
cd ~/Irostech-Workspace
python3 -m venv venv
source venv/bin/activate
```

### 2. Install AI/ML Packages
```bash
pip install --upgrade pip
pip install -r requirements.txt
```

### 3. Verify Installation
```bash
python -c "import torch; print('PyTorch:', torch.__version__)"
python -c "import tensorflow as tf; print('TensorFlow:', tf.__version__)"
python -c "import sklearn; print('Scikit-learn:', sklearn.__version__)"
```

### 4. Launch Jupyter Lab
```bash
jupyter lab
```

## Collaboration Baseline

- Roles, ownership, and roadmap: [docs/collaboration.md](docs/collaboration.md)
- Roadmap planning: [docs/roadmap.md](docs/roadmap.md)
- Architecture overview: [docs/architecture.md](docs/architecture.md)
- Decisions log: [docs/decisions.md](docs/decisions.md)
- Runbook: [docs/runbook.md](docs/runbook.md)
- Metrics tracking: [docs/metrics.md](docs/metrics.md)
- Contributing guide: [CONTRIBUTING.md](CONTRIBUTING.md)
- Meeting notes template: [templates/meeting-notes.md](templates/meeting-notes.md)

## Daily Workflow

### Start Your Day
```bash
cd ~/Irostech-Workspace
source venv/bin/activate
# Log your plan for the day
echo "$(date): Today's plan - [TASK]" >> daily-logs/$(date +%Y-%m).txt
```

### End Your Day
```bash
# Log what you accomplished
echo "$(date): Completed - [SUMMARY]" >> daily-logs/$(date +%Y-%m).txt
deactivate
```

## Productivity Tips

1. **Time Tracking**: Use `toggl` or simple text logs
2. **Code Quality**: Run `black .` before commits
3. **Experiments**: Use MLflow or Weights & Biases to track
4. **Backups**: Commit daily to Git

## Useful Commands

```bash
# Quick model training template
python templates/train_model.py --data data/ --model resnet

# Check GPU
python -c "import torch; print('CUDA available:', torch.cuda.is_available())"

# Format code
black . --line-length 100

# Install new package
pip install <package> && pip freeze > requirements.txt
```

## Communication Best Practices (WFH)

- **Standup**: Share progress in morning messages
- **Blockers**: Flag issues within 30 min
- **Questions**: Ask clearly with context
- **Updates**: Overcommunicate your status

## Resources

- [PyTorch Docs](https://pytorch.org/docs/)
- [TensorFlow Guide](https://www.tensorflow.org/guide)
- [Scikit-learn](https://scikit-learn.org/stable/)
- [Hugging Face](https://huggingface.co/)

Good luck! 🚀
