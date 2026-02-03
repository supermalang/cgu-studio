<script setup>
import { ref, computed, onMounted, onUnmounted } from 'vue'
import { useRouter } from 'vue-router'
import { supabase } from '@/lib/supabase'
import { useAuthStore } from '@/stores/auth'
import { useEnvironmentsStore } from '@/stores/environments'
import Sidebar from '@/components/common/Sidebar.vue'
import AppHeader from '@/components/common/AppHeader.vue'

const router = useRouter()
const authStore = useAuthStore()
const environmentsStore = useEnvironmentsStore()

// State
const isLoading = ref(true)
const error = ref(null)
const activeFilter = ref('all')
const searchQuery = ref('')

// Use store environments
const environments = computed(() => environmentsStore.environments)

// Fetch environments from store
async function fetchEnvironments() {
  isLoading.value = true
  error.value = null

  try {
    await environmentsStore.fetchEnvironments()

    // If no environments exist, use placeholder data
    if (!environmentsStore.environments || environmentsStore.environments.length === 0) {
      const { count } = await supabase
        .from('environments')
        .select('*', { count: 'exact', head: true })

      if (count === 0) {
        // Show placeholder for empty state
        environmentsStore.environments = [
          {
            id: 'placeholder-1',
            name: 'Modern Home Office',
            category: 'interior',
            reference_image_url: 'https://images.unsplash.com/photo-1484154218962-a197022b5858?w=400&h=400&fit=crop',
            environment_specs: {
              category: 'interior',
              lighting_type: 'natural'
            },
            is_active: true,
            created_at: new Date().toISOString()
          }
        ]
      }
    }
  } catch (err) {
    console.error('Error fetching environments:', err)
    error.value = 'Failed to load environments'
  } finally {
    isLoading.value = false
  }
}

onMounted(async () => {
  await fetchEnvironments()

  // Subscribe to realtime updates
  if (authStore.user?.id) {
    environmentsStore.subscribeToEnvironments(authStore.user.id)
  }
})

onUnmounted(() => {
  // Clean up subscription
  environmentsStore.unsubscribe()
})

const totalActive = computed(() => environments.value.filter(env => env.is_active).length)

const filteredEnvironments = computed(() => {
  let filtered = environments.value

  // Filter by category
  if (activeFilter.value !== 'all') {
    filtered = filtered.filter(env => {
      const category = env.environment_specs?.category || 'interior'
      return category === activeFilter.value
    })
  }

  // Filter by search query
  if (searchQuery.value) {
    const query = searchQuery.value.toLowerCase()
    filtered = filtered.filter(env => {
      const name = env.name?.toLowerCase() || ''
      const category = env.environment_specs?.category?.toLowerCase() || ''
      return name.includes(query) || category.includes(query)
    })
  }

  return filtered
})

function handleCreateEnvironment() {
  router.push('/environments/new')
}

function openEnvironment(environmentId) {
  router.push(`/environments/${environmentId}`)
}

function getStatusBadgeClass(isActive) {
  return isActive ? 'bg-success-500 text-white' : 'bg-neutral-400 text-white'
}

function getEnvironmentCategory(env) {
  return env.environment_specs?.category || 'interior'
}

function getEnvironmentLighting(env) {
  return env.environment_specs?.lighting_type || 'natural'
}

function formatCategoryLabel(category) {
  return category.charAt(0).toUpperCase() + category.slice(1)
}

function formatLightingLabel(lighting) {
  return lighting.charAt(0).toUpperCase() + lighting.slice(1)
}
</script>

<template>
  <div class="min-h-screen bg-neutral-50">
    <Sidebar />
    <AppHeader />

    <main class="ml-64 px-6 py-8">
      <!-- Page Header -->
      <div class="mb-8">
        <h1 class="text-4xl font-black text-neutral-900 mb-2">Manage Environments</h1>
        <p class="text-base text-neutral-600">
          Create and customize virtual environments for your AI-generated video content.
        </p>
      </div>

      <!-- Filters and Actions -->
      <div class="flex items-center justify-between mb-6">
        <div class="flex items-center gap-2">
          <button
            @click="activeFilter = 'all'"
            :class="[
              'px-5 py-2 rounded-full font-semibold text-sm transition-all',
              activeFilter === 'all'
                ? 'bg-primary-600 text-white shadow-lg shadow-primary-600/40'
                : 'bg-white text-neutral-700 hover:bg-neutral-50'
            ]"
          >
            All Environments
          </button>

          <button
            @click="activeFilter = 'interior'"
            :class="[
              'px-5 py-2 rounded-full font-semibold text-sm transition-all',
              activeFilter === 'interior'
                ? 'bg-primary-600 text-white shadow-lg shadow-primary-600/40'
                : 'bg-white text-neutral-700 hover:bg-neutral-50'
            ]"
          >
            Interior
          </button>

          <button
            @click="activeFilter = 'exterior'"
            :class="[
              'px-5 py-2 rounded-full font-semibold text-sm transition-all',
              activeFilter === 'exterior'
                ? 'bg-primary-600 text-white shadow-lg shadow-primary-600/40'
                : 'bg-white text-neutral-700 hover:bg-neutral-50'
            ]"
          >
            Exterior
          </button>

          <button
            @click="activeFilter = 'commercial'"
            :class="[
              'px-5 py-2 rounded-full font-semibold text-sm transition-all',
              activeFilter === 'commercial'
                ? 'bg-primary-600 text-white shadow-lg shadow-primary-600/40'
                : 'bg-white text-neutral-700 hover:bg-neutral-50'
            ]"
          >
            Commercial
          </button>
        </div>

        <div class="flex items-center gap-3">
          <!-- Active Count -->
          <div class="flex items-center gap-2 px-4 py-2 bg-primary-50 rounded-lg">
            <svg class="w-5 h-5 text-primary-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 11H5m14 0a2 2 0 012 2v6a2 2 0 01-2 2H5a2 2 0 01-2-2v-6a2 2 0 012-2m14 0V9a2 2 0 00-2-2M5 11V9a2 2 0 012-2m0 0V5a2 2 0 012-2h6a2 2 0 012 2v2M7 7h10" />
            </svg>
            <span class="text-sm font-semibold text-primary-700">{{ totalActive }} Active Environments</span>
          </div>

          <!-- Create Button -->
          <button
            @click="handleCreateEnvironment"
            class="btn-primary flex items-center gap-2 shadow-lg shadow-primary-600/40"
          >
            <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v16m8-8H4" />
            </svg>
            Create New Environment
          </button>
        </div>
      </div>

      <!-- Loading State -->
      <div v-if="isLoading" class="text-center py-12">
        <div class="loading-spinner mx-auto"></div>
        <p class="mt-4 text-neutral-600">Loading environments...</p>
      </div>

      <!-- Error State -->
      <div v-else-if="error" class="bg-error-50 border border-error-200 text-error-700 px-4 py-3 rounded-lg">
        {{ error }}
      </div>

      <!-- Environment Grid -->
      <div v-else class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-6">
        <!-- Environment Cards -->
        <div
          v-for="environment in filteredEnvironments"
          :key="environment.id"
          @click="openEnvironment(environment.id)"
          class="card-interactive group cursor-pointer"
        >
          <!-- Environment Image -->
          <div class="relative mb-4 rounded-lg overflow-hidden bg-neutral-100" style="aspect-ratio: 4/3;">
            <!-- Active Result Image (if available) -->
            <img
              v-if="environmentsStore.getActiveResultImage(environment.id)"
              :src="environmentsStore.getActiveResultImage(environment.id).url"
              :alt="environment.name"
              class="w-full h-full object-cover"
            />

            <!-- Processing Placeholder (if no result yet) -->
            <div v-else class="w-full h-full flex items-center justify-center bg-gradient-to-br from-neutral-100 to-neutral-200">
              <div class="text-center">
                <svg class="w-12 h-12 text-neutral-400 mx-auto mb-3 animate-pulse" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 16l4.586-4.586a2 2 0 012.828 0L16 16m-2-2l1.586-1.586a2 2 0 012.828 0L20 14m-6-6h.01M6 20h12a2 2 0 002-2V6a2 2 0 00-2-2H6a2 2 0 00-2 2v12a2 2 0 002 2z" />
                </svg>
                <span class="inline-flex items-center px-3 py-1.5 rounded-full text-xs font-bold tracking-wide bg-warning-500 text-white">
                  🔄 PROCESSING
                </span>
              </div>
            </div>

            <!-- Variant Count Badge (if multiple) -->
            <div
              v-if="environment.result_images && environment.result_images.length > 1"
              class="absolute bottom-2 right-2"
            >
              <span class="inline-flex items-center px-2 py-1 rounded-full text-xs font-bold bg-neutral-900/80 text-white backdrop-blur">
                {{ environment.result_images.length }} variants
              </span>
            </div>

            <!-- Hover Overlay -->
            <div class="absolute inset-0 bg-black bg-opacity-0 group-hover:bg-opacity-20 transition-all flex items-center justify-center opacity-0 group-hover:opacity-100">
              <button class="btn-primary btn-sm">
                View Details
              </button>
            </div>
          </div>

          <!-- Environment Info -->
          <div>
            <h3 class="text-lg font-bold text-neutral-900 mb-1">
              {{ environment.name }}
            </h3>
            <div class="flex items-center gap-3 text-sm text-neutral-500">
              <span>{{ formatCategoryLabel(getEnvironmentCategory(environment)) }}</span>
              <span class="text-neutral-300">•</span>
              <span>{{ formatLightingLabel(getEnvironmentLighting(environment)) }} Lighting</span>
            </div>
          </div>
        </div>

        <!-- New Environment Card -->
        <button
          @click="handleCreateEnvironment"
          class="card-hover flex flex-col items-center justify-center text-center min-h-[320px] group"
        >
          <div class="w-16 h-16 rounded-full bg-neutral-100 flex items-center justify-center mb-4 group-hover:bg-primary-100 transition-colors">
            <svg class="w-8 h-8 text-neutral-400 group-hover:text-primary-600 transition-colors" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v16m8-8H4" />
            </svg>
          </div>
          <h3 class="text-lg font-bold text-neutral-900 mb-2">New Environment</h3>
          <p class="text-sm text-neutral-500 max-w-[200px]">
            Create a custom virtual environment for your videos
          </p>
        </button>
      </div>

      <!-- Empty State (when no results) -->
      <div v-if="filteredEnvironments.length === 0 && searchQuery" class="text-center py-16">
        <div class="w-16 h-16 rounded-full bg-neutral-100 flex items-center justify-center mx-auto mb-4">
          <svg class="w-8 h-8 text-neutral-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z" />
          </svg>
        </div>
        <h3 class="text-lg font-semibold text-neutral-900 mb-2">No environments found</h3>
        <p class="text-neutral-600 mb-4">
          Try adjusting your search terms or filters
        </p>
        <button @click="searchQuery = ''" class="btn-secondary">
          Clear Search
        </button>
      </div>
    </main>
  </div>
</template>
