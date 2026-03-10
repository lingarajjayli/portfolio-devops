// Apple-style extremely smooth, subtle scroll animations

document.addEventListener('DOMContentLoaded', () => {
    // Reveal Observer for smooth sliding up of elements
    const observerOptions = {
        root: null,
        rootMargin: '0px',
        threshold: 0.15 
    };

    const observer = new IntersectionObserver((entries, observer) => {
        entries.forEach(entry => {
            if (entry.isIntersecting) {
                entry.target.classList.add('active');
                // Optional: Unobserve after revealing to keep the state
                // observer.unobserve(entry.target); 
            }
        });
    }, observerOptions);

    const revealElements = document.querySelectorAll('.reveal-up');
    revealElements.forEach(el => {
        observer.observe(el);
    });

    // Make the initial hero reveal automatically instead of waiting for scroll
    setTimeout(() => {
        const heroElements = document.querySelectorAll('.hero-section .reveal-up');
        heroElements.forEach(el => {
            el.classList.add('active');
        });
    }, 100);
});
