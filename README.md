## Publish PowerShell Module(s)

This GitHub Action enables you to publish PowerShell module(s) to the [PowerShell Gallery](https://powershellgallery.com)

## Usage

1. Add a GitHub Actions Workflow configuration to your GitHub project, (e.g. under `.github/workflows/main.yml`)
2. Configure a secret on your GitHub repository, containing your PowerShell Gallery API key
3. Add a step to your GitHub Actions job

For example, if you named your secret `PSGALLERY_API_KEY`:

```yaml
      - name: Publish Module(s) to PowerShell Gallery
        uses: chris-peterson/publish-powershell-modules@v1
        with:
          ApiKey: ${{ secrets.PSGALLERY_API_KEY }}
```

## Example

Here's a full listing for a hypothetical project

```yaml
name: CI

on:
  push:
    branches: [ 'main']

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v5

      - name: Publish PowerShell Module
        uses: chris-peterson/publish-powershell-modules@v1
        with:
          ApiKey: ${{ secrets.PSGALLERY_API_KEY }}
    environment:
      name: PowerShell Gallery
      url: https://www.powershellgallery.com/packages/<YOUR_PACKAGE_HERE>
```
