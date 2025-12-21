defmodule InventorySyncWeb.Layouts do
  @moduledoc """
  This module holds layouts and related functionality
  used by your application.
  """
  use InventorySyncWeb, :html

  # Embed all files in layouts/* within this module.
  # The default root.html.heex file contains the HTML
  # skeleton of your application, namely HTML headers
  # and other static content.
  embed_templates "layouts/*"

  # ============================================
  # Logo Component
  # ============================================

  attr :size, :string, default: "md", values: ["sm", "md", "lg"]
  attr :show_text, :boolean, default: true
  attr :class, :string, default: ""

  def logo(assigns) do
    ~H"""
    <div class={["flex items-center gap-2", @class]}>
      <div class={[
        "bg-gradient-to-br from-emerald-400 to-teal-500 rounded-xl flex items-center justify-center shadow-lg shadow-emerald-500/25",
        case @size do
          "sm" -> "w-8 h-8"
          "md" -> "w-10 h-10"
          "lg" -> "w-12 h-12"
        end
      ]}>
        <svg
          class={[
            "text-white",
            case @size do
              "sm" -> "w-4 h-4"
              "md" -> "w-6 h-6"
              "lg" -> "w-7 h-7"
            end
          ]}
          fill="none"
          stroke="currentColor"
          viewBox="0 0 24 24"
        >
          <path
            stroke-linecap="round"
            stroke-linejoin="round"
            stroke-width="2"
            d="M4 7v10c0 2.21 3.582 4 8 4s8-1.79 8-4V7M4 7c0 2.21 3.582 4 8 4s8-1.79 8-4M4 7c0-2.21 3.582-4 8-4s8 1.79 8 4"
          />
        </svg>
      </div>
      <span
        :if={@show_text}
        class={[
          "font-bold text-white",
          case @size do
            "sm" -> "text-lg"
            "md" -> "text-xl"
            "lg" -> "text-2xl"
          end
        ]}
      >
        InventorySync
      </span>
    </div>
    """
  end

  # ============================================
  # Public Navbar Component (Unauthenticated)
  # ============================================

  attr :current_scope, :any, default: nil

  def public_navbar(assigns) do
    ~H"""
    <nav class="sticky top-0 z-50 px-6 py-4 bg-slate-900/80 backdrop-blur-xl border-b border-slate-700/50 transition-all duration-300">
      <div class="max-w-7xl mx-auto flex items-center justify-between">
        <!-- Logo -->
        <.link href={~p"/"} class="flex items-center gap-2 hover:opacity-90 transition-opacity">
          <.logo size="md" />
        </.link>
        
    <!-- Desktop Navigation -->
        <div class="hidden md:flex items-center gap-8">
          <a
            href="#features"
            class="text-slate-300 hover:text-emerald-400 transition-colors font-medium text-sm hover-underline"
          >
            Features
          </a>
          <a
            href="#pricing"
            class="text-slate-300 hover:text-emerald-400 transition-colors font-medium text-sm hover-underline"
          >
            Pricing
          </a>
          <a
            href="#testimonials"
            class="text-slate-300 hover:text-emerald-400 transition-colors font-medium text-sm hover-underline"
          >
            Testimonials
          </a>
          <a
            href="#faq"
            class="text-slate-300 hover:text-emerald-400 transition-colors font-medium text-sm hover-underline"
          >
            FAQ
          </a>
        </div>
        
    <!-- Auth Actions -->
        <div class="flex items-center gap-4">
          <%= if @current_scope do %>
            <span class="text-slate-400 text-sm hidden sm:inline">
              {@current_scope.user.email}
            </span>
            <.link
              href={~p"/dashboard"}
              class="text-slate-300 hover:text-emerald-400 transition-colors font-medium text-sm"
            >
              Dashboard
            </.link>
            <.link
              href={~p"/users/log-out"}
              method="delete"
              class="px-4 py-2 bg-slate-700/80 hover:bg-slate-600 text-white rounded-lg font-medium transition-all border border-slate-600/50 hover:border-slate-500/50 text-sm"
            >
              Log out
            </.link>
          <% else %>
            <.link
              href={~p"/users/log-in"}
              class="hidden sm:inline text-slate-300 hover:text-emerald-400 transition-colors font-medium text-sm"
            >
              Log in
            </.link>
            <.link
              href={~p"/users/register"}
              class="px-5 py-2.5 bg-gradient-to-r from-emerald-500 to-teal-500 hover:from-emerald-600 hover:to-teal-600 text-white rounded-lg font-medium transition-all shadow-lg shadow-emerald-500/25 hover:shadow-xl hover:shadow-emerald-500/40 text-sm btn-glow"
            >
              Get Started Free
            </.link>
          <% end %>
          
    <!-- Mobile Menu Button -->
          <button
            class="md:hidden p-2 text-slate-400 hover:text-white transition-colors"
            onclick="document.getElementById('mobile-menu').classList.toggle('hidden')"
            aria-label="Toggle mobile menu"
          >
            <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path
                stroke-linecap="round"
                stroke-linejoin="round"
                stroke-width="2"
                d="M4 6h16M4 12h16M4 18h16"
              />
            </svg>
          </button>
        </div>
      </div>
      
    <!-- Mobile Menu -->
      <div id="mobile-menu" class="hidden md:hidden mt-4 pt-4 border-t border-slate-700/50">
        <div class="flex flex-col gap-4">
          <a
            href="#features"
            class="text-slate-300 hover:text-emerald-400 transition-colors font-medium text-sm py-2"
          >
            Features
          </a>
          <a
            href="#pricing"
            class="text-slate-300 hover:text-emerald-400 transition-colors font-medium text-sm py-2"
          >
            Pricing
          </a>
          <a
            href="#testimonials"
            class="text-slate-300 hover:text-emerald-400 transition-colors font-medium text-sm py-2"
          >
            Testimonials
          </a>
          <a
            href="#faq"
            class="text-slate-300 hover:text-emerald-400 transition-colors font-medium text-sm py-2"
          >
            FAQ
          </a>
          <%= unless @current_scope do %>
            <.link
              href={~p"/users/log-in"}
              class="text-slate-300 hover:text-emerald-400 transition-colors font-medium text-sm py-2"
            >
              Log in
            </.link>
          <% end %>
        </div>
      </div>
    </nav>
    """
  end

  # ============================================
  # Footer Component
  # ============================================

  attr :variant, :string, default: "default", values: ["default", "minimal"]
  attr :class, :string, default: ""

  def footer(assigns) do
    ~H"""
    <footer class={[
      "px-6 py-12 border-t border-slate-700/50 bg-gradient-to-b from-slate-900 to-slate-950 relative overflow-hidden",
      @class
    ]}>
      <!-- Subtle background decoration -->
      <div class="absolute inset-0 overflow-hidden pointer-events-none">
        <div class="absolute -bottom-32 -left-32 w-64 h-64 bg-emerald-500/5 rounded-full blur-3xl">
        </div>
        <div class="absolute -bottom-32 -right-32 w-64 h-64 bg-teal-500/5 rounded-full blur-3xl">
        </div>
      </div>

      <div class="max-w-7xl mx-auto relative z-10">
        <%= if @variant == "default" do %>
          <div class="grid grid-cols-1 md:grid-cols-4 gap-8 lg:gap-12 mb-12">
            <!-- Brand Column -->
            <div class="md:col-span-1">
              <.logo size="sm" />
              <p class="mt-4 text-sm text-slate-400 leading-relaxed">
                Automatically synchronize inventory levels across all your sales channels.
                Never oversell again.
              </p>
              <!-- Newsletter Signup -->
              <div class="mt-6">
                <p class="text-xs text-slate-500 mb-2">Subscribe to our newsletter</p>
                <div class="flex gap-2">
                  <input
                    type="email"
                    placeholder="Enter your email"
                    class="flex-1 px-3 py-2 bg-slate-800/50 border border-slate-700/50 rounded-lg text-sm text-white placeholder-slate-500 focus:outline-none focus:border-emerald-500/50 focus:ring-1 focus:ring-emerald-500/25 transition-all"
                  />
                  <button class="px-3 py-2 bg-emerald-500 hover:bg-emerald-600 text-white rounded-lg text-sm font-medium transition-colors">
                    <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path
                        stroke-linecap="round"
                        stroke-linejoin="round"
                        stroke-width="2"
                        d="M14 5l7 7m0 0l-7 7m7-7H3"
                      />
                    </svg>
                  </button>
                </div>
              </div>
            </div>
            
    <!-- Product Column -->
            <div>
              <h4 class="text-sm font-semibold text-white mb-4 uppercase tracking-wider">Product</h4>
              <ul class="space-y-3">
                <li>
                  <a
                    href="#features"
                    class="text-sm text-slate-400 hover:text-emerald-400 transition-colors inline-flex items-center gap-1 group"
                  >
                    <span>Features</span>
                    <svg
                      class="w-3 h-3 opacity-0 -translate-x-2 group-hover:opacity-100 group-hover:translate-x-0 transition-all"
                      fill="none"
                      stroke="currentColor"
                      viewBox="0 0 24 24"
                    >
                      <path
                        stroke-linecap="round"
                        stroke-linejoin="round"
                        stroke-width="2"
                        d="M9 5l7 7-7 7"
                      />
                    </svg>
                  </a>
                </li>
                <li>
                  <a
                    href="#"
                    class="text-sm text-slate-400 hover:text-emerald-400 transition-colors inline-flex items-center gap-1 group"
                  >
                    <span>Integrations</span>
                    <svg
                      class="w-3 h-3 opacity-0 -translate-x-2 group-hover:opacity-100 group-hover:translate-x-0 transition-all"
                      fill="none"
                      stroke="currentColor"
                      viewBox="0 0 24 24"
                    >
                      <path
                        stroke-linecap="round"
                        stroke-linejoin="round"
                        stroke-width="2"
                        d="M9 5l7 7-7 7"
                      />
                    </svg>
                  </a>
                </li>
                <li>
                  <a
                    href="#pricing"
                    class="text-sm text-slate-400 hover:text-emerald-400 transition-colors inline-flex items-center gap-1 group"
                  >
                    <span>Pricing</span>
                    <svg
                      class="w-3 h-3 opacity-0 -translate-x-2 group-hover:opacity-100 group-hover:translate-x-0 transition-all"
                      fill="none"
                      stroke="currentColor"
                      viewBox="0 0 24 24"
                    >
                      <path
                        stroke-linecap="round"
                        stroke-linejoin="round"
                        stroke-width="2"
                        d="M9 5l7 7-7 7"
                      />
                    </svg>
                  </a>
                </li>
                <li>
                  <a
                    href="#"
                    class="text-sm text-slate-400 hover:text-emerald-400 transition-colors inline-flex items-center gap-1 group"
                  >
                    <span>Changelog</span>
                    <svg
                      class="w-3 h-3 opacity-0 -translate-x-2 group-hover:opacity-100 group-hover:translate-x-0 transition-all"
                      fill="none"
                      stroke="currentColor"
                      viewBox="0 0 24 24"
                    >
                      <path
                        stroke-linecap="round"
                        stroke-linejoin="round"
                        stroke-width="2"
                        d="M9 5l7 7-7 7"
                      />
                    </svg>
                  </a>
                </li>
              </ul>
            </div>
            
    <!-- Company Column -->
            <div>
              <h4 class="text-sm font-semibold text-white mb-4 uppercase tracking-wider">Company</h4>
              <ul class="space-y-3">
                <li>
                  <a
                    href="#"
                    class="text-sm text-slate-400 hover:text-emerald-400 transition-colors inline-flex items-center gap-1 group"
                  >
                    <span>About</span>
                    <svg
                      class="w-3 h-3 opacity-0 -translate-x-2 group-hover:opacity-100 group-hover:translate-x-0 transition-all"
                      fill="none"
                      stroke="currentColor"
                      viewBox="0 0 24 24"
                    >
                      <path
                        stroke-linecap="round"
                        stroke-linejoin="round"
                        stroke-width="2"
                        d="M9 5l7 7-7 7"
                      />
                    </svg>
                  </a>
                </li>
                <li>
                  <a
                    href="#"
                    class="text-sm text-slate-400 hover:text-emerald-400 transition-colors inline-flex items-center gap-1 group"
                  >
                    <span>Blog</span>
                    <svg
                      class="w-3 h-3 opacity-0 -translate-x-2 group-hover:opacity-100 group-hover:translate-x-0 transition-all"
                      fill="none"
                      stroke="currentColor"
                      viewBox="0 0 24 24"
                    >
                      <path
                        stroke-linecap="round"
                        stroke-linejoin="round"
                        stroke-width="2"
                        d="M9 5l7 7-7 7"
                      />
                    </svg>
                  </a>
                </li>
                <li>
                  <a
                    href="#"
                    class="text-sm text-slate-400 hover:text-emerald-400 transition-colors inline-flex items-center gap-1 group"
                  >
                    <span>Careers</span>
                    <span class="ml-1 px-1.5 py-0.5 bg-emerald-500/20 text-emerald-400 text-xs rounded">
                      Hiring
                    </span>
                  </a>
                </li>
                <li>
                  <a
                    href="#"
                    class="text-sm text-slate-400 hover:text-emerald-400 transition-colors inline-flex items-center gap-1 group"
                  >
                    <span>Contact</span>
                    <svg
                      class="w-3 h-3 opacity-0 -translate-x-2 group-hover:opacity-100 group-hover:translate-x-0 transition-all"
                      fill="none"
                      stroke="currentColor"
                      viewBox="0 0 24 24"
                    >
                      <path
                        stroke-linecap="round"
                        stroke-linejoin="round"
                        stroke-width="2"
                        d="M9 5l7 7-7 7"
                      />
                    </svg>
                  </a>
                </li>
              </ul>
            </div>
            
    <!-- Legal Column -->
            <div>
              <h4 class="text-sm font-semibold text-white mb-4 uppercase tracking-wider">Legal</h4>
              <ul class="space-y-3">
                <li>
                  <a
                    href="#"
                    class="text-sm text-slate-400 hover:text-emerald-400 transition-colors inline-flex items-center gap-1 group"
                  >
                    <span>Privacy Policy</span>
                    <svg
                      class="w-3 h-3 opacity-0 -translate-x-2 group-hover:opacity-100 group-hover:translate-x-0 transition-all"
                      fill="none"
                      stroke="currentColor"
                      viewBox="0 0 24 24"
                    >
                      <path
                        stroke-linecap="round"
                        stroke-linejoin="round"
                        stroke-width="2"
                        d="M9 5l7 7-7 7"
                      />
                    </svg>
                  </a>
                </li>
                <li>
                  <a
                    href="#"
                    class="text-sm text-slate-400 hover:text-emerald-400 transition-colors inline-flex items-center gap-1 group"
                  >
                    <span>Terms of Service</span>
                    <svg
                      class="w-3 h-3 opacity-0 -translate-x-2 group-hover:opacity-100 group-hover:translate-x-0 transition-all"
                      fill="none"
                      stroke="currentColor"
                      viewBox="0 0 24 24"
                    >
                      <path
                        stroke-linecap="round"
                        stroke-linejoin="round"
                        stroke-width="2"
                        d="M9 5l7 7-7 7"
                      />
                    </svg>
                  </a>
                </li>
                <li>
                  <a
                    href="#"
                    class="text-sm text-slate-400 hover:text-emerald-400 transition-colors inline-flex items-center gap-1 group"
                  >
                    <span>Cookie Policy</span>
                    <svg
                      class="w-3 h-3 opacity-0 -translate-x-2 group-hover:opacity-100 group-hover:translate-x-0 transition-all"
                      fill="none"
                      stroke="currentColor"
                      viewBox="0 0 24 24"
                    >
                      <path
                        stroke-linecap="round"
                        stroke-linejoin="round"
                        stroke-width="2"
                        d="M9 5l7 7-7 7"
                      />
                    </svg>
                  </a>
                </li>
                <li>
                  <a
                    href="#"
                    class="text-sm text-slate-400 hover:text-emerald-400 transition-colors inline-flex items-center gap-1 group"
                  >
                    <span>GDPR</span>
                    <svg
                      class="w-3 h-3 opacity-0 -translate-x-2 group-hover:opacity-100 group-hover:translate-x-0 transition-all"
                      fill="none"
                      stroke="currentColor"
                      viewBox="0 0 24 24"
                    >
                      <path
                        stroke-linecap="round"
                        stroke-linejoin="round"
                        stroke-width="2"
                        d="M9 5l7 7-7 7"
                      />
                    </svg>
                  </a>
                </li>
              </ul>
            </div>
          </div>
          
    <!-- Bottom Bar -->
          <div class="pt-8 border-t border-slate-800/50 flex flex-col md:flex-row items-center justify-between gap-4">
            <div class="flex flex-col sm:flex-row items-center gap-2 sm:gap-4">
              <p class="text-sm text-slate-500">
                © {DateTime.utc_now().year} InventorySync. All rights reserved.
              </p>
              <span class="hidden sm:inline text-slate-700">•</span>
              <p class="text-xs text-slate-600">
                Made with ❤️ for e-commerce sellers worldwide
              </p>
            </div>
            <div class="flex items-center gap-4">
              <!-- Social Icons with hover effects -->
              <a
                href="#"
                class="w-9 h-9 flex items-center justify-center rounded-lg bg-slate-800/50 text-slate-400 hover:bg-emerald-500/20 hover:text-emerald-400 transition-all"
                aria-label="Twitter"
              >
                <svg class="w-4 h-4" fill="currentColor" viewBox="0 0 24 24">
                  <path d="M18.244 2.25h3.308l-7.227 8.26 8.502 11.24H16.17l-5.214-6.817L4.99 21.75H1.68l7.73-8.835L1.254 2.25H8.08l4.713 6.231zm-1.161 17.52h1.833L7.084 4.126H5.117z" />
                </svg>
              </a>
              <a
                href="#"
                class="w-9 h-9 flex items-center justify-center rounded-lg bg-slate-800/50 text-slate-400 hover:bg-emerald-500/20 hover:text-emerald-400 transition-all"
                aria-label="GitHub"
              >
                <svg class="w-4 h-4" fill="currentColor" viewBox="0 0 24 24">
                  <path
                    fill-rule="evenodd"
                    clip-rule="evenodd"
                    d="M12 2C6.477 2 2 6.484 2 12.017c0 4.425 2.865 8.18 6.839 9.504.5.092.682-.217.682-.483 0-.237-.008-.868-.013-1.703-2.782.605-3.369-1.343-3.369-1.343-.454-1.158-1.11-1.466-1.11-1.466-.908-.62.069-.608.069-.608 1.003.07 1.531 1.032 1.531 1.032.892 1.53 2.341 1.088 2.91.832.092-.647.35-1.088.636-1.338-2.22-.253-4.555-1.113-4.555-4.951 0-1.093.39-1.988 1.029-2.688-.103-.253-.446-1.272.098-2.65 0 0 .84-.27 2.75 1.026A9.564 9.564 0 0112 6.844c.85.004 1.705.115 2.504.337 1.909-1.296 2.747-1.027 2.747-1.027.546 1.379.202 2.398.1 2.651.64.7 1.028 1.595 1.028 2.688 0 3.848-2.339 4.695-4.566 4.943.359.309.678.92.678 1.855 0 1.338-.012 2.419-.012 2.747 0 .268.18.58.688.482A10.019 10.019 0 0022 12.017C22 6.484 17.522 2 12 2z"
                  />
                </svg>
              </a>
              <a
                href="#"
                class="w-9 h-9 flex items-center justify-center rounded-lg bg-slate-800/50 text-slate-400 hover:bg-emerald-500/20 hover:text-emerald-400 transition-all"
                aria-label="LinkedIn"
              >
                <svg class="w-4 h-4" fill="currentColor" viewBox="0 0 24 24">
                  <path d="M20.447 20.452h-3.554v-5.569c0-1.328-.027-3.037-1.852-3.037-1.853 0-2.136 1.445-2.136 2.939v5.667H9.351V9h3.414v1.561h.046c.477-.9 1.637-1.85 3.37-1.85 3.601 0 4.267 2.37 4.267 5.455v6.286zM5.337 7.433c-1.144 0-2.063-.926-2.063-2.065 0-1.138.92-2.063 2.063-2.063 1.14 0 2.064.925 2.064 2.063 0 1.139-.925 2.065-2.064 2.065zm1.782 13.019H3.555V9h3.564v11.452zM22.225 0H1.771C.792 0 0 .774 0 1.729v20.542C0 23.227.792 24 1.771 24h20.451C23.2 24 24 23.227 24 22.271V1.729C24 .774 23.2 0 22.222 0h.003z" />
                </svg>
              </a>
              <a
                href="#"
                class="w-9 h-9 flex items-center justify-center rounded-lg bg-slate-800/50 text-slate-400 hover:bg-emerald-500/20 hover:text-emerald-400 transition-all"
                aria-label="YouTube"
              >
                <svg class="w-4 h-4" fill="currentColor" viewBox="0 0 24 24">
                  <path d="M23.498 6.186a3.016 3.016 0 0 0-2.122-2.136C19.505 3.545 12 3.545 12 3.545s-7.505 0-9.377.505A3.017 3.017 0 0 0 .502 6.186C0 8.07 0 12 0 12s0 3.93.502 5.814a3.016 3.016 0 0 0 2.122 2.136c1.871.505 9.376.505 9.376.505s7.505 0 9.377-.505a3.015 3.015 0 0 0 2.122-2.136C24 15.93 24 12 24 12s0-3.93-.502-5.814zM9.545 15.568V8.432L15.818 12l-6.273 3.568z" />
                </svg>
              </a>
            </div>
          </div>
        <% else %>
          <!-- Minimal Footer -->
          <div class="flex flex-col md:flex-row items-center justify-between gap-4">
            <div class="flex items-center gap-2">
              <.logo size="sm" show_text={false} />
              <span class="text-slate-400 text-sm">
                © {DateTime.utc_now().year} InventorySync. All rights reserved.
              </span>
            </div>
            <div class="flex items-center gap-6 text-sm text-slate-400">
              <a href="#" class="hover:text-emerald-400 transition-colors">Privacy</a>
              <a href="#" class="hover:text-emerald-400 transition-colors">Terms</a>
              <a href="#" class="hover:text-emerald-400 transition-colors">Contact</a>
            </div>
          </div>
        <% end %>
      </div>
    </footer>
    """
  end

  # ============================================
  # Sidebar Link Component (Updated Theme)
  # ============================================

  attr :href, :string, required: true
  attr :active, :boolean, default: false
  attr :icon, :string, default: nil
  slot :inner_block, required: true

  def sidebar_link(assigns) do
    ~H"""
    <a
      href={@href}
      class={[
        if(@active,
          do: "bg-slate-700/50 text-emerald-400 border-l-2 border-emerald-400",
          else:
            "text-slate-300 hover:text-emerald-400 hover:bg-slate-700/30 border-l-2 border-transparent"
        ),
        "group flex gap-x-3 rounded-r-lg p-2.5 text-sm leading-6 font-medium transition-all duration-200"
      ]}
    >
      <%= if @icon do %>
        <.icon
          name={@icon}
          class={
            if(@active,
              do: "h-5 w-5 shrink-0 transition-colors text-emerald-400",
              else: "h-5 w-5 shrink-0 transition-colors text-slate-400 group-hover:text-emerald-400"
            )
          }
        />
      <% end %>
      {render_slot(@inner_block)}
    </a>
    """
  end

  # ============================================
  # Notification Item Component (Updated Theme)
  # ============================================

  attr :title, :string, required: true
  attr :time, :string, required: true
  attr :message, :string, required: true
  attr :type, :string, default: "info", values: ["info", "success", "warning", "error"]

  def notification_item(assigns) do
    ~H"""
    <div class="px-4 py-3 hover:bg-slate-700/50 transition-colors border-b border-slate-700/50 last:border-0 cursor-pointer group">
      <div class="flex justify-between items-start mb-1">
        <div class="flex items-center gap-2">
          <span class={[
            "w-2 h-2 rounded-full",
            case @type do
              "error" -> "bg-red-400"
              "warning" -> "bg-amber-400"
              "success" -> "bg-emerald-400"
              _ -> "bg-blue-400"
            end
          ]}>
          </span>
          <p class="text-sm font-medium text-white group-hover:text-emerald-400 transition-colors">
            {@title}
          </p>
        </div>
        <span class="text-xs text-slate-500">{@time}</span>
      </div>
      <p class="text-xs text-slate-400 line-clamp-2 ml-4">{@message}</p>
    </div>
    """
  end

  @doc """
  Shows the flash group with standard titles and content.

  ## Examples

      <.flash_group flash={@flash} />
  """
  attr :flash, :map, required: true, doc: "the map of flash messages"
  attr :id, :string, default: "flash-group", doc: "the optional id of flash container"

  def flash_group(assigns) do
    ~H"""
    <div id={@id} aria-live="polite">
      <.flash kind={:info} flash={@flash} />
      <.flash kind={:error} flash={@flash} />

      <.flash
        id="client-error"
        kind={:error}
        title={gettext("We can't find the internet")}
        phx-disconnected={show(".phx-client-error #client-error") |> JS.remove_attribute("hidden")}
        phx-connected={hide("#client-error") |> JS.set_attribute({"hidden", ""})}
        hidden
      >
        {gettext("Attempting to reconnect")}
        <.icon name="hero-arrow-path" class="ml-1 size-3 motion-safe:animate-spin" />
      </.flash>

      <.flash
        id="server-error"
        kind={:error}
        title={gettext("Something went wrong!")}
        phx-disconnected={show(".phx-server-error #server-error") |> JS.remove_attribute("hidden")}
        phx-connected={hide("#server-error") |> JS.set_attribute({"hidden", ""})}
        hidden
      >
        {gettext("Attempting to reconnect")}
        <.icon name="hero-arrow-path" class="ml-1 size-3 motion-safe:animate-spin" />
      </.flash>
    </div>
    """
  end

  @doc """
  Provides dark vs light theme toggle based on themes defined in app.css.

  See <head> in root.html.heex which applies the theme before page load.
  """
  def theme_toggle(assigns) do
    ~H"""
    <div class="card relative flex flex-row items-center border-2 border-base-300 bg-base-300 rounded-full">
      <div class="absolute w-1/3 h-full rounded-full border-1 border-base-200 bg-base-100 brightness-200 left-0 [[data-theme=light]_&]:left-1/3 [[data-theme=dark]_&]:left-2/3 transition-[left]" />

      <button
        class="flex p-2 cursor-pointer w-1/3"
        phx-click={JS.dispatch("phx:set-theme")}
        data-phx-theme="system"
      >
        <.icon name="hero-computer-desktop-micro" class="size-4 opacity-75 hover:opacity-100" />
      </button>

      <button
        class="flex p-2 cursor-pointer w-1/3"
        phx-click={JS.dispatch("phx:set-theme")}
        data-phx-theme="light"
      >
        <.icon name="hero-sun-micro" class="size-4 opacity-75 hover:opacity-100" />
      </button>

      <button
        class="flex p-2 cursor-pointer w-1/3"
        phx-click={JS.dispatch("phx:set-theme")}
        data-phx-theme="dark"
      >
        <.icon name="hero-moon-micro" class="size-4 opacity-75 hover:opacity-100" />
      </button>
    </div>
    """
  end
end
