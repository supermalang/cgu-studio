<script setup>
import { ref, computed } from 'vue'
import { useAuthStore } from '@/stores/auth'
import { useCompanyStore } from '@/stores/company'
import { useRouter, useRoute } from 'vue-router'

const authStore = useAuthStore()
const companyStore = useCompanyStore()
const router = useRouter()
const route = useRoute()

const isLibraryOpen = ref(true)

const isLibraryActive = computed(() => {
  return route.name === 'avatars' || route.name === 'environments'
})
</script>

<template>
  <aside class="fixed left-0 top-0 bottom-0 w-64 bg-white border-r border-neutral-200 flex flex-col">
    <!-- Logo -->
    <div class="p-6">
      <router-link to="/projects" class="flex items-center space-x-2">
        <div class="w-10 h-10 bg-primary rounded-xl flex items-center justify-center">
          <span class="text-white font-bold text-xl">J</span>
        </div>
        <div>
          <div class="font-black text-lg text-neutral-900">{{ companyStore.companyName }}</div>
          <div class="text-xs text-neutral-500">Pro Plan</div>
        </div>
      </router-link>
    </div>

    <!-- Navigation -->
    <nav class="flex-1 px-4 space-y-1">
      <router-link
        to="/calendar"
        class="flex items-center gap-3 px-4 py-3 rounded-lg transition-all"
        :class="['calendar', 'post-create', 'post-edit'].includes($route.name)
          ? 'bg-primary-50 text-primary-600'
          : 'text-neutral-600 hover:bg-neutral-50'"
      >
        <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8 7V3m8 4V3m-9 8h10M5 21h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v12a2 2 0 002 2z" />
        </svg>
        <span class="font-medium">Calendar</span>
      </router-link>

      <router-link
        to="/projects"
        class="flex items-center gap-3 px-4 py-3 rounded-lg transition-all"
        :class="$route.name === 'projects' || $route.name === 'project-detail' || $route.name === 'project-create'
          ? 'bg-primary-50 text-primary-600'
          : 'text-neutral-600 hover:bg-neutral-50'"
      >
        <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 6a2 2 0 012-2h2a2 2 0 012 2v2a2 2 0 01-2 2H6a2 2 0 01-2-2V6zM14 6a2 2 0 012-2h2a2 2 0 012 2v2a2 2 0 01-2 2h-2a2 2 0 01-2-2V6zM4 16a2 2 0 012-2h2a2 2 0 012 2v2a2 2 0 01-2 2H6a2 2 0 01-2-2v-2zM14 16a2 2 0 012-2h2a2 2 0 012 2v2a2 2 0 01-2 2h-2a2 2 0 01-2-2v-2z" />
        </svg>
        <span class="font-medium">Campaigns</span>
      </router-link>

      <!-- Library Section (Collapsible) -->
      <div>
        <button
          @click="isLibraryOpen = !isLibraryOpen"
          class="w-full flex items-center gap-3 px-4 py-3 rounded-lg transition-all"
          :class="isLibraryActive
            ? 'bg-primary-50 text-primary-600'
            : 'text-neutral-600 hover:bg-neutral-50'"
        >
          <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M7 21h10a2 2 0 002-2V9.414a1 1 0 00-.293-.707l-5.414-5.414A1 1 0 0012.586 3H7a2 2 0 00-2 2v14a2 2 0 002 2z" />
          </svg>
          <span class="font-medium flex-1 text-left">Library</span>
          <svg
            class="w-4 h-4 transition-transform"
            :class="{ 'rotate-180': isLibraryOpen }"
            fill="none"
            stroke="currentColor"
            viewBox="0 0 24 24"
          >
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 9l-7 7-7-7" />
          </svg>
        </button>

        <!-- Nested items under Library -->
        <div v-if="isLibraryOpen" class="ml-4 space-y-1 mt-1">
          <router-link
            to="/avatars"
            class="flex items-center gap-3 px-4 py-2 rounded-lg transition-all"
            :class="$route.name === 'avatars'
              ? 'bg-primary-50 text-primary-600'
              : 'text-neutral-600 hover:bg-neutral-50'"
          >
            <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z" />
            </svg>
            <span class="font-medium">Avatars</span>
          </router-link>

          <router-link
            to="/environments"
            class="flex items-center gap-3 px-4 py-2 rounded-lg transition-all"
            :class="$route.name === 'environments'
              ? 'bg-primary-50 text-primary-600'
              : 'text-neutral-600 hover:bg-neutral-50'"
          >
            <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 11H5m14 0a2 2 0 012 2v6a2 2 0 01-2 2H5a2 2 0 01-2-2v-6a2 2 0 012-2m14 0V9a2 2 0 00-2-2M5 11V9a2 2 0 012-2m0 0V5a2 2 0 012-2h6a2 2 0 012 2v2M7 7h10" />
            </svg>
            <span class="font-medium">Environments</span>
          </router-link>
        </div>
      </div>

      <router-link
        to="/channels"
        class="flex items-center gap-3 px-4 py-3 rounded-lg transition-all"
        :class="$route.name === 'social-accounts'
          ? 'bg-primary-50 text-primary-600'
          : 'text-neutral-600 hover:bg-neutral-50'"
      >
        <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8.684 13.342A3 3 0 106.316 10.658m2.368 2.684a3 3 0 11-2.368-2.684m2.368 2.684l6.632 3.316m-6.632-6l6.632-3.316m0 9.316a3 3 0 105.367 2.684 3 3 0 00-5.367-2.684zm0-12a3 3 0 105.368-2.684A3 3 0 0015.316 7.658z" />
        </svg>
        <span class="font-medium">Channels</span>
      </router-link>

      <router-link
        to="/billing"
        class="flex items-center gap-3 px-4 py-3 rounded-lg transition-all"
        :class="$route.name === 'billing'
          ? 'bg-primary-50 text-primary-600'
          : 'text-neutral-600 hover:bg-neutral-50'"
      >
        <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 10h18M7 15h1m4 0h1m-7 4h12a3 3 0 003-3V8a3 3 0 00-3-3H6a3 3 0 00-3 3v8a3 3 0 003 3z" />
        </svg>
        <span class="font-medium">Billing</span>
      </router-link>
    </nav>

    <!-- Bottom Section -->
    <div class="p-4 border-t border-neutral-200">
      <!-- Upgrade Button -->
      <button class="w-full btn-primary flex items-center justify-center gap-2 mb-4">
        <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 10V3L4 14h7v7l9-11h-7z" />
        </svg>
        Upgrade Plan
      </button>

      <!-- Collapse Button -->
      <button class="w-full flex items-center gap-2 px-4 py-2 text-sm text-neutral-500 hover:text-neutral-700 transition-colors">
        <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M11 19l-7-7 7-7m8 14l-7-7 7-7" />
        </svg>
        Collapse Menu
      </button>
    </div>
  </aside>
</template>
