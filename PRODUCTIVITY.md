# Performance Tips for AI Engineer Internship

## Productivity Hacks

### 1. Use Aliases (Add to ~/.zshrc)
```bash
# Quick activate
alias ai='cd ~/AI-Internship-Workspace && source venv/bin/activate'

# Daily logs
alias daystart='~/AI-Internship-Workspace/daily_log.sh start'
alias dayend='~/AI-Internship-Workspace/daily_log.sh end'

# Jupyter
alias jlab='jupyter lab'

# Git shortcuts
alias gs='git status'
alias ga='git add .'
alias gc='git commit -m'
alias gp='git push'
```

### 2. VS Code Extensions (Install These)
- Python (Microsoft)
- Jupyter
- Pylance
- GitLens
- GitHub Copilot (if available)
- autoDocstring
- Black Formatter
- Error Lens

### 3. Chrome Extensions
- Grammarly (for communication)
- Toggl Track (time tracking)
- Notion Web Clipper (save resources)

### 4. Time Management (Pomodoro)
```bash
# Install timer
brew install --cask pomatez

# Or use terminal
timer() { sleep $1 && say "Time's up!" & }
# Usage: timer 25m
```

### 5. Daily Checklist
```
Morning (9 AM):
□ ./daily_log.sh start
□ Check messages/emails
□ Review today's tasks
□ Standup/update team

Work Blocks:
□ 9:30-11:30 - Deep work
□ 11:30-12:00 - Admin/review
□ 12:00-1:00 - Lunch
□ 1:00-3:00 - Deep work
□ 3:00-4:00 - Meetings/collab
□ 4:00-5:00 - Wrap up/docs

Evening (5 PM):
□ ./daily_log.sh end
□ Commit code
□ Update tickets/tasks
□ Plan tomorrow
```

### 6. Code Quality Automation
```bash
# Pre-commit hook (create .git/hooks/pre-commit)
#!/bin/bash
black . --line-length 100
flake8 . --max-line-length 100
```

### 7. Keyboard Shortcuts (Learn These)
- Cmd+Shift+P - VS Code command palette
- Cmd+/ - Toggle comment
- Option+Shift+F - Format document
- Cmd+D - Select next occurrence
- Cmd+Shift+L - Select all occurrences

### 8. Communication Templates

**Daily Standup:**
```
Yesterday: [What I completed]
Today: [What I'm working on]
Blockers: [Any issues/questions]
```

**Asking Questions:**
```
Context: [What you're trying to do]
What I tried: [Your attempts]
Error/Issue: [Specific problem]
Question: [Clear, specific ask]
```

**Progress Update:**
```
Task: [Name]
Status: [% complete or stage]
ETA: [Expected completion]
Next steps: [What's next]
```

### 9. Learning Resources Bookmarks
- [Papers with Code](https://paperswithcode.com/)
- [Hugging Face](https://huggingface.co/)
- [Kaggle](https://kaggle.com/)
- [arXiv.org](https://arxiv.org/) (AI papers)
- [Distill.pub](https://distill.pub/) (Visual explanations)

### 10. Energy Management
- Take breaks every 90 min
- Walk after lunch
- Drink water (keep bottle at desk)
- Eye rest: 20-20-20 rule (every 20 min, look 20 feet away for 20 sec)
- End work on time (no burnout!)

## Quick Commands Reference

```bash
# Setup env
python3 -m venv venv && source venv/bin/activate

# Install packages
pip install -r requirements.txt

# Update requirements
pip freeze > requirements.txt

# Check GPU
python -c "import torch; print(torch.cuda.is_available())"

# Run Jupyter
jupyter lab --port=8888

# Format code
black . --line-length 100

# Git workflow
git checkout -b feature/task-name
git add .
git commit -m "feat: description"
git push origin feature/task-name

# Kill process on port
lsof -ti:8888 | xargs kill -9
```

Good luck! 🚀
