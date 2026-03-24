// JS Handlers

document.addEventListener('DOMContentLoaded', () => {
    
    // Smooth reveal for sections
    const observerOptions = {
        root: null,
        rootMargin: '0px',
        threshold: 0.1
    };

    const observer = new IntersectionObserver((entries, observer) => {
        entries.forEach(entry => {
            if (entry.isIntersecting) {
                entry.target.classList.add('active');
            }
        });
    }, observerOptions);

    document.querySelectorAll('.reveal').forEach(el => {
        observer.observe(el);
    });

    // Automatically trigger reveals on load for anything currently in viewport
    setTimeout(() => {
        document.querySelectorAll('.reveal').forEach(el => {
            const rect = el.getBoundingClientRect();
            if (rect.top < window.innerHeight) {
                el.classList.add('active');
            }
        });
    }, 100);

    // Navbar scroll effect
    const navbar = document.querySelector('.navbar');
    window.addEventListener('scroll', () => {
        if (window.scrollY > 20) {
            navbar.style.background = 'rgba(11, 15, 25, 0.95)';
            navbar.style.boxShadow = '0 4px 30px rgba(0, 0, 0, 0.5)';
        } else {
            navbar.style.background = 'rgba(11, 15, 25, 0.8)';
            navbar.style.boxShadow = 'none';
        }
    });

    // Mobile Menu Toggle logic (simple)
    const mobileToggle = document.querySelector('.mobile-menu-toggle');
    const navLinks = document.querySelector('.nav-links');
    
    if(mobileToggle && navLinks) {
        mobileToggle.addEventListener('click', () => {
            if(navLinks.style.display === 'flex') {
                navLinks.style.display = 'none';
            } else {
                navLinks.style.display = 'flex';
                navLinks.style.flexDirection = 'column';
                navLinks.style.position = 'absolute';
                navLinks.style.top = '100%';
                navLinks.style.left = '0';
                navLinks.style.right = '0';
                navLinks.style.background = 'var(--bg-surface)';
                navLinks.style.padding = '20px';
                navLinks.style.borderBottom = '1px solid var(--border-subtle)';
            }
        });
    }

    // Expandable Project Cards
    document.querySelectorAll('.project-card').forEach(card => {
        card.addEventListener('click', () => {
            const isExpanded = card.classList.contains('expanded');
            document.querySelectorAll('.project-card').forEach(c => c.classList.remove('expanded'));
            if (!isExpanded) {
                card.classList.add('expanded');
            }
        });
    });

    // Expandable Skill Cards
    document.querySelectorAll('.skill-card').forEach(card => {
        card.addEventListener('click', () => {
            const isExpanded = card.classList.contains('expanded');
            document.querySelectorAll('.skill-card').forEach(c => c.classList.remove('expanded'));
            if (!isExpanded) {
                card.classList.add('expanded');
            }
        });
    });
});
