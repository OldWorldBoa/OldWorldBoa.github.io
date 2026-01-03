// from: http://stackoverflow.com/questions/901115/how-can-i-get-query-string-values-in-javascript
var isMenuOpen = false;
var menuButtonHeight = "";


function getParameterByName(name, url) {
    if (!url) url = window.location.href;
    
    name = name.replace(/[\[\]]/g, "\\$&");
    var regex = new RegExp("[?&]" + name + "(=([^&#]*)|&|#|$)"),
        results = regex.exec(url);

    if (!results || !results[2]) return 'about';

    return decodeURIComponent(results[2].replace(/\+/g, " "));
}

function ToggleMenu() {
  $pm = $(".phone-menu");
  menuButtonHeight = $(".menu-circle").css("height");

  if(isMenuOpen) {
    $(".phone-menu").animate({height: menuButtonHeight}, 200);
    isMenuOpen = false;
  } else {
    menuHeight = parseInt(menuButtonHeight) * 5;
    $(".phone-menu").animate({height: menuHeight + "px"}, 200);
    isMenuOpen = true;
  }
}

function InitialLoadPage() {
  LoadPage(getParameterByName("type"));
}

function PreviousLoadPage() {
  LoadPage(getParameterByName("type"), false);
}

function LoadPage(type, addHistory=true) {
  if (addHistory) {
    window.history.pushState({type: type}, type, `?type=${type}`);
  }

  $.get(
    GetPageUrl(type),
    function(data) {
      $("#main-view").html(data);
    });
}

function GetPageUrl(type) {
  switch(type) {
    case "about":
      contentUrl = "./pages/about.html";
      break;
    case "portfolio":
      contentUrl = "./pages/portfolio.html";
      break;
    case "contact":
      contentUrl = "./pages/contact.html";
      break;
    case "foe-1-9-calculator":
      contentUrl = "./pages/foe_1_9_calculator.html";
      break;
    case "settings":
      contentUrl = "./pages/settings.html";
      break;
    case "stock-ticker":
      contentUrl = "./pages/stock-ticker.html";
      break;
    case "svg-text-outliner":
      contentUrl = "./pages/svg-text-outliner.html";
      break;
     case "geometry-drawer":
       contentUrl=  "./pages/geometry-drawer.html";
       break;
    default:
      contentUrl = "./pages/about.html";
      break;
  }

  return contentUrl;
}

$(document).ready( function() {
  InitialLoadPage();

  $(".menu-open").on("tap click", function(e) { ToggleMenu(); });
  
  $("#menu").on("mouseleave", function(e) {
    if(isMenuOpen) {
      ToggleMenu();
    }
  });

  $("body").on("tap click", function(e) {
    if(isMenuOpen && 
       e.target.className != "menu-img-button" &&
       e.target.className != "menu-open") {
      ToggleMenu();
    }
  });

  $(".about").on("tap click", function(e) { LoadPageIfRequired("about"); });

  $(".portfolio").on("tap click", function(e) { LoadPageIfRequired("portfolio"); });

  $(".settings").on("tap click", function(e) { LoadPageIfRequired("settings"); });

  $(".contact").on("tap click", function(e) { LoadPageIfRequired("contact"); });

  $("body").on("tap click", ".foe-1-9-calculator", function(e) { LoadPageIfRequired("foe-1-9-calculator"); });

  $("body").on("tap click", ".stock-ticker", function(e) { LoadPageIfRequired("stock-ticker"); });
  
  $("body").on("tap click", ".svg-text-outliner", function(e) { LoadPageIfRequired("svg-text-outliner"); });

  $("body").on("tap click", ".geometry-drawer", function(e) { LoadPageIfRequired("geometry-drawer")});

  $(window).on('popstate', function(e) {
    PreviousLoadPage();
  });
});

function LoadPageIfRequired(type) {
  if (getParameterByName("type") !== type) {
    LoadPage(type);
  }

  ToggleMenu();
}