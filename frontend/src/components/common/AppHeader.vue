<script setup>
import { useAuthStore } from '@/stores/auth'
import { useRouter } from 'vue-router'
import { ref } from 'vue'

const authStore = useAuthStore()
const router = useRouter()
const showUserMenu = ref(false)

async function handleLogout() {
  await authStore.signOut()
  router.push('/auth/login')
}
</script>

<template>
  <header class="bg-white border-b border-neutral-200">
    <div class="ml-64 px-6">
      <div class="flex justify-between items-center h-16">
        <!-- Search Bar -->
        <div class="flex-1 max-w-2xl">
          <div class="relative">
            <svg
              class="absolute left-3 top-1/2 transform -translate-y-1/2 w-5 h-5 text-neutral-400"
              fill="none"
              stroke="currentColor"
              viewBox="0 0 24 24"
            >
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z" />
            </svg>
            <input
              type="text"
              placeholder="Search projects, templates or assets..."
              class="w-full pl-10 pr-4 py-2 bg-neutral-50 border-0 rounded-lg focus:outline-none focus:ring-2 focus:ring-primary-500 text-sm"
            />
          </div>
        </div>

        <!-- Right side -->
        <div class="flex items-center space-x-3">
          <!-- Notification Bell -->
          <button class="relative w-10 h-10 rounded-lg hover:bg-neutral-100 flex items-center justify-center transition-colors">
            <svg class="w-5 h-5 text-neutral-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 17h5l-1.405-1.405A2.032 2.032 0 0118 14.158V11a6.002 6.002 0 00-4-5.659V5a2 2 0 10-4 0v.341C7.67 6.165 6 8.388 6 11v3.159c0 .538-.214 1.055-.595 1.436L4 17h5m6 0v1a3 3 0 11-6 0v-1m6 0H9" />
            </svg>
          </button>

          <!-- Help Button -->
          <button class="w-10 h-10 rounded-lg hover:bg-neutral-100 flex items-center justify-center transition-colors">
            <svg class="w-5 h-5 text-neutral-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8.228 9c.549-1.165 2.03-2 3.772-2 2.21 0 4 1.343 4 3 0 1.4-1.278 2.575-3.006 2.907-.542.104-.994.54-.994 1.093m0 3h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
            </svg>
          </button>

          <!-- User Menu -->
          <div class="relative">
            <button
              @click="showUserMenu = !showUserMenu"
              class="flex items-center space-x-2 focus:outline-none"
            >
              <div class="w-9 h-9 bg-primary rounded-full flex items-center justify-center">
                <span class="text-white font-medium text-sm">
                  {{ authStore.profile?.full_name?.charAt(0).toUpperCase() || 'U' }}
                </span>
              </div>
            </button>

            <!-- Dropdown Menu -->
            <transition
              enter-active-class="transition ease-out duration-100"
              enter-from-class="transform opacity-0 scale-95"
              enter-to-class="transform opacity-100 scale-100"
              leave-active-class="transition ease-in duration-75"
              leave-from-class="transform opacity-100 scale-100"
              leave-to-class="transform opacity-0 scale-95"
            >
              <div
                v-if="showUserMenu"
                @click="showUserMenu = false"
                class="absolute right-0 mt-2 w-48 bg-white rounded-lg shadow-lg py-1 z-50 border border-gray-200"
              >
                <div class="px-4 py-2 border-b border-gray-200">
                  <p class="text-sm font-medium text-neutral-900">
                    {{ authStore.profile?.full_name }}
                  </p>
                  <p class="text-xs text-gray-500 truncate">
                    {{ authStore.user?.email }}
                  </p>
                </div>

                <router-link
                  to="/settings"
                  class="block px-4 py-2 text-sm text-neutral-900 hover:bg-gray-50"
                >
                  Settings
                </router-link>

                <router-link
                  to="/billing"
                  class="block px-4 py-2 text-sm text-neutral-900 hover:bg-gray-50"
                >
                  Billing
                </router-link>

                <router-link
                  v-if="authStore.isAdmin"
                  to="/admin"
                  class="block px-4 py-2 text-sm text-neutral-900 hover:bg-gray-50"
                >
                  Admin
                </router-link>

                <div class="border-t border-gray-200 mt-1 pt-1">
                  <button
                    @click="handleLogout"
                    class="block w-full text-left px-4 py-2 text-sm text-red-600 hover:bg-gray-50"
                  >
                    Log out
                  </button>
                </div>
              </div>
            </transition>
          </div>
        </div>
      </div>
    </div>
  </header>
</template>
