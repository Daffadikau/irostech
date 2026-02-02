"""
Data preprocessing utilities for ML projects
"""

import numpy as np
import pandas as pd
from sklearn.model_selection import train_test_split
from sklearn.preprocessing import StandardScaler, LabelEncoder


def load_csv_data(filepath, target_column):
    """Load data from CSV file"""
    df = pd.read_csv(filepath)
    X = df.drop(columns=[target_column])
    y = df[target_column]
    return X, y


def preprocess_data(X, y, test_size=0.2, random_state=42):
    """
    Preprocess data: split, scale, encode
    
    Returns:
        X_train, X_test, y_train, y_test (all preprocessed)
    """
    # Split data
    X_train, X_test, y_train, y_test = train_test_split(
        X, y, test_size=test_size, random_state=random_state
    )
    
    # Scale features
    scaler = StandardScaler()
    X_train_scaled = scaler.fit_transform(X_train)
    X_test_scaled = scaler.transform(X_test)
    
    # Encode labels if necessary
    if y_train.dtype == 'object':
        encoder = LabelEncoder()
        y_train = encoder.fit_transform(y_train)
        y_test = encoder.transform(y_test)
    
    return X_train_scaled, X_test_scaled, y_train, y_test, scaler


def handle_missing_values(df, strategy='mean'):
    """Handle missing values in dataframe"""
    if strategy == 'mean':
        return df.fillna(df.mean())
    elif strategy == 'median':
        return df.fillna(df.median())
    elif strategy == 'drop':
        return df.dropna()
    else:
        raise ValueError(f"Unknown strategy: {strategy}")


def remove_outliers(df, columns, n_std=3):
    """Remove outliers using z-score method"""
    df_clean = df.copy()
    for col in columns:
        mean = df_clean[col].mean()
        std = df_clean[col].std()
        df_clean = df_clean[
            (df_clean[col] >= mean - n_std * std) & 
            (df_clean[col] <= mean + n_std * std)
        ]
    return df_clean


def feature_engineering(df):
    """Add engineered features"""
    # Example: Add interaction features, polynomial features, etc.
    # TODO: Customize based on your data
    return df


if __name__ == "__main__":
    # Quick test
    print("Data utils loaded successfully!")
