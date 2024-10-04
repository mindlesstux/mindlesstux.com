import { Elm } from './Main.elm'

function initComments(config) {
  // get nullable session object from localstorage
  config['storedSession'] = JSON.parse(localStorage.getItem("cactus-session"));

  // get node from the config
  // remove it from config object before passing to elm
  var node = config['node']
  delete config['node']

  // if node is string, use query selector to find dom node
  if (typeof(node) == "string") {
    node = document.querySelector(node);
  }

  // make a comments section in DOM element `node`
  // initialize with provided config
  var app = Elm.Main.init({
    node: node,
    flags: config
  });

  // subscribe to commands from localstorage port
  app.ports.storeSession.subscribe(s => localStorage.setItem("cactus-session", s));
}

// Allow specifying config using data-* attributes on the script tag
// The script tag will be replaced by Cactus Comments box
if (document.currentScript?.dataset?.defaultHomeserverUrl) {
  initComments(Object.assign({
    node: document.currentScript
  }, document.currentScript.dataset));
}

window.initComments = initComments;
