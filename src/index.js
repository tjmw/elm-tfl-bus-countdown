import $ from "jquery";
import "signalr";
import "./tflHubs";

import Elm from './Main.elm'

const elmDiv = document.querySelector("#main");
const elmApp = Elm.Main.embed(elmDiv);

$.connection.hub.url = "https://push-api.tfl.gov.uk/signalr/hubs/signalr";

const hub = $.connection.predictionsRoomHub;

elmApp.ports.registerForLivePredictions.subscribe(function(naptanId) {
  $.connection.hub.start().done(function() {
    const lineRooms = [{ "NaptanId": naptanId }];
    hub.server.addLineRooms(lineRooms)
  });
});

elmApp.ports.requestGeoLocation.subscribe(() => {
  if ("geolocation" in navigator) {
    navigator.geolocation.getCurrentPosition((position) => {
      const geoLocation = {
        lat: position.coords.latitude,
        long: position.coords.longitude
      }

      console.log(geoLocation);

      elmApp.ports.geoLocation.send(JSON.stringify(geoLocation));
    });
  } else {
    console.log("Geo location not available");
  }
});

// Push notification callback
hub.client.showPredictions = predictions => {
  console.log(predictions);
  elmApp.ports.predictions.send(predictions);
}
