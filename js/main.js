"use strict";

const navbarHeight = document.getElementById("navbar").offsetHeight;

document.addEventListener("DOMContentLoaded", function () {

  // Navbar

  var setNavbarVisibility = function setNavbarVisibility() {
    var navbar = document.getElementById("navbar");

    if (!navbar) {
      return;
    }

    var cs = getComputedStyle(navbar);
    var paddingX = parseFloat(cs.paddingLeft) + parseFloat(cs.paddingRight);
    var brand = navbar.querySelector(".navbar-brand");
    var end = navbar.querySelector(".navbar-end");
    var search = navbar.querySelector(".bd-search");
    var original = document.getElementById("navbarStartOriginal");
    var clone = document.getElementById("navbarStartClone");
    var rest = navbar.clientWidth - paddingX - brand.clientWidth - end.clientWidth;

    var space = original.clientWidth;
    var all = document.querySelectorAll("#navbarStartClone > .bd-navbar-item");
    var base = document.querySelectorAll("#navbarStartClone > .bd-navbar-item-base");
    var more = document.querySelectorAll("#navbarStartOriginal > .bd-navbar-item-more");
    var dropdown = document.querySelectorAll("#navbarStartOriginal .bd-navbar-dropdown > .navbar-item");

    var count = 0;
    var totalWidth = 0;

    var showMore = function showMore() {};

    var hideMore = function hideMore() {};

    var _iteratorNormalCompletion = true;
    var _didIteratorError = false;
    var _iteratorError = undefined;

    try {
      for (var _iterator = all[Symbol.iterator](), _step; !(_iteratorNormalCompletion = (_step = _iterator.next()).done); _iteratorNormalCompletion = true) {
        var item = _step.value;

        totalWidth += item.offsetWidth;

        if (totalWidth > rest) {
          break;
        }

        count++;
      }
    } catch (err) {
      _didIteratorError = true;
      _iteratorError = err;
    } finally {
      try {
        if (!_iteratorNormalCompletion && _iterator.return) {
          _iterator.return();
        }
      } finally {
        if (_didIteratorError) {
          throw _iteratorError;
        }
      }
    }

    var howManyMore = Math.max(0, count - base.length);

    if (howManyMore > 0) {
      for (var i = 0; i < howManyMore; i++) {
        more[i].classList.add("bd-is-visible");
        dropdown[i].classList.add("bd-is-hidden");
      }
    }

    for (var j = howManyMore; j < more.length; j++) {
      more[j].classList.remove("bd-is-visible");
    }

    for (var k = howManyMore; k < dropdown.length; k++) {
      dropdown[k].classList.remove("bd-is-hidden");
    }
  };

  setNavbarVisibility();

  // Dropdowns

  var $dropdowns = getAll(".dropdown:not(.is-hoverable)");

  if ($dropdowns.length > 0) {
    $dropdowns.forEach(function ($el) {
      $el.addEventListener("click", function (event) {
        event.stopPropagation();
        $el.classList.toggle("is-active");
      });
    });

    document.addEventListener("click", function (event) {
      closeDropdowns();
    });
  }

  function closeDropdowns() {
    $dropdowns.forEach(function ($el) {
      $el.classList.remove("is-active");
    });
  }

  // Toggles

  var $burgers = getAll(".navbar-burger");

  if ($burgers.length > 0) {
    $burgers.forEach(function ($el) {
      if (!$el.dataset.target) {
        return;
      }
      $el.addEventListener("click", function () {
        var target = $el.dataset.target;
        var $target = document.getElementById(target);
        $el.classList.toggle("is-active");
        $target.classList.toggle("is-active");
      });
    });
  }

  // Modals

  var rootEl = document.documentElement;
  var $modals = getAll(".modal");
  var $modalButtons = getAll(".modal-button");
  var $modalCloses = getAll(".modal-background, .modal-close, .modal-card-head .delete, .modal-card-foot .button");

  if ($modalButtons.length > 0) {
    $modalButtons.forEach(function ($el) {
      $el.addEventListener("click", function () {
        var target = $el.dataset.target;
        openModal(target);
      });
    });
  }

  if ($modalCloses.length > 0) {
    $modalCloses.forEach(function ($el) {
      $el.addEventListener("click", function () {
        closeModals();
      });
    });
  }

  function openModal(target) {
    var $target = document.getElementById(target);
    rootEl.classList.add("is-clipped");
    $target.classList.add("is-active");
  }

  function closeModals() {
    rootEl.classList.remove("is-clipped");
    $modals.forEach(function ($el) {
      $el.classList.remove("is-active");
    });
  }

  document.addEventListener("keydown", function (event) {
    var e = event || window.event;

    if (e.keyCode === 27) {
      closeModals();
      closeDropdowns();
    }
  });

  // Scrolling
  var $scrollitems = getAll(".scroll");

  if ($scrollitems.length > 0) {
    $scrollitems.forEach(function ($el) {
      $el.addEventListener("click", e => {
        var target = $el.dataset.target;
        e.preventDefault();
        window.scroll({ 
          behavior: 'smooth', 
          left: 0, 
          top: document.getElementById(target).getBoundingClientRect().top - navbarHeight + window.scrollY 
        });
      }, { passive: true });
    });
  }

  // Events

  var resizeTimer = void 0;

  function handleResize() {
    window.clearTimeout(resizeTimer);

    resizeTimer = window.setTimeout(function () {
      setNavbarVisibility();
    }, 200);
  }

  window.addEventListener("resize", handleResize, { passive: true });

  // Tabs
  const TABS = [...document.querySelectorAll('#tabs li')];
  const CONTENT = [...document.querySelectorAll('#tab-content div')];
  const ACTIVE_CLASS = 'is-active';

  function initTabs() {
      TABS.forEach((tab) => {
        tab.addEventListener('click', (e) => {
          let selected = tab.getAttribute('data-tab');
          updateActiveTab(tab);
          updateActiveContent(selected);
        })
      })
  }

  function updateActiveTab(selected) {
    TABS.forEach((tab) => {
      if (tab && tab.classList.contains(ACTIVE_CLASS)) {
        tab.classList.remove(ACTIVE_CLASS);
      }
    });
    selected.classList.add(ACTIVE_CLASS);
  }

  function updateActiveContent(selected) {
    CONTENT.forEach((item) => {
      if (item && item.classList.contains(ACTIVE_CLASS)) {
        item.classList.remove(ACTIVE_CLASS);
      }
      let data = item.getAttribute('data-content');
      if (data === selected) {
        item.classList.add(ACTIVE_CLASS);
      }
    });
  }

  initTabs();

  // Utils

  function getAll(selector) {
    var parent = arguments.length > 1 && arguments[1] !== undefined ? arguments[1] : document;

    return Array.prototype.slice.call(parent.querySelectorAll(selector), 0);
  }

  var tab = document.getElementById(window.location.search.substr(1))
  if (tab) {
    let selected = tab.getAttribute('data-tab');
    updateActiveTab(tab);
    updateActiveContent(selected);
  }
});
