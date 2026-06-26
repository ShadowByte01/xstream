import os, glob
for f in glob.glob('lib/**/*.dart', recursive=True):
    with open(f, 'r', encoding='utf-8') as file: content = file.read()
    if 'const LoadingOverlay' in content:
        content = content.replace('const LoadingOverlay', 'LoadingOverlay')
        with open(f, 'w', encoding='utf-8') as file: file.write(content)
