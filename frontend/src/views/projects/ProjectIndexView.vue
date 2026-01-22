<script setup>
import { ref, computed, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import { useAuthStore } from '@/stores/auth'
import { supabase } from '@/lib/supabase'
import Sidebar from '@/components/common/Sidebar.vue'
import AppHeader from '@/components/common/AppHeader.vue'

const router = useRouter()
const authStore = useAuthStore()

const projects = ref([])
const isLoading = ref(true)
const error = ref(null)
const activeFilter = ref('all')
const searchQuery = ref('')

onMounted(async () => {
  await fetchProjects()
})

async function fetchProjects() {
  isLoading.value = true
  error.value = null

  try {
    const { data, error: fetchError } = await supabase
      .from('projects')
      .select('*')
      .order('created_at', { ascending: false })

    if (fetchError) throw fetchError

    // If no projects exist, add placeholder projects
    if (!data || data.length === 0) {
      projects.value = [
        {
          id: 'placeholder-1',
          name: 'Summer UGC Campaign #1',
          description: 'AI-generated summer product showcase',
          status: 'in_progress',
          created_at: new Date(Date.now() - 2 * 60 * 60 * 1000).toISOString(),
          thumbnail: 'https://images.unsplash.com/photo-1469854523086-cc02fe5d8800?w=400&h=600&fit=crop'
        },
        {
          id: 'placeholder-2',
          name: 'Product Demo - TechWear',
          description: 'Modern tech apparel product shots',
          status: 'draft',
          created_at: '2023-10-22T00:00:00.000Z',
          thumbnail: 'https://images.unsplash.com/photo-1556228852-80a43e04e1ce?w=400&h=600&fit=crop'
        },
        {
          id: 'placeholder-3',
          name: 'Influencer Script V2',
          description: 'Influencer collaboration content',
          status: 'completed',
          created_at: '2023-10-21T00:00:00.000Z',
          thumbnail: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=400&h=600&fit=crop'
        },
        {
          id: 'placeholder-4',
          name: 'Brand Launch Video',
          description: 'New brand identity reveal',
          status: 'completed',
          created_at: '2023-10-15T00:00:00.000Z',
          thumbnail: 'https://images.unsplash.com/photo-1505588255018-74e6c7e5b6f9?w=400&h=600&fit=crop'
        },
        {
          id: 'placeholder-5',
          name: 'Holiday Sales UGC',
          description: 'Seasonal promotional content',
          status: 'completed',
          created_at: '2023-10-10T00:00:00.000Z',
          thumbnail: 'https://images.unsplash.com/photo-1556228852-80a43e04e1ce?w=400&h=600&fit=crop'
        }
      ]
    } else {
      projects.value = data
    }
  } catch (err) {
    console.error('Error fetching projects:', err)
    error.value = 'Failed to load projects'
  } finally {
    isLoading.value = false
  }
}

const filteredProjects = computed(() => {
  let filtered = projects.value

  // Filter by status
  if (activeFilter.value !== 'all') {
    filtered = filtered.filter(project => project.status === activeFilter.value)
  }

  // Filter by search query
  if (searchQuery.value) {
    const query = searchQuery.value.toLowerCase()
    filtered = filtered.filter(project =>
      project.name.toLowerCase().includes(query) ||
      project.description?.toLowerCase().includes(query)
    )
  }

  return filtered
})

const totalProjects = computed(() => projects.value.length)
const draftProjects = computed(() => projects.value.filter(p => p.status === 'draft').length)
const inProgressProjects = computed(() => projects.value.filter(p => p.status === 'in_progress').length)
const completedProjects = computed(() => projects.value.filter(p => p.status === 'completed').length)

function openProject(projectId) {
  router.push(`/projects/${projectId}`)
}

function getStatusBadgeClass(status) {
  const classes = {
    draft: 'bg-neutral-100 text-neutral-700',
    in_progress: 'bg-primary-500 text-white',
    completed: 'bg-success-500 text-white',
    archived: 'bg-neutral-200 text-neutral-600'
  }
  return classes[status] || classes.draft
}

function getStatusLabel(status) {
  const labels = {
    draft: 'DRAFT',
    in_progress: 'RENDERING',
    completed: 'COMPLETED',
    archived: 'ARCHIVED'
  }
  return labels[status] || status.toUpperCase()
}

function formatDate(dateString) {
  const date = new Date(dateString)
  const now = new Date()
  const diffInHours = (now - date) / (1000 * 60 * 60)

  if (diffInHours < 24) {
    const hours = Math.floor(diffInHours)
    return `Modified ${hours} hours ago`
  }

  return `Created ${date.toLocaleDateString('en-US', { month: 'short', day: 'numeric', year: 'numeric' })}`
}

function getProjectThumbnail(project) {
  // Return project thumbnail if available, otherwise use placeholder
  return project.thumbnail || 'https://images.unsplash.com/photo-1492691527719-9d1e07e534b4?w=400&h=600&fit=crop'
}

function handleCreateProject() {
  router.push('/projects/new')
}
</script>

<template>
  <div class="min-h-screen bg-neutral-50">
    <Sidebar />
    <AppHeader />

    <main class="ml-64 px-6 py-8">
      <!-- Page Header -->
      <div class="mb-8">
        <h1 class="text-4xl font-black text-neutral-900 mb-2">Projects</h1>
        <p class="text-base text-neutral-600">
          Manage and create your AI-generated UGC clips.
        </p>
      </div>

      <!-- Filters and New Project Button -->
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
            All Projects
          </button>

          <button
            @click="activeFilter = 'draft'"
            :class="[
              'px-5 py-2 rounded-full font-semibold text-sm transition-all',
              activeFilter === 'draft'
                ? 'bg-primary-600 text-white shadow-lg shadow-primary-600/40'
                : 'bg-white text-neutral-700 hover:bg-neutral-50'
            ]"
          >
            Drafts
          </button>

          <button
            @click="activeFilter = 'in_progress'"
            :class="[
              'px-5 py-2 rounded-full font-semibold text-sm transition-all',
              activeFilter === 'in_progress'
                ? 'bg-primary-600 text-white shadow-lg shadow-primary-600/40'
                : 'bg-white text-neutral-700 hover:bg-neutral-50'
            ]"
          >
            In Progress
          </button>

          <button
            @click="activeFilter = 'completed'"
            :class="[
              'px-5 py-2 rounded-full font-semibold text-sm transition-all',
              activeFilter === 'completed'
                ? 'bg-primary-600 text-white shadow-lg shadow-primary-600/40'
                : 'bg-white text-neutral-700 hover:bg-neutral-50'
            ]"
          >
            Completed
          </button>
        </div>

        <!-- Create Button -->
        <button
          @click="handleCreateProject"
          class="btn-primary flex items-center gap-2 shadow-lg shadow-primary-600/40"
        >
          <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v16m8-8H4" />
          </svg>
          New Project
        </button>
      </div>

      <!-- Loading State -->
      <div v-if="isLoading" class="text-center py-12">
        <div class="loading-spinner mx-auto"></div>
        <p class="mt-4 text-neutral-600">Loading projects...</p>
      </div>

      <!-- Error State -->
      <div v-else-if="error" class="bg-error-50 border border-error-200 text-error-700 px-4 py-3 rounded-lg">
        {{ error }}
      </div>

      <!-- Empty State -->
      <div v-else-if="filteredProjects.length === 0 && !searchQuery" class="text-center py-16">
        <div class="w-16 h-16 rounded-full bg-neutral-100 flex items-center justify-center mx-auto mb-4">
          <svg class="w-8 h-8 text-neutral-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 7v10a2 2 0 002 2h14a2 2 0 002-2V9a2 2 0 00-2-2h-6l-2-2H5a2 2 0 00-2 2z" />
          </svg>
        </div>
        <h3 class="text-lg font-semibold text-neutral-900 mb-2">No projects yet</h3>
        <p class="text-neutral-600 mb-4">
          Create your first project to start producing video content.
        </p>
        <button @click="handleCreateProject" class="btn-primary">
          Create Your First Project
        </button>
      </div>

      <!-- No Results -->
      <div v-else-if="filteredProjects.length === 0 && searchQuery" class="text-center py-16">
        <div class="w-16 h-16 rounded-full bg-neutral-100 flex items-center justify-center mx-auto mb-4">
          <svg class="w-8 h-8 text-neutral-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z" />
          </svg>
        </div>
        <h3 class="text-lg font-semibold text-neutral-900 mb-2">No projects found</h3>
        <p class="text-neutral-600 mb-4">
          Try adjusting your search terms or filters
        </p>
        <button @click="searchQuery = ''" class="btn-secondary">
          Clear Search
        </button>
      </div>

      <!-- Projects Grid -->
      <div v-else class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
        <!-- Project Cards -->
        <div
          v-for="project in filteredProjects"
          :key="project.id"
          class="card-interactive group"
        >
          <!-- Project Thumbnail -->
          <div class="relative mb-4 rounded-lg overflow-hidden bg-neutral-100" style="aspect-ratio: 2/3;">
            <img
              :src="getProjectThumbnail(project)"
              :alt="project.name"
              class="w-full h-full object-cover"
            />

            <!-- Status Badge -->
            <div class="absolute top-3 right-3">
              <span
                :class="[
                  'inline-flex items-center px-2.5 py-1 rounded text-xs font-bold tracking-wide',
                  getStatusBadgeClass(project.status)
                ]"
              >
                {{ getStatusLabel(project.status) }}
              </span>
            </div>

            <!-- Progress Bar (for in_progress projects) -->
            <div v-if="project.status === 'in_progress'" class="absolute bottom-0 left-0 right-0 bg-black bg-opacity-50 p-3">
              <div class="flex items-center justify-between mb-1">
                <span class="text-xs text-white font-medium">GENERATING VIDEO</span>
                <span class="text-xs text-white font-bold">45%</span>
              </div>
              <div class="w-full bg-neutral-700 rounded-full h-1.5">
                <div class="bg-primary-500 h-1.5 rounded-full" style="width: 45%"></div>
              </div>
            </div>

            <!-- Hover Overlay -->
            <div class="absolute inset-0 bg-black bg-opacity-0 group-hover:bg-opacity-20 transition-all flex items-center justify-center opacity-0 group-hover:opacity-100">
              <button
                @click="openProject(project.id)"
                class="btn-primary btn-sm"
              >
                {{ project.status === 'draft' ? 'Continue Editing' : 'View Details' }}
              </button>
            </div>
          </div>

          <!-- Project Info -->
          <div>
            <h3 class="text-lg font-bold text-neutral-900 mb-1 line-clamp-1">
              {{ project.name }}
            </h3>
            <p v-if="project.description" class="text-sm text-neutral-500 mb-3 line-clamp-2">
              {{ project.description }}
            </p>
            <div class="text-sm text-neutral-500">
              {{ formatDate(project.created_at) }}
            </div>
          </div>

          <!-- Project Actions Menu -->
          <div class="absolute top-3 right-3 opacity-0 group-hover:opacity-100 transition-opacity">
            <button class="w-8 h-8 rounded-lg bg-white shadow-md flex items-center justify-center hover:bg-neutral-50">
              <svg class="w-5 h-5 text-neutral-700" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 5v.01M12 12v.01M12 19v.01M12 6a1 1 0 110-2 1 1 0 010 2zm0 7a1 1 0 110-2 1 1 0 010 2zm0 7a1 1 0 110-2 1 1 0 010 2z" />
              </svg>
            </button>
          </div>
        </div>

        <!-- New Project Card -->
        <button
          @click="handleCreateProject"
          class="card-hover flex flex-col items-center justify-center text-center min-h-[450px] group"
        >
          <div class="w-16 h-16 rounded-full bg-neutral-100 flex items-center justify-center mb-4 group-hover:bg-primary-100 transition-colors">
            <svg class="w-8 h-8 text-neutral-400 group-hover:text-primary-600 transition-colors" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v16m8-8H4" />
            </svg>
          </div>
          <h3 class="text-lg font-bold text-neutral-900 mb-2">New Project</h3>
          <p class="text-sm text-neutral-500 max-w-[200px]">
            Start creating your next video campaign
          </p>
        </button>
      </div>
    </main>
  </div>
</template>
