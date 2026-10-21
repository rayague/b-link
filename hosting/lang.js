// Bascule français / anglais : langue du navigateur par défaut, choix mémorisé.
(function () {
  function apply(lang) {
    document.documentElement.lang = lang;
    document.querySelectorAll('[data-' + lang + ']').forEach(function (el) {
      el.textContent = el.getAttribute('data-' + lang);
    });
    // Sections entières propres à une langue (pages longues).
    document.querySelectorAll('[data-only]').forEach(function (el) {
      el.hidden = el.getAttribute('data-only') !== lang;
    });
  }
  var saved = null;
  try { saved = localStorage.getItem('lang'); } catch (e) {}
  var lang = saved || ((navigator.language || 'fr').toLowerCase().indexOf('fr') === 0 ? 'fr' : 'en');
  apply(lang);
  document.querySelectorAll('[data-set-lang]').forEach(function (a) {
    a.addEventListener('click', function (e) {
      e.preventDefault();
      var l = a.getAttribute('data-set-lang');
      try { localStorage.setItem('lang', l); } catch (err) {}
      apply(l);
    });
  });
})();
