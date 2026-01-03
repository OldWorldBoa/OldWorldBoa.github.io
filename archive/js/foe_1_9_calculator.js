var selected_gb_data = undefined;
var selected_level = "0";

$(document).ready( function() {
  $("#gbs").on("change paste keyup", function(e) {
    $("#current_level").val(selected_level);

    getGreatBuildingJson(e.target.value, (e) => {
      selected_gb_data = e;
      updateForgePointRewards();
    });
  });

  $("#current_level").on("change paste keyup", function(e) {
    selected_level = e.target.value;
    updateForgePointRewards();
  });

  $('#first_place_fps, #second_place_fps, #third_place_fps, #fourth_place_fps, #fifth_place_fps').on(
    "change paste keyup",
    (e) => {
      calculate();
    });
});

function updateForgePointRewards() {
  if (selected_gb_data) {
    selected_gb_data.forEach((e) => {
      if (e.Level === selected_level) {
        var firstPlace = e.FirstPlace.replace(',', '');
        var required = e.Required.replace(',', '');

        $('#total_fps').val(required);
        $('#first_place_fps').val(firstPlace);
        $('#second_place_fps').val(Math.round((firstPlace/2)/5)*5);
        $('#third_place_fps').val(Math.round((firstPlace/6)/5)*5);
        $('#fourth_place_fps').val(Math.round(($('#third_place_fps').val()/4)/5)*5);
        $('#fifth_place_fps').val(Math.round(($('#fourth_place_fps').val()/5)/5)*5);
      }
    });

    calculate();
  }
}

function calculate() {
  let first_place_fps = getAndProcessFps("first");
  let second_place_fps = getAndProcessFps("second");
  let third_place_fps = getAndProcessFps("third");
  let fourth_place_fps = getAndProcessFps("fourth");
  let fifth_place_fps = getAndProcessFps("fifth");

  let leftover_fps = $("#total_fps").val() - (first_place_fps + second_place_fps + third_place_fps + fourth_place_fps + fifth_place_fps);

  $("#output").html(leftover_fps.toString());
}

function getAndProcessFps(place) {
    let place_fps = Math.ceil($(`#${place}_place_fps`).val() * 1.9);

    if (place_fps === 0) {
      place_fps = 1;
    }

    $(`#${place}_place_fps_result`).html(`= ${place_fps}`);

    return place_fps;
}

function getGreatBuildingJson(name, callback) {
    Papa.parse(`./assets/gbs_csv/${name}.csv`, {
        download: true,
        header: true,
        complete: (result) => {
          if (result.errors.length > 0) {
              console.log(result.errors);
          }

          callback(result.data)
        }
    })
}
