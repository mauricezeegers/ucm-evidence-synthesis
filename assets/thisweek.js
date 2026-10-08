// Marks the current week (elements with data-start/data-end) and past deadlines (data-due).
(function () {
  var today = new Date().toISOString().slice(0, 10);
  document.querySelectorAll("[data-start][data-end]").forEach(function (el) {
    if (el.dataset.start <= today && today <= el.dataset.end) el.classList.add("current");
  });
  var now = new Date();
  document.querySelectorAll("[data-due]").forEach(function (el) {
    if (new Date(el.dataset.due) < now) el.classList.add("past");
  });
})();
