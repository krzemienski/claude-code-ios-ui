#!/usr/bin/env python3

"""
Test Report Generator
Generates comprehensive HTML and JSON test reports from test results
"""

import json
import os
import sys
import argparse
import glob
import datetime
import base64
from pathlib import Path
from typing import Dict, List, Any, Optional
import xml.etree.ElementTree as ET

class TestReportGenerator:
    def __init__(self, results_dir: str, output_file: str, format: str = 'html'):
        self.results_dir = Path(results_dir)
        self.output_file = Path(output_file)
        self.format = format
        self.test_results = {
            'unit': [],
            'integration': [],
            'ui': [],
            'performance': []
        }
        self.metrics = {
            'total_tests': 0,
            'passed': 0,
            'failed': 0,
            'skipped': 0,
            'duration': 0,
            'coverage': 0
        }
        
    def collect_results(self):
        """Collect all test results from the results directory"""
        print(f"Collecting test results from {self.results_dir}")
        
        # Find all xcresult bundles
        for xcresult in self.results_dir.glob("**/*.xcresult"):
            self.parse_xcresult(xcresult)
            
        # Find all JSON reports
        for json_file in self.results_dir.glob("**/*.json"):
            self.parse_json_report(json_file)
            
        # Find all log files
        for log_file in self.results_dir.glob("**/*.log"):
            self.parse_log_file(log_file)
            
    def parse_xcresult(self, xcresult_path: Path):
        """Parse xcresult bundle for test results"""
        try:
            # Use xcresulttool to extract test results
            import subprocess
            result = subprocess.run(
                ['xcrun', 'xcresulttool', 'get', '--path', str(xcresult_path), '--format', 'json'],
                capture_output=True,
                text=True
            )
            
            if result.returncode == 0:
                data = json.loads(result.stdout)
                self.process_xcresult_data(data, xcresult_path.name)
        except Exception as e:
            print(f"Error parsing {xcresult_path}: {e}")
            
    def parse_json_report(self, json_path: Path):
        """Parse JSON test report"""
        try:
            with open(json_path, 'r') as f:
                data = json.load(f)
                self.process_json_data(data, json_path.name)
        except Exception as e:
            print(f"Error parsing {json_path}: {e}")
            
    def parse_log_file(self, log_path: Path):
        """Parse log file for test results"""
        try:
            with open(log_path, 'r') as f:
                content = f.read()
                # Extract test results from log content
                self.process_log_content(content, log_path.name)
        except Exception as e:
            print(f"Error parsing {log_path}: {e}")
            
    def process_xcresult_data(self, data: Dict, filename: str):
        """Process parsed xcresult data"""
        # Determine test type from filename
        test_type = self.determine_test_type(filename)
        
        # Extract test results
        if 'tests' in data:
            for test in data['tests']:
                result = {
                    'name': test.get('name', 'Unknown'),
                    'status': test.get('status', 'unknown'),
                    'duration': test.get('duration', 0),
                    'message': test.get('message', '')
                }
                self.test_results[test_type].append(result)
                self.update_metrics(result)
                
    def process_json_data(self, data: Dict, filename: str):
        """Process parsed JSON data"""
        test_type = self.determine_test_type(filename)
        
        if 'tests' in data:
            for test in data['tests']:
                self.test_results[test_type].append(test)
                self.update_metrics(test)
        
        # Extract coverage if available
        if 'coverage' in data:
            self.metrics['coverage'] = data['coverage']
            
    def process_log_content(self, content: str, filename: str):
        """Process log file content"""
        # Parse test results from log format
        pass
        
    def determine_test_type(self, filename: str) -> str:
        """Determine test type from filename"""
        filename_lower = filename.lower()
        if 'unit' in filename_lower:
            return 'unit'
        elif 'integration' in filename_lower:
            return 'integration'
        elif 'ui' in filename_lower:
            return 'ui'
        elif 'performance' in filename_lower:
            return 'performance'
        return 'unit'
        
    def update_metrics(self, test_result: Dict):
        """Update overall metrics"""
        self.metrics['total_tests'] += 1
        
        status = test_result.get('status', '').lower()
        if status in ['passed', 'pass', 'success']:
            self.metrics['passed'] += 1
        elif status in ['failed', 'fail', 'failure']:
            self.metrics['failed'] += 1
        elif status in ['skipped', 'skip']:
            self.metrics['skipped'] += 1
            
        self.metrics['duration'] += float(test_result.get('duration', 0))
        
    def generate_report(self):
        """Generate the test report in the specified format"""
        self.collect_results()
        
        if self.format == 'html':
            self.generate_html_report()
        elif self.format == 'json':
            self.generate_json_report()
        elif self.format == 'markdown':
            self.generate_markdown_report()
        else:
            raise ValueError(f"Unsupported format: {self.format}")
            
    def generate_html_report(self):
        """Generate HTML test report"""
        pass_rate = (self.metrics['passed'] / self.metrics['total_tests'] * 100) if self.metrics['total_tests'] > 0 else 0
        
        html_content = f"""
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Test Report - {datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S')}</title>
    <style>
        * {{
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }}
        
        body {{
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen, Ubuntu, sans-serif;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            min-height: 100vh;
            padding: 20px;
        }}
        
        .container {{
            max-width: 1400px;
            margin: 0 auto;
        }}
        
        .header {{
            background: white;
            border-radius: 12px;
            padding: 30px;
            margin-bottom: 20px;
            box-shadow: 0 10px 40px rgba(0,0,0,0.1);
        }}
        
        h1 {{
            color: #333;
            font-size: 2.5em;
            margin-bottom: 10px;
        }}
        
        .timestamp {{
            color: #666;
            font-size: 1.1em;
        }}
        
        .metrics-grid {{
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
            gap: 20px;
            margin-bottom: 30px;
        }}
        
        .metric-card {{
            background: white;
            padding: 25px;
            border-radius: 12px;
            box-shadow: 0 5px 20px rgba(0,0,0,0.08);
            transition: transform 0.3s, box-shadow 0.3s;
        }}
        
        .metric-card:hover {{
            transform: translateY(-5px);
            box-shadow: 0 10px 30px rgba(0,0,0,0.15);
        }}
        
        .metric-label {{
            color: #888;
            font-size: 0.9em;
            text-transform: uppercase;
            letter-spacing: 1px;
            margin-bottom: 10px;
        }}
        
        .metric-value {{
            font-size: 2.5em;
            font-weight: bold;
            color: #333;
        }}
        
        .metric-value.success {{ color: #10b981; }}
        .metric-value.danger {{ color: #ef4444; }}
        .metric-value.warning {{ color: #f59e0b; }}
        .metric-value.info {{ color: #3b82f6; }}
        
        .progress-bar {{
            width: 100%;
            height: 40px;
            background: #f3f4f6;
            border-radius: 20px;
            overflow: hidden;
            margin: 30px 0;
        }}
        
        .progress-fill {{
            height: 100%;
            background: linear-gradient(90deg, #10b981 0%, #34d399 100%);
            display: flex;
            align-items: center;
            justify-content: center;
            color: white;
            font-weight: bold;
            font-size: 1.1em;
            transition: width 1s ease;
        }}
        
        .test-section {{
            background: white;
            border-radius: 12px;
            padding: 30px;
            margin-bottom: 20px;
            box-shadow: 0 5px 20px rgba(0,0,0,0.08);
        }}
        
        h2 {{
            color: #333;
            margin-bottom: 20px;
            font-size: 1.8em;
        }}
        
        .test-table {{
            width: 100%;
            border-collapse: collapse;
        }}
        
        .test-table th {{
            background: #f3f4f6;
            padding: 12px;
            text-align: left;
            font-weight: 600;
            color: #666;
            border-bottom: 2px solid #e5e7eb;
        }}
        
        .test-table td {{
            padding: 12px;
            border-bottom: 1px solid #e5e7eb;
        }}
        
        .test-table tr:hover {{
            background: #f9fafb;
        }}
        
        .status-badge {{
            display: inline-block;
            padding: 4px 12px;
            border-radius: 20px;
            font-size: 0.85em;
            font-weight: 600;
        }}
        
        .status-badge.passed {{
            background: #d1fae5;
            color: #065f46;
        }}
        
        .status-badge.failed {{
            background: #fee2e2;
            color: #991b1b;
        }}
        
        .status-badge.skipped {{
            background: #fef3c7;
            color: #92400e;
        }}
        
        .chart-container {{
            background: white;
            border-radius: 12px;
            padding: 30px;
            margin-bottom: 20px;
            box-shadow: 0 5px 20px rgba(0,0,0,0.08);
        }}
        
        .footer {{
            text-align: center;
            color: white;
            padding: 20px;
            font-size: 0.9em;
        }}
    </style>
    <script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>📊 ClaudeCode iOS Test Report</h1>
            <div class="timestamp">Generated on {datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S')}</div>
        </div>
        
        <div class="metrics-grid">
            <div class="metric-card">
                <div class="metric-label">Total Tests</div>
                <div class="metric-value info">{self.metrics['total_tests']}</div>
            </div>
            <div class="metric-card">
                <div class="metric-label">Passed</div>
                <div class="metric-value success">{self.metrics['passed']}</div>
            </div>
            <div class="metric-card">
                <div class="metric-label">Failed</div>
                <div class="metric-value danger">{self.metrics['failed']}</div>
            </div>
            <div class="metric-card">
                <div class="metric-label">Skipped</div>
                <div class="metric-value warning">{self.metrics['skipped']}</div>
            </div>
            <div class="metric-card">
                <div class="metric-label">Pass Rate</div>
                <div class="metric-value {'success' if pass_rate >= 80 else 'warning'}">{pass_rate:.1f}%</div>
            </div>
            <div class="metric-card">
                <div class="metric-label">Coverage</div>
                <div class="metric-value {'success' if self.metrics['coverage'] >= 80 else 'warning'}">{self.metrics['coverage']:.1f}%</div>
            </div>
        </div>
        
        <div class="progress-bar">
            <div class="progress-fill" style="width: {pass_rate}%">{pass_rate:.1f}% Tests Passing</div>
        </div>
        
        {self.generate_test_sections_html()}
        
        <div class="chart-container">
            <h2>Test Distribution</h2>
            <canvas id="testChart"></canvas>
        </div>
        
        <div class="footer">
            <p>Generated by ClaudeCode Test Infrastructure | © 2025</p>
        </div>
    </div>
    
    <script>
        // Test distribution chart
        const ctx = document.getElementById('testChart').getContext('2d');
        new Chart(ctx, {{
            type: 'doughnut',
            data: {{
                labels: ['Passed', 'Failed', 'Skipped'],
                datasets: [{{
                    data: [{self.metrics['passed']}, {self.metrics['failed']}, {self.metrics['skipped']}],
                    backgroundColor: ['#10b981', '#ef4444', '#f59e0b'],
                    borderWidth: 0
                }}]
            }},
            options: {{
                responsive: true,
                maintainAspectRatio: false,
                plugins: {{
                    legend: {{
                        position: 'bottom'
                    }}
                }}
            }}
        }});
    </script>
</body>
</html>
"""
        
        with open(self.output_file, 'w') as f:
            f.write(html_content)
            
        print(f"HTML report generated: {self.output_file}")
        
    def generate_test_sections_html(self) -> str:
        """Generate HTML for test sections"""
        sections_html = ""
        
        for test_type, tests in self.test_results.items():
            if not tests:
                continue
                
            sections_html += f"""
        <div class="test-section">
            <h2>{test_type.capitalize()} Tests</h2>
            <table class="test-table">
                <thead>
                    <tr>
                        <th>Test Name</th>
                        <th>Status</th>
                        <th>Duration</th>
                        <th>Message</th>
                    </tr>
                </thead>
                <tbody>
"""
            
            for test in tests:
                status_class = test['status'].lower()
                sections_html += f"""
                    <tr>
                        <td>{test['name']}</td>
                        <td><span class="status-badge {status_class}">{test['status'].upper()}</span></td>
                        <td>{test.get('duration', 0):.2f}s</td>
                        <td>{test.get('message', '')}</td>
                    </tr>
"""
            
            sections_html += """
                </tbody>
            </table>
        </div>
"""
        
        return sections_html
        
    def generate_json_report(self):
        """Generate JSON test report"""
        report_data = {
            'timestamp': datetime.datetime.now().isoformat(),
            'metrics': self.metrics,
            'test_results': self.test_results,
            'summary': {
                'pass_rate': (self.metrics['passed'] / self.metrics['total_tests'] * 100) if self.metrics['total_tests'] > 0 else 0,
                'total_duration': self.metrics['duration'],
                'coverage': self.metrics['coverage']
            }
        }
        
        with open(self.output_file, 'w') as f:
            json.dump(report_data, f, indent=2)
            
        print(f"JSON report generated: {self.output_file}")
        
    def generate_markdown_report(self):
        """Generate Markdown test report"""
        pass_rate = (self.metrics['passed'] / self.metrics['total_tests'] * 100) if self.metrics['total_tests'] > 0 else 0
        
        markdown_content = f"""# Test Report

Generated on: {datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S')}

## Summary

| Metric | Value |
|--------|-------|
| Total Tests | {self.metrics['total_tests']} |
| Passed | {self.metrics['passed']} |
| Failed | {self.metrics['failed']} |
| Skipped | {self.metrics['skipped']} |
| Pass Rate | {pass_rate:.1f}% |
| Coverage | {self.metrics['coverage']:.1f}% |
| Duration | {self.metrics['duration']:.2f}s |

## Test Results

"""
        
        for test_type, tests in self.test_results.items():
            if not tests:
                continue
                
            markdown_content += f"""### {test_type.capitalize()} Tests

| Test Name | Status | Duration |
|-----------|--------|----------|
"""
            
            for test in tests:
                markdown_content += f"| {test['name']} | {test['status']} | {test.get('duration', 0):.2f}s |\n"
                
            markdown_content += "\n"
            
        with open(self.output_file, 'w') as f:
            f.write(markdown_content)
            
        print(f"Markdown report generated: {self.output_file}")

def main():
    parser = argparse.ArgumentParser(description='Generate test reports from test results')
    parser.add_argument('--results-dir', required=True, help='Directory containing test results')
    parser.add_argument('--output-file', required=True, help='Output file path')
    parser.add_argument('--format', choices=['html', 'json', 'markdown'], default='html', help='Report format')
    
    args = parser.parse_args()
    
    generator = TestReportGenerator(args.results_dir, args.output_file, args.format)
    generator.generate_report()

if __name__ == '__main__':
    main()