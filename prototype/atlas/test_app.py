from pathlib import Path
from html.parser import HTMLParser

ROOT = Path(__file__).parent


def test_app_shell_has_core_surfaces():
    html = (ROOT / "index.html").read_text()
    assert '<title>Atlas — connected thinking</title>' in html
    assert 'id="app"' in html
    assert 'app.js' in html
    assert 'styles.css' in html


def test_app_logic_exposes_persistent_object_workflow():
    js = (ROOT / "app.js").read_text()
    assert "localStorage" in js
    assert "exportWorkspace" in js
    assert "importWorkspace" in js
    assert "createObject" in js
    assert "searchObjects" in js


def test_html_is_parseable():
    html = (ROOT / "index.html").read_text()
    HTMLParser().feed(html)
