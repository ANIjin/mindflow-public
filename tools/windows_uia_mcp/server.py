"""Windows UI Automation MCP server for driving the MindFlow Flutter desktop app.

Exposes launch/attach/inspect/click/type/screenshot tools over stdio so an agent
can drive the native Windows window. Requires pywinauto, pillow, mcp<2.
"""

import pywinauto.keyboard as kb
from mcp.server.fastmcp import FastMCP
from pywinauto import Application, Desktop

m = FastMCP("windows-uia")
state = {"app": None, "win": None, "elements": []}


def _win():
    if state["win"] is None:
        raise RuntimeError("no window attached; call launch() or attach() first")
    return state["win"]


def _info(el):
    ei = el.element_info
    return (
        getattr(ei, "control_type", "?") or "?",
        getattr(ei, "name", "") or "",
        getattr(ei, "automation_id", "") or "",
    )


def _desc(e) -> str:
    r = e.rectangle()
    ct, name, aid = _info(e)
    return (
        f"{ct} name='{name}' aid='{aid}' "
        f"rect=({r.left},{r.top},{r.right},{r.bottom}) visible={e.is_visible}"
    )


@m.tool()
def launch(exe: str, args: str = "") -> str:
    """Start an app by executable path and attach to its main window."""
    cmd = f'"{exe}"' if " " in exe else exe
    if args:
        cmd = f"{cmd} {args}"
    app = Application(backend="uia")
    app.start(cmd, timeout=60)
    state["app"] = app
    state["win"] = app.top_window()
    state["win"].set_focus()
    return f"launched pid={app.process} window='{state['win'].window_text()}'"


@m.tool()
def attach(title_contains: str) -> str:
    """Attach to an already-running window whose title contains the text."""
    win = Desktop(backend="uia").window(title_re=f".*{title_contains}.*")
    state["app"] = None
    state["win"] = win
    win.set_focus()
    return f"attached window='{win.window_text()}'"


@m.tool()
def list_windows() -> str:
    """List visible top-level windows with their bounding rectangles."""
    lines = []
    for w in Desktop(backend="uia").windows():
        t = w.window_text()
        if t and t.strip():
            r = w.rectangle()
            lines.append(f"({r.left},{r.top},{r.right},{r.bottom}) '{t}'")
    return "\n".join(lines)


@m.tool()
def snapshot(max_depth: int = 6) -> str:
    """Dump the UI Automation tree of the attached window."""
    lines = []

    def walk(el, d):
        if d > max_depth:
            return
        r = el.rectangle()
        ct, name, aid = _info(el)
        lines.append(
            "  " * d
            + f"{ct} '{name}' aid='{aid}' ({r.left},{r.top},{r.right},{r.bottom})"
        )
        for c in el.children():
            walk(c, d + 1)

    for c in _win().children():
        walk(c, 0)
    return "\n".join(lines[:400])


@m.tool()
def find(query: str) -> str:
    """Find elements whose name, automation id, or control type contains query.

    Results are indexed; use the index with click() and type_text().
    """
    q = query.lower()
    hits = []
    for i, e in enumerate(_win().descendants()):
        ct, name, aid = _info(e)
        if q in name.lower() or q in aid.lower() or q in ct.lower():
            hits.append((i, e))
    state["elements"] = [e for _, e in hits]
    out = [f"{len(hits)} matches"]
    for idx, e in hits[:40]:
        out.append(f"[{idx}] {_desc(e)}")
    return "\n".join(out)


@m.tool()
def click(index: int) -> str:
    """Click the element at the given index from the last find()."""
    els = state["elements"]
    if index < 0 or index >= len(els):
        return f"index {index} out of range ({len(els)} elements)"
    e = els[index]
    e.click_input()
    return f"clicked [{index}] '{_info(e)[1]}'"


@m.tool()
def type_text(index: int, text: str, clear: bool = True) -> str:
    """Focus the element at index and enter text (set_text when supported)."""
    els = state["elements"]
    if index < 0 or index >= len(els):
        return f"index {index} out of range ({len(els)} elements)"
    e = els[index]
    e.click_input()
    if clear:
        try:
            e.set_text(text)
            return f"set text on [{index}] '{_info(e)[1]}'"
        except Exception:
            pass
    e.type_keys(text, with_spaces=True)
    return f"typed into [{index}] '{_info(e)[1]}'"


@m.tool()
def press_key(keys: str) -> str:
    """Send keystrokes to the focused window (pywinauto send_keys syntax)."""
    _win().set_focus()
    kb.send_keys(keys)
    return f"sent '{keys}'"


@m.tool()
def screenshot(path: str) -> str:
    """Capture the attached window to a PNG file and report its size."""
    img = _win().capture_as_image()
    img.save(path)
    return f"saved {path} ({img.width}x{img.height})"


@m.tool()
def click_xy(x: int, y: int) -> str:
    """Click at window-relative coordinates taken from a screenshot."""
    import pywinauto.mouse as mouse

    r = _win().rectangle()
    mouse.click("left", (r.left + x, r.top + y))
    return f"clicked window ({x},{y}) -> screen ({r.left + x},{r.top + y})"


@m.tool()
def type_xy(x: int, y: int, text: str, clear: bool = True) -> str:
    """Click window-relative coordinates then type text."""
    import pywinauto.mouse as mouse

    r = _win().rectangle()
    mouse.click("left", (r.left + x, r.top + y))
    if clear:
        kb.send_keys("^a")
    kb.send_keys(text, with_spaces=True)
    return f"typed '{text}' at window ({x},{y})"


@m.tool()
def close() -> str:
    """Close the attached window."""
    _win().close()
    state["win"] = None
    state["elements"] = []
    return "closed"


if __name__ == "__main__":
    m.run()
