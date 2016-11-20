import $ from "jquery";
import "signalr";
import "./tflHubs";

import Elm from './Main.elm'

$.connection.hub.url = "https://push-api.tfl.gov.uk/signalr/hubs/signalr";

var hub = $.connection.predictionsRoomHub;

// Push notification callback
hub.client.showPredictions = console.log;

$.connection.hub.start().done(function() {
  // Hardcode stop for now
  var lineRooms = [{ "NaptanId": "490003989Z" }];
  hub.server.addLineRooms(lineRooms)
});


const elmDiv = document.querySelector("#main");
const elmApp = Elm.Main.embed(elmDiv);
