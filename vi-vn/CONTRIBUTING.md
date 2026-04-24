# Contributing to this Documentation

> ⚠️ **UNOFFICIAL THIRD-PARTY DOCUMENTATION**
> Này là contribution guide cho **documentation này** — không phải cho official BMAD-METHOD framework.
> Muốn contribute BMAD-METHOD? → <https://github.com/bmad-code-org/BMAD-METHOD/blob/main/CONTRIBUTING.md>

---

## 🎯 Scope of this repository

Repository này chứa **unofficial documentation** về BMAD-METHOD framework. Contributions are welcome for:

✅ **Accepted contributions:**
- Sửa lỗi chính tả, ngữ pháp tiếng Việt
- Sửa technical inaccuracies (verify với source BMad)
- Cải thiện giải thích, thêm examples
- Thêm Mermaid diagrams
- Cập nhật khi BMad có breaking changes
- Translate sang ngôn ngữ khác (tạo folder `/dev-en`, `/dev-zh`, etc.)
- Thêm FAQ entries
- Cải thiện cheat sheet

❌ **NOT accepted:**
- Content không liên quan BMad framework
- Marketing/promotional content
- Derivative content cho products/services tên "BMad-*"
- Claims about official BMad endorsement
- Copyright-infringing material (code từ proprietary sources)

---

## 📋 Before contributing

### 1. Read the disclaimers

- [ ] Đọc [DISCLAIMER.md](DISCLAIMER.md)
- [ ] Đọc [LICENSE](LICENSE)
- [ ] Đọc [NOTICE](NOTICE)
- [ ] Hiểu rằng đây là **unofficial** documentation

### 2. Understand the legal framework

Bằng cách contribute, bạn đồng ý:

- Contribution của bạn được **MIT Licensed** (like the rest)
- Bạn có quyền contribute (own the content or properly attributed)
- Bạn không claim ownership của BMAD-METHOD framework
- Bạn không sử dụng BMad trademarks inappropriately

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
3. Commit với clear message
4. PR với description của changes

### Medium changes (new content, restructuring)

1. Open issue first để discuss
2. Wait for maintainer response (1-3 days)
3. Fork + branch
4. Make changes
5. Run validator: `./validate-dev-docs.sh`
6. PR với detailed description

### Large changes (new files, major restructure)

1. Open issue với proposal
2. Discuss với maintainer + community
3. Wait for approval (could take 1-2 weeks)
4. Follow workflow above

---

## ✅ Quality standards

### For all changes

- [ ] **Accuracy:** Technical info verified against BMad source
- [ ] **Attribution:** Credit sources if drawing from external material
- [ ] **Disclaimer:** Preserve "UNOFFICIAL" notices
- [ ] **Language:** Tiếng Việt cho narrative, English cho technical terms
- [ ] **Validator:** `./validate-dev-docs.sh` passes
- [ ] **Links:** Cross-links work (no broken refs)
- [ ] **Mermaid:** New diagrams render correctly
- [ ] **License headers:** New files have proper disclaimer

### Content standards

- **Precise:** Don't paraphrase to point of inaccuracy
- **Cited:** Link to BMad source when making claims
- **Bilingual clarity:** Keep technical terms recognizable
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
```

---

## 🧪 Testing your contribution

### 1. Run validator

```bash
cd dev/
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

Use your editor's spell checker. Mix Vietnamese + English is expected.

### 4. Preview markdown

Use GitHub-style preview (VSCode, Obsidian, etc.) to verify formatting.

---

## ⚖️ License agreement

By submitting a contribution, you agree that:

1. **Copyright:** Bạn có quyền contribute content (own it or proper attribution)
2. **License:** Contribution của bạn được licensed dưới **MIT License** (kế thừa từ this repo's license)
3. **Non-exclusive:** You grant this repository và downstream users a non-exclusive right to use, modify, distribute
4. **Moral rights:** You keep attribution (you're credited as contributor nếu significant)
5. **No warranty:** Contribution "as is", không warranty

### Important: Trademark considerations

**DO NOT contribute:**
- Content using "BMad" trong context suggesting official endorsement
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

- Vietnamese + English welcome
- Help beginners
- Diverse perspectives appreciated

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

### Về BMAD-METHOD (official)

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

Thanks for wanting to contribute! Every typo fix, every clarification, every new diagram helps Vietnamese-speaking developers and the broader community understand BMAD-METHOD better.

Remember: **Human Amplification, Not Replacement** — contributions should help humans better understand and use BMad, not replace human judgment with AI-generated content.

---

**Last updated:** April 2026
