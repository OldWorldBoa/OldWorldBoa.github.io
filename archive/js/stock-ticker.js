$(document).ready(function() {
	$.get(
    "./pages/ticker.html",
    function(data) {
      $("#stock-ticker-container").html(data);
    });
});