# Git Commit/Push Protection Protocol

*CRITICAL RULE - MUST ENFORCE:*

## NEVER COMMIT OR PUSH WITHOUT EXPLICIT USER INSTRUCTION

*YOU MUST NEVER:*
- Run git commit unless the user explicitly tells you to commit
- Run git push unless the user explicitly tells you to push
- Automatically commit or push after making changes
- Assume the user wants you to commit/push

*EVEN IF:*
- The user says "get ready for deployment"
- You've run all the checks
- The builds pass
- Everything looks good

*YOU MUST WAIT* for the user to explicitly say:
- "commit" or "push" or "commit and push"
- ONLY THEN ask if they said "get ready for deployment"

## Deployment Check Protocol

When the user asks to "commit", "push", "commit and push", or any variation:

1. *IMMEDIATELY STOP* - Do NOT proceed with ANY git commands
2. *ASK THIS EXACT QUESTION*:
   "Have you said 'get ready for deployment'? I need to run the deployment checks before committing/pushing."
3. *WAIT for user confirmation*

## Deployment Check Protocol - What Happens:

When user says "get ready for deployment":

1. *Run these 5 checks automatically (for new changes only):*
   - Type check (npx tsc --noEmit)
   - Lint check (npx eslint)
   - Remove unused imports and variables
   - Remove all unexpected "any" types
   - Apply "unknown" types only for truly unpredictable data

2. *After all 5 checks pass, REMIND user to run builds:*
   - Say: "✅ All deployment checks passed. Ready for you to instruct me which builds to run."
   - *DO NOT run builds automatically*
   - *DO NOT assume which repositories need building*
   - WAIT for user to tell you exactly which repos to build (e.g., "run build on frontend", "build the backend", "build btslanding")

3. *After user instructs which builds to run:*
   - Run ONLY the builds the user specified
   - Track which builds passed/failed
   - After builds complete, WAIT for user to say "commit"
   - DO NOT commit automatically

4. *After commit:*
   - WAIT for user to say "push"
   - DO NOT push automatically

## Build Protection Rules

*CRITICAL - REQUIRE SUCCESSFUL BUILDS BEFORE PUSH:*

1. *Before allowing ANY push command:*
   - Check if builds were run for the repositories being pushed
   - If builds have NOT been run, *BLOCK the push* and say:
     "⚠ BLOCKED: Builds have not been run yet. Please instruct me which repos to build."
   - If any builds FAILED, *BLOCK the push* and say:
     "⚠ BLOCKED: Some builds failed. Cannot push until all required builds pass successfully."
   - Only allow push if all required builds completed successfully with exit code 0

2. *Track build status in session:*
   - Remember which repositories had builds run
   - Remember if each build passed or failed
   - All required builds must pass before allowing push

## If user bypasses this:
- User says "commit and push" without saying "get ready for deployment" first
- *BLOCK IT* - refuse to commit/push until deployment checks are confirmed

*This is a safety mechanism to prevent broken code from being pushed.*