#!/usr/bin/env python3
"""Compile tailored Academic CVs and send individual Gmail outreach emails.

Designed for /home/cesium/notes/10-professors:
  - Parses each professor folder's email.md (strictly To-only, no CC/BCC)
  - Compiles each folder's academic_cv.tex -> Animesh_Raj_Academic_CV.pdf
  - Supports preview, dry-run (default), self-test (--test-to), rate limiting,
    and atomic sent_log.json tracking to prevent duplicate sends.
"""

from __future__ import annotations

import argparse
from dataclasses import dataclass
from datetime import datetime, timedelta, timezone
from email.message import EmailMessage
from email.utils import formataddr
import getpass
import hashlib
import json
import os
from pathlib import Path
import random
import re
import shutil
import smtplib
import ssl
import subprocess
import sys
import tempfile
import time
from typing import Iterable

DEFAULT_ROOT = Path(__file__).resolve().parent
ATTACHMENT_NAME = "Animesh_Raj_Academic_CV.pdf"
FALLBACK_PDF_NAME = "academic_cv.pdf"
SENT_LOG_NAME = "sent_log.json"
PROGRESS_NAME = "PROGRESS.md"
KEYRING_SERVICE = "gmail-cli"
EMAIL_RE = re.compile(r"^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$")
FOLDER_RE = re.compile(r"^(\d+)-(.+)$")


@dataclass(frozen=True)
class ProfessorEmail:
    """Parsed email metadata, body, notes, and CV paths for one professor."""

    index: int
    folder: Path
    title: str
    to_email: str
    subject: str
    body: str
    sender_name: str
    sender_email: str
    notes: tuple[str, ...]
    tex_path: Path
    pdf_path: Path | None


def find_existing_pdf(folder: Path) -> Path | None:
    """Return the compiled CV PDF path if present in the professor folder."""
    for name in (ATTACHMENT_NAME, FALLBACK_PDF_NAME):
        candidate = folder / name
        if candidate.is_file() and candidate.stat().st_size > 0:
            return candidate
    return None


def parse_email_md(folder: Path) -> ProfessorEmail:
    """Parse and validate <folder>/email.md into a ProfessorEmail record."""
    match = FOLDER_RE.match(folder.name)
    if not match:
        raise ValueError(f"Unexpected folder name format: {folder.name}")
    index = int(match.group(1))

    email_md = folder / "email.md"
    if not email_md.is_file():
        raise FileNotFoundError(f"Missing {email_md}")

    lines = email_md.read_text(encoding="utf-8").splitlines()
    sep_indices = [i for i, line in enumerate(lines) if line.strip() == "---"]
    if len(sep_indices) != 1:
        raise ValueError(f"{email_md}: expected exactly one '---' separator")
    sep_idx = sep_indices[0]

    header_lines = [line.strip() for line in lines[:sep_idx] if line.strip()]
    if len(header_lines) < 3:
        raise ValueError(f"{email_md}: incomplete header before '---'")

    title = header_lines[0].lstrip("# ").strip()
    to_email = header_lines[-2]
    subject = header_lines[-1]

    if not EMAIL_RE.fullmatch(to_email):
        raise ValueError(f"{email_md}: invalid recipient email {to_email!r}")
    if not subject or subject.startswith(("#", "**")):
        raise ValueError(f"{email_md}: invalid subject {subject!r}")

    notes = tuple(
        line
        for line in header_lines[1:-2]
        if line.startswith(("**Note:**", "**Important:**"))
    )

    body_lines = [line.rstrip() for line in lines[sep_idx + 1 :]]
    body = "\n".join(body_lines).strip() + "\n"
    if not body.strip():
        raise ValueError(f"{email_md}: empty body")

    sender_email = ""
    sender_name = ""
    raw_body_lines = body.splitlines()
    for i, line in enumerate(raw_body_lines):
        if line.startswith("Email:"):
            sender_email = line.split(":", 1)[1].strip()
        if line.strip().rstrip(",") == "Sincerely" and i + 1 < len(raw_body_lines):
            sender_name = raw_body_lines[i + 1].strip()

    if not EMAIL_RE.fullmatch(sender_email):
        raise ValueError(f"{email_md}: could not detect sender email in body")

    return ProfessorEmail(
        index=index,
        folder=folder,
        title=title,
        to_email=to_email,
        subject=subject,
        body=body,
        sender_name=sender_name or "Animesh Raj",
        sender_email=sender_email,
        notes=notes,
        tex_path=folder / "academic_cv.tex",
        pdf_path=find_existing_pdf(folder),
    )


def folder_sort_key(path: Path) -> tuple[int, str]:
    """Sort professor folders numerically so 100-* follows 99-* cleanly."""
    match = FOLDER_RE.match(path.name)
    assert match is not None
    return (int(match.group(1)), path.name)


def discover_professors(root: Path) -> list[ProfessorEmail]:
    """Load all professor directories sorted by leading numeric prefix."""
    folders = sorted(
        (p for p in root.iterdir() if p.is_dir() and FOLDER_RE.match(p.name)),
        key=folder_sort_key,
    )
    return [parse_email_md(folder) for folder in folders]


def filter_professors(
    records: list[ProfessorEmail],
    only: str | None,
    range_spec: str | None,
) -> list[ProfessorEmail]:
    """Filter professor records by --only (names/indices) and/or --range (a-b)."""
    selected = records

    if only:
        tokens = {tok.strip() for tok in only.split(",") if tok.strip()}
        numeric_tokens = {int(tok) for tok in tokens if tok.isdigit()}
        matched = [
            rec
            for rec in selected
            if rec.folder.name in tokens or rec.index in numeric_tokens
        ]
        if not matched:
            raise ValueError(f"--only {only!r} matched no professor folders")
        selected = matched

    if range_spec:
        m = re.fullmatch(r"(\d+)-(\d+)", range_spec.strip())
        if not m:
            raise ValueError(f"Invalid --range {range_spec!r}; expected e.g. 1-10")
        start, end = int(m.group(1)), int(m.group(2))
        if start > end:
            raise ValueError(f"Invalid --range {range_spec!r}: start > end")
        selected = [rec for rec in selected if start <= rec.index <= end]
        if not selected:
            raise ValueError(f"--range {range_spec!r} matched no professor folders")

    return selected


def find_duplicates(records: list[ProfessorEmail]) -> list[str]:
    """Return warning messages for duplicate folder indices or recipient emails."""
    warnings: list[str] = []
    by_index: dict[int, list[str]] = {}
    by_email: dict[str, list[str]] = {}
    for rec in records:
        by_index.setdefault(rec.index, []).append(rec.folder.name)
        by_email.setdefault(rec.to_email.lower(), []).append(rec.folder.name)

    for idx, names in sorted(by_index.items()):
        if len(names) > 1:
            warnings.append(f"Duplicate index {idx}: {', '.join(names)}")
    for email, names in sorted(by_email.items()):
        if len(names) > 1:
            warnings.append(f"Duplicate recipient {email}: {', '.join(names)}")
    return warnings


def format_ranges(indices: list[int]) -> str:
    """Compress sorted ints into readable ranges like '1-12, 15, 18-20'."""
    if not indices:
        return "none"
    nums = sorted(set(indices))
    ranges: list[str] = []
    start = prev = nums[0]
    for num in nums[1:]:
        if num == prev + 1:
            prev = num
            continue
        ranges.append(str(start) if start == prev else f"{start}-{prev}")
        start = prev = num
    ranges.append(str(start) if start == prev else f"{start}-{prev}")
    return ", ".join(ranges)


def count_sent_last_24h(sent_log: dict[str, dict]) -> int:
    """Count non-manual emails recorded in sent_log within the past 24 hours."""
    cutoff = datetime.now(timezone.utc) - timedelta(hours=24)
    count = 0
    for entry in sent_log.values():
        if entry.get("transport") == "manual":
            continue
        raw_ts = entry.get("sent_at")
        if not raw_ts:
            continue
        try:
            ts = datetime.fromisoformat(raw_ts)
        except ValueError:
            continue
        if ts >= cutoff:
            count += 1
    return count


def load_sent_log(root: Path) -> dict[str, dict]:
    """Load the JSON log of already-sent professor outreach emails."""
    path = root / SENT_LOG_NAME
    if not path.is_file():
        return {}
    return json.loads(path.read_text(encoding="utf-8"))


def write_progress_file(
    root: Path,
    records: list[ProfessorEmail],
    sent_log: dict[str, dict],
) -> Path:
    """Atomically write PROGRESS.md with step-by-step done/pending status."""
    done_indices = [rec.index for rec in records if rec.folder.name in sent_log]
    pending_indices = [rec.index for rec in records if rec.folder.name not in sent_log]
    pdf_ready = sum(1 for rec in records if rec.pdf_path is not None)
    sent_24h = count_sent_last_24h(sent_log)
    dup_warnings = find_duplicates(records)
    now_str = datetime.now().astimezone().strftime("%Y-%m-%d %H:%M %Z")

    lines = [
        "# Professor Outreach Progress",
        "",
        f"> Auto-updated by `mail_cli.py` at `{now_str}` (source of truth: `{SENT_LOG_NAME}`).",
        "",
        f"- **Done:** {len(done_indices)} / {len(records)} (`{format_ranges(done_indices)}`)",
        f"- **Pending:** {len(pending_indices)} / {len(records)} (`{format_ranges(pending_indices)}`)",
        f"- **Compiled PDFs ready:** {pdf_ready} / {len(records)}",
        f"- **Sent via CLI in last 24h:** {sent_24h}",
    ]

    next_pending = [rec.folder.name for rec in records if rec.folder.name not in sent_log][:5]
    if next_pending:
        lines.append(f"- **Next pending:** {', '.join(f'`{name}`' for name in next_pending)}")

    if dup_warnings:
        lines.append("")
        lines.append("## Warnings")
        for warn in dup_warnings:
            lines.append(f"- **WARNING:** {warn}")

    lines.extend([
        "",
        "## Quick Commands",
        "```bash",
        "python3 mail_cli.py status                 # Refresh this file & check counts",
        "python3 mail_cli.py compile                # Compile any new/edited CVs",
        "python3 mail_cli.py send --limit 10        # Dry-run next 10 pending",
        "python3 mail_cli.py send --limit 10 --confirm",
        "python3 mail_cli.py mark-sent --range 1-12 # Mark externally sent folders",
        "```",
        "",
        "## Step-by-Step Checklist",
        "",
    ])

    for rec in records:
        entry = sent_log.get(rec.folder.name)
        checked = "x" if entry else " "
        pdf_state = "PDF: OK" if rec.pdf_path else "PDF: MISSING"
        if entry:
            ts = entry.get("sent_at", "")[:16].replace("T", " ")
            transport = entry.get("transport", "unknown")
            status_text = f"Sent `{ts} UTC` ({transport})"
        else:
            status_text = "Pending"
        lines.append(
            f"- [{checked}] `{rec.folder.name}` — `{rec.to_email}` | {pdf_state} | {status_text}"
        )
        for note in rec.notes:
            lines.append(f"  - {note}")

    path = root / PROGRESS_NAME
    tmp = path.with_suffix(".md.tmp")
    tmp.write_text("\n".join(lines) + "\n", encoding="utf-8")
    os.replace(tmp, path)
    return path


def save_sent_log(
    root: Path,
    log: dict[str, dict],
    records: list[ProfessorEmail] | None = None,
) -> None:
    """Atomically write sent_log.json and keep PROGRESS.md in sync."""
    path = root / SENT_LOG_NAME
    tmp = path.with_suffix(".json.tmp")
    tmp.write_text(json.dumps(log, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    os.replace(tmp, path)
    if records is not None:
        write_progress_file(root, records, log)


def sha256_file(path: Path) -> str:
    """Return SHA-256 hex digest of a file."""
    h = hashlib.sha256()
    with path.open("rb") as fh:
        for chunk in iter(lambda: fh.read(65536), b""):
            h.update(chunk)
    return h.hexdigest()


def detect_latex_engine() -> str | None:
    """Return the preferred installed LaTeX compiler, or None if missing."""
    for engine in ("pdflatex", "xelatex", "lualatex", "tectonic"):
        if shutil.which(engine):
            return engine
    return None


def compile_tex(tex_path: Path, output_pdf: Path, engine: str) -> None:
    """Compile tex_path in a temporary directory and move the PDF to output_pdf."""
    with tempfile.TemporaryDirectory(prefix="cv_build_") as tmp:
        tmpdir = Path(tmp)
        if engine == "tectonic":
            cmd = [engine, "-X", "compile", str(tex_path), "--outdir", str(tmpdir)]
            passes = 1
        else:
            cmd = [
                engine,
                "-interaction=nonstopmode",
                "-halt-on-error",
                f"-output-directory={tmpdir}",
                str(tex_path),
            ]
            passes = 2  # Second pass ensures hyperref/page layout stabilize.

        for _ in range(passes):
            proc = subprocess.run(
                cmd,
                cwd=tex_path.parent,
                stdout=subprocess.PIPE,
                stderr=subprocess.STDOUT,
                text=True,
            )
            if proc.returncode != 0:
                tail = "\n".join(proc.stdout.splitlines()[-25:])
                raise RuntimeError(
                    f"LaTeX compile failed for {tex_path} ({engine}):\n{tail}"
                )

        built_pdf = tmpdir / f"{tex_path.stem}.pdf"
        if not built_pdf.is_file() or built_pdf.stat().st_size == 0:
            raise RuntimeError(f"Expected PDF missing after compile: {built_pdf}")
        shutil.copy2(built_pdf, output_pdf)


def build_message(
    rec: ProfessorEmail,
    from_name: str,
    from_email: str,
    test_to: str | None = None,
) -> EmailMessage:
    """Build a To-only EmailMessage with the compiled CV PDF attached."""
    if not rec.pdf_path or not rec.pdf_path.is_file():
        raise FileNotFoundError(
            f"Missing compiled CV PDF for {rec.folder.name}. Run `compile` first."
        )

    msg = EmailMessage()
    msg["From"] = formataddr((from_name, from_email))
    msg["To"] = test_to or rec.to_email
    # Intentionally never set Cc or Bcc (per email.md instructions).
    msg["Subject"] = (
        f"[TEST for {rec.folder.name}] {rec.subject}" if test_to else rec.subject
    )
    msg.set_content(rec.body, subtype="plain", charset="utf-8")

    pdf_bytes = rec.pdf_path.read_bytes()
    msg.add_attachment(
        pdf_bytes,
        maintype="application",
        subtype="pdf",
        filename=ATTACHMENT_NAME,
    )
    return msg


def lookup_keyring_password(user_email: str) -> str | None:
    """Read Gmail App Password from Secret Service keyring if available."""
    if not shutil.which("secret-tool"):
        return None
    proc = subprocess.run(
        ["secret-tool", "lookup", "service", KEYRING_SERVICE, "user", user_email],
        stdout=subprocess.PIPE,
        stderr=subprocess.DEVNULL,
        text=True,
    )
    if proc.returncode == 0 and proc.stdout.strip():
        return proc.stdout.replace(" ", "").strip()
    return None


def normalize_app_password(raw: str) -> str:
    """Strip spaces/newlines that Google displays in 4-char groups."""
    cleaned = "".join(raw.split())
    if cleaned and (len(cleaned) != 16 or not cleaned.isascii()):
        print(
            f"Warning: resolved password is {len(cleaned)} char(s); "
            "Google App Passwords are 16 ASCII characters (not your normal Gmail password).",
            file=sys.stderr,
        )
    return cleaned


def resolve_app_password(user_email: str) -> str:
    """Resolve Gmail App Password from env, keyring, or hidden prompt."""
    env_pw = os.environ.get("GMAIL_APP_PASSWORD", "")
    if env_pw.strip():
        return normalize_app_password(env_pw)

    keyring_pw = lookup_keyring_password(user_email)
    if keyring_pw:
        return normalize_app_password(keyring_pw)

    if sys.stdin.isatty():
        pw = getpass.getpass(f"Gmail App Password for {user_email}: ")
        if pw.strip():
            return normalize_app_password(pw)

    raise RuntimeError(
        "No Gmail App Password found. Set GMAIL_APP_PASSWORD, run `setup-keyring`, "
        "or run interactively."
    )


def smtp_auth_plain(smtp: smtplib.SMTP, user_email: str, app_password: str) -> None:
    """Authenticate with AUTH PLAIN directly so 535 errors are not masked.

    smtplib.SMTP.login() retries AUTH LOGIN after AUTH PLAIN fails; Gmail closes
    the socket on 535 BadCredentials, turning the real auth error into a generic
    'Connection unexpectedly closed' exception.
    """
    smtp.ehlo_or_helo_if_needed()
    smtp.user, smtp.password = user_email, app_password
    try:
        smtp.auth("PLAIN", smtp.auth_plain, initial_response_ok=True)
    except smtplib.SMTPAuthenticationError as exc:
        detail = (
            exc.smtp_error.decode("utf-8", errors="replace")
            if isinstance(exc.smtp_error, bytes)
            else str(exc.smtp_error)
        )
        raise RuntimeError(
            f"Gmail rejected authentication ({exc.smtp_code}): {detail}\n"
            f"Make sure you are using a 16-character Google App Password for {user_email} "
            "(generated at myaccount.google.com/apppasswords with 2-Step Verification on), "
            "not your normal Gmail password."
        ) from exc


def send_via_smtp(
    msg: EmailMessage,
    user_email: str,
    app_password: str,
    port: int = 465,
    debug: bool = False,
) -> None:
    """Send an EmailMessage via Gmail SMTP (465 SSL or 587 STARTTLS)."""
    context = ssl.create_default_context()
    if port == 465:
        with smtplib.SMTP_SSL("smtp.gmail.com", 465, context=context, timeout=30) as smtp:
            if debug:
                smtp.set_debuglevel(1)
            smtp_auth_plain(smtp, user_email, app_password)
            smtp.send_message(msg)
    else:
        with smtplib.SMTP("smtp.gmail.com", port, timeout=30) as smtp:
            if debug:
                smtp.set_debuglevel(1)
            smtp.ehlo()
            smtp.starttls(context=context)
            smtp.ehlo()
            smtp_auth_plain(smtp, user_email, app_password)
            smtp.send_message(msg)


def send_via_msmtp(msg: EmailMessage) -> None:
    """Send an EmailMessage through local msmtp using header recipients (-t)."""
    if not shutil.which("msmtp"):
        raise RuntimeError("`msmtp` is not installed. Run: sudo pacman -S msmtp")
    subprocess.run(["msmtp", "-t"], input=msg.as_bytes(), check=True)


def cmd_status(args: argparse.Namespace) -> int:
    root = Path(args.root).resolve()
    all_records = discover_professors(root)
    records = filter_professors(all_records, args.only, args.range)
    sent_log = load_sent_log(root)
    progress_path = write_progress_file(root, all_records, sent_log)

    pdfs_ready = 0
    sent_count = 0
    for rec in records:
        pdf_ok = rec.pdf_path is not None
        sent_ok = rec.folder.name in sent_log
        pdfs_ready += int(pdf_ok)
        sent_count += int(sent_ok)

        pdf_badge = "PDF:OK " if pdf_ok else "PDF:NO "
        sent_badge = "SENT   " if sent_ok else "PENDING"
        note_badge = f" [{len(rec.notes)} note]" if rec.notes else ""
        print(
            f"{rec.folder.name:<24} | {pdf_badge} | {sent_badge} | "
            f"{rec.to_email:<28}{note_badge}"
        )

    done_ids = [rec.index for rec in all_records if rec.folder.name in sent_log]
    pending_ids = [rec.index for rec in all_records if rec.folder.name not in sent_log]
    print("-" * 78)
    print(
        f"Total: {len(records)} | PDFs ready: {pdfs_ready}/{len(records)} | "
        f"Sent: {sent_count}/{len(records)} | Last 24h (CLI): {count_sent_last_24h(sent_log)}"
    )
    print(f"Done ranges:    {format_ranges(done_ids)}")
    print(f"Pending ranges: {format_ranges(pending_ids)}")
    for warn in find_duplicates(all_records):
        print(f"WARNING: {warn}", file=sys.stderr)
    engine = detect_latex_engine()
    print(f"LaTeX compiler: {engine or 'NONE INSTALLED'}")
    print(f"Tracker file:   {progress_path}")
    return 0


def cmd_compile(args: argparse.Namespace) -> int:
    root = Path(args.root).resolve()
    engine = args.engine or detect_latex_engine()
    if not engine:
        print(
            "Error: No LaTeX compiler found (checked pdflatex, xelatex, lualatex, tectonic).\n"
            "On Arch Linux, install TeX Live packages needed by academic_cv.tex:\n"
            "  sudo pacman -S texlive-basic texlive-latex texlive-latexrecommended "
            "texlive-latexextra texlive-fontsrecommended texlive-fontsextra",
            file=sys.stderr,
        )
        return 1

    all_records = discover_professors(root)
    records = filter_professors(all_records, args.only, args.range)
    compiled = 0
    skipped = 0

    for rec in records:
        if not rec.tex_path.is_file():
            print(f"[SKIP] {rec.folder.name}: missing {rec.tex_path.name}")
            skipped += 1
            continue

        target_pdf = rec.folder / ATTACHMENT_NAME
        if (
            not args.force
            and target_pdf.is_file()
            and target_pdf.stat().st_size > 0
            and target_pdf.stat().st_mtime >= rec.tex_path.stat().st_mtime
        ):
            print(f"[UP-TO-DATE] {rec.folder.name}/{ATTACHMENT_NAME}")
            skipped += 1
            continue

        print(f"[COMPILE] {rec.folder.name}/academic_cv.tex -> {ATTACHMENT_NAME} ({engine})")
        compile_tex(rec.tex_path, target_pdf, engine)
        compiled += 1

    write_progress_file(root, discover_professors(root), load_sent_log(root))
    print(f"Done: {compiled} compiled, {skipped} skipped.")
    return 0


def print_notes(rec: ProfessorEmail) -> None:
    """Print any **Note:** or **Important:** lines flagged in email.md."""
    for note in rec.notes:
        print(f"  ! {note}")


def cmd_preview(args: argparse.Namespace) -> int:
    root = Path(args.root).resolve()
    records = filter_professors(discover_professors(root), args.only, args.range)
    sent_log = load_sent_log(root)

    for rec in records:
        pdf_desc = (
            f"{rec.pdf_path.name} ({rec.pdf_path.stat().st_size:,} bytes)"
            if rec.pdf_path
            else "MISSING (compile academic_cv.tex first)"
        )
        sent_desc = "YES (" + sent_log[rec.folder.name]["sent_at"] + ")" if rec.folder.name in sent_log else "NO"
        print("=" * 78)
        print(f"Folder:     {rec.folder.name}")
        print(f"AlreadySent:{sent_desc}")
        print(f"From:       {rec.sender_name} <{rec.sender_email}>")
        print(f"To:         {rec.to_email}")
        print("CC / BCC:   None")
        print(f"Subject:    {rec.subject}")
        print(f"Attachment: {pdf_desc} (sent as {ATTACHMENT_NAME})")
        if rec.notes:
            print("Notes:")
            print_notes(rec)
        print("-" * 78)
        print(rec.body, end="")

    return 0


def cmd_setup_keyring(args: argparse.Namespace) -> int:
    if not shutil.which("secret-tool"):
        print("Error: secret-tool not found.", file=sys.stderr)
        return 1
    user_email = args.email
    print(
        f"Storing Gmail App Password in keyring (service={KEYRING_SERVICE}, user={user_email}).\n"
        "Tip: paste the 16-character App Password from myaccount.google.com/apppasswords."
    )
    proc = subprocess.run(
        [
            "secret-tool",
            "store",
            f"--label=Gmail CLI ({user_email})",
            "service",
            KEYRING_SERVICE,
            "user",
            user_email,
        ]
    )
    return proc.returncode


def filter_pending_for_send(
    records: list[ProfessorEmail],
    sent_log: dict[str, dict],
    resend: bool,
    test_to: str | None,
    limit: int | None,
) -> list[ProfessorEmail]:
    """Select eligible records respecting sent_log.json unless --resend/--test-to."""
    queue: list[ProfessorEmail] = []
    for rec in records:
        if rec.folder.name in sent_log and not resend and not test_to:
            continue
        queue.append(rec)
    if limit is not None:
        if limit < 1:
            raise ValueError("--limit must be >= 1")
        queue = queue[:limit]
    return queue


def make_sent_entry(
    rec: ProfessorEmail,
    from_email: str,
    transport: str,
) -> dict[str, str | None]:
    """Build a sent_log.json record for one professor folder."""
    return {
        "to": rec.to_email,
        "subject": rec.subject,
        "from": from_email,
        "attachment": rec.pdf_path.name if rec.pdf_path else None,
        "pdf_sha256": sha256_file(rec.pdf_path) if rec.pdf_path else None,
        "transport": transport,
        "sent_at": datetime.now(timezone.utc).isoformat(),
    }


def cmd_mark_sent(args: argparse.Namespace) -> int:
    if not args.only and not args.range:
        raise ValueError("Specify --only or --range to mark folders as sent.")
    root = Path(args.root).resolve()
    all_records = discover_professors(root)
    records = filter_professors(all_records, args.only, args.range)
    sent_log = load_sent_log(root)

    added = 0
    for rec in records:
        if rec.folder.name in sent_log:
            print(f"[ALREADY SENT] {rec.folder.name}")
            continue
        sent_log[rec.folder.name] = make_sent_entry(
            rec, from_email=rec.sender_email, transport=args.transport
        )
        added += 1
        print(f"[MARKED SENT] {rec.folder.name} ({rec.to_email})")

    save_sent_log(root, sent_log, all_records)
    print(f"Done: {added} marked sent in {SENT_LOG_NAME} (updated {PROGRESS_NAME}).")
    return 0


def cmd_unmark_sent(args: argparse.Namespace) -> int:
    if not args.only and not args.range:
        raise ValueError("Specify --only or --range to remove folders from sent_log.json.")
    root = Path(args.root).resolve()
    all_records = discover_professors(root)
    records = filter_professors(all_records, args.only, args.range)
    sent_log = load_sent_log(root)

    removed = 0
    for rec in records:
        if rec.folder.name not in sent_log:
            print(f"[NOT SENT] {rec.folder.name}")
            continue
        del sent_log[rec.folder.name]
        removed += 1
        print(f"[UNMARKED] {rec.folder.name}")

    save_sent_log(root, sent_log, all_records)
    print(f"Done: {removed} removed from {SENT_LOG_NAME} (updated {PROGRESS_NAME}).")
    return 0


def cmd_send(args: argparse.Namespace) -> int:
    root = Path(args.root).resolve()
    all_records = discover_professors(root)
    records = filter_professors(all_records, args.only, args.range)
    sent_log = load_sent_log(root)
    queue = filter_pending_for_send(
        records, sent_log, resend=args.resend, test_to=args.test_to, limit=args.limit
    )

    if not queue:
        print("Nothing to send (all matching folders already recorded in sent_log.json).")
        return 0

    missing_pdfs = [rec.folder.name for rec in queue if rec.pdf_path is None]
    if missing_pdfs:
        print(
            "Error: Missing compiled PDF for:\n  "
            + ", ".join(missing_pdfs)
            + "\nRun `python3 mail_cli.py compile` first.",
            file=sys.stderr,
        )
        return 1

    mode = "LIVE SEND" if args.confirm else "DRY RUN (pass --confirm to actually send)"
    print(f"Mode: {mode} | Transport: {args.transport} | Count: {len(queue)}")
    if args.test_to:
        print(f"Test redirect: ALL emails will go ONLY to {args.test_to} (not logged as sent)")

    for rec in queue:
        dest = args.test_to or rec.to_email
        print(f"  - {rec.folder.name:<22} -> {dest} | {rec.subject}")
        if rec.notes:
            print_notes(rec)

    if not args.confirm:
        print("\nDry run complete. No emails were sent.")
        return 0

    if len(queue) > 1 and not args.yes:
        reply = input(f"\nSend {len(queue)} email(s) now? Type 'yes' to proceed: ").strip()
        if reply.lower() != "yes":
            print("Aborted.")
            return 1

    app_password = None
    if args.transport == "smtp":
        sender_email = args.from_email or queue[0].sender_email
        app_password = resolve_app_password(sender_email)

    for idx, rec in enumerate(queue):
        from_name = args.from_name or rec.sender_name
        from_email = args.from_email or rec.sender_email
        msg = build_message(rec, from_name=from_name, from_email=from_email, test_to=args.test_to)

        print(f"[{idx + 1}/{len(queue)}] Sending {rec.folder.name} -> {msg['To']} ...")
        if args.transport == "smtp":
            assert app_password is not None
            send_via_smtp(
                msg,
                from_email,
                app_password,
                port=args.smtp_port,
                debug=args.debug_smtp,
            )
        else:
            send_via_msmtp(msg)

        if not args.test_to:
            sent_log[rec.folder.name] = make_sent_entry(
                rec, from_email=from_email, transport=args.transport
            )
            save_sent_log(root, sent_log, all_records)

        print("  -> Sent.")
        if idx + 1 < len(queue) and args.delay > 0:
            sleep_for = args.delay + random.uniform(0, min(5.0, args.delay * 0.25))
            print(f"  -> Waiting {sleep_for:.1f}s before next send...")
            time.sleep(sleep_for)

    print("All queued emails processed.")
    return 0


def add_selection_args(parser: argparse.ArgumentParser) -> None:
    parser.add_argument("--only", help="Comma-separated indices or folder names (e.g. 01,05 or 01-yang-feng)")
    parser.add_argument("--range", help="Inclusive folder number range (e.g. 1-10)")


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description="Compile CVs and send individual Gmail outreach emails for 10-professors."
    )
    parser.add_argument(
        "--root",
        default=str(DEFAULT_ROOT),
        help="Path to 10-professors directory (default: directory containing this script)",
    )
    sub = parser.add_subparsers(dest="command", required=True)

    p_status = sub.add_parser("status", help="Show parsed emails, PDF readiness, and sent state")
    add_selection_args(p_status)
    p_status.set_defaults(func=cmd_status)

    p_compile = sub.add_parser("compile", help="Compile academic_cv.tex to PDF in each folder")
    add_selection_args(p_compile)
    p_compile.add_argument("--engine", choices=("pdflatex", "xelatex", "lualatex", "tectonic"))
    p_compile.add_argument("--force", action="store_true", help="Recompile even if PDF is newer than .tex")
    p_compile.set_defaults(func=cmd_compile)

    p_preview = sub.add_parser("preview", help="Preview full email headers, notes, and body")
    add_selection_args(p_preview)
    p_preview.set_defaults(func=cmd_preview)

    p_keyring = sub.add_parser("setup-keyring", help="Store Gmail App Password in system keyring")
    p_keyring.add_argument("--email", default="animesh080808@gmail.com")
    p_keyring.set_defaults(func=cmd_setup_keyring)

    p_mark = sub.add_parser("mark-sent", help="Record folders already sent externally in sent_log.json")
    add_selection_args(p_mark)
    p_mark.add_argument("--transport", default="manual", help="Label stored in sent_log.json (default: manual)")
    p_mark.set_defaults(func=cmd_mark_sent)

    p_unmark = sub.add_parser("unmark-sent", help="Remove folders from sent_log.json so they return to pending")
    add_selection_args(p_unmark)
    p_unmark.set_defaults(func=cmd_unmark_sent)

    p_send = sub.add_parser("send", help="Validate and send emails (dry-run unless --confirm)")
    add_selection_args(p_send)
    p_send.add_argument("--confirm", action="store_true", help="Actually transmit emails (default is dry-run)")
    p_send.add_argument("--test-to", help="Redirect all emails to your own address for end-to-end testing")
    p_send.add_argument("--limit", type=int, help="Max emails to send in this run")
    p_send.add_argument("--delay", type=float, default=20.0, help="Seconds to wait between sends (default: 20)")
    p_send.add_argument("--resend", action="store_true", help="Include folders already present in sent_log.json")
    p_send.add_argument("--yes", action="store_true", help="Skip interactive confirmation for multi-email runs")
    p_send.add_argument("--transport", choices=("smtp", "msmtp"), default="smtp")
    p_send.add_argument("--smtp-port", type=int, choices=(465, 587), default=465)
    p_send.add_argument("--debug-smtp", action="store_true", help="Print SMTP protocol trace")
    p_send.add_argument("--from-email", help="Override sender email address")
    p_send.add_argument("--from-name", help="Override sender display name")
    p_send.set_defaults(func=cmd_send)

    return parser


def main(argv: Iterable[str] | None = None) -> int:
    parser = build_parser()
    args = parser.parse_args(list(argv) if argv is not None else None)
    try:
        return args.func(args)
    except Exception as exc:
        print(f"Error: {exc}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
