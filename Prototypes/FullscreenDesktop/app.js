const variants = [
  { key: "A", name: "胡桃木唱机" },
  { key: "B", name: "黑曜石唱台" },
  { key: "C", name: "唱片内页" },
];

const scenes = Array.from(document.querySelectorAll("[data-variant]"));
const label = document.querySelector("#variant-label");

function currentKey() {
  const key = new URLSearchParams(window.location.search).get("variant")?.toUpperCase();
  return variants.some((variant) => variant.key === key) ? key : "A";
}

function render(key) {
  const variant = variants.find((item) => item.key === key) ?? variants[0];
  scenes.forEach((scene) => {
    scene.hidden = scene.dataset.variant !== variant.key;
  });
  label.textContent = `${variant.key} — ${variant.name}`;
  document.title = `CloudPlatter 原型 ${variant.key} — ${variant.name}`;
}

function selectOffset(offset) {
  const index = variants.findIndex((variant) => variant.key === currentKey());
  const next = variants[(index + offset + variants.length) % variants.length];
  const url = new URL(window.location.href);
  url.searchParams.set("variant", next.key);
  window.history.replaceState({}, "", url);
  render(next.key);
}

document.querySelector("[data-direction='previous']").addEventListener("click", () => selectOffset(-1));
document.querySelector("[data-direction='next']").addEventListener("click", () => selectOffset(1));

window.addEventListener("keydown", (event) => {
  if (event.key === "ArrowLeft") selectOffset(-1);
  if (event.key === "ArrowRight") selectOffset(1);
});

window.addEventListener("popstate", () => render(currentKey()));
render(currentKey());
