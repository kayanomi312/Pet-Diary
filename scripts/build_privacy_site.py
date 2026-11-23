#!/usr/bin/env python3
"""Render docs/privacy-policy.md into a static page for GitHub Pages.

Usage: build_privacy_site.py <output-dir>
Fails if the support-email placeholder is still in the policy, so a draft never gets published.
"""
import html
import pathlib
import sys

import markdown

PLACEHOLDER = "<insert support email>"
PLACEHOLDER_ZH = "<填入支援電子郵件>"

TEMPLATE = """<!doctype html>
<html lang="zh-Hant">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>足印日記 隱私權政策 · Pawprint Days Privacy Policy</title>
<style>
  body {{ font: 17px/1.7 -apple-system, "PingFang TC", "Noto Sans TC", system-ui, sans-serif;
         max-width: 42rem; margin: 2.5rem auto; padding: 0 1rem; color: #3b2f2a; background: #fbf6ec; }}
  h1 {{ font-size: 1.6rem; }} h2 {{ margin-top: 2.5rem; border-bottom: 1px solid #e3d6c0; padding-bottom: .3rem; }}
  a {{ color: #a0522d; }}
  @media (prefers-color-scheme: dark) {{ body {{ color: #efe6d8; background: #231d1a; }} h2 {{ border-color: #4a3f38; }} a {{ color: #e0a27a; }} }}
</style>
</head>
<body>
{body}
</body>
</html>
"""


def main() -> int:
    if len(sys.argv) != 2:
        print(__doc__)
        return 2
    root = pathlib.Path(__file__).resolve().parent.parent
    source = (root / "docs" / "privacy-policy.md").read_text(encoding="utf-8")
    if PLACEHOLDER in source or PLACEHOLDER_ZH in source:
        print("error: docs/privacy-policy.md still contains the support-email placeholder", file=sys.stderr)
        return 1
    out = pathlib.Path(sys.argv[1])
    (out / "privacy").mkdir(parents=True, exist_ok=True)
    body = markdown.markdown(source, extensions=["extra"])
    (out / "privacy" / "index.html").write_text(TEMPLATE.format(body=body), encoding="utf-8")
    (out / "index.html").write_text(
        '<!doctype html><meta charset="utf-8"><meta http-equiv="refresh" content="0; url=privacy/">'
        '<a href="privacy/">%s</a>' % html.escape("Privacy Policy"),
        encoding="utf-8",
    )
    return 0


if __name__ == "__main__":
    sys.exit(main())
