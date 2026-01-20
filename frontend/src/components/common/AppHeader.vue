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
  <header class="bg-white border-b border-gray-200">
    <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
      <div class="flex justify-between items-center h-16">
        <!-- Logo -->
        <div class="flex items-center">
          <router-link to="/dashboard" class="flex items-center space-x-2">
            <div class="w-8 h-8 bg-primary rounded-lg flex items-center justify-center">
              <span class="text-white font-bold text-lg">U</span>
            </div>
            <span class="text-xl font-bold text-neutral-900">UCG Studio</span>
          </router-link>
        </div>

        <!-- Right side -->
        <div class="flex items-center space-x-4">
          <!-- Credit Balance -->
          <div class="hidden sm:flex items-center space-x-2 px-3 py-1.5 bg-neutral-50 rounded-lg">
            <svg
              class="w-5 h-5 text-primary"
              fill="none"
              stroke="currentColor"
              viewBox="0 0 24 24"
            >
              <path
                stroke-linecap="round"
                stroke-linejoin="round"
                stroke-width="2"
                d="M12 8c-1.657 0-3 .895-3 2s1.343 2 3 2 3 .895 3 2-1.343 2-3 2m0-8c1.11 0 2.08.402 2.599 1M12 8V7m0 1v8m0 0v1m0-1c-1.11 0-2.08-.402-2.599-1M21 12a9 9 0 11-18 0 9 9 0 0118 0z"
              />
            </svg>
            <span class="font-semibold text-neutral-900">{{ authStore.creditBalance }}</span>
            <span class="text-sm text-gray-500">credits</span>
          </div>

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
                  to="/dashboard"
                  class="block px-4 py-2 text-sm text-neutral-900 hover:bg-gray-50"
                >
                  Dashboard
                </router-link>

                <router-link
                  to="/settings"
                  class="block px-4 py-2 text-sm text-neutral-900 hover:bg-gray-50"
                >
                  Settings
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
