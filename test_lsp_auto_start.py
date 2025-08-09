#!/usr/bin/env python3
"""Test file for LSP auto-start functionality.

Instructions:
1. Open this file with: nvim test_lsp_auto_start.py
2. Don't wait for LSP to start manually
3. Place cursor on any function/variable name
4. Press 'gd' to go to definition - LSP should auto-start
5. Press 'gD' for declaration - should work or fallback to definition
6. Press 'gr' for references - LSP should be already started

The LSP server should start automatically when you press these keys.
"""

def test_function():
    """A simple test function."""
    result = 42
    return result

def main():
    """Main entry point."""
    # Test: put cursor on test_function and press gd
    value = test_function()
    
    # Test: put cursor on value and press gr for references
    print(f"The value is: {value}")
    
    # Another reference to value
    if value > 0:
        print("Value is positive")
    
    return value

if __name__ == "__main__":
    # Test: put cursor on main and press gd
    main()