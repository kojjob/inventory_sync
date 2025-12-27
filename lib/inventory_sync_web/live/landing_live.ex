defmodule InventorySyncWeb.LandingLive do
  use InventorySyncWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:pricing_period, "monthly")
     |> assign(:active_faq, nil)}
  end

  @impl true
  def handle_event("toggle_pricing", %{"period" => period}, socket) do
    {:noreply, assign(socket, :pricing_period, period)}
  end

  @impl true
  def handle_event("toggle_faq", %{"id" => id}, socket) do
    current = socket.assigns.active_faq
    new_active = if current == id, do: nil, else: id
    {:noreply, assign(socket, :active_faq, new_active)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="overflow-hidden">
      <!-- Hero Section -->
      <section class="relative px-6 pt-16 pb-24 lg:pt-24 lg:pb-32">
        <!-- Background Effects -->
        <div class="absolute inset-0 overflow-hidden pointer-events-none">
          <div class="absolute top-0 left-1/4 w-96 h-96 bg-emerald-500/20 rounded-full blur-3xl animate-float-slow">
          </div>
          <div class="absolute top-1/4 right-1/4 w-80 h-80 bg-teal-500/15 rounded-full blur-3xl animate-float">
          </div>
          <div class="absolute bottom-0 right-1/3 w-72 h-72 bg-cyan-500/10 rounded-full blur-3xl animate-float-reverse">
          </div>
        </div>

        <div class="relative max-w-7xl mx-auto">
          <div class="grid lg:grid-cols-2 gap-12 lg:gap-16 items-center">
            <!-- Hero Content -->
            <div class="text-center lg:text-left animate-fade-in-up">
              <div class="inline-flex items-center gap-2 px-4 py-2 bg-emerald-500/10 border border-emerald-500/20 rounded-full mb-6 animate-pulse-glow">
                <span class="relative flex h-2 w-2">
                  <span class="animate-ping absolute inline-flex h-full w-full rounded-full bg-emerald-400 opacity-75">
                  </span>
                  <span class="relative inline-flex rounded-full h-2 w-2 bg-emerald-500"></span>
                </span>
                <span class="text-emerald-400 text-sm font-medium">
                  Real-time inventory synchronization
                </span>
              </div>

              <h1 class="text-4xl sm:text-5xl lg:text-6xl font-bold text-white mb-6 leading-tight tracking-tight">
                Sync Your Inventory
                <span class="block mt-2 bg-gradient-to-r from-emerald-400 via-teal-400 to-cyan-400 bg-clip-text text-transparent">
                  Across Every Channel
                </span>
              </h1>

              <p class="text-lg sm:text-xl text-slate-400 mb-8 max-w-xl mx-auto lg:mx-0 leading-relaxed">
                Our platform automatically synchronizes inventory levels across Shopify, Amazon, eBay, and more.
                Prevent overselling, reduce manual work, and scale your multi-channel business with confidence.
              </p>

              <div class="flex flex-col sm:flex-row items-center justify-center lg:justify-start gap-4">
                <.link
                  href={~p"/users/register"}
                  class="group w-full sm:w-auto inline-flex items-center justify-center px-8 py-4 bg-gradient-to-r from-emerald-500 to-teal-500 hover:from-emerald-600 hover:to-teal-600 text-white rounded-xl font-semibold text-lg transition-all shadow-lg shadow-emerald-500/25 hover:shadow-xl hover:shadow-emerald-500/40 transform hover:-translate-y-1 btn-glow"
                >
                  Get Started Free
                  <svg
                    class="w-5 h-5 ml-2 group-hover:translate-x-1 transition-transform"
                    fill="none"
                    stroke="currentColor"
                    viewBox="0 0 24 24"
                  >
                    <path
                      stroke-linecap="round"
                      stroke-linejoin="round"
                      stroke-width="2"
                      d="M17 8l4 4m0 0l-4 4m4-4H3"
                    />
                  </svg>
                </.link>
                <button class="group w-full sm:w-auto inline-flex items-center justify-center px-8 py-4 bg-slate-800/80 hover:bg-slate-700/80 text-white rounded-xl font-semibold text-lg transition-all border border-slate-700 hover:border-slate-600">
                  <svg class="w-5 h-5 mr-2 text-emerald-400" fill="currentColor" viewBox="0 0 24 24">
                    <path d="M8 5v14l11-7z" />
                  </svg>
                  Watch Demo
                </button>
              </div>
              
    <!-- Quick Stats -->
              <div class="mt-10 pt-8 border-t border-slate-700/50 grid grid-cols-3 gap-6">
                <div class="text-center lg:text-left">
                  <div class="text-2xl sm:text-3xl font-bold text-white">99.9%</div>
                  <div class="text-sm text-slate-500">Uptime SLA</div>
                </div>
                <div class="text-center lg:text-left">
                  <div class="text-2xl sm:text-3xl font-bold text-white">&lt;1s</div>
                  <div class="text-sm text-slate-500">Sync Speed</div>
                </div>
                <div class="text-center lg:text-left">
                  <div class="text-2xl sm:text-3xl font-bold text-white">5M+</div>
                  <div class="text-sm text-slate-500">SKUs Synced</div>
                </div>
              </div>
            </div>
            
    <!-- Hero Image/Dashboard Preview -->
            <div class="relative animate-fade-in-up-delay-2">
              <div class="relative z-10">
                <!-- Dashboard Mockup -->
                <div class="bg-slate-800/80 backdrop-blur-xl rounded-2xl border border-slate-700/50 shadow-2xl shadow-black/40 overflow-hidden animate-subtle-bounce glass">
                  <!-- Browser Header -->
                  <div class="flex items-center gap-2 px-4 py-3 bg-slate-900/80 border-b border-slate-700/50">
                    <div class="flex gap-1.5">
                      <div class="w-3 h-3 rounded-full bg-red-500/80"></div>
                      <div class="w-3 h-3 rounded-full bg-yellow-500/80"></div>
                      <div class="w-3 h-3 rounded-full bg-green-500/80"></div>
                    </div>
                    <div class="flex-1 mx-4">
                      <div class="bg-slate-700/50 rounded-lg px-3 py-1.5 text-xs text-slate-400 text-center">
                        app.inventorysync.com/dashboard
                      </div>
                    </div>
                  </div>
                  
    <!-- Dashboard Content -->
                  <div class="p-6">
                    <!-- Stats Row -->
                    <div class="grid grid-cols-3 gap-4 mb-6">
                      <div class="bg-slate-700/30 rounded-xl p-4 border border-slate-600/30">
                        <div class="text-emerald-400 text-2xl font-bold">2,847</div>
                        <div class="text-slate-400 text-xs mt-1">Products Synced</div>
                        <div class="mt-2 flex items-center text-xs text-emerald-400">
                          <svg class="w-3 h-3 mr-1" fill="currentColor" viewBox="0 0 20 20">
                            <path
                              fill-rule="evenodd"
                              d="M5.293 9.707a1 1 0 010-1.414l4-4a1 1 0 011.414 0l4 4a1 1 0 01-1.414 1.414L11 7.414V15a1 1 0 11-2 0V7.414L6.707 9.707a1 1 0 01-1.414 0z"
                              clip-rule="evenodd"
                            />
                          </svg>
                          12.5%
                        </div>
                      </div>
                      <div class="bg-slate-700/30 rounded-xl p-4 border border-slate-600/30">
                        <div class="text-teal-400 text-2xl font-bold">4</div>
                        <div class="text-slate-400 text-xs mt-1">Active Channels</div>
                        <div class="mt-2 flex gap-1">
                          <div class="w-5 h-5 rounded bg-green-500/20 flex items-center justify-center text-[8px] text-green-400">
                            S
                          </div>
                          <div class="w-5 h-5 rounded bg-orange-500/20 flex items-center justify-center text-[8px] text-orange-400">
                            A
                          </div>
                          <div class="w-5 h-5 rounded bg-blue-500/20 flex items-center justify-center text-[8px] text-blue-400">
                            E
                          </div>
                          <div class="w-5 h-5 rounded bg-red-500/20 flex items-center justify-center text-[8px] text-red-400">
                            Et
                          </div>
                        </div>
                      </div>
                      <div class="bg-slate-700/30 rounded-xl p-4 border border-slate-600/30">
                        <div class="text-cyan-400 text-2xl font-bold">99.8%</div>
                        <div class="text-slate-400 text-xs mt-1">Sync Success</div>
                        <div class="mt-2 h-1.5 bg-slate-600/50 rounded-full overflow-hidden">
                          <div class="h-full w-[99.8%] bg-gradient-to-r from-cyan-500 to-emerald-500 rounded-full">
                          </div>
                        </div>
                      </div>
                    </div>
                    
    <!-- Activity Chart Placeholder -->
                    <div class="bg-slate-700/20 rounded-xl p-4 border border-slate-600/30">
                      <div class="flex items-center justify-between mb-4">
                        <div class="text-sm font-medium text-white">Sync Activity</div>
                        <div class="text-xs text-slate-400">Last 7 days</div>
                      </div>
                      <div class="flex items-end gap-2 h-24">
                        <div class="flex-1 bg-gradient-to-t from-emerald-500/60 to-emerald-500/20 rounded-t h-[45%]">
                        </div>
                        <div class="flex-1 bg-gradient-to-t from-emerald-500/60 to-emerald-500/20 rounded-t h-[65%]">
                        </div>
                        <div class="flex-1 bg-gradient-to-t from-emerald-500/60 to-emerald-500/20 rounded-t h-[55%]">
                        </div>
                        <div class="flex-1 bg-gradient-to-t from-emerald-500/60 to-emerald-500/20 rounded-t h-[85%]">
                        </div>
                        <div class="flex-1 bg-gradient-to-t from-emerald-500/60 to-emerald-500/20 rounded-t h-[70%]">
                        </div>
                        <div class="flex-1 bg-gradient-to-t from-emerald-500/60 to-emerald-500/20 rounded-t h-[90%]">
                        </div>
                        <div class="flex-1 bg-gradient-to-t from-emerald-500 to-teal-500 rounded-t h-full">
                        </div>
                      </div>
                    </div>
                  </div>
                </div>
              </div>
              
    <!-- Decorative Elements -->
              <div class="absolute -top-4 -right-4 w-24 h-24 bg-gradient-to-br from-emerald-500/30 to-teal-500/30 rounded-full blur-2xl">
              </div>
              <div class="absolute -bottom-6 -left-6 w-32 h-32 bg-gradient-to-br from-cyan-500/20 to-emerald-500/20 rounded-full blur-2xl">
              </div>
            </div>
          </div>
        </div>
      </section>
      
    <!-- Trust Logos Section -->
      <section class="py-16 border-y border-slate-800">
        <div class="max-w-7xl mx-auto px-6">
          <p class="text-center text-slate-500 text-sm font-medium uppercase tracking-wider mb-8">
            Trusted by leading e-commerce businesses worldwide
          </p>
          <div class="flex flex-wrap items-center justify-center gap-8 lg:gap-16">
            <!-- Shopify -->
            <div class="group flex items-center gap-2 px-4 py-2 opacity-60 hover:opacity-100 transition-opacity">
              <svg
                class="h-8 w-auto text-slate-400 group-hover:text-[#96BF48] transition-colors"
                viewBox="0 0 109 40"
                fill="currentColor"
              >
                <path d="M26.5 7.7c0-.1-.1-.2-.2-.2s-.3 0-.3 0l-2.1-.1-.8-.8c-.1-.1-.1-.1-.2-.1l-1.1 23.3 9.7-2.1L26.5 7.7zm-3.3-.4c-.1 0-.1-.2-.2-.4-.3-.8-.8-1.9-1.7-1.9h-.1c-.3-.3-.5-.5-.8-.5C17.6 4.4 16 8.5 15.5 11c-1.2.4-2.1.7-2.2.7-.7.2-.7.2-.8.9-.1.5-1.8 14-1.8 14l14.3 2.7 1-21.3c-.5 0-.7-.1-.8-.1zM19 9.7v.3c-.8.2-1.6.5-2.5.8.5-1.9 1.4-2.8 2.2-3.2.1.7.3 1.4.3 2.1zm-1.3-3.4c.1 0 .3.1.4.2-.5.2-1 .8-1.5 1.5C16 9.7 15.3 13 15.3 13c.8-.2 1.5-.5 2.2-.7.1-.4.2-.8.2-1.2v-.1-.3c-.1-1.5-.1-3.4 0-4.4zm1.5-.4c.7 0 1.2 1.2 1.4 1.8-.7.2-1.5.5-2.3.7.2-1 .6-2.5.9-2.5z" />
              </svg>
              <span class="text-slate-400 font-semibold group-hover:text-white transition-colors">
                Shopify
              </span>
            </div>
            
    <!-- Amazon -->
            <div class="group flex items-center gap-2 px-4 py-2 opacity-60 hover:opacity-100 transition-opacity">
              <svg
                class="h-7 w-auto text-slate-400 group-hover:text-[#FF9900] transition-colors"
                viewBox="0 0 603 182"
                fill="currentColor"
              >
                <path d="M374.00 142.27c-34.52 25.45-84.59 39.01-127.7 39.01c-60.43 0-114.86-22.35-156-59.52c-3.23-2.92 0.34-6.90 3.72-4.63c44.43 25.83 99.35 41.37 156.08 41.37c38.27 0 80.36-7.93 119.08-24.38c5.84-2.48 10.72 3.83 4.82 8.15z" />
                <path d="M387.56 126.7c-4.40-5.64-29.17-2.67-40.28-1.35c-3.38 0.41-3.90-2.53-0.85-4.66c19.72-13.87 52.07-9.87 55.85-5.22c3.78 4.67-0.99 37.05-19.51 52.49c-2.85 2.37-5.56 1.11-4.30-2.03c4.17-10.43 13.49-33.60 9.09-39.23z" />
              </svg>
              <span class="text-slate-400 font-semibold group-hover:text-white transition-colors">
                Amazon
              </span>
            </div>
            
    <!-- eBay -->
            <div class="group flex items-center gap-2 px-4 py-2 opacity-60 hover:opacity-100 transition-opacity">
              <span class="text-2xl font-bold">
                <span class="text-slate-400 group-hover:text-red-500 transition-colors">e</span>
                <span class="text-slate-400 group-hover:text-blue-500 transition-colors">B</span>
                <span class="text-slate-400 group-hover:text-yellow-500 transition-colors">a</span>
                <span class="text-slate-400 group-hover:text-green-500 transition-colors">y</span>
              </span>
            </div>
            
    <!-- Etsy -->
            <div class="group flex items-center gap-2 px-4 py-2 opacity-60 hover:opacity-100 transition-opacity">
              <svg
                class="h-6 w-auto text-slate-400 group-hover:text-[#F56400] transition-colors"
                viewBox="0 0 100 40"
                fill="currentColor"
              >
                <path d="M10 8h25v6H18v8h14v6H18v8h17v6H10V8zm32 0h8v6h-8V8zm0 10h8v24h-8V18zm12-10h8l7 24h-8l-1-4H52l-1 4h-8l11-24h8zm3 16l-2-8-2 8h4zm20-16h8v34h-8V8z" />
              </svg>
              <span class="text-slate-400 font-semibold group-hover:text-white transition-colors">
                Etsy
              </span>
            </div>
            
    <!-- WooCommerce -->
            <div class="group flex items-center gap-2 px-4 py-2 opacity-60 hover:opacity-100 transition-opacity">
              <svg
                class="h-7 w-auto text-slate-400 group-hover:text-[#96588A] transition-colors"
                viewBox="0 0 120 40"
                fill="currentColor"
              >
                <path d="M8 8h8l4 16 4-16h8l4 16 4-16h8l-8 24h-8l-4-16-4 16h-8L8 8z" />
                <circle cx="80" cy="20" r="8" />
                <circle cx="100" cy="20" r="8" />
              </svg>
              <span class="text-slate-400 font-semibold group-hover:text-white transition-colors">
                WooCommerce
              </span>
            </div>
            
    <!-- BigCommerce -->
            <div class="group flex items-center gap-2 px-4 py-2 opacity-60 hover:opacity-100 transition-opacity">
              <div class="w-8 h-8 rounded-lg bg-slate-700 group-hover:bg-black flex items-center justify-center transition-colors">
                <span class="text-slate-400 group-hover:text-white font-bold text-lg transition-colors">
                  B
                </span>
              </div>
              <span class="text-slate-400 font-semibold group-hover:text-white transition-colors">
                BigCommerce
              </span>
            </div>
          </div>
        </div>
      </section>
      
    <!-- Core Features Section -->
      <section id="features" class="py-32 px-6 relative overflow-hidden">
        <!-- Background Decorative Elements -->
        <div class="absolute top-0 left-1/2 -translate-x-1/2 w-full h-full -z-10">
          <div class="absolute top-1/3 right-0 w-[500px] h-[500px] bg-emerald-500/5 rounded-full blur-[120px] animate-pulse-glow">
          </div>
          <div
            class="absolute bottom-1/3 left-0 w-[500px] h-[500px] bg-blue-500/5 rounded-full blur-[120px] animate-pulse-glow"
            style="animation-delay: 2s"
          >
          </div>
        </div>

        <div class="max-w-7xl mx-auto">
          <div class="text-center mb-20">
            <div class="inline-flex items-center gap-2 px-4 py-1.5 bg-emerald-500/10 border border-emerald-500/20 rounded-full mb-6">
              <span class="relative flex h-2 w-2">
                <span class="animate-ping absolute inline-flex h-full w-full rounded-full bg-emerald-400 opacity-75">
                </span>
                <span class="relative inline-flex rounded-full h-2 w-2 bg-emerald-500"></span>
              </span>
              <span class="text-emerald-400 text-sm font-semibold tracking-wide uppercase">
                Platform Capabilities
              </span>
            </div>
            <h2 class="text-4xl md:text-5xl lg:text-6xl font-bold text-white mb-6 tracking-tight">
              Core features that drive
              <span class="text-transparent bg-clip-text bg-gradient-to-r from-emerald-400 to-cyan-400">
                real value
              </span>
            </h2>
            <p class="text-slate-400 text-lg md:text-xl max-w-2xl mx-auto leading-relaxed">
              Everything you need to manage inventory across multiple sales channels efficiently and accurately.
            </p>
          </div>

          <div class="grid md:grid-cols-2 lg:grid-cols-4 gap-8">
            <!-- Feature 1 -->
            <div class="group relative p-8 bg-slate-900/40 backdrop-blur-xl rounded-3xl border border-slate-800/50 hover:border-emerald-500/30 transition-all duration-500 card-hover-lift">
              <div class="w-16 h-16 bg-gradient-to-br from-emerald-500/20 to-emerald-500/5 rounded-2xl flex items-center justify-center mb-8 group-hover:scale-110 transition-transform duration-500 shadow-lg shadow-emerald-500/10">
                <svg
                  class="w-8 h-8 text-emerald-400"
                  fill="none"
                  stroke="currentColor"
                  viewBox="0 0 24 24"
                >
                  <path
                    stroke-linecap="round"
                    stroke-linejoin="round"
                    stroke-width="1.5"
                    d="M13 10V3L4 14h7v7l9-11h-7z"
                  />
                </svg>
              </div>
              <h3 class="text-2xl font-bold text-white mb-4">Real-Time Sync</h3>
              <p class="text-slate-400 leading-relaxed mb-6">
                Inventory updates propagate across all channels instantly. No delays, no manual intervention required.
              </p>
              <div class="flex items-center text-emerald-400 font-semibold text-sm group/link cursor-pointer">
                <span>Explore Sync</span>
                <svg
                  class="w-4 h-4 ml-2 group-hover/link:translate-x-1 transition-transform"
                  fill="none"
                  stroke="currentColor"
                  viewBox="0 0 24 24"
                >
                  <path
                    stroke-linecap="round"
                    stroke-linejoin="round"
                    stroke-width="2"
                    d="M17 8l4 4m0 0l-4 4m4-4H3"
                  />
                </svg>
              </div>
            </div>
            
    <!-- Feature 2 -->
            <div class="group relative p-8 bg-slate-900/40 backdrop-blur-xl rounded-3xl border border-slate-800/50 hover:border-blue-500/30 transition-all duration-500 card-hover-lift">
              <div class="w-16 h-16 bg-gradient-to-br from-blue-500/20 to-blue-500/5 rounded-2xl flex items-center justify-center mb-8 group-hover:scale-110 transition-transform duration-500 shadow-lg shadow-blue-500/10">
                <svg
                  class="w-8 h-8 text-blue-400"
                  fill="none"
                  stroke="currentColor"
                  viewBox="0 0 24 24"
                >
                  <path
                    stroke-linecap="round"
                    stroke-linejoin="round"
                    stroke-width="1.5"
                    d="M4 6a2 2 0 012-2h2a2 2 0 012 2v2a2 2 0 01-2 2H6a2 2 0 01-2-2V6zM14 6a2 2 0 012-2h2a2 2 0 012 2v2a2 2 0 01-2 2h-2a2 2 0 01-2-2V6zM4 16a2 2 0 012-2h2a2 2 0 012 2v2a2 2 0 01-2 2H6a2 2 0 01-2-2v-2zM14 16a2 2 0 012-2h2a2 2 0 012 2v2a2 2 0 01-2 2h-2a2 2 0 01-2-2v-2z"
                  />
                </svg>
              </div>
              <h3 class="text-2xl font-bold text-white mb-4">Multi-Channel</h3>
              <p class="text-slate-400 leading-relaxed mb-6">
                Connect all major marketplaces and e-commerce platforms from a single unified dashboard.
              </p>
              <div class="flex items-center text-blue-400 font-semibold text-sm group/link cursor-pointer">
                <span>View Integrations</span>
                <svg
                  class="w-4 h-4 ml-2 group-hover/link:translate-x-1 transition-transform"
                  fill="none"
                  stroke="currentColor"
                  viewBox="0 0 24 24"
                >
                  <path
                    stroke-linecap="round"
                    stroke-linejoin="round"
                    stroke-width="2"
                    d="M17 8l4 4m0 0l-4 4m4-4H3"
                  />
                </svg>
              </div>
            </div>
            
    <!-- Feature 3 -->
            <div class="group relative p-8 bg-slate-900/40 backdrop-blur-xl rounded-3xl border border-slate-800/50 hover:border-cyan-500/30 transition-all duration-500 card-hover-lift">
              <div class="w-16 h-16 bg-gradient-to-br from-cyan-500/20 to-cyan-500/5 rounded-2xl flex items-center justify-center mb-8 group-hover:scale-110 transition-transform duration-500 shadow-lg shadow-cyan-500/10">
                <svg
                  class="w-8 h-8 text-cyan-400"
                  fill="none"
                  stroke="currentColor"
                  viewBox="0 0 24 24"
                >
                  <path
                    stroke-linecap="round"
                    stroke-linejoin="round"
                    stroke-width="1.5"
                    d="M9 19v-6a2 2 0 00-2-2H5a2 2 0 00-2 2v6a2 2 0 002 2h2a2 2 0 002-2zm0 0V9a2 2 0 012-2h2a2 2 0 012 2v10m-6 0a2 2 0 002 2h2a2 2 0 002-2m0 0V5a2 2 0 012-2h2a2 2 0 012 2v14a2 2 0 01-2 2h-2a2 2 0 01-2-2z"
                  />
                </svg>
              </div>
              <h3 class="text-2xl font-bold text-white mb-4">Analytics</h3>
              <p class="text-slate-400 leading-relaxed mb-6">
                Detailed insights into sync performance, inventory levels, and channel health at a glance.
              </p>
              <div class="flex items-center text-cyan-400 font-semibold text-sm group/link cursor-pointer">
                <span>See Insights</span>
                <svg
                  class="w-4 h-4 ml-2 group-hover/link:translate-x-1 transition-transform"
                  fill="none"
                  stroke="currentColor"
                  viewBox="0 0 24 24"
                >
                  <path
                    stroke-linecap="round"
                    stroke-linejoin="round"
                    stroke-width="2"
                    d="M17 8l4 4m0 0l-4 4m4-4H3"
                  />
                </svg>
              </div>
            </div>
            
    <!-- Feature 4 -->
            <div class="group relative p-8 bg-slate-900/40 backdrop-blur-xl rounded-3xl border border-slate-800/50 hover:border-purple-500/30 transition-all duration-500 card-hover-lift">
              <div class="w-16 h-16 bg-gradient-to-br from-purple-500/20 to-purple-500/5 rounded-2xl flex items-center justify-center mb-8 group-hover:scale-110 transition-transform duration-500 shadow-lg shadow-purple-500/10">
                <svg
                  class="w-8 h-8 text-purple-400"
                  fill="none"
                  stroke="currentColor"
                  viewBox="0 0 24 24"
                >
                  <path
                    stroke-linecap="round"
                    stroke-linejoin="round"
                    stroke-width="1.5"
                    d="M9 12l2 2 4-4m5.618-4.016A11.955 11.955 0 0112 2.944a11.955 11.955 0 01-8.618 3.04A12.02 12.02 0 003 9c0 5.591 3.824 10.29 9 11.622 5.176-1.332 9-6.03 9-11.622 0-1.042-.133-2.052-.382-3.016z"
                  />
                </svg>
              </div>
              <h3 class="text-2xl font-bold text-white mb-4">Smart Rate Limiting</h3>
              <p class="text-slate-400 leading-relaxed mb-6">
                Intelligent API management prevents throttling while maximizing sync throughput.
              </p>
              <div class="flex items-center text-purple-400 font-semibold text-sm group/link cursor-pointer">
                <span>Learn More</span>
                <svg
                  class="w-4 h-4 ml-2 group-hover/link:translate-x-1 transition-transform"
                  fill="none"
                  stroke="currentColor"
                  viewBox="0 0 24 24"
                >
                  <path
                    stroke-linecap="round"
                    stroke-linejoin="round"
                    stroke-width="2"
                    d="M17 8l4 4m0 0l-4 4m4-4H3"
                  />
                </svg>
              </div>
            </div>
          </div>
        </div>
      </section>
      
    <!-- Feature Detail Section 1 - Accessibility -->
      <section class="py-32 px-6 relative overflow-hidden">
        <!-- Background Decorative Elements -->
        <div class="absolute top-1/2 left-0 -translate-y-1/2 w-full h-full -z-10">
          <div class="absolute top-1/4 left-0 w-[600px] h-[600px] bg-teal-500/5 rounded-full blur-[120px] animate-pulse-glow">
          </div>
        </div>

        <div class="max-w-7xl mx-auto">
          <div class="grid lg:grid-cols-2 gap-16 lg:gap-24 items-center">
            <!-- Image/Visualization -->
            <div class="relative order-2 lg:order-1">
              <div class="relative z-10 bg-slate-900/60 backdrop-blur-2xl rounded-3xl border border-slate-800/50 p-8 shadow-2xl animate-float">
                <!-- Multi-channel visualization -->
                <div class="grid grid-cols-2 gap-6">
                  <div class="group bg-slate-800/40 rounded-2xl p-5 border border-slate-700/30 hover:border-emerald-500/30 transition-all duration-300">
                    <div class="flex items-center gap-3 mb-4">
                      <div class="w-10 h-10 rounded-xl bg-emerald-500/20 flex items-center justify-center shadow-inner">
                        <span class="text-emerald-400 text-lg font-bold">S</span>
                      </div>
                      <span class="text-white font-bold text-sm tracking-wide">Shopify</span>
                    </div>
                    <div class="text-3xl font-black text-white mb-1">1,284</div>
                    <div class="text-xs text-slate-400 font-medium uppercase tracking-wider">
                      Products synced
                    </div>
                    <div class="mt-4 flex items-center gap-2">
                      <div class="w-2 h-2 rounded-full bg-emerald-400 animate-pulse"></div>
                      <span class="text-[10px] text-emerald-400 font-bold uppercase tracking-widest">
                        Live
                      </span>
                    </div>
                  </div>

                  <div class="group bg-slate-800/40 rounded-2xl p-5 border border-slate-700/30 hover:border-orange-500/30 transition-all duration-300">
                    <div class="flex items-center gap-3 mb-4">
                      <div class="w-10 h-10 rounded-xl bg-orange-500/20 flex items-center justify-center shadow-inner">
                        <span class="text-orange-400 text-lg font-bold">A</span>
                      </div>
                      <span class="text-white font-bold text-sm tracking-wide">Amazon</span>
                    </div>
                    <div class="text-3xl font-black text-white mb-1">892</div>
                    <div class="text-xs text-slate-400 font-medium uppercase tracking-wider">
                      Products synced
                    </div>
                    <div class="mt-4 flex items-center gap-2">
                      <div class="w-2 h-2 rounded-full bg-emerald-400 animate-pulse"></div>
                      <span class="text-[10px] text-emerald-400 font-bold uppercase tracking-widest">
                        Live
                      </span>
                    </div>
                  </div>

                  <div class="group bg-slate-800/40 rounded-2xl p-5 border border-slate-700/30 hover:border-blue-500/30 transition-all duration-300">
                    <div class="flex items-center gap-3 mb-4">
                      <div class="w-10 h-10 rounded-xl bg-blue-500/20 flex items-center justify-center shadow-inner">
                        <span class="text-blue-400 text-lg font-bold">E</span>
                      </div>
                      <span class="text-white font-bold text-sm tracking-wide">eBay</span>
                    </div>
                    <div class="text-3xl font-black text-white mb-1">671</div>
                    <div class="text-xs text-slate-400 font-medium uppercase tracking-wider">
                      Products synced
                    </div>
                    <div class="mt-4 flex items-center gap-2">
                      <div class="w-2 h-2 rounded-full bg-emerald-400 animate-pulse"></div>
                      <span class="text-[10px] text-emerald-400 font-bold uppercase tracking-widest">
                        Live
                      </span>
                    </div>
                  </div>

                  <div class="group bg-slate-800/40 rounded-2xl p-5 border border-slate-700/30 hover:border-red-500/30 transition-all duration-300">
                    <div class="flex items-center gap-3 mb-4">
                      <div class="w-10 h-10 rounded-xl bg-red-500/20 flex items-center justify-center shadow-inner">
                        <span class="text-red-400 text-lg font-bold">Et</span>
                      </div>
                      <span class="text-white font-bold text-sm tracking-wide">Etsy</span>
                    </div>
                    <div class="text-3xl font-black text-white mb-1">423</div>
                    <div class="text-xs text-slate-400 font-medium uppercase tracking-wider">
                      Products synced
                    </div>
                    <div class="mt-4 flex items-center gap-2">
                      <div class="w-2 h-2 rounded-full bg-emerald-400 animate-pulse"></div>
                      <span class="text-[10px] text-emerald-400 font-bold uppercase tracking-widest">
                        Live
                      </span>
                    </div>
                  </div>
                </div>
                
    <!-- Central sync indicator -->
                <div class="mt-8 bg-gradient-to-r from-emerald-500/10 via-teal-500/10 to-cyan-500/10 rounded-2xl p-6 border border-emerald-500/20 relative overflow-hidden group">
                  <div class="absolute inset-0 bg-gradient-to-r from-transparent via-white/5 to-transparent -translate-x-full group-hover:translate-x-full transition-transform duration-1000">
                  </div>
                  <div class="flex items-center justify-between relative z-10">
                    <div class="flex items-center gap-4">
                      <div class="w-12 h-12 rounded-full bg-emerald-500/20 flex items-center justify-center shadow-lg shadow-emerald-500/20">
                        <svg
                          class="w-6 h-6 text-emerald-400 animate-spin"
                          style="animation-duration: 3s;"
                          fill="none"
                          stroke="currentColor"
                          viewBox="0 0 24 24"
                        >
                          <path
                            stroke-linecap="round"
                            stroke-linejoin="round"
                            stroke-width="2"
                            d="M4 4v5h.582m15.356 2A8.001 8.001 0 004.582 9m0 0H9m11 11v-5h-.581m0 0a8.003 8.003 0 01-15.357-2m15.357 2H15"
                          />
                        </svg>
                      </div>
                      <div>
                        <div class="text-white font-bold">Global Sync Active</div>
                        <div class="text-xs text-slate-400 font-medium">Last update: 2s ago</div>
                      </div>
                    </div>
                    <div class="text-3xl font-black text-emerald-400 tabular-nums">3,270</div>
                  </div>
                </div>
              </div>
              
    <!-- Decorative Background Glow -->
              <div class="absolute -bottom-10 -left-10 w-64 h-64 bg-emerald-500/10 rounded-full blur-3xl -z-10">
              </div>
            </div>
            
    <!-- Content -->
            <div class="order-1 lg:order-2">
              <div class="inline-flex items-center gap-2 px-4 py-1.5 bg-teal-500/10 border border-teal-500/20 rounded-full mb-6">
                <span class="text-teal-400 text-sm font-semibold tracking-wide uppercase">
                  Simplicity First
                </span>
              </div>
              <h2 class="text-4xl md:text-5xl font-bold text-white mb-8 leading-tight tracking-tight">
                Accessible to businesses
                <span class="text-transparent bg-clip-text bg-gradient-to-r from-teal-400 to-cyan-400">
                  of all sizes
                </span>
              </h2>
              <p class="text-slate-400 text-lg md:text-xl mb-8 leading-relaxed">
                Our inventory sync platform is designed to be intuitive and powerful, whether you're a small seller or enterprise-level operation. No technical expertise required.
              </p>

              <div class="grid gap-6">
                <div class="flex items-start gap-5 group">
                  <div class="w-10 h-10 rounded-xl bg-emerald-500/10 flex items-center justify-center flex-shrink-0 mt-1 group-hover:bg-emerald-500/20 transition-colors">
                    <svg
                      class="w-6 h-6 text-emerald-400"
                      fill="none"
                      stroke="currentColor"
                      viewBox="0 0 24 24"
                    >
                      <path
                        stroke-linecap="round"
                        stroke-linejoin="round"
                        stroke-width="2"
                        d="M5 13l4 4L19 7"
                      />
                    </svg>
                  </div>
                  <div>
                    <div class="text-white font-bold text-lg mb-1">No coding required</div>
                    <p class="text-slate-400 leading-relaxed">
                      Get started in minutes with guided setup and automatic channel detection.
                    </p>
                  </div>
                </div>

                <div class="flex items-start gap-5 group">
                  <div class="w-10 h-10 rounded-xl bg-blue-500/10 flex items-center justify-center flex-shrink-0 mt-1 group-hover:bg-blue-500/20 transition-colors">
                    <svg
                      class="w-6 h-6 text-blue-400"
                      fill="none"
                      stroke="currentColor"
                      viewBox="0 0 24 24"
                    >
                      <path
                        stroke-linecap="round"
                        stroke-linejoin="round"
                        stroke-width="2"
                        d="M13 10V3L4 14h7v7l9-11h-7z"
                      />
                    </svg>
                  </div>
                  <div>
                    <div class="text-white font-bold text-lg mb-1">Instant Deployment</div>
                    <p class="text-slate-400 leading-relaxed">
                      Connect your stores and start syncing immediately with our smart defaults.
                    </p>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>
      </section>
      
    <!-- Feature Detail Section 2 - Quick Deploy -->
      <section class="py-32 px-6 relative overflow-hidden">
        <!-- Background Decorative Elements -->
        <div class="absolute top-1/2 right-0 -translate-y-1/2 w-full h-full -z-10">
          <div class="absolute top-1/4 right-0 w-[600px] h-[600px] bg-blue-500/5 rounded-full blur-[120px] animate-pulse-glow">
          </div>
        </div>

        <div class="max-w-7xl mx-auto">
          <div class="grid lg:grid-cols-2 gap-16 lg:gap-24 items-center">
            <!-- Content -->
            <div>
              <div class="inline-flex items-center gap-2 px-4 py-1.5 bg-cyan-500/10 border border-cyan-500/20 rounded-full mb-6">
                <span class="text-cyan-400 text-sm font-semibold tracking-wide uppercase">
                  Speed & Efficiency
                </span>
              </div>
              <h2 class="text-4xl md:text-5xl font-bold text-white mb-8 leading-tight tracking-tight">
                Providing lightning-fast
                <span class="text-transparent bg-clip-text bg-gradient-to-r from-cyan-400 to-emerald-400">
                  deployment solutions
                </span>
              </h2>
              <p class="text-slate-400 text-lg md:text-xl mb-10 leading-relaxed">
                Our sync engine can be deployed and operational within minutes, enabling you to start managing inventory across channels without lengthy setup or development time.
              </p>

              <div class="space-y-6">
                <div class="group flex items-center gap-6 p-4 rounded-2xl hover:bg-slate-800/40 transition-colors border border-transparent hover:border-slate-700/50">
                  <div class="w-14 h-14 rounded-2xl bg-gradient-to-br from-emerald-500/20 to-emerald-500/5 flex items-center justify-center flex-shrink-0 group-hover:scale-110 transition-transform">
                    <svg
                      class="w-7 h-7 text-emerald-400"
                      fill="none"
                      stroke="currentColor"
                      viewBox="0 0 24 24"
                    >
                      <path
                        stroke-linecap="round"
                        stroke-linejoin="round"
                        stroke-width="2"
                        d="M5 13l4 4L19 7"
                      />
                    </svg>
                  </div>
                  <div>
                    <div class="text-white font-bold text-lg">Ready-to-use integrations</div>
                    <div class="text-slate-400 font-medium">
                      Pre-built connectors for all major platforms
                    </div>
                  </div>
                </div>

                <div class="group flex items-center gap-6 p-4 rounded-2xl hover:bg-slate-800/40 transition-colors border border-transparent hover:border-slate-700/50">
                  <div class="w-14 h-14 rounded-2xl bg-gradient-to-br from-teal-500/20 to-teal-500/5 flex items-center justify-center flex-shrink-0 group-hover:scale-110 transition-transform">
                    <svg
                      class="w-7 h-7 text-teal-400"
                      fill="none"
                      stroke="currentColor"
                      viewBox="0 0 24 24"
                    >
                      <path
                        stroke-linecap="round"
                        stroke-linejoin="round"
                        stroke-width="2"
                        d="M13 10V3L4 14h7v7l9-11h-7z"
                      />
                    </svg>
                  </div>
                  <div>
                    <div class="text-white font-bold text-lg">One-click channel connection</div>
                    <div class="text-slate-400 font-medium">OAuth-based secure authentication</div>
                  </div>
                </div>

                <div class="group flex items-center gap-6 p-4 rounded-2xl hover:bg-slate-800/40 transition-colors border border-transparent hover:border-slate-700/50">
                  <div class="w-14 h-14 rounded-2xl bg-gradient-to-br from-cyan-500/20 to-cyan-500/5 flex items-center justify-center flex-shrink-0 group-hover:scale-110 transition-transform">
                    <svg
                      class="w-7 h-7 text-cyan-400"
                      fill="none"
                      stroke="currentColor"
                      viewBox="0 0 24 24"
                    >
                      <path
                        stroke-linecap="round"
                        stroke-linejoin="round"
                        stroke-width="2"
                        d="M9 12l2 2 4-4m5.618-4.016A11.955 11.955 0 0112 2.944a11.955 11.955 0 01-8.618 3.04A12.02 12.02 0 003 9c0 5.591 3.824 10.29 9 11.622 5.176-1.332 9-6.03 9-11.622 0-1.042-.133-2.052-.382-3.016z"
                      />
                    </svg>
                  </div>
                  <div>
                    <div class="text-white font-bold text-lg">Zero downtime updates</div>
                    <div class="text-slate-400 font-medium">
                      Seamless upgrades without interruption
                    </div>
                  </div>
                </div>
              </div>

              <div class="mt-12">
                <.link
                  navigate={~p"/users/register"}
                  class="inline-flex items-center gap-2 px-8 py-4 bg-white text-slate-900 font-bold rounded-2xl hover:bg-emerald-50 transition-all hover:scale-105 active:scale-95 shadow-xl shadow-white/10"
                >
                  Start Deploying Now
                  <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path
                      stroke-linecap="round"
                      stroke-linejoin="round"
                      stroke-width="2"
                      d="M17 8l4 4m0 0l-4 4m4-4H3"
                    />
                  </svg>
                </.link>
              </div>
            </div>
            
    <!-- Image/Visualization -->
            <div class="relative">
              <div class="relative z-10 bg-slate-900/60 backdrop-blur-2xl rounded-3xl border border-slate-800/50 p-8 shadow-2xl animate-float-reverse">
                <!-- Speed Visualization -->
                <div class="space-y-8">
                  <div class="flex items-center justify-between mb-2">
                    <span class="text-white font-bold">Deployment Progress</span>
                    <span class="text-emerald-400 font-black">98%</span>
                  </div>
                  <div class="h-4 w-full bg-slate-800 rounded-full overflow-hidden p-1 border border-slate-700">
                    <div class="h-full bg-gradient-to-r from-emerald-500 via-teal-400 to-cyan-400 rounded-full w-[98%] animate-pulse">
                    </div>
                  </div>

                  <div class="grid grid-cols-3 gap-4">
                    <div class="bg-slate-800/40 rounded-2xl p-4 border border-slate-700/30 text-center">
                      <div class="text-slate-400 text-[10px] font-bold uppercase tracking-widest mb-1">
                        Latency
                      </div>
                      <div class="text-white font-black text-xl">12ms</div>
                    </div>
                    <div class="bg-slate-800/40 rounded-2xl p-4 border border-slate-700/30 text-center">
                      <div class="text-slate-400 text-[10px] font-bold uppercase tracking-widest mb-1">
                        Uptime
                      </div>
                      <div class="text-white font-black text-xl">99.9%</div>
                    </div>
                    <div class="bg-slate-800/40 rounded-2xl p-4 border border-slate-700/30 text-center">
                      <div class="text-slate-400 text-[10px] font-bold uppercase tracking-widest mb-1">
                        Sync
                      </div>
                      <div class="text-white font-black text-xl">Real-time</div>
                    </div>
                  </div>

                  <div class="p-6 bg-emerald-500/10 rounded-2xl border border-emerald-500/20">
                    <div class="flex items-center gap-4">
                      <div class="w-3 h-3 rounded-full bg-emerald-400 animate-ping"></div>
                      <span class="text-emerald-400 font-bold text-sm">
                        System optimized for peak performance
                      </span>
                    </div>
                  </div>
                </div>
              </div>
              
    <!-- Decorative Background Glow -->
              <div class="absolute -top-10 -right-10 w-64 h-64 bg-blue-500/10 rounded-full blur-3xl -z-10">
              </div>
            </div>
          </div>
        </div>
      </section>
      
    <!-- Pricing Section -->
      <section
        id="pricing"
        class="py-24 px-6 bg-gradient-to-b from-slate-900/0 via-slate-800/50 to-slate-900/0"
      >
        <div class="max-w-7xl mx-auto">
          <div class="text-center mb-12">
            <div class="inline-flex items-center gap-2 px-3 py-1 bg-violet-500/10 border border-violet-500/20 rounded-full mb-4">
              <span class="text-violet-400 text-sm font-medium">Pricing</span>
            </div>
            <h2 class="text-3xl sm:text-4xl lg:text-5xl font-bold text-white mb-4">
              Cost-effectively scale your
              <span class="bg-gradient-to-r from-violet-400 to-purple-400 bg-clip-text text-transparent">
                inventory management
              </span>
            </h2>
            <p class="text-slate-400 text-lg max-w-2xl mx-auto mb-8">
              Choose the plan that fits your business. All plans include core sync features with no hidden fees.
            </p>
            
    <!-- Pricing Toggle -->
            <div class="inline-flex items-center gap-4 p-1 bg-slate-800/80 rounded-xl border border-slate-700/50">
              <button
                phx-click="toggle_pricing"
                phx-value-period="monthly"
                class={"px-6 py-2 rounded-lg font-medium transition-all " <> if @pricing_period == "monthly", do: "bg-gradient-to-r from-emerald-500 to-teal-500 text-white shadow-lg", else: "text-slate-400 hover:text-white"}
              >
                Monthly
              </button>
              <button
                phx-click="toggle_pricing"
                phx-value-period="annually"
                class={"px-6 py-2 rounded-lg font-medium transition-all " <> if @pricing_period == "annually", do: "bg-gradient-to-r from-emerald-500 to-teal-500 text-white shadow-lg", else: "text-slate-400 hover:text-white"}
              >
                Annually <span class="ml-1 text-xs text-emerald-400">(Save 20%)</span>
              </button>
            </div>
          </div>

          <div class="grid md:grid-cols-3 gap-8 max-w-5xl mx-auto">
            <!-- Starter Plan -->
            <div class="relative p-8 bg-slate-800/60 backdrop-blur-xl rounded-2xl border border-slate-700/50 hover:border-slate-600/50 transition-all card-hover-lift stagger-1">
              <div class="mb-6">
                <h3 class="text-xl font-semibold text-white mb-2">Starter</h3>
                <p class="text-slate-400 text-sm">Perfect for small sellers getting started</p>
              </div>

              <div class="mb-6">
                <div class="flex items-baseline">
                  <span class="text-4xl font-bold text-white">
                    ${if @pricing_period == "monthly", do: "29", else: "23"}
                  </span>
                  <span class="text-slate-400 ml-2">/month</span>
                </div>
                <%= if @pricing_period == "annually" do %>
                  <div class="text-sm text-emerald-400 mt-1">Billed annually ($276/year)</div>
                <% end %>
              </div>

              <ul class="space-y-4 mb-8">
                <li class="flex items-center gap-3 text-slate-300">
                  <svg
                    class="w-5 h-5 text-emerald-400 flex-shrink-0"
                    fill="none"
                    stroke="currentColor"
                    viewBox="0 0 24 24"
                  >
                    <path
                      stroke-linecap="round"
                      stroke-linejoin="round"
                      stroke-width="2"
                      d="M5 13l4 4L19 7"
                    />
                  </svg>
                  Up to 500 SKUs
                </li>
                <li class="flex items-center gap-3 text-slate-300">
                  <svg
                    class="w-5 h-5 text-emerald-400 flex-shrink-0"
                    fill="none"
                    stroke="currentColor"
                    viewBox="0 0 24 24"
                  >
                    <path
                      stroke-linecap="round"
                      stroke-linejoin="round"
                      stroke-width="2"
                      d="M5 13l4 4L19 7"
                    />
                  </svg>
                  2 sales channels
                </li>
                <li class="flex items-center gap-3 text-slate-300">
                  <svg
                    class="w-5 h-5 text-emerald-400 flex-shrink-0"
                    fill="none"
                    stroke="currentColor"
                    viewBox="0 0 24 24"
                  >
                    <path
                      stroke-linecap="round"
                      stroke-linejoin="round"
                      stroke-width="2"
                      d="M5 13l4 4L19 7"
                    />
                  </svg>
                  Real-time sync
                </li>
                <li class="flex items-center gap-3 text-slate-300">
                  <svg
                    class="w-5 h-5 text-emerald-400 flex-shrink-0"
                    fill="none"
                    stroke="currentColor"
                    viewBox="0 0 24 24"
                  >
                    <path
                      stroke-linecap="round"
                      stroke-linejoin="round"
                      stroke-width="2"
                      d="M5 13l4 4L19 7"
                    />
                  </svg>
                  Email support
                </li>
              </ul>

              <.link
                href={~p"/users/register"}
                class="block w-full py-3 px-4 text-center bg-slate-700 hover:bg-slate-600 text-white rounded-xl font-medium transition-all border border-slate-600"
              >
                Get Started
              </.link>
            </div>
            
    <!-- Professional Plan (Featured) -->
            <div class="relative p-8 bg-gradient-to-b from-emerald-500/10 to-slate-800/80 backdrop-blur-xl rounded-2xl border border-emerald-500/30 hover:border-emerald-500/50 transition-all shadow-xl shadow-emerald-500/10 scale-105 pricing-popular stagger-2">
              <div class="absolute -top-4 left-1/2 -translate-x-1/2 px-4 py-1 bg-gradient-to-r from-emerald-500 to-teal-500 rounded-full text-white text-sm font-medium">
                Most Popular
              </div>

              <div class="mb-6 pt-2">
                <h3 class="text-xl font-semibold text-white mb-2">Professional</h3>
                <p class="text-slate-400 text-sm">For growing multi-channel businesses</p>
              </div>

              <div class="mb-6">
                <div class="flex items-baseline">
                  <span class="text-4xl font-bold text-white">
                    ${if @pricing_period == "monthly", do: "79", else: "63"}
                  </span>
                  <span class="text-slate-400 ml-2">/month</span>
                </div>
                <%= if @pricing_period == "annually" do %>
                  <div class="text-sm text-emerald-400 mt-1">Billed annually ($756/year)</div>
                <% end %>
              </div>

              <ul class="space-y-4 mb-8">
                <li class="flex items-center gap-3 text-slate-300">
                  <svg
                    class="w-5 h-5 text-emerald-400 flex-shrink-0"
                    fill="none"
                    stroke="currentColor"
                    viewBox="0 0 24 24"
                  >
                    <path
                      stroke-linecap="round"
                      stroke-linejoin="round"
                      stroke-width="2"
                      d="M5 13l4 4L19 7"
                    />
                  </svg>
                  Up to 5,000 SKUs
                </li>
                <li class="flex items-center gap-3 text-slate-300">
                  <svg
                    class="w-5 h-5 text-emerald-400 flex-shrink-0"
                    fill="none"
                    stroke="currentColor"
                    viewBox="0 0 24 24"
                  >
                    <path
                      stroke-linecap="round"
                      stroke-linejoin="round"
                      stroke-width="2"
                      d="M5 13l4 4L19 7"
                    />
                  </svg>
                  5 sales channels
                </li>
                <li class="flex items-center gap-3 text-slate-300">
                  <svg
                    class="w-5 h-5 text-emerald-400 flex-shrink-0"
                    fill="none"
                    stroke="currentColor"
                    viewBox="0 0 24 24"
                  >
                    <path
                      stroke-linecap="round"
                      stroke-linejoin="round"
                      stroke-width="2"
                      d="M5 13l4 4L19 7"
                    />
                  </svg>
                  Advanced analytics
                </li>
                <li class="flex items-center gap-3 text-slate-300">
                  <svg
                    class="w-5 h-5 text-emerald-400 flex-shrink-0"
                    fill="none"
                    stroke="currentColor"
                    viewBox="0 0 24 24"
                  >
                    <path
                      stroke-linecap="round"
                      stroke-linejoin="round"
                      stroke-width="2"
                      d="M5 13l4 4L19 7"
                    />
                  </svg>
                  Priority support
                </li>
                <li class="flex items-center gap-3 text-slate-300">
                  <svg
                    class="w-5 h-5 text-emerald-400 flex-shrink-0"
                    fill="none"
                    stroke="currentColor"
                    viewBox="0 0 24 24"
                  >
                    <path
                      stroke-linecap="round"
                      stroke-linejoin="round"
                      stroke-width="2"
                      d="M5 13l4 4L19 7"
                    />
                  </svg>
                  Webhook integrations
                </li>
              </ul>

              <.link
                href={~p"/users/register"}
                class="block w-full py-3 px-4 text-center bg-gradient-to-r from-emerald-500 to-teal-500 hover:from-emerald-600 hover:to-teal-600 text-white rounded-xl font-medium transition-all shadow-lg shadow-emerald-500/25"
              >
                Get Started
              </.link>
            </div>
            
    <!-- Enterprise Plan -->
            <div class="relative p-8 bg-slate-800/60 backdrop-blur-xl rounded-2xl border border-slate-700/50 hover:border-slate-600/50 transition-all card-hover-lift stagger-3">
              <div class="mb-6">
                <h3 class="text-xl font-semibold text-white mb-2">Enterprise</h3>
                <p class="text-slate-400 text-sm">For large-scale operations</p>
              </div>

              <div class="mb-6">
                <div class="flex items-baseline">
                  <span class="text-4xl font-bold text-white">
                    ${if @pricing_period == "monthly", do: "199", else: "159"}
                  </span>
                  <span class="text-slate-400 ml-2">/month</span>
                </div>
                <%= if @pricing_period == "annually" do %>
                  <div class="text-sm text-emerald-400 mt-1">Billed annually ($1,908/year)</div>
                <% end %>
              </div>

              <ul class="space-y-4 mb-8">
                <li class="flex items-center gap-3 text-slate-300">
                  <svg
                    class="w-5 h-5 text-emerald-400 flex-shrink-0"
                    fill="none"
                    stroke="currentColor"
                    viewBox="0 0 24 24"
                  >
                    <path
                      stroke-linecap="round"
                      stroke-linejoin="round"
                      stroke-width="2"
                      d="M5 13l4 4L19 7"
                    />
                  </svg>
                  Unlimited SKUs
                </li>
                <li class="flex items-center gap-3 text-slate-300">
                  <svg
                    class="w-5 h-5 text-emerald-400 flex-shrink-0"
                    fill="none"
                    stroke="currentColor"
                    viewBox="0 0 24 24"
                  >
                    <path
                      stroke-linecap="round"
                      stroke-linejoin="round"
                      stroke-width="2"
                      d="M5 13l4 4L19 7"
                    />
                  </svg>
                  Unlimited channels
                </li>
                <li class="flex items-center gap-3 text-slate-300">
                  <svg
                    class="w-5 h-5 text-emerald-400 flex-shrink-0"
                    fill="none"
                    stroke="currentColor"
                    viewBox="0 0 24 24"
                  >
                    <path
                      stroke-linecap="round"
                      stroke-linejoin="round"
                      stroke-width="2"
                      d="M5 13l4 4L19 7"
                    />
                  </svg>
                  Custom integrations
                </li>
                <li class="flex items-center gap-3 text-slate-300">
                  <svg
                    class="w-5 h-5 text-emerald-400 flex-shrink-0"
                    fill="none"
                    stroke="currentColor"
                    viewBox="0 0 24 24"
                  >
                    <path
                      stroke-linecap="round"
                      stroke-linejoin="round"
                      stroke-width="2"
                      d="M5 13l4 4L19 7"
                    />
                  </svg>
                  Dedicated support
                </li>
                <li class="flex items-center gap-3 text-slate-300">
                  <svg
                    class="w-5 h-5 text-emerald-400 flex-shrink-0"
                    fill="none"
                    stroke="currentColor"
                    viewBox="0 0 24 24"
                  >
                    <path
                      stroke-linecap="round"
                      stroke-linejoin="round"
                      stroke-width="2"
                      d="M5 13l4 4L19 7"
                    />
                  </svg>
                  SLA guarantee
                </li>
              </ul>

              <.link
                href={~p"/users/register"}
                class="block w-full py-3 px-4 text-center bg-slate-700 hover:bg-slate-600 text-white rounded-xl font-medium transition-all border border-slate-600"
              >
                Contact Sales
              </.link>
            </div>
          </div>
        </div>
      </section>
      
    <!-- FAQ Section -->
      <section id="faq" class="py-24 px-6">
        <div class="max-w-3xl mx-auto">
          <div class="text-center mb-12">
            <div class="inline-flex items-center gap-2 px-3 py-1 bg-amber-500/10 border border-amber-500/20 rounded-full mb-4">
              <span class="text-amber-400 text-sm font-medium">FAQ</span>
            </div>
            <h2 class="text-3xl sm:text-4xl font-bold text-white mb-4">
              Frequently asked questions
            </h2>
            <p class="text-slate-400 text-lg">
              Got questions? We've got answers.
            </p>
          </div>

          <div class="space-y-4">
            <!-- FAQ Item 1 -->
            <div class="bg-slate-800/60 backdrop-blur-xl rounded-xl border border-slate-700/50 overflow-hidden">
              <button
                phx-click="toggle_faq"
                phx-value-id="faq1"
                class="w-full px-6 py-5 flex items-center justify-between text-left hover:bg-slate-700/30 transition-colors"
              >
                <span class="text-white font-medium">How does InventorySync work?</span>
                <svg
                  class={"w-5 h-5 text-slate-400 transition-transform " <> if @active_faq == "faq1", do: "rotate-180", else: ""}
                  fill="none"
                  stroke="currentColor"
                  viewBox="0 0 24 24"
                >
                  <path
                    stroke-linecap="round"
                    stroke-linejoin="round"
                    stroke-width="2"
                    d="M19 9l-7 7-7-7"
                  />
                </svg>
              </button>
              <div class={"px-6 overflow-hidden transition-all duration-300 " <> if @active_faq == "faq1", do: "pb-5 max-h-48", else: "max-h-0"}>
                <p class="text-slate-400 leading-relaxed">
                  InventorySync connects to your sales channels via secure API integrations. When inventory changes on any channel, our system automatically updates all other connected channels in real-time, preventing overselling and maintaining accurate stock levels everywhere.
                </p>
              </div>
            </div>
            
    <!-- FAQ Item 2 -->
            <div class="bg-slate-800/60 backdrop-blur-xl rounded-xl border border-slate-700/50 overflow-hidden">
              <button
                phx-click="toggle_faq"
                phx-value-id="faq2"
                class="w-full px-6 py-5 flex items-center justify-between text-left hover:bg-slate-700/30 transition-colors"
              >
                <span class="text-white font-medium">Which platforms do you support?</span>
                <svg
                  class={"w-5 h-5 text-slate-400 transition-transform " <> if @active_faq == "faq2", do: "rotate-180", else: ""}
                  fill="none"
                  stroke="currentColor"
                  viewBox="0 0 24 24"
                >
                  <path
                    stroke-linecap="round"
                    stroke-linejoin="round"
                    stroke-width="2"
                    d="M19 9l-7 7-7-7"
                  />
                </svg>
              </button>
              <div class={"px-6 overflow-hidden transition-all duration-300 " <> if @active_faq == "faq2", do: "pb-5 max-h-48", else: "max-h-0"}>
                <p class="text-slate-400 leading-relaxed">
                  We support all major e-commerce platforms including Shopify, Amazon, eBay, Etsy, WooCommerce, BigCommerce, and more. We're constantly adding new integrations based on customer demand.
                </p>
              </div>
            </div>
            
    <!-- FAQ Item 3 -->
            <div class="bg-slate-800/60 backdrop-blur-xl rounded-xl border border-slate-700/50 overflow-hidden">
              <button
                phx-click="toggle_faq"
                phx-value-id="faq3"
                class="w-full px-6 py-5 flex items-center justify-between text-left hover:bg-slate-700/30 transition-colors"
              >
                <span class="text-white font-medium">How fast are inventory updates?</span>
                <svg
                  class={"w-5 h-5 text-slate-400 transition-transform " <> if @active_faq == "faq3", do: "rotate-180", else: ""}
                  fill="none"
                  stroke="currentColor"
                  viewBox="0 0 24 24"
                >
                  <path
                    stroke-linecap="round"
                    stroke-linejoin="round"
                    stroke-width="2"
                    d="M19 9l-7 7-7-7"
                  />
                </svg>
              </button>
              <div class={"px-6 overflow-hidden transition-all duration-300 " <> if @active_faq == "faq3", do: "pb-5 max-h-48", else: "max-h-0"}>
                <p class="text-slate-400 leading-relaxed">
                  Our sync engine processes updates in less than 1 second on average. With our intelligent rate limiting, we maximize throughput while respecting platform API limits, ensuring your inventory stays accurate across all channels.
                </p>
              </div>
            </div>
            
    <!-- FAQ Item 4 -->
            <div class="bg-slate-800/60 backdrop-blur-xl rounded-xl border border-slate-700/50 overflow-hidden">
              <button
                phx-click="toggle_faq"
                phx-value-id="faq4"
                class="w-full px-6 py-5 flex items-center justify-between text-left hover:bg-slate-700/30 transition-colors"
              >
                <span class="text-white font-medium">Can I try before I buy?</span>
                <svg
                  class={"w-5 h-5 text-slate-400 transition-transform " <> if @active_faq == "faq4", do: "rotate-180", else: ""}
                  fill="none"
                  stroke="currentColor"
                  viewBox="0 0 24 24"
                >
                  <path
                    stroke-linecap="round"
                    stroke-linejoin="round"
                    stroke-width="2"
                    d="M19 9l-7 7-7-7"
                  />
                </svg>
              </button>
              <div class={"px-6 overflow-hidden transition-all duration-300 " <> if @active_faq == "faq4", do: "pb-5 max-h-48", else: "max-h-0"}>
                <p class="text-slate-400 leading-relaxed">
                  Absolutely! We offer a 14-day free trial with full access to all features. No credit card required to start. You can connect your channels and experience the power of real-time inventory sync risk-free.
                </p>
              </div>
            </div>
            
    <!-- FAQ Item 5 -->
            <div class="bg-slate-800/60 backdrop-blur-xl rounded-xl border border-slate-700/50 overflow-hidden">
              <button
                phx-click="toggle_faq"
                phx-value-id="faq5"
                class="w-full px-6 py-5 flex items-center justify-between text-left hover:bg-slate-700/30 transition-colors"
              >
                <span class="text-white font-medium">What happens if there's a sync issue?</span>
                <svg
                  class={"w-5 h-5 text-slate-400 transition-transform " <> if @active_faq == "faq5", do: "rotate-180", else: ""}
                  fill="none"
                  stroke="currentColor"
                  viewBox="0 0 24 24"
                >
                  <path
                    stroke-linecap="round"
                    stroke-linejoin="round"
                    stroke-width="2"
                    d="M19 9l-7 7-7-7"
                  />
                </svg>
              </button>
              <div class={"px-6 overflow-hidden transition-all duration-300 " <> if @active_faq == "faq5", do: "pb-5 max-h-48", else: "max-h-0"}>
                <p class="text-slate-400 leading-relaxed">
                  Our system includes automatic retry mechanisms with exponential backoff. If a sync fails, you'll be notified immediately with detailed error information. Our support team is available 24/7 to help resolve any issues quickly.
                </p>
              </div>
            </div>
          </div>

          <div class="mt-10 text-center">
            <p class="text-slate-400 mb-4">Still have questions?</p>
            <a
              href="#"
              class="inline-flex items-center text-emerald-400 hover:text-emerald-300 font-medium transition-colors"
            >
              Contact our support team
              <svg class="w-4 h-4 ml-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path
                  stroke-linecap="round"
                  stroke-linejoin="round"
                  stroke-width="2"
                  d="M17 8l4 4m0 0l-4 4m4-4H3"
                />
              </svg>
            </a>
          </div>
        </div>
      </section>
      
    <!-- Testimonials Section -->
      <section id="testimonials" class="py-32 px-6 relative overflow-hidden">
        <!-- Background Decorative Elements -->
        <div class="absolute top-0 left-1/2 -translate-x-1/2 w-full h-full -z-10">
          <div class="absolute top-1/4 left-1/4 w-96 h-96 bg-emerald-500/10 rounded-full blur-[120px] animate-pulse-glow">
          </div>
          <div
            class="absolute bottom-1/4 right-1/4 w-96 h-96 bg-blue-500/10 rounded-full blur-[120px] animate-pulse-glow"
            style="animation-delay: 1.5s"
          >
          </div>
        </div>

        <div class="max-w-7xl mx-auto">
          <div class="text-center mb-20">
            <div class="inline-flex items-center gap-2 px-4 py-1.5 bg-emerald-500/10 border border-emerald-500/20 rounded-full mb-6">
              <span class="relative flex h-2 w-2">
                <span class="animate-ping absolute inline-flex h-full w-full rounded-full bg-emerald-400 opacity-75">
                </span>
                <span class="relative inline-flex rounded-full h-2 w-2 bg-emerald-500"></span>
              </span>
              <span class="text-emerald-400 text-sm font-semibold tracking-wide uppercase">
                Success Stories
              </span>
            </div>
            <h2 class="text-4xl md:text-5xl lg:text-6xl font-bold text-white mb-6 tracking-tight">
              Trusted by
              <span class="text-transparent bg-clip-text bg-gradient-to-r from-emerald-400 to-cyan-400">
                thousands
              </span>
              of sellers
            </h2>
            <p class="text-slate-400 text-lg md:text-xl max-w-2xl mx-auto leading-relaxed">
              Join the growing community of high-volume retailers who have transformed their operations with InventorySync.
            </p>
          </div>

          <div class="grid md:grid-cols-2 lg:grid-cols-3 gap-8">
            <!-- Testimonial 1 -->
            <div class="group relative p-8 bg-slate-900/40 backdrop-blur-xl rounded-3xl border border-slate-800/50 hover:border-emerald-500/30 transition-all duration-500 card-hover-lift">
              <div class="absolute top-0 right-0 p-8 opacity-10 group-hover:opacity-20 transition-opacity">
                <svg class="w-12 h-12 text-emerald-400" fill="currentColor" viewBox="0 0 24 24">
                  <path d="M14.017 21L14.017 18C14.017 16.8954 14.9124 16 16.017 16H19.017C19.5693 16 20.017 15.5523 20.017 15V9C20.017 8.44772 19.5693 8 19.017 8H16.017C15.4647 8 15.017 8.44772 15.017 9V12C15.017 12.5523 14.5693 13 14.017 13H13.017V21H14.017ZM6.017 21L6.017 18C6.017 16.8954 6.91243 16 8.017 16H11.017C11.5693 16 12.017 15.5523 12.017 15V9C12.017 8.44772 11.5693 8 11.017 8H8.017C7.46472 8 7.017 8.44772 7.017 9V12C7.017 12.5523 6.56929 13 6.017 13H5.017V21H6.017Z" />
                </svg>
              </div>

              <div class="flex items-center gap-1 mb-6">
                <%= for _ <- 1..5 do %>
                  <svg class="w-5 h-5 text-amber-400 fill-current" viewBox="0 0 20 20">
                    <path d="M9.049 2.927c.3-.921 1.603-.921 1.902 0l1.07 3.292a1 1 0 00.95.69h3.462c.969 0 1.371 1.24.588 1.81l-2.8 2.034a1 1 0 00-.364 1.118l1.07 3.292c.3.921-.755 1.688-1.54 1.118l-2.8-2.034a1 1 0 00-1.175 0l-2.8 2.034c-.784.57-1.838-.197-1.539-1.118l1.07-3.292a1 1 0 00-.364-1.118L2.98 8.72c-.783-.57-.38-1.81.588-1.81h3.461a1 1 0 00.951-.69l1.07-3.292z" />
                  </svg>
                <% end %>
              </div>

              <blockquote class="text-slate-300 text-lg leading-relaxed mb-8 relative z-10">
                "InventorySync completely eliminated our overselling problem. We went from 10+ cancellations a week to zero. The ROI was immediate and the setup was surprisingly simple."
              </blockquote>

              <div class="flex items-center gap-4 pt-6 border-t border-slate-800/50">
                <div class="relative">
                  <div class="w-14 h-14 rounded-2xl bg-gradient-to-br from-emerald-400 to-teal-500 flex items-center justify-center text-white font-bold text-xl shadow-lg shadow-emerald-500/20">
                    SC
                  </div>
                  <div class="absolute -bottom-1 -right-1 w-6 h-6 bg-slate-900 rounded-full flex items-center justify-center border-2 border-slate-800">
                    <svg class="w-3 h-3 text-emerald-400" fill="currentColor" viewBox="0 0 20 20">
                      <path
                        fill-rule="evenodd"
                        d="M16.707 5.293a1 1 0 010 1.414l-8 8a1 1 0 01-1.414 0l-4-4a1 1 0 011.414-1.414L8 12.586l7.293-7.293a1 1 0 011.414 0z"
                        clip-rule="evenodd"
                      />
                    </svg>
                  </div>
                </div>
                <div>
                  <div class="text-white font-bold text-lg">Sarah Chen</div>
                  <div class="text-slate-400 text-sm font-medium">
                    E-commerce Director, ModernHome
                  </div>
                </div>
              </div>
            </div>
            
    <!-- Testimonial 2 -->
            <div class="group relative p-8 bg-slate-900/40 backdrop-blur-xl rounded-3xl border border-slate-800/50 hover:border-emerald-500/30 transition-all duration-500 card-hover-lift lg:translate-y-8">
              <div class="absolute top-0 right-0 p-8 opacity-10 group-hover:opacity-20 transition-opacity">
                <svg class="w-12 h-12 text-emerald-400" fill="currentColor" viewBox="0 0 24 24">
                  <path d="M14.017 21L14.017 18C14.017 16.8954 14.9124 16 16.017 16H19.017C19.5693 16 20.017 15.5523 20.017 15V9C20.017 8.44772 19.5693 8 19.017 8H16.017C15.4647 8 15.017 8.44772 15.017 9V12C15.017 12.5523 14.5693 13 14.017 13H13.017V21H14.017ZM6.017 21L6.017 18C6.017 16.8954 6.91243 16 8.017 16H11.017C11.5693 16 12.017 15.5523 12.017 15V9C12.017 8.44772 11.5693 8 11.017 8H8.017C7.46472 8 7.017 8.44772 7.017 9V12C7.017 12.5523 6.56929 13 6.017 13H5.017V21H6.017Z" />
                </svg>
              </div>

              <div class="flex items-center gap-1 mb-6">
                <%= for _ <- 1..5 do %>
                  <svg class="w-5 h-5 text-amber-400 fill-current" viewBox="0 0 20 20">
                    <path d="M9.049 2.927c.3-.921 1.603-.921 1.902 0l1.07 3.292a1 1 0 00.95.69h3.462c.969 0 1.371 1.24.588 1.81l-2.8 2.034a1 1 0 00-.364 1.118l1.07 3.292c.3.921-.755 1.688-1.54 1.118l-2.8-2.034a1 1 0 00-1.175 0l-2.8 2.034c-.784.57-1.838-.197-1.539-1.118l1.07-3.292a1 1 0 00-.364-1.118L2.98 8.72c-.783-.57-.38-1.81.588-1.81h3.461a1 1 0 00.951-.69l1.07-3.292z" />
                  </svg>
                <% end %>
              </div>

              <blockquote class="text-slate-300 text-lg leading-relaxed mb-8 relative z-10">
                "We manage inventory across 6 channels and 3,000+ SKUs. Before InventorySync, we had 2 people doing manual updates. Now it's all automated and error-free."
              </blockquote>

              <div class="flex items-center gap-4 pt-6 border-t border-slate-800/50">
                <div class="relative">
                  <div class="w-14 h-14 rounded-2xl bg-gradient-to-br from-blue-400 to-indigo-500 flex items-center justify-center text-white font-bold text-xl shadow-lg shadow-blue-500/20">
                    MR
                  </div>
                  <div class="absolute -bottom-1 -right-1 w-6 h-6 bg-slate-900 rounded-full flex items-center justify-center border-2 border-slate-800">
                    <svg class="w-3 h-3 text-emerald-400" fill="currentColor" viewBox="0 0 20 20">
                      <path
                        fill-rule="evenodd"
                        d="M16.707 5.293a1 1 0 010 1.414l-8 8a1 1 0 01-1.414 0l-4-4a1 1 0 011.414-1.414L8 12.586l7.293-7.293a1 1 0 011.414 0z"
                        clip-rule="evenodd"
                      />
                    </svg>
                  </div>
                </div>
                <div>
                  <div class="text-white font-bold text-lg">Marcus Rodriguez</div>
                  <div class="text-slate-400 text-sm font-medium">Founder, TechGear Supply</div>
                </div>
              </div>
            </div>
            
    <!-- Testimonial 3 -->
            <div class="group relative p-8 bg-slate-900/40 backdrop-blur-xl rounded-3xl border border-slate-800/50 hover:border-emerald-500/30 transition-all duration-500 card-hover-lift">
              <div class="absolute top-0 right-0 p-8 opacity-10 group-hover:opacity-20 transition-opacity">
                <svg class="w-12 h-12 text-emerald-400" fill="currentColor" viewBox="0 0 24 24">
                  <path d="M14.017 21L14.017 18C14.017 16.8954 14.9124 16 16.017 16H19.017C19.5693 16 20.017 15.5523 20.017 15V9C20.017 8.44772 19.5693 8 19.017 8H16.017C15.4647 8 15.017 8.44772 15.017 9V12C15.017 12.5523 14.5693 13 14.017 13H13.017V21H14.017ZM6.017 21L6.017 18C6.017 16.8954 6.91243 16 8.017 16H11.017C11.5693 16 12.017 15.5523 12.017 15V9C12.017 8.44772 11.5693 8 11.017 8H8.017C7.46472 8 7.017 8.44772 7.017 9V12C7.017 12.5523 6.56929 13 6.017 13H5.017V21H6.017Z" />
                </svg>
              </div>

              <div class="flex items-center gap-1 mb-6">
                <%= for _ <- 1..5 do %>
                  <svg class="w-5 h-5 text-amber-400 fill-current" viewBox="0 0 20 20">
                    <path d="M9.049 2.927c.3-.921 1.603-.921 1.902 0l1.07 3.292a1 1 0 00.95.69h3.462c.969 0 1.371 1.24.588 1.81l-2.8 2.034a1 1 0 00-.364 1.118l1.07 3.292c.3.921-.755 1.688-1.54 1.118l-2.8-2.034a1 1 0 00-1.175 0l-2.8 2.034c-.784.57-1.838-.197-1.539-1.118l1.07-3.292a1 1 0 00-.364-1.118L2.98 8.72c-.783-.57-.38-1.81.588-1.81h3.461a1 1 0 00.951-.69l1.07-3.292z" />
                  </svg>
                <% end %>
              </div>

              <blockquote class="text-slate-300 text-lg leading-relaxed mb-8 relative z-10">
                "The analytics dashboard is incredible. I can finally see exactly what's happening across all my stores in real-time. Customer support is also top-notch."
              </blockquote>

              <div class="flex items-center gap-4 pt-6 border-t border-slate-800/50">
                <div class="relative">
                  <div class="w-14 h-14 rounded-2xl bg-gradient-to-br from-purple-400 to-pink-500 flex items-center justify-center text-white font-bold text-xl shadow-lg shadow-purple-500/20">
                    JL
                  </div>
                  <div class="absolute -bottom-1 -right-1 w-6 h-6 bg-slate-900 rounded-full flex items-center justify-center border-2 border-slate-800">
                    <svg class="w-3 h-3 text-emerald-400" fill="currentColor" viewBox="0 0 20 20">
                      <path
                        fill-rule="evenodd"
                        d="M16.707 5.293a1 1 0 010 1.414l-8 8a1 1 0 01-1.414 0l-4-4a1 1 0 011.414-1.414L8 12.586l7.293-7.293a1 1 0 011.414 0z"
                        clip-rule="evenodd"
                      />
                    </svg>
                  </div>
                </div>
                <div>
                  <div class="text-white font-bold text-lg">Jessica Lee</div>
                  <div class="text-slate-400 text-sm font-medium">
                    Operations Manager, LuxeFashion
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>
      </section>
      
    <!-- Final CTA Section -->
      <section class="py-24 px-6">
        <div class="max-w-4xl mx-auto">
          <div class="relative overflow-hidden rounded-3xl bg-gradient-to-r from-emerald-500/20 via-teal-500/20 to-cyan-500/20 border border-emerald-500/30 p-12 text-center">
            <!-- Background effects -->
            <div class="absolute inset-0 overflow-hidden pointer-events-none">
              <div class="absolute top-0 left-1/4 w-64 h-64 bg-emerald-500/20 rounded-full blur-3xl">
              </div>
              <div class="absolute bottom-0 right-1/4 w-64 h-64 bg-teal-500/20 rounded-full blur-3xl">
              </div>
            </div>

            <div class="relative z-10">
              <h2 class="text-3xl sm:text-4xl font-bold text-white mb-4">
                Ready to sync your inventory?
              </h2>
              <p class="text-slate-300 text-lg mb-8 max-w-2xl mx-auto">
                Join thousands of sellers who trust InventorySync to keep their inventory accurate across every sales channel. Start your free trial today.
              </p>
              <div class="flex flex-col sm:flex-row items-center justify-center gap-4">
                <.link
                  href={~p"/users/register"}
                  class="w-full sm:w-auto inline-flex items-center justify-center px-8 py-4 bg-gradient-to-r from-emerald-500 to-teal-500 hover:from-emerald-600 hover:to-teal-600 text-white rounded-xl font-semibold text-lg transition-all shadow-lg shadow-emerald-500/25 hover:shadow-xl hover:shadow-emerald-500/40 transform hover:-translate-y-1 btn-glow"
                >
                  Start Free Trial
                  <svg class="w-5 h-5 ml-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path
                      stroke-linecap="round"
                      stroke-linejoin="round"
                      stroke-width="2"
                      d="M17 8l4 4m0 0l-4 4m4-4H3"
                    />
                  </svg>
                </.link>
                <a href="#" class="text-slate-300 hover:text-white font-medium transition-colors">
                  Schedule a demo →
                </a>
              </div>
              <p class="mt-6 text-sm text-slate-400">
                No credit card required • 14-day free trial • Cancel anytime
              </p>
            </div>
          </div>
        </div>
      </section>
    </div>
    """
  end
end
