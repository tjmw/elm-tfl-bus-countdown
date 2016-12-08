import $ from "jquery";
import "signalr";
import "./tflHubs";

import Elm from './Main.elm'

const elmDiv = document.querySelector("#main");
const elmApp = Elm.Main.embed(elmDiv);

$.connection.hub.url = "https://push-api.tfl.gov.uk/signalr/hubs/signalr";

const hub = $.connection.predictionsRoomHub;
window.hub = hub;

elmApp.ports.registerForLivePredictions.subscribe(function(naptanId) {
  $.connection.hub.start().done(function() {
    const lineRooms = [{ "NaptanId": naptanId }];
    console.log("Registering for updates: " + naptanId);
    hub.server.addLineRooms(lineRooms)
  });
});

// Push notification callback
hub.client.showPredictions = predictions => {
  console.log(predictions);
  elmApp.ports.predictions.send(predictions);
}

elmApp.ports.deregisterFromLivePredictions.subscribe(function(naptanId) {
  const lineRooms = [{ "NaptanId": naptanId }];
  console.log("Deregistering for updates: " + naptanId);
  hub.server.removeLineRooms(lineRooms);
})

elmApp.ports.requestGeoLocation.subscribe(() => {
  if ("geolocation" in navigator) {
    navigator.geolocation.getCurrentPosition((position) => {
      const geoLocation = {
        lat: position.coords.latitude,
        long: position.coords.longitude
      }

      console.log(geoLocation);

      elmApp.ports.geoLocation.send(geoLocation);
    });
  } else {
    console.log("Geo location not available");
  }
});
