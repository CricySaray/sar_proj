#!/bin/python3
# --------------------------
# author    : sar song
# date      : 2025/08/21 20:24:49 Thursday
# label     : 
#   -> (atomic_proc|display_proc|gui_proc|task_proc|dump_proc|check_proc|math_proc|package_proc|test_proc|datatype_proc|db_proc|misc_proc)
# descrip   : This script analyzes hierarchical paths from a file, enables users to specify categorization levels and keywords, 
#               then classifies paths into user-defined categories with empty lines separating different categories.
# usage     : Run the script with: python file_categorizer.py <your_input_file.txt> [output_file.txt]  
#             Follow prompts to choose a level for categorization, define categories with keywords (format: Category:keyword1,keyword2), 
#             type "done" when finished. Results will show on screen or save to your output file.
# return    : 
# ref       : link url
# --------------------------
import sys
from collections import defaultdict

def analyze_file(file_path):
  """Analyze the file and find all possible categorization points"""
  paths = []
  levels = defaultdict(set)  # Store all possible values for each level
  
  with open(file_path, 'r') as f:
    for line in f:
      line = line.strip()
      if line:
        paths.append(line)
        # Split path into levels
        parts = line.split('/')
        # Skip empty strings (since paths start with /)
        parts = [p for p in parts if p]
        for i, part in enumerate(parts):
          levels[i].add(part)
  
  print("File analysis results:")
  print(f"Found {len(paths)} paths")
  print("Possible categorization levels:")
  for level, values in levels.items():
    print(f"Level {level + 1}: Contains {len(values)} different values - {sorted(values)}")
  
  return paths, levels

def get_user_categories(levels):
  """Get user-defined categorization rules"""
  categories = {}
  
  # Let user select categorization level
  while True:
    try:
      level = int(input("\nPlease select the level to use for categorization (number): ")) - 1  # Convert to 0-based index
      if level in levels:
        break
      print(f"Invalid level, please select a number between 1 and {len(levels)}")
    except ValueError:
      print("Please enter a valid number")
  
  # Show all possible values for this level
  print(f"\nAll possible values for level {level + 1}: {sorted(levels[level])}")
  
  # Let user define categories
  print("\nPlease define categories (enter 'done' to finish)")
  print("Format: category_name:keyword1,keyword2,...")
  print("Example: CategoryA:item1,item2")
  
  while True:
    entry = input("> ").strip()
    if entry.lower() == 'done':
      if categories:  # Ensure at least one category is defined
        break
      else:
        print("Please define at least one category")
        continue
    
    if ':' not in entry:
      print("Format error, please use 'category_name:keyword1,keyword2,...' format")
      continue
    
    cat_name, keywords = entry.split(':', 1)
    cat_name = cat_name.strip()
    keywords = [k.strip() for k in keywords.split(',') if k.strip()]
    
    if not cat_name or not keywords:
      print("Both category name and keywords cannot be empty")
      continue
    
    categories[cat_name] = keywords
  
  # Add an "Other" category for paths that don't match any keywords
  categories["Other"] = []
  
  return level, categories

def categorize_paths(paths, level, categories):
  """Categorize paths according to user-defined rules"""
  categorized = defaultdict(list)
  
  for path in paths:
    parts = [p for p in path.split('/') if p]  # Split path and remove empty strings
    if len(parts) > level:
      path_part = parts[level]
      
      # Find matching category
      matched = False
      for cat_name, keywords in categories.items():
        if cat_name == "Other":
          continue  # Handle "Other" category last
        if any(keyword in path_part for keyword in keywords):
          categorized[cat_name].append(path)
          matched = True
          break
      
      if not matched:
        categorized["Other"].append(path)
    else:
      # Path doesn't have enough levels, put in "Other" category
      categorized["Other"].append(path)
  
  return categorized

def output_results(categorized, output_file=None):
  """Output the categorization results"""
  output = []
  
  for cat_name, paths in categorized.items():
    if paths:  # Only output categories with content
      output.append(f"===== {cat_name} =====")
      output.extend(paths)
      output.append("")  # Add empty line between different categories
  
  # Remove the last empty line
  if output and output[-1] == "":
    output.pop()
  
  result = '\n'.join(output)
  
  if output_file:
    with open(output_file, 'w') as f:
      f.write(result)
    print(f"\nCategorization results saved to {output_file}")
  else:
    print("\nCategorization results:")
    print(result)

def main():
  if len(sys.argv) < 2:
    print("Usage: python file_categorizer.py <input_file_path> [output_file_path]")
    sys.exit(1)
  
  input_file = sys.argv[1]
  output_file = sys.argv[2] if len(sys.argv) > 2 else None
  
  try:
    # Analyze the file
    paths, levels = analyze_file(input_file)
    
    # Get user-defined categorization rules
    level, categories = get_user_categories(levels)
    
    # Categorize paths
    categorized = categorize_paths(paths, level, categories)
    
    # Output results
    output_results(categorized, output_file)
    
  except FileNotFoundError:
    print(f"Error: File {input_file} not found")
    sys.exit(1)
  except Exception as e:
    print(f"An error occurred: {str(e)}")
    sys.exit(1)

if __name__ == "__main__":
  main()

