"""Build the installable WC Scholar ZIP and extract its GitHub release notes."""

import argparse
import re
import subprocess
from pathlib import Path
from zipfile import ZIP_DEFLATED, ZipFile

ROOT = Path(__file__).resolve().parents[1]
ADDON = "WCScholar"
VERSION = r"[0-9]+\.[0-9]+\.[0-9]+"


def git_paths(*args):
    result = subprocess.check_output(["git", "ls-files", "-z", *args], cwd=ROOT)
    return set(result.decode("utf-8").split("\0")) - {""}


def release_details(tag):
    toc = (ROOT / f"{ADDON}.toc").read_text(encoding="utf-8")
    version_match = re.search(rf"^## Version: ({VERSION})$", toc, re.MULTILINE)
    if not version_match:
        raise ValueError(f"Expected a version like 1.5.0 in {ADDON}.toc")
    version = version_match[1]
    if tag is not None and tag != f"v{version}":
        raise ValueError(f"Tag {tag} does not match add-on version v{version}")
    core = (ROOT / "Core.lua").read_text(encoding="utf-8")
    if not re.search(rf'^S\.version = "{re.escape(version)}"$', core, re.MULTILINE):
        raise ValueError(f"Core.lua does not declare version {version}")

    changelog = (ROOT / "CHANGELOG.md").read_text(encoding="utf-8")
    sections = re.split(r"^## ", changelog, flags=re.MULTILINE)[1:]
    notes = ""
    for section in sections:
        heading, _, body = section.partition("\n")
        if heading.strip() == version:
            notes = body.strip()
            break
    if not notes:
        raise ValueError(f"CHANGELOG.md has no notes under '## {version}'")
    return toc, version, core, notes


def addon_files(toc):
    tracked = git_paths("--cached") - git_paths("--cached", "--ignored", "--exclude-standard")
    files = {
        name for name in tracked
        if (("/" not in name and Path(name).suffix in {".lua", ".toc"}) or name.startswith("Media/"))
        and Path(name).suffix.lower() not in {".md", ".markdown"}
        and Path(name).stem.lower() not in {"license", "licence"}
    }
    required = {f"{ADDON}.toc", "Core.lua", "Media/Book.tga"}
    required.update(line.strip().replace("\\", "/") for line in toc.splitlines()
                    if line.strip() and not line.lstrip().startswith("#"))
    missing = (required - files) | {name for name in files if not (ROOT / name).is_file()}
    if missing:
        raise ValueError("Missing or excluded add-on files: " + ", ".join(sorted(missing)))
    return files


def package(tag):
    toc, version, core, notes = release_details(tag)
    files = addon_files(toc)
    # Keep the MIT notice in every extracted copy without a standalone LICENSE file.
    license_lines = (ROOT / "LICENSE").read_text(encoding="utf-8").splitlines()
    core = "".join(f"-- {line}\n" for line in license_lines) + "\n" + core
    dist = ROOT / "dist"
    dist.mkdir(exist_ok=True)
    archive = dist / f"{ADDON}-{version}.zip"
    with ZipFile(archive, "w", compression=ZIP_DEFLATED) as output:
        for name in sorted(files):
            entry = f"{ADDON}/{name}"
            if name == "Core.lua":
                output.writestr(entry, core)
            else:
                output.write(ROOT / name, entry)
    (dist / "release-notes.md").write_text(notes + "\n", encoding="utf-8")
    return archive.relative_to(ROOT)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--tag", help="require the release tag to match v<add-on version>")
    args = parser.parse_args()
    try:
        print(package(args.tag))
    except (OSError, ValueError, subprocess.CalledProcessError) as error:
        parser.exit(1, f"Packaging failed: {error}\n")
