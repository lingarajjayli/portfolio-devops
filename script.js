// Navbar Scroll Effect
const navbar = document.querySelector('.navbar');

window.addEventListener('scroll', () => {
    if (window.scrollY > 50) {
        navbar.classList.add('scrolled');
    } else {
        navbar.classList.remove('scrolled');
    }
});

// Scroll Reveal Animations
function reveal() {
    var reveals = document.querySelectorAll(".reveal");

    for (var i = 0; i < reveals.length; i++) {
        var windowHeight = window.innerHeight;
        var elementTop = reveals[i].getBoundingClientRect().top;
        var elementVisible = 100;

        if (elementTop < windowHeight - elementVisible) {
            reveals[i].classList.add("active");
        }
    }
}

window.addEventListener("scroll", reveal);

// Trigger reveal on load
reveal();

// Glitch effect on hover for the main title
const glitchText = document.querySelector('.glitch');

glitchText.addEventListener('mouseover', () => {
    glitchText.style.animation = 'none';
    setTimeout(() => {
        glitchText.style.animation = 'glitch 1s linear infinite';
    }, 10);
});

glitchText.addEventListener('mouseout', () => {
    glitchText.style.animation = 'none';
});
