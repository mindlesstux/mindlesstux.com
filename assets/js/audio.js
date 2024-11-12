// get the button
const audioBtn = document.querySelector(".audio-block");
// set the default state of the button
let isPlaying = false;
// get the default title of the tab (so we can change it later)
let defaultTabTitle = document.title;
// check if speechSynthesis is available in the browser
const isSynthAvailable = window.speechSynthesis !== undefined;
// if speechSynthesis is not available, hide the button
if (!isSynthAvailable) {
  audioBtn.style.display = "none";
}
// speak the text passed in as a parameter, and call the onend function when the speech is finished
function speak(text, onend) {
  window.speechSynthesis.cancel();
  var ssu = new SpeechSynthesisUtterance(text);
  window.speechSynthesis.speak(ssu);
  function _wait() {
    if (!window.speechSynthesis.speaking) {
      onend();
      return;
    }
    window.setTimeout(_wait, 200);
  }
  _wait();
}

// get the text from the blog post
function getBlogText() {
  const text = document.querySelectorAll(".content > *");
  let textArray = [];
  text.forEach((elem) => {
    textArray.push(elem.innerText);
  });
  // remove "Copy" from the start of the text
  textArray.forEach((elem, index) => {
    // if the text starts with "Copy", remove it
    if (elem.startsWith("Copy")) textArray[index] = elem.replace("Copy\n", "");
  });
  return textArray.join("\n");
}
// add click event listener to the button
audioBtn.addEventListener("click", () => {
  isPlaying = !isPlaying;
  if (isPlaying) {
    let text = getBlogText();
    speak(text, () => {
      isPlaying = false;
      audioBtn.classList.remove("active");
    });
  } else {
    window.speechSynthesis.cancel();
  }
  audioBtn.classList.toggle("active");
});

// stop audio when user navigates away from the page
window.addEventListener("beforeunload", () => {
  window.speechSynthesis.cancel();
});

// change title of the tab when audio is playing (to show that audio is playing)
window.setInterval(() => {
  if (isPlaying) {
    document.title = "🔊 Playing... " + defaultTabTitle;
  } else {
    document.title = defaultTabTitle;
  }
}, 500);