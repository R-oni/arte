// Menu Mobile
const hamburger = document.querySelector('.hamburger');
const navMenu = document.querySelector('.nav-menu');
const navLinks = document.querySelectorAll('.nav-link');

if (hamburger) {
    hamburger.addEventListener('click', () => {
        navMenu.classList.toggle('active');
        hamburger.classList.toggle('active');
    });

    navLinks.forEach(link => {
        link.addEventListener('click', () => {
            navMenu.classList.remove('active');
            hamburger.classList.remove('active');
        });
    });
}

// Smooth Scroll
document.querySelectorAll('a[href^="#"]').forEach(anchor => {
    anchor.addEventListener('click', function (e) {
        e.preventDefault();
        const target = document.querySelector(this.getAttribute('href'));
        if (target) {
            target.scrollIntoView({
                behavior: 'smooth',
                block: 'start'
            });
        }
    });
});

// Formulário de Contato
const contactForm = document.querySelector('.contact-form');
if (contactForm) {
    contactForm.addEventListener('submit', function (e) {
        e.preventDefault();
        alert('Obrigado pela sua mensagem! Entraremos em contato em breve.');
        this.reset();
    });
}

// Animação ao Scroll
const observerOptions = {
    threshold: 0.1,
    rootMargin: '0px 0px -100px 0px'
};

const observer = new IntersectionObserver(function (entries) {
    entries.forEach(entry => {
        if (entry.isIntersecting) {
            entry.target.style.opacity = '1';
            entry.target.style.transform = 'translateY(0)';
        }
    });
}, observerOptions);

// Animar elementos do portfolio
document.querySelectorAll('.portfolio-item').forEach(item => {
    item.style.opacity = '0';
    item.style.transform = 'translateY(20px)';
    item.style.transition = 'opacity 0.6s ease, transform 0.6s ease';
    observer.observe(item);
});

// Modal para imagens do portfolio
const modal = document.getElementById('imageModal');
const modalImage = document.querySelector('.modal-image');
const closeBtn = document.querySelector('.close');

if (modal && modalImage && closeBtn) {
    // Adicionar evento de clique às imagens do portfolio
    document.querySelectorAll('.portfolio-item').forEach(item => {
        const portfolioImage = item.querySelector('.portfolio-image');
        if (portfolioImage) {
            portfolioImage.addEventListener('click', function() {
                const imageSrc = item.dataset.image;
                modalImage.src = imageSrc;
                modal.classList.add('active');
                document.body.style.overflow = 'hidden';
            });
        }
    });

    // Fechar modal ao clicar no X
    closeBtn.addEventListener('click', function() {
        modal.classList.remove('active');
        document.body.style.overflow = 'auto';
    });

    // Fechar modal ao clicar fora da imagem
    modal.addEventListener('click', function(e) {
        if (e.target === modal) {
            modal.classList.remove('active');
            document.body.style.overflow = 'auto';
        }
    });

    // Fechar modal com tecla ESC
    document.addEventListener('keydown', function(e) {
        if (e.key === 'Escape' && modal.classList.contains('active')) {
            modal.classList.remove('active');
            document.body.style.overflow = 'auto';
        }
    });
}

// Controlar vídeo de assinatura
const assinaturaVideo = document.getElementById('assinatura-video');
if (assinaturaVideo) {
    assinaturaVideo.addEventListener('ended', function() {
        this.currentTime = this.duration;
        this.pause();
    });
}
