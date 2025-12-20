// If you want to use Phoenix channels, run `mix help phx.gen.channel`
// to get started and then uncomment the line below.
// import "./user_socket.js"

// You can include dependencies in two ways.
//
// The simplest option is to put them in assets/vendor and
// import them using relative paths:
//
//     import "../vendor/some-package.js"
//
// Alternatively, you can `npm install some-package --prefix assets` and import
// them using a path starting with the package name:
//
//     import "some-package"
//
// If you have dependencies that try to import CSS, esbuild will generate a separate `app.css` file.
// To load it, simply add a second `<link>` to your `root.html.heex` file.

// Include phoenix_html to handle method=PUT/DELETE in forms and buttons.
import "phoenix_html"
// Establish Phoenix Socket and LiveView configuration.
import {Socket} from "phoenix"
import {LiveSocket} from "phoenix_live_view"
import {hooks as colocatedHooks} from "phoenix-colocated/inventory_sync"
import topbar from "../vendor/topbar"
// Sidebar persistence
const SIDEBAR_KEY = "sidebarCollapsed"
function setupSidebarPersistence() {
  const root = document.getElementById("app-root") || document.body
  const collapsed = localStorage.getItem(SIDEBAR_KEY) === "true"
  if (collapsed) root.classList.add("sidebar-collapsed")
  window.addEventListener("phx:sidebar:toggle", () => {
    const nowCollapsed = !root.classList.contains("sidebar-collapsed")
    root.classList.toggle("sidebar-collapsed", nowCollapsed)
    localStorage.setItem(SIDEBAR_KEY, String(nowCollapsed))
  })
}

// Chart Hook
const SyncChart = {
  mounted() {
    this.renderChart(JSON.parse(this.el.dataset.points))
    this.handleEvent("update_chart", ({points}) => {
      this.renderChart(points)
    })
  },
  updated() {
    this.renderChart(JSON.parse(this.el.dataset.points))
  },
  renderChart(points) {
    const ctx = this.el.getContext('2d')
    if (this.chart) this.chart.destroy()
    
    this.chart = new Chart(ctx, {
      type: 'bar',
      data: {
        labels: points.map(p => p.label),
        datasets: [{
          label: 'Sync Events',
          data: points.map(p => p.value),
          backgroundColor: '#4f46e5',
          borderRadius: 4
        }]
      },
      options: {
        responsive: true,
        maintainAspectRatio: false,
        plugins: {
          legend: { display: false }
        },
        scales: {
          y: { beginAtZero: true, grid: { display: false } },
          x: { grid: { display: false } }
        }
      }
    })
  }
}

const csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content")
const liveSocket = new LiveSocket("/live", Socket, {
  longPollFallbackMs: 2500,
  params: {_csrf_token: csrfToken},
  hooks: {...colocatedHooks, SyncChart},
})

// Show progress bar on live navigation and form submits
topbar.config({barColors: {0: "#29d"}, shadowColor: "rgba(0, 0, 0, .3)"})
window.addEventListener("phx:page-loading-start", _info => topbar.show(300))
window.addEventListener("phx:page-loading-stop", _info => topbar.hide())

// connect if there are any LiveViews on the page
liveSocket.connect()
setupSidebarPersistence()

// expose liveSocket on window for web console debug logs and latency simulation:
// >> liveSocket.enableDebug()
// >> liveSocket.enableLatencySim(1000)  // enabled for duration of browser session
// >> liveSocket.disableLatencySim()
window.liveSocket = liveSocket

// The lines below enable quality of life phoenix_live_reload
// development features:
//
//     1. stream server logs to the browser console
//     2. click on elements to jump to their definitions in your code editor
//
if (process.env.NODE_ENV === "development") {
  window.addEventListener("phx:live_reload:attached", ({detail: reloader}) => {
    // Enable server log streaming to client.
    // Disable with reloader.disableServerLogs()
    reloader.enableServerLogs()

    // Open configured PLUG_EDITOR at file:line of the clicked element's HEEx component
    //
    //   * click with "c" key pressed to open at caller location
    //   * click with "d" key pressed to open at function component definition location
    let keyDown
    window.addEventListener("keydown", e => keyDown = e.key)
    window.addEventListener("keyup", e => keyDown = null)
    window.addEventListener("click", e => {
      if(keyDown === "c"){
        e.preventDefault()
        e.stopImmediatePropagation()
        reloader.openEditorAtCaller(e.target)
      } else if(keyDown === "d"){
        e.preventDefault()
        e.stopImmediatePropagation()
        reloader.openEditorAtDef(e.target)
      }
    }, true)

    window.liveReloader = reloader
  })

  // Minimal UI unit tests (development only)
  try {
    const assert = (name, cond) => console[(cond ? "log" : "error")](`UI Test: ${name} -> ${cond ? "PASS" : "FAIL"}`)
    const root = document.getElementById("app-root") || document.body
    const initial = root.classList.contains("sidebar-collapsed")
    window.dispatchEvent(new CustomEvent("phx:sidebar:toggle"))
    assert("Sidebar toggles class", root.classList.contains("sidebar-collapsed") !== initial)
  } catch (_) { /* no-op */ }
}
