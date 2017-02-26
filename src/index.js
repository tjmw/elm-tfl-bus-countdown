import $ from "jquery";
import "signalr";
import "./tflHubs";

import "./index.html";
import Elm from './Main.elm'

if (!window.location.host.match(/^localhost/) && window.location.protocol != "https:") {
  window.location.protocol = "https:"
}

const elmDiv = document.querySelector("#main");
const elmApp = Elm.Main.embed(elmDiv, {
  tfl_app_id: process.env.TFL_APP_ID,
  tfl_app_key: process.env.TFL_APP_KEY
});

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
  console.log("🚌 New predictions @", new Date().toTimeString());
  console.table(predictions, ["LineName", "VehicleId", "DestinationName", "ExpectedArrival", "TimeToLive", "Id"]);
  elmApp.ports.predictions.send(predictions);
}

elmApp.ports.deregisterFromLivePredictions.subscribe(function(naptanId) {
  const lineRooms = [{ "NaptanId": naptanId }];
  console.log("Deregistering for updates: " + naptanId);
  hub.server.removeLineRooms(lineRooms);
})

elmApp.ports.requestGeoLocation.subscribe(() => {
  const success = (position) => {
    const geoLocation = {
      lat: position.coords.latitude,
      long: position.coords.longitude
    }

    console.log(geoLocation);

    elmApp.ports.geoLocation.send(geoLocation);
  };

  const error = () => {
    elmApp.ports.geoLocationUnavailable.send("");
  };

  const options = {
    timeout: 5000
  };

  if ("geolocation" in navigator) {
    navigator.geolocation.getCurrentPosition(success, error, options);
  } else {
    error();
  }
});
