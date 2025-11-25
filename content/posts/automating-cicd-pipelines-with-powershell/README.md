# Page Bundle: **Article 3: Automating CI/CD Pipelines with PowerShell**

This is a Hugo page bundle for the article: ****Article 3: Automating CI/CD Pipelines with PowerShell****

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

1. Review: `code content/posts/article-3-automating-cicd-pipelines-with-powershell/index.md`
2. Add images to: `content/posts/article-3-automating-cicd-pipelines-with-powershell/images/`
3. Add files to: `content/posts/article-3-automating-cicd-pipelines-with-powershell/files/`
4. Expand article: `.\scripts\Expand-Article.ps1 -Slug article-3-automating-cicd-pipelines-with-powershell`
5. Preview: `hugo server --buildDrafts`
