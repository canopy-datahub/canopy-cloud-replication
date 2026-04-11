(function () {
    var backLink = document.createElement('a');
    backLink.id = 'canopy-back-link';
    backLink.href = '/';
    backLink.textContent = '\u2190 Back to Canopy Main Page';

    var container = document.querySelector('.login-pf-page');
    if (container) {
        container.appendChild(backLink);
    }
})();
