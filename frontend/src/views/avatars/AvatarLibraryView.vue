<script setup>
import { ref, computed } from 'vue'
import { useRouter } from 'vue-router'
import Sidebar from '@/components/common/Sidebar.vue'
import AppHeader from '@/components/common/AppHeader.vue'

const router = useRouter()

// Mock data for avatars
const avatars = ref([
  {
    id: 1,
    name: 'Sarah',
    category: 'Lifestyle',
    imageUrl: 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=400&h=400&fit=crop',
    outfits: 5,
    version: 'v2.1',
    status: 'ready'
  },
  {
    id: 2,
    name: 'Mike',
    category: 'Tech',
    imageUrl: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=400&h=400&fit=crop',
    outfits: 3,
    version: 'v1.0',
    status: null
  },
  {
    id: 3,
    name: 'Elena',
    category: 'Corporate',
    imageUrl: 'https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?w=400&h=400&fit=crop',
    outfits: 4,
    version: 'v3.4',
    status: null
  },
  {
    id: 4,
    name: 'Jordan',
    category: 'Streetwear',
    imageUrl: 'https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?w=400&h=400&fit=crop',
    outfits: 6,
    version: 'v1.2',
    status: 'in_sync'
  },
  {
    id: 5,
    name: 'Chloe',
    category: 'Fitness',
    imageUrl: 'https://images.unsplash.com/photo-1524504388940-b1c1722653e1?w=400&h=400&fit=crop',
    outfits: 2,
    version: 'v2.0',
    status: null
  }
])

const activeFilter = ref('all')
const searchQuery = ref('')

const totalActive = computed(() => avatars.value.length)

const filteredAvatars = computed(() => {
  let filtered = avatars.value

  if (searchQuery.value) {
    filtered = filtered.filter(avatar =>
      avatar.name.toLowerCase().includes(searchQuery.value.toLowerCase()) ||
      avatar.category.toLowerCase().includes(searchQuery.value.toLowerCase())
    )
  }

  return filtered
})

function handleCreateAvatar() {
  // Navigate to create avatar page or show modal
  console.log('Create new avatar')
}

function getStatusBadge(status) {
  if (status === 'ready') return 'status-completed'
  if (status === 'in_sync') return 'status-generating'
  return ''
}

function getStatusLabel(status) {
  if (status === 'ready') return 'READY'
  if (status === 'in_sync') return 'IN SYNC'
  return ''
}
</script>

<template>
  <div class="min-h-screen bg-neutral-50">
    <Sidebar />
    <AppHeader />

    <main class="ml-64 px-6 py-8">
      <!-- Page Header -->
      <div class="mb-8">
        <h1 class="text-4xl font-black text-neutral-900 mb-2">Manage Avatars</h1>
        <p class="text-base text-neutral-600">
          Create and customize AI actors for your brand's video content campaigns.
        </p>
      </div>

      <!-- Filters and Search -->
      <div class="flex items-center justify-between mb-6">
        <div class="flex items-center gap-3">
          <button
            @click="activeFilter = 'all'"
            :class="[
              'px-4 py-2 rounded-lg font-medium text-sm transition-all',
              activeFilter === 'all'
                ? 'bg-neutral-900 text-white'
                : 'bg-white text-neutral-700 border border-neutral-200 hover:border-neutral-300'
            ]"
          >
            All Avatars
          </button>

          <button
            @click="activeFilter = 'recent'"
            :class="[
              'px-4 py-2 rounded-lg font-medium text-sm transition-all flex items-center gap-2',
              activeFilter === 'recent'
                ? 'bg-neutral-900 text-white'
                : 'bg-white text-neutral-700 border border-neutral-200 hover:border-neutral-300'
            ]"
          >
            Recent
            <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 9l-7 7-7-7" />
            </svg>
          </button>

          <button
            @click="activeFilter = 'templates'"
            :class="[
              'px-4 py-2 rounded-lg font-medium text-sm transition-all flex items-center gap-2',
              activeFilter === 'templates'
                ? 'bg-neutral-900 text-white'
                : 'bg-white text-neutral-700 border border-neutral-200 hover:border-neutral-300'
            ]"
          >
            Custom Templates
            <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 9l-7 7-7-7" />
            </svg>
          </button>

          <button
            @click="activeFilter = 'archived'"
            :class="[
              'px-4 py-2 rounded-lg font-medium text-sm transition-all',
              activeFilter === 'archived'
                ? 'bg-neutral-900 text-white'
                : 'bg-white text-neutral-700 border border-neutral-200 hover:border-neutral-300'
            ]"
          >
            Archived
          </button>
        </div>

        <div class="flex items-center gap-3">
          <!-- Search -->
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
              v-model="searchQuery"
              type="text"
              placeholder="Search avatars..."
              class="pl-10 pr-4 py-2 border border-neutral-200 rounded-lg bg-white focus:outline-none focus:ring-2 focus:ring-primary-500 focus:border-transparent w-64"
            />
          </div>

          <!-- Active Count -->
          <div class="flex items-center gap-2 px-4 py-2 bg-primary-50 rounded-lg">
            <svg class="w-5 h-5 text-primary-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4.354a4 4 0 110 5.292M15 21H3v-1a6 6 0 0112 0v1zm0 0h6v-1a6 6 0 00-9-5.197M13 7a4 4 0 11-8 0 4 4 0 018 0z" />
            </svg>
            <span class="text-sm font-semibold text-primary-700">{{ totalActive }} Active Avatars</span>
          </div>

          <!-- Create Button -->
          <button
            @click="handleCreateAvatar"
            class="btn-primary flex items-center gap-2"
          >
            <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v16m8-8H4" />
            </svg>
            Create New Avatar
          </button>
        </div>
      </div>

      <!-- Avatar Grid -->
      <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-6">
        <!-- Avatar Cards -->
        <div
          v-for="avatar in filteredAvatars"
          :key="avatar.id"
          class="card-interactive group"
        >
          <!-- Avatar Image -->
          <div class="relative mb-4 rounded-lg overflow-hidden bg-neutral-100" style="aspect-ratio: 3/4;">
            <img
              :src="avatar.imageUrl"
              :alt="avatar.name"
              class="w-full h-full object-cover"
            />

            <!-- Status Badge -->
            <div
              v-if="avatar.status"
              class="absolute top-3 right-3"
            >
              <span
                :class="[
                  'inline-flex items-center px-2.5 py-1 rounded text-xs font-bold tracking-wide',
                  avatar.status === 'ready' ? 'bg-success-500 text-white' : 'bg-primary-500 text-white'
                ]"
              >
                {{ getStatusLabel(avatar.status) }}
              </span>
            </div>

            <!-- Hover Overlay -->
            <div class="absolute inset-0 bg-black bg-opacity-0 group-hover:bg-opacity-20 transition-all flex items-center justify-center opacity-0 group-hover:opacity-100">
              <button class="btn-primary btn-sm">
                View Details
              </button>
            </div>
          </div>

          <!-- Avatar Info -->
          <div>
            <h3 class="text-lg font-bold text-neutral-900 mb-1">
              {{ avatar.name }} - {{ avatar.category }}
            </h3>
            <div class="flex items-center gap-3 text-sm text-neutral-500">
              <span>{{ avatar.outfits }} Outfits</span>
              <span class="text-neutral-300">•</span>
              <span>{{ avatar.version }}</span>
            </div>
          </div>
        </div>

        <!-- New Avatar Card -->
        <button
          @click="handleCreateAvatar"
          class="card-hover flex flex-col items-center justify-center text-center min-h-[400px] group"
        >
          <div class="w-16 h-16 rounded-full bg-neutral-100 flex items-center justify-center mb-4 group-hover:bg-primary-100 transition-colors">
            <svg class="w-8 h-8 text-neutral-400 group-hover:text-primary-600 transition-colors" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v16m8-8H4" />
            </svg>
          </div>
          <h3 class="text-lg font-bold text-neutral-900 mb-2">New Avatar</h3>
          <p class="text-sm text-neutral-500 max-w-[200px]">
            Train a new AI actor with your unique style
          </p>
        </button>
      </div>

      <!-- Empty State (when no results) -->
      <div v-if="filteredAvatars.length === 0 && searchQuery" class="text-center py-16">
        <div class="w-16 h-16 rounded-full bg-neutral-100 flex items-center justify-center mx-auto mb-4">
          <svg class="w-8 h-8 text-neutral-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z" />
          </svg>
        </div>
        <h3 class="text-lg font-semibold text-neutral-900 mb-2">No avatars found</h3>
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
