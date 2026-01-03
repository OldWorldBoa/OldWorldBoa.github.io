var radius = 250;

$(document).ready(function() {
  createPath(radius, radius, radius, 0, "origin");
  createCircle(radius, radius, "center");
  createCircle(2*radius, radius, "end");
  createDataInputs();

  $("#target-geometry").on("change", function() {
    createDataInputs();
  });

  $(document).on('change', '.target-angle', function(e) {
    drawGeometry();
  });
});

function drawGeometry() {
  var selected = $('#target-geometry').find(":selected").text();

  switch(selected.toLowerCase()) {
    case "angle":
      drawAngle();
      break;
    case "triangle":
      drawTriangle();
      break;
    default:
      drawAngle();
      break;
  }
}

function drawAngle() {
  let target_angle = parseInt($("#target-angle-1").val());

  if (isNaN(target_angle)) {
    console.log(`${target_angle} is not a number.`);
  } else {
    console.log(`${target_angle} is a number.`);

    let dx = Math.cos(degToRad(target_angle));
    let dy = Math.sin(degToRad(target_angle));

    createPath(radius, radius, radius * dx, radius * -dy, "angle-line");
  }
}

function drawTriangle() {
  let target_angle_1 = parseInt($("#target-angle-1").val());
  let target_angle_2 = parseInt($("#target-angle-2").val());

  if (isNaN(target_angle_1) || isNaN(target_angle_2)) {
    console.log(`${target_angle_1} or ${target_angle_2} is not a number.`);
  } else if (target_angle_1 + target_angle_2 >= 180) {
    alert('The combined angles must be under 180 degrees.');
  } else {
    // Law of sines: lengthA/sin(angleA) = lengthB/sin(angleB) = lengthC/sin(angleC)
    let length_a = radius;
    let angle_a = 180 - target_angle_1 - target_angle_2;

    let angle_b = target_angle_2;
    let length_b = (length_a/Math.sin(degToRad(angle_a)))*Math.sin(degToRad(angle_b));

    let angle_c = target_angle_1;

    let dx = Math.cos(degToRad(angle_c))*length_b;
    let dy = Math.sin(degToRad(angle_c))*length_b;

    let point_3_x = radius + dx;
    let point_3_y = radius - dy;

    createCircle(point_3_x, point_3_y, "tip");
    createPath(radius, radius, dx, -dy, "angle-line-1");
    createPath(2*radius, radius, point_3_x - 2*radius, -dy, "angle-line-2");
  }
}

function createCircle(x_center, y_center, id) {
  $(`#${id}`).remove();

  var circle = document.createElementNS("http://www.w3.org/2000/svg", 'circle'); //Create a path in SVG's namespace
  $(circle).attr("id", id);
  $(circle).attr("cx", x_center);
  $(circle).attr("cy", y_center);
  $(circle).attr("r", "2");

  $("#geometry-display").append(circle);
}

function createPath(start_x, start_y, length_x, length_y, id, width="3px") {
  var center = radius;

  $(`#${id}`).remove();

  var newElement = document.createElementNS("http://www.w3.org/2000/svg", 'path'); //Create a path in SVG's namespace
  $(newElement).attr("id", id);
  newElement.setAttribute("d",`M ${start_x} ${start_y} L ${start_x + length_x} ${start_y + length_y}`); //Set path's data
  newElement.style.stroke = "#000"; //Set stroke colour
  newElement.style.strokeWidth = width; //Set stroke width
  $("#geometry-display").append(newElement);
}

function degToRad(deg) {
  return deg * Math.PI / 180;
}

function createDataInputs() {
  var num_sides = getNumSidesForGeometry();

  $("#data-inputs").html("");

  for (var i = 1; i <= num_sides; i++) {
    var container = $('<div/>');
    $('<label/>', {text: `Angle ${i}`}).appendTo(container);

    $('<input/>', {
      id: `target-angle-${i}`,
      class: 'target-angle',
      type: 'text',
      name: 'target angle'
    }).appendTo(container);

    container.appendTo("#data-inputs");
  }
}

function getNumSidesForGeometry() {
  var selected = $('#target-geometry').find(":selected").text();
  var num_sides = 1;

  switch(selected.toLowerCase()) {
    case "angle":
      num_sides = 1;
      break;
    case "triangle":
      num_sides = 2;
      break;
    default:
      num_sides = 1;
      break;
  }

  return num_sides;
}