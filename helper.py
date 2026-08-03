#!/usr/bin/env python3
"""
OmniRoute Cookie Helper

- Kullanıcıdan Cookie header değerini alır.
- Basit doğrulama yapar.
- config.json dosyasına yazar.

Kullanım:
    python cookie_helper.py
"""

import json
import os
import re
from pathlib import Path

CONFIG_FILE = Path("config.json")


def validate_cookie(cookie: str):
    cookie = cookie.strip()

    if cookie.lower().startswith("cookie:"):
        cookie = cookie[7:].strip()

    if len(cookie) < 20:
        return False, "Cookie çok kısa."

    if ";" not in cookie:
        return False, "Cookie header formatı hatalı."

    # İsteğe bağlı temel kontrol
    has_hf = "hf-chat=" in cookie
    has_token = "token=" in cookie

    if not (has_hf or has_token):
        print("Uyarı: hf-chat veya token bulunamadı.")
        print("Yine de kaydetmek ister misiniz? (e/h)")
        if input("> ").lower() != "e":
            return False, "İptal edildi."

    return True, cookie


def load_config():
    if CONFIG_FILE.exists():
        with open(CONFIG_FILE, "r", encoding="utf8") as f:
            return json.load(f)
    return {}


def save_config(cookie):
    cfg = load_config()

    cfg["huggingchat"] = {
        "session_credentials": cookie
    }

    with open(CONFIG_FILE, "w", encoding="utf8") as f:
        json.dump(cfg, f, indent=4, ensure_ascii=False)


def main():
    print("=" * 50)
    print(" OmniRoute Cookie Helper")
    print("=" * 50)
    print()
    print("Cookie: kısmını DEĞİL")
    print("yalnızca değerini yapıştırın.")
    print()

    cookie = input("Cookie > ")

    ok, result = validate_cookie(cookie)

    if not ok:
        print("HATA:", result)
        return

    save_config(result)

    print()
    print("✓ Cookie doğrulandı.")
    print(f"✓ {CONFIG_FILE.absolute()} dosyasına kaydedildi.")


if __name__ == "__main__":
    main()