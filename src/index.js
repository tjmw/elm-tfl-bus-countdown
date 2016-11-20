import $ from "jquery";
import "signalr";
import "./tflHubs";

import Elm from './Main.elm'

const elmDiv = document.querySelector("#main");
const elmApp = Elm.Main.embed(elmDiv);

$.connection.hub.url = "https://push-api.tfl.gov.uk/signalr/hubs/signalr";

const hub = $.connection.predictionsRoomHub;

// Push notification callback
hub.client.showPredictions = predictions => {
  const predictionStrings = predictions.map( p => {
    return p["LineName"] + ": " + p["DestinationName"] + " (" + p["TimeToStation"] + ")";
  });

  console.log(predictions);
  elmApp.ports.predictions.send(predictionStrings);
}

$.connection.hub.start().done(function() {
  // Hardcode stop for now
  const lineRooms = [{ "NaptanId": "490003989Z" }];
  hub.server.addLineRooms(lineRooms)
});
