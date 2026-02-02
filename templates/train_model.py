"""
Training Template for ML Models
Usage: python train_model.py --config config.yaml
"""

import argparse
import torch
import numpy as np
from datetime import datetime


def setup_training():
    """Initialize training environment"""
    # Set random seeds for reproducibility
    torch.manual_seed(42)
    np.random.seed(42)
    
    # Check device
    device = torch.device("cuda" if torch.cuda.is_available() else "cpu")
    print(f"Using device: {device}")
    return device


def load_data(data_path):
    """Load and preprocess data"""
    print(f"Loading data from: {data_path}")
    # TODO: Implement data loading
    pass


def build_model():
    """Build and return model architecture"""
    # TODO: Define your model
    pass


def train_epoch(model, train_loader, optimizer, criterion, device):
    """Train for one epoch"""
    model.train()
    total_loss = 0
    
    for batch_idx, (data, target) in enumerate(train_loader):
        data, target = data.to(device), target.to(device)
        
        optimizer.zero_grad()
        output = model(data)
        loss = criterion(output, target)
        loss.backward()
        optimizer.step()
        
        total_loss += loss.item()
        
        if batch_idx % 10 == 0:
            print(f"Batch {batch_idx}/{len(train_loader)}, Loss: {loss.item():.4f}")
    
    return total_loss / len(train_loader)


def validate(model, val_loader, criterion, device):
    """Validate model"""
    model.eval()
    total_loss = 0
    correct = 0
    
    with torch.no_grad():
        for data, target in val_loader:
            data, target = data.to(device), target.to(device)
            output = model(data)
            loss = criterion(output, target)
            total_loss += loss.item()
            
            pred = output.argmax(dim=1, keepdim=True)
            correct += pred.eq(target.view_as(pred)).sum().item()
    
    accuracy = 100. * correct / len(val_loader.dataset)
    avg_loss = total_loss / len(val_loader)
    
    return avg_loss, accuracy


def main():
    parser = argparse.ArgumentParser(description='Train ML Model')
    parser.add_argument('--data', type=str, default='data/', help='Data directory')
    parser.add_argument('--epochs', type=int, default=10, help='Number of epochs')
    parser.add_argument('--batch-size', type=int, default=32, help='Batch size')
    parser.add_argument('--lr', type=float, default=0.001, help='Learning rate')
    parser.add_argument('--save', type=str, default='model.pth', help='Model save path')
    args = parser.parse_args()
    
    print(f"Starting training at {datetime.now()}")
    print(f"Arguments: {args}")
    
    # Setup
    device = setup_training()
    
    # Load data
    train_loader, val_loader = load_data(args.data)
    
    # Build model
    model = build_model().to(device)
    optimizer = torch.optim.Adam(model.parameters(), lr=args.lr)
    criterion = torch.nn.CrossEntropyLoss()
    
    # Training loop
    best_accuracy = 0
    for epoch in range(1, args.epochs + 1):
        print(f"\nEpoch {epoch}/{args.epochs}")
        
        train_loss = train_epoch(model, train_loader, optimizer, criterion, device)
        val_loss, val_accuracy = validate(model, val_loader, criterion, device)
        
        print(f"Train Loss: {train_loss:.4f}")
        print(f"Val Loss: {val_loss:.4f}, Val Accuracy: {val_accuracy:.2f}%")
        
        # Save best model
        if val_accuracy > best_accuracy:
            best_accuracy = val_accuracy
            torch.save(model.state_dict(), args.save)
            print(f"Saved best model with accuracy: {best_accuracy:.2f}%")
    
    print(f"\nTraining completed at {datetime.now()}")
    print(f"Best accuracy: {best_accuracy:.2f}%")


if __name__ == "__main__":
    main()
