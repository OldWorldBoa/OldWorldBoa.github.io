$(document).ready(function() {
  updateOutputColors();

  $("#outliner-text-input").on("keyup change", function(e) {
    updateTextToOutline();
   });

  $("#outline-color").on("change", function(e) {
    updateOutputColors()
  });

  $("#background-color").on("change", function(e) {
    updateOutputColors()
  });
});

function updateTextToOutline() {
  let newText = $("#outliner-text-input").val();
  let lines = newText.split("\n");

  $("#outliner-output-container").html("");

  let svgElement = document.createElement("svg");

  for (var i = 0; i < lines.length; i++) {
    console.log(lines[i]);

    let textElement = document.createElement("text");
    textElement.setAttribute("x", "5");
    textElement.setAttribute("y", 30*i);
    textElement.innerHTML = lines[i];

    $("#outliner-output-container").append(textElement);
  }

  $("#outliner-output-container").html($("#outliner-output-container").html());
  updateOutputColors();
}

function updateOutputColors() {
  let outlineColor = $("#outline-color").val();
  let backgroundColor = $("#background-color").val();

  $("#outliner-output-container").css("background-color", backgroundColor);
  $("#outliner-output-container text").css("stroke", outlineColor);
}