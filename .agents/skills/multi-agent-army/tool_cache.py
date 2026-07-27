"""
Tool Output Caching for Multi-Agent Army
Caches tool results to avoid redundant API calls and reduce latency.
"""

import json
import time
import hashlib
from pathlib import Path
from typing import Any, Optional
from dataclasses import dataclass, asdict
import threading


@dataclass
class CacheEntry:
    timestamp: float
    tool: str
    args_hash: str
    output: str
    hit_count: int = 0


class ToolCache:
    """Thread-safe tool output cache with TTL and size limits."""
    
    def __init__(
        self,
        cache_dir: Optional[Path] = None,
        default_ttl: int = 3600,  # 1 hour
        max_entries: int = 10000,
        max_size_mb: int = 100
    ):
        self.cache_dir = cache_dir or Path.home() / ".hermes" / "cache" / "tool_outputs"
        self.cache_dir.mkdir(parents=True, exist_ok=True)
        self.default_ttl = default_ttl
        self.max_entries = max_entries
        self.max_size_bytes = max_size_mb * 1024 * 1024
        self._lock = threading.RLock()
        self._memory_cache: dict[str, CacheEntry] = {}
        self._load_index()
    
    def _load_index(self):
        """Load cache index from disk."""
        index_path = self.cache_dir / "index.json"
        if index_path.exists():
            try:
                data = json.loads(index_path.read_text())
                for key, entry_data in data.items():
                    self._memory_cache[key] = CacheEntry(**entry_data)
            except Exception:
                pass  # Ignore corrupt index
    
    def _save_index(self):
        """Save cache index to disk."""
        index_path = self.cache_dir / "index.json"
        try:
            data = {k: asdict(v) for k, v in self._memory_cache.items()}
            index_path.write_text(json.dumps(data))
        except Exception:
            pass
    
    def _args_hash(self, tool: str, args: dict) -> str:
        """Generate deterministic hash for tool + args."""
        # Sort args for consistent hashing
        content = f"{tool}:{json.dumps(args, sort_keys=True, default=str)}"
        return hashlib.sha256(content.encode()).hexdigest()[:16]
    
    def _cache_key(self, tool: str, args: dict) -> str:
        return f"{tool}:{self._args_hash(tool, args)}"
    
    def get(self, tool: str, args: dict, ttl: Optional[int] = None) -> Optional[str]:
        """
        Get cached output if valid.
        
        Args:
            tool: Tool name (e.g., 'read_file', 'search_files')
            args: Tool arguments
            ttl: Time-to-live in seconds (None = default)
        
        Returns:
            Cached output string or None if miss/expired
        """
        key = self._cache_key(tool, args)
        ttl = ttl or self.default_ttl
        
        with self._lock:
            entry = self._memory_cache.get(key)
            if not entry:
                return None
            
            if time.time() - entry.timestamp > ttl:
                # Expired
                del self._memory_cache[key]
                return None
            
            entry.hit_count += 1
            return entry.output
    
    def set(self, tool: str, args: dict, output: str):
        """Cache tool output."""
        key = self._cache_key(tool, args)
        
        with self._lock:
            # Evict if needed
            if len(self._memory_cache) >= self.max_entries:
                self._evict_lru()
            
            entry = CacheEntry(
                timestamp=time.time(),
                tool=tool,
                args_hash=self._args_hash(tool, args),
                output=output,
                hit_count=0
            )
            self._memory_cache[key] = entry
            self._save_index()
    
    def _evict_lru(self):
        """Evict least recently used entries."""
        # Sort by (hit_count, timestamp) - prefer keeping high-hit, recent entries
        sorted_keys = sorted(
            self._memory_cache.keys(),
            key=lambda k: (self._memory_cache[k].hit_count, self._memory_cache[k].timestamp)
        )
        # Remove oldest 10%
        evict_count = max(1, len(sorted_keys) // 10)
        for key in sorted_keys[:evict_count]:
            del self._memory_cache[key]
    
    def invalidate(self, tool: str, args: dict) -> bool:
        """Manually invalidate a cache entry."""
        key = self._cache_key(tool, args)
        with self._lock:
            if key in self._memory_cache:
                del self._memory_cache[key]
                self._save_index()
                return True
        return False
    
    def clear(self, tool: Optional[str] = None):
        """Clear cache entries (all or for specific tool)."""
        with self._lock:
            if tool is None:
                self._memory_cache.clear()
            else:
                keys_to_delete = [
                    k for k, v in self._memory_cache.items()
                    if v.tool == tool
                ]
                for k in keys_to_delete:
                    del self._memory_cache[k]
            self._save_index()
    
    def stats(self) -> dict:
        """Get cache statistics."""
        with self._lock:
            total_hits = sum(e.hit_count for e in self._memory_cache.values())
            by_tool = {}
            for entry in self._memory_cache.values():
                by_tool[entry.tool] = by_tool.get(entry.tool, 0) + 1
            
            return {
                "entries": len(self._memory_cache),
                "total_hits": total_hits,
                "hit_rate": total_hits / max(1, len(self._memory_cache)),
                "by_tool": by_tool,
                "size_estimate_mb": sum(len(e.output) for e in self._memory_cache.values()) / 1024 / 1024
            }


# Global cache instance (lazy initialization)
_global_cache: Optional[ToolCache] = None


def get_cache() -> ToolCache:
    """Get global cache instance."""
    global _global_cache
    if _global_cache is None:
        _global_cache = ToolCache()
    return _global_cache


# Convenience functions for common tools
CACHEABLE_TOOLS = {
    'read_file', 'read_text_file', 'search_files',
    'terminal', 'bash', 'list_directory',
    'mcp__filesystem__read_file', 'mcp__filesystem__list_directory',
    'mcp__filesystem__search_files',
}


def cached_tool_call(tool: str, args: dict, call_func, ttl: int = 3600) -> str:
    """
    Wrapper that caches tool calls.
    
    Usage:
        output = cached_tool_call('read_file', {'path': 'config.yaml'}, lambda: read_file('config.yaml'))
    """
    if tool not in CACHEABLE_TOOLS:
        return call_func()
    
    cache = get_cache()
    
    # Try cache first
    cached = cache.get(tool, args, ttl)
    if cached is not None:
        return f"[CACHED] {cached}"
    
    # Execute and cache
    output = call_func()
    cache.set(tool, args, output)
    return output


def make_cached_reader(read_func):
    """Decorator to add caching to file read functions."""
    def wrapper(path: str, *args, **kwargs):
        return cached_tool_call('read_file', {'path': path}, lambda: read_func(path, *args, **kwargs))
    return wrapper


if __name__ == "__main__":
    # Test
    cache = ToolCache(Path("./test_cache"))
    
    # Test set/get
    cache.set("read_file", {"path": "test.py"}, "print('hello')")
    result = cache.get("read_file", {"path": "test.py"})
    print(f"Cached read: {result}")
    
    # Test stats
    print(f"Stats: {cache.stats()}")
    
    # Cleanup
    import shutil
    shutil.rmtree("./test_cache", ignore_errors=True)