const config = {
  load: async function (elmLoaded) {
    const app = await elmLoaded;
    console.log("App loaded", app);

    app.ports.setContractions.subscribe(function (state) {
      localStorage.setItem("owb-contractions", JSON.stringify(state));
    });

    app.ports.loadContractions.send(localStorage.getItem("owb-contractions"));

    app.ports.initializeMermad.subscribe(function () {
      console.log("JS: Initialize Mermaid.");
      mermaid.init();
    });
  },
  flags: function () {
    return "You can decode this in Shared.elm using Json.Decode.string!";
  },
};
export default config;
