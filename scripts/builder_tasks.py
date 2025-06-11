#!/usr/bin/env python3

import subprocess
from datetime import datetime, timedelta
import re
from collections import defaultdict
import argparse

def run_command(command):
    """Run a shell command and return its output as a list of lines."""
    try:
        result = subprocess.run(command, shell=True, capture_output=True, text=True, check=True)
        return result.stdout.strip().split('\n')
    except subprocess.CalledProcessError as e:
        print(f"Error running command: {e}")
        return []

def builder_tasks(node):
    """Query builder tasks for a specific node between today and tomorrow."""
    today = datetime.now().strftime("%m-%d-%Y")
    tomorrow = (datetime.now() + timedelta(days=1)).strftime("%m-%d-%Y")

    command = f'brake-query builder-tasks "{node}" "{today}" "{tomorrow}"'
    return run_command(command)

def last_failed_builder_tasks(node):
    """Get failed builder tasks for a specific node."""
    tasks = builder_tasks(node)
    failed_tasks = []
    for task in tasks:
        if "failed" in task:
            # Split the line and get task ID (first column) and the full task name
            parts = task.split()
            if len(parts) >= 2:
                task_id = parts[0]
                # Find the Groq. part
                match = re.search(r'Groq\..*$', task)
                if match:
                    failed_tasks.append((task_id, match.group(0)))
    return failed_tasks

def failed_ci_diag_tasks():
    """Get failed tasks for all ci_diag nodes."""
    # Get list of ci_diag nodes
    command = 'brake-ctl list | grep "ci_diag" | awk \'{print $1}\''
    suspended_nodes = run_command(command)

    # Get failed tasks for each node
    all_failed_tasks = []
    for node in suspended_nodes:
        failed_tasks = last_failed_builder_tasks(node)
        all_failed_tasks.extend(failed_tasks)

    return all_failed_tasks

def normalize_task_name(task):
    """Normalize task name by removing node numbers."""
    # Replace node numbers with a placeholder
    return re.sub(r'\.node\d+\.', '.nodeX.', task)

def print_task_summary(tasks, verbose=False):
    """Print a summary of failed tasks with counts."""
    if not tasks:
        print("No failed tasks found.")
        return

    # Group tasks by normalized name
    task_groups = defaultdict(list)
    for task_id, task_name in tasks:
        normalized_name = normalize_task_name(task_name)
        task_groups[normalized_name].append((task_id, task_name))

    # Sort groups by count (descending) and then by task name
    sorted_groups = sorted(task_groups.items(), key=lambda x: (-len(x[1]), x[0]))

    # Print summary
    total_tasks = len(tasks)
    unique_patterns = len(task_groups)
    print(f"\nFound {total_tasks} failed tasks across {unique_patterns} unique patterns:")
    print("-" * 80)

    for pattern, task_list in sorted_groups:
        count = len(task_list)
        print(f"{count:3d}x  {pattern}")
        if verbose:
            # Sort task IDs for consistent output
            task_list.sort(key=lambda x: x[0])
            for task_id, _ in task_list:
                print(f"      {task_id}")
            print()  # Add blank line between groups

    print("-" * 80)

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description='Show failed builder tasks with optional verbose output.')
    parser.add_argument('node', nargs='?', help='Specific node to check (optional)')
    parser.add_argument('-v', '--verbose', action='store_true', help='Show task IDs for each pattern')
    args = parser.parse_args()

    if args.node:
        # If a node is provided as argument, show failed tasks for that node
        tasks = last_failed_builder_tasks(args.node)
        print(f"\nFailed tasks for node {args.node}:")
        print_task_summary(tasks, args.verbose)
    else:
        # Otherwise show failed tasks for all ci_diag nodes
        tasks = failed_ci_diag_tasks()
        print("\nFailed tasks across all ci_diag nodes:")
        print_task_summary(tasks, args.verbose)
