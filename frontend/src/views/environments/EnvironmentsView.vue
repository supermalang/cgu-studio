<script setup>
import { ref, computed } from 'vue'
import { useRouter } from 'vue-router'
import Sidebar from '@/components/common/Sidebar.vue'
import AppHeader from '@/components/common/AppHeader.vue'

const router = useRouter()

// Mock data for environments
const environments = ref([
  {
    id: 1,
    name: 'Modern Home Office',
    category: 'Interior',
    imageUrl: 'https://images.unsplash.com/photo-1484154218962-a197022b5858?w=400&h=400&fit=crop',
    lighting: 'Natural',
    version: 'v2.0',
    status: 'ready'
  },
  {
    id: 2,
    name: 'Luxury Car Interior',
    category: 'Vehicle',
    imageUrl: 'https://images.unsplash.com/photo-1549399542-7e3f8b79c341?w=400&h=400&fit=crop',
    lighting: 'Studio',
    version: 'v1.5',
    status: null
  },
  {
    id: 3,
    name: 'Coffee Shop',
    category: 'Commercial',
    imageUrl: 'https://images.unsplash.com/photo-1501339847302-ac426a4a7cbb?w=400&h=400&fit=crop',
    lighting: 'Ambient',
    version: 'v3.0',
    status: null
  },
  {
    id: 4,
    name: 'Retail Store',
    category: 'Commercial',
    imageUrl: 'https://images.unsplash.com/photo-1441986300917-64674bd600d8?w=400&h=400&fit=crop',
    lighting: 'Bright',
    version: 'v1.0',
    status: 'in_sync'
  },
  {
    id: 5,
    name: 'Outdoor Park',
    category: 'Exterior',
    imageUrl: 'https://images.unsplash.com/photo-1551006917-7c3efc9ecc8a?w=400&h=400&fit=crop',
    lighting: 'Natural',
    version: 'v2.1',
    status: null
  },
  {
    id: 6,
    name: 'Studio Setup',
    category: 'Interior',
    imageUrl: 'https://images.unsplash.com/photo-1478720568477-152d9b164e26?w=400&h=400&fit=crop',
    lighting: 'Studio',
    version: 'v1.8',
    status: 'ready'
  }
])

const activeFilter = ref('all')
const searchQuery = ref('')

const totalActive = computed(() => environments.value.length)

const filteredEnvironments = computed(() => {
  let filtered = environments.value

  if (searchQuery.value) {
    filtered = filtered.filter(env =>
      env.name.toLowerCase().includes(searchQuery.value.toLowerCase()) ||
      env.category.toLowerCase().includes(searchQuery.value.toLowerCase())
    )
  }

  return filtered
})

function handleCreateEnvironment() {
  router.push('/environments/new')
}

function openEnvironment(environmentId) {
  router.push(`/environments/${environmentId}`)
}

function getStatusBadgeClass(status) {
  const classes = {
    ready: 'bg-success-500 text-white',
    in_sync: 'bg-primary-500 text-white'
  }
  return classes[status] || ''
}

function getStatusLabel(status) {
  const labels = {
    ready: 'READY',
    in_sync: 'IN SYNC'
  }
  return labels[status] || status.toUpperCase()
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

      <!-- Environment Grid -->
      <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-6">
        <!-- Environment Cards -->
        <div
          v-for="environment in filteredEnvironments"
          :key="environment.id"
          @click="openEnvironment(environment.id)"
          class="card-interactive group cursor-pointer"
        >
          <!-- Environment Image -->
          <div class="relative mb-4 rounded-lg overflow-hidden bg-neutral-100" style="aspect-ratio: 4/3;">
            <img
              :src="environment.imageUrl"
              :alt="environment.name"
              class="w-full h-full object-cover"
            />

            <!-- Status Badge -->
            <div
              v-if="environment.status"
              class="absolute top-3 right-3"
            >
              <span
                :class="[
                  'inline-flex items-center px-2.5 py-1 rounded text-xs font-bold tracking-wide',
                  getStatusBadgeClass(environment.status)
                ]"
              >
                {{ getStatusLabel(environment.status) }}
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
              <span>{{ environment.category }}</span>
              <span class="text-neutral-300">•</span>
              <span>{{ environment.lighting }} Lighting</span>
            </div>
            <div class="text-sm text-neutral-400 mt-1">
              {{ environment.version }}
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
