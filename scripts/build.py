"""Generate schedule pages, week pages, the deadlines page and calendar.ics from data/*.yml.

Quarto runs this automatically before every render (see `pre-render` in _quarto.yml).
Generated files are listed in .gitignore; edit the data files or the handwritten
`_concepts-week-N.qmd` files instead.
"""

import datetime as dt
import html
import pathlib
from zoneinfo import ZoneInfo

import yaml

ROOT = pathlib.Path(__file__).resolve().parent.parent
MODULES = ["ski3010", "ski3011", "pro3017"]
TZ = ZoneInfo("Europe/Amsterdam")
SITE = "https://ucm.meta-research.nl"


def esc(text):
    return html.escape(str(text))


def parse_due(text):
    return dt.datetime.strptime(text, "%Y-%m-%d %H:%M").replace(tzinfo=TZ)


def week_range(day):
    """Monday to Sunday of the week that contains `day`."""
    monday = day - dt.timedelta(days=day.weekday())
    return monday, monday + dt.timedelta(days=6)


def fmt_day(day):
    return day.strftime("%a %-d %b")


def fmt_due(due):
    return due.strftime("%a %-d %b, %H:%M")


def load(module):
    data = yaml.safe_load((ROOT / "data" / f"{module}.yml").read_text())
    for w in data["weeks"]:
        w["start"], w["end"] = week_range(w["date"])
        for a in w.get("assignments", []):
            a["due_dt"] = parse_due(a["due"])
    return data


def week_label(w):
    if w.get("exam_week"):
        return f"{w['start'].strftime('%-d')}-{(w['start'] + dt.timedelta(days=4)).strftime('%-d %b')}"
    return fmt_day(w["date"])


def items(lst):
    return "<br>".join(esc(x) for x in lst) if lst else ""


def schedule_html(module, data):
    rows = []
    for w in data["weeks"]:
        attrs = f'data-start="{w["start"]}" data-end="{w["end"]}"'
        if "break" in w:
            rows.append(f'<tr class="break" {attrs}><td></td><td>{week_label(w)}</td>'
                        f'<td colspan="4"><em>{esc(w["break"])}</em></td></tr>')
            continue
        tutorial = list(w.get("tutorial", []))
        tut = items(tutorial)
        if w.get("quiz"):
            q = w["quiz"]
            tut = f'<strong class="quiz">Quiz {q["n"]}</strong>: {esc(q["topic"])}' + ("<br>" + tut if tut else "")
        assign = "<br>".join(
            f'<strong>{esc(a["id"])}</strong>: {esc(a["title"])} <span class="due">(DL {fmt_due(a["due_dt"])})</span>'
            for a in w.get("assignments", []))
        lecture = items(w.get("lecture", [])) or ("<em>Exam week</em>" if w.get("exam_week") else "")
        rows.append(
            f'<tr {attrs}><td><a href="week-{w["week"]}.qmd">{w["week"]}</a></td><td>{week_label(w)}</td>'
            f'<td>{lecture}</td><td>{tut}</td><td>{assign}</td><td>{items(w.get("homework", []))}</td></tr>')
    head = ("<tr><th>Week</th><th>Date</th><th>Lecture</th><th>Tutorial</th>"
            "<th>Assignments</th><th>Homework</th></tr>")
    return ('```{=html}\n<div class="table-responsive"><table class="table schedule">'
            f"<thead>{head}</thead><tbody>{''.join(rows)}</tbody></table></div>\n```\n")


def assessment_md(data):
    lines = ["| Component | Weight | Notes |", "|---|---|---|"]
    lines += [f"| {c} | {w} | {n} |" for c, w, n in data["assessment"]]
    return "\n".join(lines) + "\n"


NOTE = ("::: {.callout-note}\nDates follow the UM academic calendar 2026-2027. "
        "Times and rooms are in the UM timetable.\n:::\n\n")


def write_schedule(module, data):
    text = (f'---\ntitle: "Schedule"\nsubtitle: "{data["code"]} {data["title"]}"\ntoc: false\n---\n\n'
            + NOTE
            + "The current week is highlighted. Click a week number for the week page.\n\n"
            + "::: {.column-page}\n" + schedule_html(module, data) + ":::\n\n"
            + "## Assessment\n\n" + assessment_md(data))
    (ROOT / module / "schedule.qmd").write_text(text)


def materials_md(module, n):
    folder = ROOT / "materials" / module / f"week-{n}"
    files = sorted(p for p in folder.glob("*") if p.is_file() and not p.name.startswith(".")) if folder.exists() else []
    files = [p for p in files if not (p.suffix == ".R" and p.name.startswith("r-lecture-")) and p.name != "bcg.csv"]  # linked via data file
    if not files:
        return "" if (folder.exists()) else "Lecture slides and other materials appear here before the lecture.\n"
    return "".join(f"* [{p.name}](../materials/{module}/week-{n}/{p.name.replace(' ', '%20')})\n" for p in files)


def write_week(module, data, w):
    n = w["week"]
    lines = [f'---\ntitle: "Week {n}: {w["theme"]}"\nsubtitle: "{data["code"]} · {week_label(w)}"\n---\n']
    if w.get("quiz"):
        q = w["quiz"]
        lines.append(f'::: {{.callout-important}}\n## Quiz {q["n"]} in this tutorial\n{q["topic"]}. '
                     "Paper quiz, no devices. Prepare with the concept list and practice questions of last week.\n:::\n")
    if w.get("lecture"):
        lines.append("## Lecture\n" + "".join(f"* {x}\n" for x in w["lecture"]))
        links = "".join(f'* [{l["text"]}]({l["href"]})\n' for l in w.get("links", []))
        lines.append("### Slides and materials\n" + links + materials_md(module, n))
    if w.get("tutorial"):
        lines.append("## Tutorial\n" + "".join(f"* {x}\n" for x in w["tutorial"]))
    if w.get("assignments"):
        lines.append("## Hand in\n" + "".join(
            f'* **{a["id"]}**: {a["title"]}. Deadline **{fmt_due(a["due_dt"])}** ({a["grading"]}). '
            "[How to submit](../submit.qmd)\n" for a in w["assignments"]))
    if w.get("homework"):
        lines.append("## Homework\n" + "".join(f"* {x}\n" for x in w["homework"]))
    concepts = ROOT / module / f"_concepts-week-{n}.qmd"
    if concepts.exists():
        lines.append(f"{{{{< include _concepts-week-{n}.qmd >}}}}\n")
    elif not w.get("exam_week"):
        lines.append("## Concepts and practice\nThe concept list and practice questions for this week will appear here.\n")
    (ROOT / module / f"week-{n}.qmd").write_text("\n".join(lines))


def write_overview(module, data):
    cards = []
    for w in data["weeks"]:
        attrs = f'data-start="{w["start"]}" data-end="{w["end"]}"'
        if "break" in w:
            cards.append(f'<div class="week-card break" {attrs}><span class="when">{week_label(w)}</span>'
                         f'<span class="what">{esc(w["break"])}</span></div>')
            continue
        # group assignments that share a deadline: "A1a, A1b due Tue 10 Feb, 11:59"
        by_due = {}
        for a in w.get("assignments", []):
            by_due.setdefault(fmt_due(a["due_dt"]), []).append(a["id"])
        due = "; ".join(f'{", ".join(ids)} due {d}' for d, ids in by_due.items())
        quiz = f'Quiz {w["quiz"]["n"]} · ' if w.get("quiz") else ""
        cards.append(
            f'<a class="week-card" href="week-{w["week"]}.html" {attrs}>'
            f'<span class="when">Week {w["week"]} · {week_label(w)}</span>'
            f'<span class="what">{esc(w["theme"])}</span>'
            f'<span class="due">{esc(quiz + due)}</span></a>')
    (ROOT / module / "_weeks.qmd").write_text(
        '```{=html}\n<div class="week-cards">' + "".join(cards) + "</div>\n```\n")


def write_deadlines(all_data):
    rows = []
    for data in all_data:
        for w in data["weeks"]:
            if w.get("quiz"):
                q = w["quiz"]
                rows.append((dt.datetime.combine(w["date"], dt.time(9, 0), TZ), data["code"],
                             f'Quiz {q["n"]}', q["topic"], "in the tutorial", "quiz"))
            for a in w.get("assignments", []):
                rows.append((a["due_dt"], data["code"], a["id"], a["title"], a["grading"], "assignment"))
    rows.sort()
    trs = "".join(
        f'<tr class="{kind}" data-due="{due.isoformat()}"><td>{fmt_due(due) if kind == "assignment" else fmt_day(due)}</td>'
        f"<td>{code}</td><td><strong>{esc(i)}</strong></td><td>{esc(t)}</td><td>{esc(g)}</td></tr>"
        for due, code, i, t, g, kind in rows)
    text = ('---\ntitle: "Deadlines"\nsubtitle: "All quizzes and deadlines of the semester"\ntoc: false\n---\n\n'
            + NOTE
            + f"**Add them to your own calendar:** subscribe to [calendar.ics]({SITE}/calendar.ics) "
            "(in Google Calendar: *Other calendars* → *From URL*; on Apple devices: *File* → *New Calendar Subscription*). "
            "Changes appear in your calendar automatically. Past items are greyed out.\n\n"
            '```{=html}\n<div class="table-responsive"><table class="table deadlines"><thead><tr><th>When</th>'
            "<th>Module</th><th>What</th><th>Description</th><th>Weight</th></tr></thead><tbody>"
            + trs + "</tbody></table></div>\n```\n")
    (ROOT / "deadlines.qmd").write_text(text)
    return rows


def ics_escape(text):
    return str(text).replace("\\", "\\\\").replace(";", "\\;").replace(",", "\\,")


def write_ics(rows):
    utc = dt.timezone.utc
    stamp = dt.datetime.now(utc).strftime("%Y%m%dT%H%M%SZ")
    out = ["BEGIN:VCALENDAR", "VERSION:2.0", "PRODID:-//ucm.meta-research.nl//Evidence Synthesis//EN",
           "CALSCALE:GREGORIAN", "X-WR-CALNAME:Evidence Synthesis UCM", "X-WR-TIMEZONE:Europe/Amsterdam"]
    for due, code, i, t, g, kind in rows:
        uid = f"{code}-{i}".replace(" ", "").lower() + "@ucm.meta-research.nl"
        out += ["BEGIN:VEVENT", f"UID:{uid}", f"DTSTAMP:{stamp}"]
        if kind == "quiz":
            day = due.date()
            out += [f"DTSTART;VALUE=DATE:{day:%Y%m%d}",
                    f"DTEND;VALUE=DATE:{day + dt.timedelta(days=1):%Y%m%d}",
                    f"SUMMARY:{ics_escape(f'{code} {i} (in tutorial)')}"]
        else:
            end = due.astimezone(utc)
            start = end - dt.timedelta(minutes=30)
            out += [f"DTSTART:{start:%Y%m%dT%H%M%SZ}", f"DTEND:{end:%Y%m%dT%H%M%SZ}",
                    f"SUMMARY:{ics_escape(f'{code} {i} deadline')}"]
        out += [f"DESCRIPTION:{ics_escape(t)} ({ics_escape(g)}). {SITE}/deadlines.html", "END:VEVENT"]
    out.append("END:VCALENDAR")
    (ROOT / "calendar.ics").write_text("\r\n".join(out) + "\r\n")


def main():
    all_data = []
    for module in MODULES:
        data = load(module)
        all_data.append(data)
        write_schedule(module, data)
        write_overview(module, data)
        (ROOT / module / "_assessment.qmd").write_text(assessment_md(data))
        for w in data["weeks"]:
            if "week" in w:
                write_week(module, data, w)
    write_ics(write_deadlines(all_data))


if __name__ == "__main__":
    main()
