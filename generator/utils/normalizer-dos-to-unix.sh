#!/bin/bash
cat >.git/hooks/pre-commit <<'EOF'
#!/bin/bash
echo "🔄 Normalizando .sh con dos2unix..."
find . -type f -name "*.sh" -exec dos2unix {} +
EOF

chmod +x .git/hooks/pre-commit
