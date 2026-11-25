// === LINKEDIN EMAIL EXTRACTOR - Updated with ... more button ===

let extractedEmails = new Set();

// Find scrollable parent
function findScrollableParent(el) {
    while (el) {
        if (el.scrollHeight > el.clientHeight + 50) return el;
        el = el.parentElement;
    }
    return document.documentElement || document.body;
}

// Extract emails
function extractEmails() {
    const emailRegex = /[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}/g;
    const found = document.body.innerText.match(emailRegex);
    if (found) {
        found.forEach(e => extractedEmails.add(e.toLowerCase()));
    }
    console.clear();
    console.log("📧 Total Emails:", extractedEmails.size);
}

// Block media (no leak)
function blockImages() {
    const style = document.createElement("style");
    style.innerHTML = `img, video, iframe { display: none !important; }`;
    document.head.appendChild(style);

    const observer = new MutationObserver(m => {
        document.querySelectorAll("img, video, iframe").forEach(el => el.remove());
    });
    observer.observe(document.body, { childList: true, subtree: true });
}

// Safe click helper
function clickIfExists(selector, textMatch = null) {
    document.querySelectorAll(selector).forEach(btn => {
        if (btn.dataset.clicked) return;
        const text = (btn.innerText || "").trim();
        if (!textMatch || text.includes(textMatch)) {
            btn.click();
            btn.dataset.clicked = "true";
        }
    });
}

// Main loop
function clickSeeMoreAndScroll() {
    // Existing clicks
    clickIfExists('button.feed-shared-inline-show-more-text__see-more-less-toggle');
    clickIfExists('button.artdeco-button--muted.artdeco-button--full', 'Show more');
    clickIfExists('button.artdeco-button', 'Load more posts');

    // NEW: Click "... more" buttons
    clickIfExists('[data-testid="expandable-text-button"]', 'more');
    clickIfExists('button', '… more');   // backup

    // Targeted scroll
    const lazy = document.querySelector('[data-testid="lazy-column"]');
    const scroller = lazy ? findScrollableParent(lazy) : window;
    
    if (scroller !== window) {
        scroller.scrollTop = scroller.scrollHeight;
    } else {
        window.scrollTo(0, document.body.scrollHeight);
    }

    setTimeout(() => {
        extractEmails();
        clickSeeMoreAndScroll();
    }, 700);
}

// Copy function (fixed)
function copyEmails() {
    const emails = Array.from(extractedEmails);
    if (emails.length === 0) {
        console.log("No emails yet");
        return;
    }
    const text = emails.map(e => e + ',').join('\n');

    navigator.clipboard.writeText(text).then(() => {
        console.log(`✅ Copied ${emails.length} emails`);
    }).catch(() => {
        const ta = document.createElement('textarea');
        ta.value = text;
        ta.style.position = 'fixed';
        ta.style.opacity = '0';
        document.body.appendChild(ta);
        ta.select();
        document.execCommand('copy');
        document.body.removeChild(ta);
        console.log(`✅ Copied ${emails.length} emails (fallback)`);
    });
}

function getEmails() {
    return Array.from(extractedEmails);
}

// Start
console.log("🚀 Starting Email Extractor...");
blockImages();
clickSeeMoreAndScroll();

// Auto copy every 25s (only if emails found)
setInterval(() => {
    if (extractedEmails.size > 3) copyEmails();
}, 25000);
