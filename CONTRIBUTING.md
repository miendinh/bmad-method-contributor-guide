# Contributing to this Documentation

> ⚠️ **UNOFFICIAL THIRD-PARTY DOCUMENTATION**
> This is the contribution guide for **THIS documentation** — not the official BMAD-METHOD framework.
> Want to contribute to BMAD-METHOD? → <https://github.com/bmad-code-org/BMAD-METHOD/blob/main/CONTRIBUTING.md>

---

## 🎯 Scope of this repository

This repository contains **unofficial documentation** about the BMAD-METHOD framework. Contributions are welcome for:

✅ **Accepted contributions:**
- Fix typos, grammar (English or Vietnamese)
- Fix technical inaccuracies (verify against BMad source)
- Improve explanations, add examples
- Add Mermaid diagrams
- Update when BMad has breaking changes
- Translate to other languages (create folder like `/fr`, `/zh`, etc.)
- Add FAQ entries
- Improve cheat sheet

❌ **NOT accepted:**
- Content unrelated to BMad framework
- Marketing/promotional content
- Derivative content for products/services named "BMad-*"
- Claims about official BMad endorsement
- Copyright-infringing material (code from proprietary sources)

---

## 📋 Before contributing

### 1. Read the disclaimers

- [ ] Read [DISCLAIMER.md](DISCLAIMER.md)
- [ ] Read [LICENSE](LICENSE)
- [ ] Read [NOTICE](NOTICE)
- [ ] Understand this is **unofficial** documentation

### 2. Understand the legal framework

By contributing, you agree that:

- Your contribution is **MIT Licensed** (like the rest of this repo)
- You have the right to contribute (own the content or proper attribution)
- You do not claim ownership of the BMAD-METHOD framework
- You do not use BMad trademarks inappropriately

### 3. Verify with source

For technical claims, ALWAYS verify against:
1. Current BMAD-METHOD source code: <https://github.com/bmad-code-org/BMAD-METHOD>
2. Official documentation: <https://bmad-method.org>
3. If in doubt, official docs take precedence

---

## 🔄 Contribution workflow

### Small changes (typos, small clarifications)

1. Fork repository
2. Edit files directly
3. Commit with clear message
4. Submit PR with description of changes

### Medium changes (new content, restructuring)

1. Open issue first to discuss
2. Wait for maintainer response (1-3 days)
3. Fork + branch
4. Make changes
5. Run validator: `./validate-dev-docs.sh`
6. Submit PR with detailed description

### Large changes (new files, major restructure)

1. Open issue with proposal
2. Discuss with maintainer + community
3. Wait for approval (could take 1-2 weeks)
4. Follow workflow above

---

## ✅ Quality standards

### For all changes

- [ ] **Accuracy:** Technical info verified against BMad source
- [ ] **Attribution:** Credit sources if drawing from external material
- [ ] **Disclaimer:** Preserve "UNOFFICIAL" notices
- [ ] **Language:** Match the folder's primary language
  - `/dev/*.md` → English (primary, international audience)
  - `/vi-vn/*.md` → Vietnamese (primary, with English technical terms)
- [ ] **Validator:** `./validate-dev-docs.sh` passes
- [ ] **Links:** Cross-links work (no broken refs)
- [ ] **Mermaid:** New diagrams render correctly
- [ ] **License headers:** New files have proper disclaimer

### Content standards

- **Precise:** Don't paraphrase to the point of inaccuracy
- **Cited:** Link to BMad source when making claims
- **Non-endorsing:** Don't imply official endorsement
- **Forward-compatible:** Note when info is v6.3.0-specific

### Commit messages

Use Conventional Commits:

```
feat: add new Mermaid diagram for installer state machine
fix: correct typo in 09a skill description
docs: add FAQ entry about Windows support
refactor: reorganize section in 03-skill-anatomy-deep
chore: update validator script
i18n: sync Vietnamese translation for file 05
```

---

## 🧪 Testing your contribution

### 1. Run validator

```bash
cd dev/
./validate-dev-docs.sh

# Or for Vietnamese version
cd vi-vn/
./validate-dev-docs.sh
```

Must pass with 0 errors (warnings are OK if not strict).

### 2. Verify Mermaid diagrams

If you added/changed Mermaid:

```bash
# Requires mermaid-cli
npx -y @mermaid-js/mermaid-cli -i your-diagram.mmd -o /tmp/test.png
```

### 3. Spell check (optional)

Use your editor's spell checker.

### 4. Preview markdown

Use GitHub-style preview (VSCode, Obsidian, etc.) to verify formatting.

### 5. Translation sync

If you update content in one language, consider updating the corresponding file in the other language folder (`/dev/` ↔ `/vi-vn/`).

---

## ⚖️ License agreement

By submitting a contribution, you agree that:

1. **Copyright:** You have the right to contribute content (own it or proper attribution)
2. **License:** Your contribution is licensed under **MIT License** (inherited from this repo's license)
3. **Non-exclusive:** You grant this repository and downstream users a non-exclusive right to use, modify, distribute
4. **Moral rights:** You keep attribution (you're credited as a contributor for significant work)
5. **No warranty:** Contribution "as is", no warranty

### Important: Trademark considerations

**DO NOT contribute:**
- Content using "BMad" in context suggesting official endorsement
- Branding/marketing materials
- Derivative products named with "BMad"

**Allowed references to BMad:**
- Descriptive use ("the BMad framework")
- Technical reference ("BMad's skill architecture")
- Attribution ("BMAD-METHOD by BMad Code, LLC")

When in doubt, check [TRADEMARK.md](https://github.com/bmad-code-org/BMAD-METHOD/blob/main/TRADEMARK.md).

---

## 🐛 Reporting issues

### Issues in this documentation

Use this repository's Issues tab:

- **Typos/grammar:** Label `typo`
- **Technical inaccuracy:** Label `bug`
- **Missing content:** Label `enhancement`
- **Unclear explanation:** Label `clarification`
- **Outdated info:** Label `outdated`
- **Translation issue:** Label `i18n`

### Issues in BMAD-METHOD framework

**Do NOT report here.** Go to: <https://github.com/bmad-code-org/BMAD-METHOD/issues>

### Security issues

**For this documentation:** Report via private issue
**For BMad framework:** Follow <https://github.com/bmad-code-org/BMAD-METHOD/blob/main/SECURITY.md>

---

## 🤝 Code of conduct

### Be respectful

- Respect contributors, authors, and BMad Code, LLC
- Constructive feedback only
- No personal attacks, harassment, discrimination

### Be accurate

- Verify before claiming
- Correct mistakes promptly
- Don't spread misinformation about BMad

### Be humble

- Remember: this is unofficial
- Official docs are source of truth
- We're users/analysts, not authors of BMad

### Be inclusive

- Multiple languages welcome (English, Vietnamese, and more)
- Help beginners
- Diverse perspectives appreciated

See [CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md) for full details.

---

## 🏆 Recognition

Significant contributors are acknowledged in:
- Git commit history (forever)
- `CONTRIBUTORS.md` file (for notable contributions)
- README recognition section (for major efforts)

We don't currently offer paid bounties. This is a labor of love for the BMad community.

---

## 📧 Contact

### Project maintainers

Via this repository's Issues tab or README contact info.

### For BMAD-METHOD (official)

- GitHub: <https://github.com/bmad-code-org/BMAD-METHOD>
- Discord: <https://discord.gg/gk8jAdXWmj>
- Email: <contact@bmadcode.com> (trademark questions only)

---

## 📚 Useful resources

### For this documentation

- [README.md](README.md) — Start here
- [DISCLAIMER.md](DISCLAIMER.md) — Legal notices
- [LICENSE](LICENSE) — MIT License
- [NOTICE](NOTICE) — Attributions
- [validate-dev-docs.sh](validate-dev-docs.sh) — Validator script

### For BMAD-METHOD (official)

- [Official repo](https://github.com/bmad-code-org/BMAD-METHOD)
- [Official CONTRIBUTING.md](https://github.com/bmad-code-org/BMAD-METHOD/blob/main/CONTRIBUTING.md)
- [Official docs](https://bmad-method.org)

---

## 🙏 Thank you

Thanks for wanting to contribute! Every typo fix, every clarification, every new diagram helps developers better understand BMAD-METHOD.

Remember: **Human Amplification, Not Replacement** — contributions should help humans better understand and use BMad, not replace human judgment with AI-generated content.

---

**Last updated:** April 2026
