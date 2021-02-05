#!/usr/bin/env bash
set -e
x=1

rm content/posts/gerry*.md || true

for f in ./static/images/*; do
	[[ "$f" == "./static/images/logos" ]] && continue

	cat <<EOF > "content/posts/gerry$x.md"
---
title: gerry$x
date: $(date -u +"%Y-%m-%dT%H:%M:%S+00:00")
draft: false
---

![gerry$x](/images/$(basename "$f" | sed 's/ /%20/g' | sed 's/?/%3F/g'))

EOF

	x=$((x+1))
done

