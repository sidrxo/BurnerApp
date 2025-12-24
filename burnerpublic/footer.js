// Load footer HTML and inject it into the page
async function loadFooter() {
    try {
        const response = await fetch('/footer.html');
        const footerHTML = await response.text();

        // Find the #swup container and append footer
        const swupContainer = document.getElementById('swup');
        if (swupContainer) {
            const tempDiv = document.createElement('div');
            tempDiv.innerHTML = footerHTML;
            swupContainer.appendChild(tempDiv.firstElementChild);
        }

        // Initialize footer intro visibility
        updateFooterIntro();
    } catch (error) {
        console.error('Failed to load footer:', error);
    }
}

// Update footer intro visibility based on current page
function updateFooterIntro() {
    const footerIntro = document.querySelector('.footer-intro');
    if (!footerIntro) return;

    // Show only on homepage (root path or /index.html)
    const isHomepage = window.location.pathname === '/' ||
                       window.location.pathname === '/index.html' ||
                       window.location.pathname === '';

    footerIntro.style.opacity = isHomepage ? '1' : '0';
    footerIntro.style.pointerEvents = isHomepage ? 'auto' : 'none';
}

// Load footer when DOM is ready
if (document.readyState === 'complete' || document.readyState === 'interactive') {
    loadFooter();
} else {
    document.addEventListener('DOMContentLoaded', loadFooter);
}

// Update footer intro on Swup page transitions (if Swup is available)
if (typeof Swup !== 'undefined') {
    document.addEventListener('DOMContentLoaded', () => {
        if (window.swup) {
            window.swup.hooks.on('page:view', updateFooterIntro);
        }
    });
}
