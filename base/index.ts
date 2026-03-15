type ElmPagesInit = {
	load: (elmLoaded: Promise<unknown>) => Promise<void>;
	flags: unknown;
};

const config: ElmPagesInit = {
	load: async function (elmLoaded) {
		const app = await elmLoaded;
		console.log("App loaded", app);

		var app = Elm.Main.init({
			node: document.getElementById("app"),
			flags: {}
		});

		app.ports.setContractions.subscribe(function(state) {
			localStorage.setItem('owb-contractions', JSON.stringify(state));
		});

		app.ports.loadContractions.send(JSON.parse(localStorage.getItem('owb-contractions')));
	},
	flags: function () {
		return "You can decode this in Shared.elm using Json.Decode.string!";
	},
};

export default config;
