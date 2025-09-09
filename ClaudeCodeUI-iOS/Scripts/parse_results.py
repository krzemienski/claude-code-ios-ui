#!/usr/bin/env python3
"""
iOS Test Results Parser
Parses xcresult bundles and generates comprehensive test reports
"""

import json
import sys
import os
import subprocess
from datetime import datetime
from pathlib import Path
from typing import Dict, List, Any, Optional
import re

class TestResultParser:
    """Parse and analyze iOS test results from xcresult bundles"""
    
    def __init__(self, results_dir: str):
        self.results_dir = Path(results_dir)
        self.results = {
            'total_tests': 0,
            'passed': 0,
            'failed': 0,
            'skipped': 0,
            'performance': {},
            'failures': [],
            'test_suites': {},
            'coverage': None,
            'duration': 0.0
        }
        
    def parse_all_results(self) -> Dict[str, Any]:
        """Parse all xcresult bundles in the results directory"""
        
        print(f"📊 Parsing test results from {self.results_dir}")
        
        # Find all xcresult bundles
        xcresult_files = list(self.results_dir.glob("*.xcresult"))
        
        if not xcresult_files:
            print("⚠️  No xcresult files found")
            return self.results
        
        for xcresult_path in xcresult_files:
            print(f"  Processing: {xcresult_path.name}")
            self._parse_xcresult(xcresult_path)
        
        # Parse log files for additional metrics
        self._parse_log_files()
        
        return self.results
    
    def _parse_xcresult(self, xcresult_path: Path) -> None:
        """Parse a single xcresult bundle"""
        
        try:
            # Export JSON from xcresult
            json_output = subprocess.check_output([
                'xcrun', 'xcresulttool', 'get',
                '--format', 'json',
                '--path', str(xcresult_path)
            ], text=True)
            
            data = json.loads(json_output)
            
            # Extract test metrics
            self._extract_test_metrics(data, xcresult_path.stem)
            
            # Extract performance metrics
            self._extract_performance_metrics(data)
            
            # Extract failure details
            self._extract_failures(data)
            
        except subprocess.CalledProcessError as e:
            print(f"  ❌ Failed to parse {xcresult_path.name}: {e}")
        except json.JSONDecodeError as e:
            print(f"  ❌ Invalid JSON in {xcresult_path.name}: {e}")
    
    def _extract_test_metrics(self, data: Dict, suite_name: str) -> None:
        """Extract test count metrics from result data"""
        
        metrics = data.get('metrics', {})
        
        # Get test counts
        tests_count = metrics.get('testsCount', {}).get('_value', 0)
        tests_failed = metrics.get('testsFailedCount', {}).get('_value', 0)
        tests_skipped = metrics.get('testsSkippedCount', {}).get('_value', 0)
        
        # Update totals
        self.results['total_tests'] += tests_count
        self.results['failed'] += tests_failed
        self.results['skipped'] += tests_skipped
        self.results['passed'] += (tests_count - tests_failed - tests_skipped)
        
        # Store per-suite metrics
        self.results['test_suites'][suite_name] = {
            'total': tests_count,
            'passed': tests_count - tests_failed - tests_skipped,
            'failed': tests_failed,
            'skipped': tests_skipped
        }
        
        # Get duration if available
        if 'duration' in metrics:
            duration = metrics['duration'].get('_value', 0)
            self.results['duration'] += duration
    
    def _extract_performance_metrics(self, data: Dict) -> None:
        """Extract performance metrics from test results"""
        
        # Look for performance test results in the actions
        actions = data.get('actions', {}).get('_values', [])
        
        for action in actions:
            if action.get('_type', {}).get('_name') == 'ActionTestPlanRunSummaries':
                summaries = action.get('summaries', {}).get('_values', [])
                
                for summary in summaries:
                    tests = summary.get('testableSummaries', {}).get('_values', [])
                    
                    for test in tests:
                        self._parse_performance_tests(test)
    
    def _parse_performance_tests(self, test_data: Dict) -> None:
        """Parse performance test metrics"""
        
        tests = test_data.get('tests', {}).get('_values', [])
        
        for test in tests:
            if 'performanceMetrics' in test:
                metrics = test['performanceMetrics'].get('_values', [])
                
                for metric in metrics:
                    name = metric.get('displayName', 'Unknown')
                    value = metric.get('value', {}).get('_value', 0)
                    unit = metric.get('unitOfMeasurement', '')
                    
                    self.results['performance'][name] = {
                        'value': value,
                        'unit': unit
                    }
    
    def _extract_failures(self, data: Dict) -> None:
        """Extract test failure details"""
        
        # Navigate through the complex xcresult structure
        issues = data.get('issues', {}).get('testFailureSummaries', {}).get('_values', [])
        
        for issue in issues:
            failure = {
                'test_name': issue.get('testCaseName', 'Unknown'),
                'message': issue.get('message', 'No message'),
                'file': issue.get('documentLocationInCreatingWorkspace', {}).get('url', ''),
                'line': issue.get('documentLocationInCreatingWorkspace', {}).get('lineNumber', 0)
            }
            
            self.results['failures'].append(failure)
    
    def _parse_log_files(self) -> None:
        """Parse log files for additional metrics and information"""
        
        log_files = list(self.results_dir.glob("*.log"))
        
        for log_file in log_files:
            with open(log_file, 'r') as f:
                content = f.read()
                
                # Extract performance metrics from logs
                self._extract_performance_from_logs(content)
                
                # Extract error patterns
                self._extract_error_patterns(content)
    
    def _extract_performance_from_logs(self, content: str) -> None:
        """Extract performance metrics from log content"""
        
        # Look for common performance patterns
        patterns = {
            'launch_time': r'Launch time: ([\d.]+)(?:ms|s)',
            'memory_usage': r'Memory usage: ([\d.]+)(?:MB|KB)',
            'frame_rate': r'Frame rate: ([\d.]+)\s*(?:fps|FPS)',
            'response_time': r'Response time: ([\d.]+)(?:ms|s)'
        }
        
        for metric_name, pattern in patterns.items():
            matches = re.findall(pattern, content)
            if matches:
                # Take the average if multiple matches
                values = [float(m) for m in matches]
                avg_value = sum(values) / len(values)
                
                if metric_name not in self.results['performance']:
                    self.results['performance'][metric_name] = {
                        'value': avg_value,
                        'unit': 'ms' if 'time' in metric_name else 'MB'
                    }
    
    def _extract_error_patterns(self, content: str) -> None:
        """Extract common error patterns from logs"""
        
        error_patterns = [
            r'XCTAssertTrue failed',
            r'XCTAssertEqual failed',
            r'XCTAssertNotNil failed',
            r'Test Case.*failed',
            r'error:.*',
            r'FAILED:.*'
        ]
        
        for pattern in error_patterns:
            matches = re.findall(pattern, content)
            for match in matches[:5]:  # Limit to first 5 of each type
                if match not in [f['message'] for f in self.results['failures']]:
                    self.results['failures'].append({
                        'test_name': 'Log Error',
                        'message': match,
                        'file': 'test.log',
                        'line': 0
                    })
    
    def generate_report(self) -> str:
        """Generate a comprehensive test report"""
        
        report = []
        report.append("=" * 60)
        report.append("📊 iOS FUNCTIONAL TEST REPORT")
        report.append("=" * 60)
        report.append(f"Generated: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
        report.append("")
        
        # Overall Summary
        report.append("## OVERALL SUMMARY")
        report.append("-" * 40)
        total = self.results['total_tests']
        if total > 0:
            pass_rate = (self.results['passed'] / total) * 100
            report.append(f"Total Tests:    {total}")
            report.append(f"Passed:         {self.results['passed']} ({pass_rate:.1f}%)")
            report.append(f"Failed:         {self.results['failed']}")
            report.append(f"Skipped:        {self.results['skipped']}")
            report.append(f"Duration:       {self.results['duration']:.2f}s")
            
            # Add verdict
            if self.results['failed'] == 0:
                report.append("\n✅ ALL TESTS PASSED!")
            else:
                report.append(f"\n❌ {self.results['failed']} TESTS FAILED")
        else:
            report.append("No test results found")
        
        # Test Suite Breakdown
        if self.results['test_suites']:
            report.append("\n## TEST SUITE BREAKDOWN")
            report.append("-" * 40)
            
            for suite_name, metrics in self.results['test_suites'].items():
                status = "✅" if metrics['failed'] == 0 else "❌"
                report.append(f"{status} {suite_name}:")
                report.append(f"   Total: {metrics['total']}, Passed: {metrics['passed']}, Failed: {metrics['failed']}")
        
        # Performance Metrics
        if self.results['performance']:
            report.append("\n## PERFORMANCE METRICS")
            report.append("-" * 40)
            
            for metric_name, data in self.results['performance'].items():
                report.append(f"{metric_name}: {data['value']:.2f} {data.get('unit', '')}")
        
        # Failures
        if self.results['failures']:
            report.append("\n## TEST FAILURES")
            report.append("-" * 40)
            
            for i, failure in enumerate(self.results['failures'][:10], 1):  # Show first 10
                report.append(f"\n{i}. {failure['test_name']}")
                report.append(f"   Message: {failure['message']}")
                if failure['file']:
                    report.append(f"   Location: {failure['file']}:{failure['line']}")
            
            if len(self.results['failures']) > 10:
                report.append(f"\n... and {len(self.results['failures']) - 10} more failures")
        
        # Recommendations
        report.append("\n## RECOMMENDATIONS")
        report.append("-" * 40)
        
        if self.results['failed'] > 0:
            report.append("1. Review and fix failing tests")
            report.append("2. Check test logs for detailed error messages")
            report.append("3. Ensure backend services are running correctly")
        
        if self.results['performance']:
            # Check for performance issues
            if 'launch_time' in self.results['performance']:
                launch_time = self.results['performance']['launch_time']['value']
                if launch_time > 1000:  # More than 1 second
                    report.append(f"⚠️  App launch time is slow ({launch_time:.0f}ms)")
            
            if 'memory_usage' in self.results['performance']:
                memory = self.results['performance']['memory_usage']['value']
                if memory > 100:  # More than 100MB
                    report.append(f"⚠️  High memory usage detected ({memory:.0f}MB)")
        
        if self.results['passed'] == self.results['total_tests'] and total > 0:
            report.append("✅ All tests passing - ready for deployment!")
        
        report.append("\n" + "=" * 60)
        
        return "\n".join(report)
    
    def export_json(self, output_file: str) -> None:
        """Export results as JSON"""
        
        with open(output_file, 'w') as f:
            json.dump(self.results, f, indent=2)
        
        print(f"📁 Results exported to {output_file}")
    
    def check_ci_status(self) -> int:
        """Return exit code for CI: 0 if all tests pass, 1 if any fail"""
        
        if self.results['failed'] > 0:
            return 1
        return 0


def main():
    """Main entry point"""
    
    if len(sys.argv) < 2:
        print("Usage: python3 parse_results.py <results_directory> [output_file]")
        sys.exit(1)
    
    results_dir = sys.argv[1]
    output_file = sys.argv[2] if len(sys.argv) > 2 else None
    
    # Check if results directory exists
    if not os.path.exists(results_dir):
        print(f"❌ Results directory not found: {results_dir}")
        sys.exit(1)
    
    # Parse results
    parser = TestResultParser(results_dir)
    results = parser.parse_all_results()
    
    # Generate and print report
    report = parser.generate_report()
    print(report)
    
    # Export JSON if requested
    if output_file:
        parser.export_json(output_file)
    else:
        # Save to default location
        json_file = os.path.join(results_dir, 'test-results.json')
        parser.export_json(json_file)
    
    # Exit with appropriate code for CI
    sys.exit(parser.check_ci_status())


if __name__ == "__main__":
    main()