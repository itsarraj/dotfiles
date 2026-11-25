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

// Auto click "See more" + scroll + extract emails
function clickSeeMoreAndScroll() {

    // Expand posts
    const seeMoreButtons = document.querySelectorAll(
        'button.feed-shared-inline-show-more-text__see-more-less-toggle'
    );

    seeMoreButtons.forEach(button => {
        if (!button.dataset.clicked) {
            button.click();
            button.dataset.clicked = "true";
        }
    });

    // LinkedIn "Show more results"
    const showMoreResultsButton = document.querySelector(
        'button.artdeco-button--muted.artdeco-button--full'
    );

    if (showMoreResultsButton && !showMoreResultsButton.dataset.clicked) {
        showMoreResultsButton.click();
        showMoreResultsButton.dataset.clicked = "true";
        console.log("Clicked Show More Results");
    }

    // Scroll down
    window.scrollTo(0, document.body.scrollHeight);

    // Extract emails after content loads
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

// Start
blockImages();
clickSeeMoreAndScroll();
