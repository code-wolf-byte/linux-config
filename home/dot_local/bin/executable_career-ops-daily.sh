#!/usr/bin/env bash
# Daily career-ops Simplify internship scan. Driven by career-ops-daily.timer.
# ponytail: retries on ANY nonzero exit, not just usage limits — same recovery either way.
set -uo pipefail

PROJECT=/home/tupreti/claude-ops/career-ops
CLAUDE=/home/tupreti/.local/bin/claude
LOG_DIR=/home/tupreti/.local/state/career-ops
LOG="$LOG_DIR/daily-$(date +%F).log"
MAX_TRIES=16          # 16 x 30min = 8h of waiting for a usage limit to renew
SLEEP_SECS=1800
ROWS="$PROJECT/output/sheet-rows.json"   # pushed to the Google Sheet tracker by career-ops-sheet.mjs

mkdir -p "$LOG_DIR"
cd "$PROJECT" || { echo "$(date -Is) FATAL: $PROJECT missing" >>"$LOG"; exit 1; }

read -r -d '' PROMPT <<'PEOF'
Daily automated career-ops run. Nobody is watching this session: never ask a question, never wait for confirmation, and pick a sensible default whenever you would otherwise ask. Never submit an application, send an email, git commit, or git push.

1. Run: node scan.mjs --company "Simplify GitHub Listings"
2. From data/scan-history.tsv, take only the rows this run added (first_seen is today's or yesterday's UTC date) whose title is an internship or co-op.
3. Drop: non-US locations (F-1 CPT/OPT is US-only), ITAR / US-citizen-only / security-clearance employers per the work authorization policy in modes/_profile.md, and non-software titles.
4. For the strongest remaining candidates, fetch the full JD through the public ATS APIs — boards-api.greenhouse.io/v1/boards/{org}/jobs/{id}?content=true, api.ashbyhq.com/posting-api/job-board/{org}, api.lever.co/v0/postings/{org}/{id} — and drop any whose stated graduation window excludes a May 2027 graduate, and any that say they will not sponsor now or in the future.
5. Rank the survivors against cv.md and modes/_profile.md.
6. For up to the top 10, follow the LaTeX resume workflow in modes/_custom.md to produce output/resume-overleaf-{slug}.zip, and write a cover letter to output/cover-{slug}.md. Every fact must come from cv.md and config/profile.yml — reorder, regroup and reword to match the JD, never invent a claim.
7. Write output/internship-shortlist-{YYYY-MM-DD}.md: the ranking, the eligibility requirement quoted from each JD, and the artifact paths. Also overwrite output/sheet-rows.json with a JSON array, one object per shortlisted role, keys: date (today, YYYY-MM-DD), company, role, url (the job listing), score (fit against cv.md and modes/_profile.md, X.X/5), resume (absolute path of the resume PDF), cover (absolute path of the cover letter), notes (one line: location, pay, eligibility quote, cautions). Write [] if nothing was shortlisted.
8. Mark the shortlisted URLs processed in data/pipeline.md, then run: node verify-pipeline.mjs
9. Finish with a short plain-text summary: how many roles the scan added, how many survived each filter, and the final shortlist.

If no new eligible internships came in, write a one-line note to output/internship-shortlist-{YYYY-MM-DD}.md saying so, and stop. Do not re-tailor CVs for roles already shortlisted on an earlier day.
PEOF

push_sheet() {
  [ -s "$ROWS" ] || { echo "$(date -Is) sheet: skipped (no rows file)" >>"$LOG"; return; }
  echo "$(date -Is) sheet: $(node /home/tupreti/.local/bin/career-ops-sheet.mjs "$ROWS" 2>&1)" >>"$LOG"
}

for try in $(seq 1 "$MAX_TRIES"); do
  echo "=== $(date -Is) attempt $try/$MAX_TRIES ===" >>"$LOG"
  if "$CLAUDE" -p "$PROMPT" \
       --allowedTools Bash Read Write Edit Glob Grep WebFetch \
       --permission-prompts none >>"$LOG" 2>&1; then
    echo "=== $(date -Is) OK ===" >>"$LOG"
    push_sheet
    exit 0
  fi
  echo "=== $(date -Is) attempt $try failed (likely usage limit); sleeping ${SLEEP_SECS}s ===" >>"$LOG"
  [ "$try" -lt "$MAX_TRIES" ] && sleep "$SLEEP_SECS"
done

echo "=== $(date -Is) GAVE UP after $MAX_TRIES attempts ===" >>"$LOG"
exit 1
