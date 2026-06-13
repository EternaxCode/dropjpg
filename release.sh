#!/usr/bin/env bash
# Cut a new DropJPG release.
#   ./release.sh 1.1
# Bumps VERSION, commits, tags v<version>, and pushes — which triggers the
# GitHub Actions "Release" workflow to build the DMG and publish the release.
set -euo pipefail

cd "$(dirname "$0")"

NEW="${1:-}"
if [ -z "$NEW" ]; then
    echo "usage: ./release.sh <version>   e.g. ./release.sh 1.1"
    echo "current: $(cat VERSION)"
    exit 1
fi
if ! echo "$NEW" | grep -Eq '^[0-9]+\.[0-9]+(\.[0-9]+)?$'; then
    echo "error: version must look like 1.1 or 1.1.0"
    exit 1
fi

TAG="v$NEW"
if git rev-parse "$TAG" >/dev/null 2>&1; then
    echo "error: tag $TAG already exists"
    exit 1
fi
if [ -n "$(git status --porcelain)" ]; then
    echo "error: working tree not clean — commit or stash first"
    git status --short
    exit 1
fi

echo "==> Bumping VERSION → $NEW"
echo "$NEW" > VERSION

echo "==> Verifying it builds"
./build.sh >/dev/null
echo "    build OK"

git add VERSION CHANGELOG.md 2>/dev/null || git add VERSION
git commit -q -m "Release $TAG"
git tag "$TAG"

echo "==> Pushing main + $TAG"
git push -q origin main
git push -q origin "$TAG"

echo "==> Done. GitHub Actions will build the DMG and publish the release:"
echo "    https://github.com/EternaxCode/dropjpg/actions"
echo "    https://github.com/EternaxCode/dropjpg/releases/tag/$TAG"
