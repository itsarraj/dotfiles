(function executeScript() {
    

    let step = 0;
    let interval = null;

    let stuckCounter = 0;
    const STUCK_LIMIT = 50; // ~5 seconds (50 * 100ms)

    const message = `You know, you’re truly one of a kind. Your expressions on camera feel so real, and your smile is effortlessly natural, full of emotion.

If no one has ever told you how practical and inspiring you are, let me be the first.

You make me want to be a better man.`;

    function resetCycle() {
        step = 0;
        stuckCounter = 0;
        console.log("🔄 Resetting cycle");
    }

    function stop() {
        if (interval) clearInterval(interval);
        console.log("🛑 Stopped script");
    }

    interval = setInterval(() => {

        stuckCounter++;

        // safety reset if stuck too long
        if (stuckCounter > STUCK_LIMIT) {
            resetCycle();
        }

        // STEP 0: click DM
        if (step === 0) {
            const dmButton = document.querySelector('button[aria-label="DM"]');

            if (dmButton) {
                dmButton.click();
                console.log("✅ DM clicked");
                step = 1;
                stuckCounter = 0;
            }
            return;
        }

        // STEP 1: fill textarea
        if (step === 1) {
            const textArea = document.querySelector('textarea');

            if (textArea) {
                textArea.focus();
                textArea.value = message;
                textArea.dispatchEvent(new Event('input', { bubbles: true }));

                console.log("✅ Message filled");
                step = 2;
                stuckCounter = 0;
            }
            return;
        }

        // STEP 2: click send
        if (step === 2) {
            const sendButton =
                document.querySelector('img[src*="send.svg"]') ||
                document.querySelector('button[type="submit"]') ||
                document.querySelector('[aria-label="Send"]');

            if (sendButton) {
                const clickable = sendButton.closest('button') || sendButton;
                clickable.click();

                console.log("✅ Send clicked");

                resetCycle(); // ready for next run OR keep stopped if you want
                // stop(); // <- uncomment if you want one-shot behavior
            }
            return;
        }

    }, 100);

    window.__stopDMBot = stop;
    window.__resetDMBot = resetCycle;

    console.log("🚀 100ms heartbeat bot started");

})();