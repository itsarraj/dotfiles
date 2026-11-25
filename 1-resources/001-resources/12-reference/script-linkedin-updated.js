// Store unique emails
let extractedEmails = new Set();

// Extract emails from visible page text
function extractEmails() {
    const emailRegex = /[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}/g;

    const pageText = document.body.innerText || "";
    const foundEmails = pageText.match(emailRegex);

    if (foundEmails) {
        foundEmails.forEach(email => extractedEmails.add(email));
    }

    console.clear();
    console.log("Total Emails:", extractedEmails.size);
    console.log(Array.from(extractedEmails));
}

// Block images/videos for performance
function blockImages() {
    const style = document.createElement("style");

    style.innerHTML = `
        img, video {
            display: none !important;
        }
    `;

    document.head.appendChild(style);

    // Remove dynamically loaded media
    const observer = new MutationObserver(() => {
        document.querySelectorAll("img, video").forEach(el => el.remove());
    });

    observer.observe(document.body, {
        childList: true,
        subtree: true
    });
}

// Click button safely once
function clickIfExists(selector, textMatch = null) {
    const buttons = document.querySelectorAll(selector);

    buttons.forEach(button => {
        if (button.dataset.clicked) return;

        const text = button.innerText?.trim() || "";

        if (!textMatch || text.includes(textMatch)) {
            button.click();
            button.dataset.clicked = "true";
            console.log("Clicked:", text);
        }
    });
}

// Auto click + scroll + extract emails
function clickSeeMoreAndScroll() {

    // Expand post text
    clickIfExists(
        'button.feed-shared-inline-show-more-text__see-more-less-toggle'
    );

    // LinkedIn "Show more results"
    clickIfExists(
        'button.artdeco-button--muted.artdeco-button--full',
        'Show more'
    );

    // NEW: Load more posts
    clickIfExists(
        'button.artdeco-button',
        'Load more posts'
    );

    // Scroll page
    window.scrollTo(0, document.body.scrollHeight);

    // Wait for lazy loaded content
    setTimeout(() => {
        extractEmails();

        // Continue loop
        clickSeeMoreAndScroll();

    }, 1500);
}

// Export helper
function getEmails() {
    return Array.from(extractedEmails);
}

// Copy helper
function copyEmails() {
    copy(
        getEmails()
            .map(email => email + ',')
            .join('\n')
    );
}

// Start
blockImages();
clickSeeMoreAndScroll();

// Use this to copy the emails seperated with comma
copy(getEmails().map(email => email + ',').join('\n'))
