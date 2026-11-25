---
id: 20260101014026
title: Scripts Collection
date: 2026-01-01 01:40
type: reference # note | concept | snippet | bug | journal | reference
status: stable # draft | stable | evergreen
tags: [scripts, automation, javascript, bash, tools]
links: []
---
# Log
- 2026-01-01 01:40 - Created note.

# Notes

# Scripts Collection

## 🔗 LinkedIn Scraper
## 📧 Email Extractor
```js
// Array to store extracted emails
let extractedEmails = new Set();

const emailRegex = /[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}/g;


// Extract emails
function extractEmails() {
    const text = document.body.innerText;
    const found = text.match(emailRegex);

    if (found) {
        found.forEach(e => extractedEmails.add(e));
        console.log("Emails found:", extractedEmails.size);
    }
}


// Get emails anytime
function getEmails() {
    return Array.from(extractedEmails);
}


// Block images/videos COMPLETELY
function blockImages() {

    const style = document.createElement("style");
    style.innerHTML = `
        img, video {
            display: none !important;
        }
        * {
            background-image: none !important;
        }
    `;
    document.head.appendChild(style);


    function removeImageSources(root=document) {

        root.querySelectorAll("img").forEach(img => {
            img.src = "";
            img.srcset = "";
            img.removeAttribute("src");
            img.removeAttribute("srcset");
            img.remove();
        });

        root.querySelectorAll("video").forEach(video => {
            video.src = "";
            video.remove();
        });

    }


    removeImageSources();


    new MutationObserver((mutations) => {

        mutations.forEach(mutation => {

            mutation.addedNodes.forEach(node => {

                if (node.tagName === "IMG" || node.tagName === "VIDEO") {
                    node.remove();
                }

                if (node.querySelectorAll) {
                    removeImageSources(node);
                }

            });

        });

    }).observe(document.body, { childList: true, subtree: true });

}


// Find scrollable container
function getScrollableContainer() {

    const elements = document.querySelectorAll("*");

    for (let el of elements) {

        const style = window.getComputedStyle(el);

        if (
            (style.overflowY === "auto" || style.overflowY === "scroll") &&
            el.scrollHeight > el.clientHeight + 200
        ) {
            return el;
        }
    }

    return document.documentElement;
}


// Click element by text
function clickByText(text) {

    const elements = document.querySelectorAll("span, button, div, a");

    elements.forEach(el => {

        if (
            el.innerText &&
            el.innerText.trim().toLowerCase() === text.toLowerCase() &&
            !el.dataset.clicked
        ) {
            el.dataset.clicked = "true";
            el.click();

            console.log("Clicked:", text);
        }

    });
}


// Main auto runner
function autoRun() {

    const container = getScrollableContainer();

    console.log("Scroll container:", container);

    function loop() {

        extractEmails();

        clickByText("Load more");
        clickByText("See more");
        clickByText("Show more");

        container.scrollTop = container.scrollHeight;

        setTimeout(loop, 1500);
    }

    loop();
}


// Start script
blockImages();
autoRun();


// Access emails anytime
// getEmails()
```


## 📝 Zettelkasten Indexer
Auto-generate index from markdown files.

```bash
#!/bin/bash
base_dir="$(dirname "$0")"
index_file="$base_dir/index.md"
touch "$index_file"

for file in "$base_dir"/*.md; do
    [[ "$file" == "$index_file" ]] && continue
    filename=$(basename "$file")
    title=$(grep -m 1 '^title:' "$file" | sed 's/title: //')
    [ -z "$title" ] && title="$filename"
    grep -q "\[$title\]($filename)" "$index_file" || echo "- [$title]($filename)" >> "$index_file"
done
echo "Index updated."
```

