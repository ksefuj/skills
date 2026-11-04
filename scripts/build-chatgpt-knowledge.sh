#!/usr/bin/env bash
# Builds the knowledge files for the ChatGPT custom GPT from the skill sources.
# ChatGPT knowledge needs unique, flat file names, so:
#   skills/<skill>/SKILL.md             -> <skill>.md
#   skills/<skill>/references/<ref>.md  -> <skill>--<ref>.md
# Output: dist/chatgpt-knowledge/ and dist/chatgpt-knowledge.zip
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$root"

out="dist/chatgpt-knowledge"
rm -rf "$out" dist/chatgpt-knowledge.zip
mkdir -p "$out"

shopt -s nullglob
for skill_md in skills/*/SKILL.md; do
  skill="$(basename "$(dirname "$skill_md")")"
  cp "$skill_md" "$out/$skill.md"
done
for ref in skills/*/references/*.md; do
  skill="$(basename "$(dirname "$(dirname "$ref")")")"
  cp "$ref" "$out/$skill--$(basename "$ref")"
done

if [ -z "$(ls -A "$out")" ]; then
  echo "No skill files found" >&2
  exit 1
fi

(cd "$out" && zip -q -j ../chatgpt-knowledge.zip ./*.md)

ls -1 "$out"
echo "Wrote dist/chatgpt-knowledge.zip"
