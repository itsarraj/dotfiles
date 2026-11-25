// === LINKEDIN EMAIL EXTRACTOR - Fixed Scrolling Issue ===

let extractedEmails = new Set();
let cycleCount = 0;

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

// Block media
function blockImages() {
    const style = document.createElement("style");
    style.innerHTML = `img, video, iframe { display: none !important; }`;
    document.head.appendChild(style);

    const observer = new MutationObserver(() => {
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

// Improved scrolling with occasional swipe up
function smartScroll(scroller) {
    if (!scroller) return;

    const currentScroll = scroller.scrollTop;
    const maxScroll = scroller.scrollHeight - scroller.clientHeight;

    if (cycleCount % 5 === 0 && cycleCount > 0) {
        // Every 5 cycles: Swipe up then down (helps trigger more loading)
        scroller.scrollTop = Math.max(0, maxScroll - 800);
        setTimeout(() => {
            scroller.scrollTop = scroller.scrollHeight;
        }, 300);
    } else {
        // Normal scroll to bottom
        scroller.scrollTop = scroller.scrollHeight;
    }
}

// Main loop
function clickSeeMoreAndScroll() {
    cycleCount++;

    // Click buttons
    clickIfExists('button.feed-shared-inline-show-more-text__see-more-less-toggle');
    clickIfExists('button.artdeco-button--muted.artdeco-button--full', 'Show more');
    clickIfExists('button.artdeco-button', 'Load more posts');
    clickIfExists('[data-testid="expandable-text-button"]', 'more');
    clickIfExists('button', '… more');

    // Smart scrolling
    const lazy = document.querySelector('[data-testid="lazy-column"]');
    const scroller = lazy ? findScrollableParent(lazy) : window;

    if (scroller !== window && scroller.scrollHeight) {
        smartScroll(scroller);
    } else {
        smartScroll(document.documentElement);
    }

    setTimeout(() => {
        extractEmails();
        clickSeeMoreAndScroll();
    }, 750);
}

// Copy function
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

// === START ===
console.log("🚀 Starting Email Extractor with Smart Scrolling...");
blockImages();
clickSeeMoreAndScroll();

// Auto copy every 20 seconds (fixed interval)
setInterval(() => {
    if (extractedEmails.size > 3) copyEmails();
}, 200);