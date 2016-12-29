var webpack = require("webpack");
var CopyWebpackPlugin = require('copy-webpack-plugin');
var dotenv = require('dotenv').config();

module.exports = {
  context: __dirname + "/src",
  entry: {
    javascript: "./index.js",
    html: "./index.html"
  },
  output: {
    filename: "app.js",
    path: __dirname + "/dist",
  },
  module: {
    loaders: [
      {
        test: /\.js$/,
        exclude: /node_modules/,
        presets: ["es2015"],
        loaders: ["babel-loader"],
      },
      {
        test: /\.html$/,
        loader: "file?name=[name].[ext]",
      },
      {
        test:    /\.elm$/,
        exclude: [/elm-stuff/, /node_modules/],
        loader:  'elm-webpack',
      },
      {
        test: /\.woff(2)?(\?v=[0-9]\.[0-9]\.[0-9])?$/,
        loader: 'url-loader?limit=10000&mimetype=application/font-woff',
      },
      {
        test: /\.(ttf|eot|svg)(\?v=[0-9]\.[0-9]\.[0-9])?$/,
        loader: 'file-loader',
      },
    ],

    noParse: /\.elm$/,
  },
  plugins: [
    new webpack.ProvidePlugin({
      $: "jquery",
      jQuery: "jquery",
      "window.$": "jquery",
      "window.jQuery": "jquery"
    }),
    new CopyWebpackPlugin([
      { from: 'css/main.css', to: "css/main.css" },
      { from: 'css/pure-min.css', to: "css/pure-min.css" }
    ]),
    new webpack.EnvironmentPlugin(["TFL_APP_ID", "TFL_APP_KEY"])
  ]
};
