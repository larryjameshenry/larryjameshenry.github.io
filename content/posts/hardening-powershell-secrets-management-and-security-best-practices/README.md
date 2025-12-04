# Page Bundle: Hardening PowerShell: Secrets Management and Security Best Practices

This is a Hugo page bundle for the article: **Hardening PowerShell: Secrets Management and Security Best Practices**

## Structure

- `index.md` - Main article content
- `images/` - Article-specific images (referenced as `images/filename.png`)
- `files/` - Downloadable files, scripts, or other resources

## Usage

### Adding Images

1. Place images in the `images/` directory
2. Reference in markdown: `![Alt text](images/your-image.png)`

### Adding Files

1. Place files in the `files/` directory
2. Link in markdown: `[Download](files/your-file.zip)`

### Bundle Benefits

- All resources are self-contained
- Images and files move with the article
- Simpler relative paths
- Better organization

## Next Steps

1. Review: `code content/posts/hardening-powershell-secrets-management-and-security-best-practices/index.md`
2. Add images to: `content/posts/hardening-powershell-secrets-management-and-security-best-practices/images/`
3. Add files to: `content/posts/hardening-powershell-secrets-management-and-security-best-practices/files/`
4. Expand article: `.\scripts\Expand-Article.ps1 -Slug hardening-powershell-secrets-management-and-security-best-practices`
5. Preview: `hugo server --buildDrafts`
