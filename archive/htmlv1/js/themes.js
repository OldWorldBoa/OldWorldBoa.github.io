$(document).ready(function() {
  setTheme(Cookies.get('theme'));

  $("body").on('click', '.theme-option', function(e) {
    setTheme($(e.target).data('value'));
  });
});

function setTheme(theme) {
  if (theme === undefined) {
    theme = 'default-theme';
  }

  Cookies.set('theme', theme);

  if (!$("body").hasClass(theme)) {
    $("body").removeClass();
    $("body").addClass(theme);
  }
}
