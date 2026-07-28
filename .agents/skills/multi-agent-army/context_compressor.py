"""
Context Compression Utilities for Multi-Agent Army
Reduces token usage by compressing agent outputs and managing conversation history.
"""

import json
import re
from typing import Any
from dataclasses import dataclass


@dataclass
class CompressionResult:
    original_chars: int
    compressed_chars: int
    compression_ratio: float
    content: str


def compress_agent_output(
    raw_output: str,
    max_chars: int = 2000,
    preserve_keys: list[str] | None = None
) -> CompressionResult:
    """
    Compress agent output to structured summary.
    
    Preserves: status, files_changed, errors, summary, metrics
    Removes: verbose logs, full file contents, repetitive content
    """
    if preserve_keys is None:
        preserve_keys = [
            "status", "files_changed", "tests_added", "summary",
            "errors", "warnings", "metrics", "next_steps",
            "quality_gates_passed", "blockers"
        ]
    
    original_len = len(raw_output)
    
    if original_len <= max_chars:
        return CompressionResult(
            original_chars=original_len,
            compressed_chars=original_len,
            compression_ratio=1.0,
            content=raw_output
        )
    
    # Try to parse as JSON first (structured output)
    try:
        data = json.loads(raw_output)
        if isinstance(data, dict):
            # Extract only important keys
            compressed = {}
            for key in preserve_keys:
                if key in data:
                    compressed[key] = data[key]
            
            result = json.dumps(compressed, ensure_ascii=False)
            if len(result) > max_chars:
                # Truncate summary fields
                for key in ["summary", "errors", "warnings"]:
                    if key in compressed and isinstance(compressed[key], str):
                        compressed[key] = compressed[key][:500] + "... [truncated]"
                result = json.dumps(compressed, ensure_ascii=False)
            
            return CompressionResult(
                original_chars=original_len,
                compressed_chars=len(result),
                compression_ratio=len(result) / original_len,
                content=f"[COMPRESSED {original_len}→{len(result)} chars]\n{result}"
            )
    except (json.JSONDecodeError, TypeError):
        pass
    
    # Fallback: text-based compression
    lines = raw_output.split('\n')
    important_lines = []
    
    # Keywords that indicate important content
    important_keywords = [
        'status', 'completed', 'failed', 'error', 'warning',
        'files_changed', 'summary', 'metrics', 'tokens',
        'quality_gate', 'passed', 'blocked', 'next_steps',
        'created', 'modified', 'deleted', 'commit'
    ]
    
    for line in lines:
        line_lower = line.lower()
        if any(kw in line_lower for kw in important_keywords):
            important_lines.append(line)
        elif len(line) > 100 and not line.strip().startswith('#'):
            # Long lines might be file paths or important output
            important_lines.append(line[:200])
    
    # If still too many lines, take first and last N
    if len(important_lines) > 100:
        important_lines = important_lines[:50] + ["... [middle truncated] ..."] + important_lines[-50:]
    
    result = '\n'.join(important_lines)
    if len(result) > max_chars:
        result = result[:max_chars] + "\n... [truncated]"
    
    return CompressionResult(
        original_chars=original_len,
        compressed_chars=len(result),
        compression_ratio=len(result) / original_len,
        content=f"[COMPRESSED {original_len}→{len(result)} chars ({len(important_lines)} lines)]\n{result}"
    )


def sliding_window_history(
    messages: list[dict],
    window_size: int = 10,
    keep_system: bool = True,
    keep_first_user: bool = True
) -> list[dict]:
    """
    Apply sliding window to conversation history.
    
    Keeps:
    - System prompt (index 0)
    - First user message (index 1)  
    - Last N messages
    """
    if len(messages) <= window_size + (2 if keep_system and keep_first_user else 1):
        return messages
    
    result = []
    start_idx = 0
    
    if keep_system and messages and messages[0].get('role') == 'system':
        result.append(messages[0])
        start_idx = 1
    
    if keep_first_user and len(messages) > start_idx and messages[start_idx].get('role') == 'user':
        result.append(messages[start_idx])
        start_idx += 1
    
    # Add last N messages
    window_messages = messages[-window_size:]
    result.extend(window_messages)
    
    return result


def extract_key_info(text: str, max_items: int = 20) -> list[str]:
    """Extract key information from text (file paths, errors, status)."""
    patterns = [
        r'(?:created|modified|deleted|updated)\s+([\w/.-]+\.\w+)',  # file changes
        r'(?:error|exception|failed):\s*(.+)',  # errors
        r'(?:status|result):\s*(\w+)',  # status
        r'(?:warning|warn):\s*(.+)',  # warnings
    ]
    
    results = []
    for pattern in patterns:
        matches = re.findall(pattern, text, re.IGNORECASE)
        results.extend(matches[:max_items])
    
    return results[:max_items]


def summarize_tool_output(tool_name: str, args: dict, output: str, max_chars: int = 500) -> str:
    """Create a concise summary of tool output for context."""
    # Quick summaries per tool
    if tool_name in ['read_file', 'read_text_file']:
        lines = output.count('\n')
        return f"[read_file] {args.get('path', '?')} ({lines} lines)"
    
    elif tool_name in ['search_files', 'grep']:
        match_count = output.count('match') if 'match' in output else 'N/A'
        return f"[search_files] pattern={args.get('pattern', '?')} ({match_count} matches)"
    
    elif tool_name in ['terminal', 'bash']:
        cmd = args.get('command', '?')
        exit_code = 'OK' if 'exit_code=0' in output else 'FAIL'
        return f"[terminal] {cmd[:50]}... ({exit_code})"
    
    elif tool_name in ['write_file', 'patch']:
        path = args.get('path', '?')
        return f"[{tool_name}] {path}"
    
    elif tool_name == 'delegate_task':
        return f"[delegate_task] {args.get('goal', '?')[:60]}..."
    
    # Generic fallback
    return f"[{tool_name}] {str(args)[:100]}"


if __name__ == "__main__":
    # Test
    test_output = """
    Status: completed
    Files changed: src/auth/main.py, src/auth/routes.py, tests/test_auth.py
    Summary: Implemented JWT authentication with register, login, refresh endpoints
    Tests: 15 tests added, all passing
    Quality gates: ruff check passed, mypy passed, pytest passed
    Tokens used: 45,231
    Duration: 120s
    """ * 10  # Make it long
    
    result = compress_agent_output(test_output, max_chars=500)
    print(f"Original: {result.original_chars} chars")
    print(f"Compressed: {result.compressed_chars} chars")
    print(f"Ratio: {result.compression_ratio:.2%}")
    print(f"Content:\n{result.content}")