<script setup>
import { ref, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import { useAuthStore } from '@/stores/auth'
import { supabase } from '@/lib/supabase'
import AppHeader from '@/components/common/AppHeader.vue'

const router = useRouter()
const authStore = useAuthStore()

const projects = ref([])
const isLoading = ref(true)
const error = ref(null)
const showCreateModal = ref(false)

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
    projects.value = data || []
  } catch (err) {
    console.error('Error fetching projects:', err)
    error.value = 'Failed to load projects'
  } finally {
    isLoading.value = false
  }
}

function openProject(projectId) {
  router.push(`/projects/${projectId}`)
}

function getStatusColor(status) {
  const colors = {
    draft: 'bg-gray-100 text-gray-800',
    in_progress: 'bg-blue-100 text-blue-800',
    completed: 'bg-green-100 text-green-800',
    archived: 'bg-gray-100 text-gray-600'
  }
  return colors[status] || colors.draft
}

function formatDate(dateString) {
  const date = new Date(dateString)
  return date.toLocaleDateString('en-US', {
    year: 'numeric',
    month: 'short',
    day: 'numeric'
  })
}
</script>

<template>
  <div class="min-h-screen bg-neutral-50">
    <AppHeader />

    <main class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
      <!-- Welcome Section -->
      <div class="mb-8">
        <h1 class="text-3xl font-bold text-neutral-900 mb-2">
          Welcome back, {{ authStore.profile?.full_name }}!
        </h1>
        <p class="text-gray-600">
          Manage your video projects and create amazing content.
        </p>
      </div>

      <!-- Quick Stats -->
      <div class="grid grid-cols-1 md:grid-cols-3 gap-6 mb-8">
        <div class="card">
          <div class="flex items-center justify-between">
            <div>
              <p class="text-sm text-gray-600 mb-1">Total Projects</p>
              <p class="text-2xl font-bold text-neutral-900">{{ projects.length }}</p>
            </div>
            <div class="w-12 h-12 bg-primary/10 rounded-lg flex items-center justify-center">
              <svg class="w-6 h-6 text-primary" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 7v10a2 2 0 002 2h14a2 2 0 002-2V9a2 2 0 00-2-2h-6l-2-2H5a2 2 0 00-2 2z" />
              </svg>
            </div>
          </div>
        </div>

        <div class="card">
          <div class="flex items-center justify-between">
            <div>
              <p class="text-sm text-gray-600 mb-1">Credits Available</p>
              <p class="text-2xl font-bold text-neutral-900">{{ authStore.creditBalance }}</p>
            </div>
            <div class="w-12 h-12 bg-success/10 rounded-lg flex items-center justify-center">
              <svg class="w-6 h-6 text-success" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8c-1.657 0-3 .895-3 2s1.343 2 3 2 3 .895 3 2-1.343 2-3 2m0-8c1.11 0 2.08.402 2.599 1M12 8V7m0 1v8m0 0v1m0-1c-1.11 0-2.08-.402-2.599-1M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
              </svg>
            </div>
          </div>
        </div>

        <div class="card">
          <div class="flex items-center justify-between">
            <div>
              <p class="text-sm text-gray-600 mb-1">Active Projects</p>
              <p class="text-2xl font-bold text-neutral-900">
                {{ projects.filter(p => p.status === 'in_progress').length }}
              </p>
            </div>
            <div class="w-12 h-12 bg-blue-100 rounded-lg flex items-center justify-center">
              <svg class="w-6 h-6 text-blue-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 10V3L4 14h7v7l9-11h-7z" />
              </svg>
            </div>
          </div>
        </div>
      </div>

      <!-- Projects Section -->
      <div class="flex items-center justify-between mb-6">
        <h2 class="text-xl font-bold text-neutral-900">Your Projects</h2>
        <button
          @click="showCreateModal = true"
          class="btn-primary"
        >
          <svg class="w-5 h-5 inline-block mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v16m8-8H4" />
          </svg>
          New Project
        </button>
      </div>

      <!-- Loading State -->
      <div v-if="isLoading" class="text-center py-12">
        <div class="inline-block animate-spin rounded-full h-8 w-8 border-b-2 border-primary"></div>
        <p class="mt-2 text-gray-600">Loading projects...</p>
      </div>

      <!-- Error State -->
      <div v-else-if="error" class="bg-red-50 border border-red-200 text-red-700 px-4 py-3 rounded-lg">
        {{ error }}
      </div>

      <!-- Empty State -->
      <div v-else-if="projects.length === 0" class="text-center py-12">
        <div class="w-16 h-16 bg-gray-100 rounded-full flex items-center justify-center mx-auto mb-4">
          <svg class="w-8 h-8 text-gray-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 7v10a2 2 0 002 2h14a2 2 0 002-2V9a2 2 0 00-2-2h-6l-2-2H5a2 2 0 00-2 2z" />
          </svg>
        </div>
        <h3 class="text-lg font-medium text-neutral-900 mb-2">No projects yet</h3>
        <p class="text-gray-600 mb-4">Create your first project to start producing video content.</p>
        <button @click="showCreateModal = true" class="btn-primary">
          Create Your First Project
        </button>
      </div>

      <!-- Projects Grid -->
      <div v-else class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
        <div
          v-for="project in projects"
          :key="project.id"
          @click="openProject(project.id)"
          class="card cursor-pointer hover:shadow-md transition-shadow"
        >
          <div class="flex items-start justify-between mb-3">
            <h3 class="text-lg font-semibold text-neutral-900 line-clamp-1">
              {{ project.name }}
            </h3>
            <span
              :class="getStatusColor(project.status)"
              class="px-2 py-1 text-xs font-medium rounded-full"
            >
              {{ project.status.replace('_', ' ') }}
            </span>
          </div>

          <p v-if="project.description" class="text-sm text-gray-600 mb-4 line-clamp-2">
            {{ project.description }}
          </p>

          <div class="flex items-center justify-between text-sm text-gray-500">
            <div class="flex items-center space-x-4">
              <span>{{ project.total_shots }} shots</span>
              <span>{{ project.total_credits_used }} credits</span>
            </div>
            <span>{{ formatDate(project.created_at) }}</span>
          </div>
        </div>
      </div>
    </main>

    <!-- Create Project Modal (placeholder for now) -->
    <div
      v-if="showCreateModal"
      class="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50 p-4"
      @click.self="showCreateModal = false"
    >
      <div class="bg-white rounded-lg max-w-md w-full p-6">
        <h2 class="text-xl font-bold mb-4">Create New Project</h2>
        <p class="text-gray-600 mb-4">Project creation form coming soon!</p>
        <button @click="showCreateModal = false" class="btn-primary w-full">
          Close
        </button>
      </div>
    </div>
  </div>
</template>
