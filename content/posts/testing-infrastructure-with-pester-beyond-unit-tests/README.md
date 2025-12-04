# Page Bundle: Testing Infrastructure with Pester: Beyond Unit Tests

This is a Hugo page bundle for the article: **Testing Infrastructure with Pester: Beyond Unit Tests**

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

1. Review: `code content/posts/testing-infrastructure-with-pester-beyond-unit-tests/index.md`
2. Add images to: `content/posts/testing-infrastructure-with-pester-beyond-unit-tests/images/`
3. Add files to: `content/posts/testing-infrastructure-with-pester-beyond-unit-tests/files/`
4. Expand article: `.\scripts\Expand-Article.ps1 -Slug testing-infrastructure-with-pester-beyond-unit-tests`
5. Preview: `hugo server --buildDrafts`
