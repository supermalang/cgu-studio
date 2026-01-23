<script setup>
import { ref, computed, onMounted } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { useAuthStore } from '@/stores/auth'
import { supabase } from '@/lib/supabase'
import Sidebar from '@/components/common/Sidebar.vue'
import AppHeader from '@/components/common/AppHeader.vue'

const route = useRoute()
const router = useRouter()
const authStore = useAuthStore()

const environmentId = route.params.id

// State
const environment = ref(null)
const isLoading = ref(true)
const error = ref(null)
const showDeleteModal = ref(false)
const isDeleting = ref(false)
const isDummyData = ref(false)

// Projects using this environment (mock data for now)
const projectsUsingEnvironment = ref([
  {
    id: 1,
    name: 'Summer Campaign 2024',
    status: 'completed',
    created_at: '2024-01-15'
  },
  {
    id: 2,
    name: 'Product Launch Video',
    status: 'in_progress',
    created_at: '2024-01-20'
  }
])

onMounted(async () => {
  await fetchEnvironment()
})

async function fetchEnvironment() {
  isLoading.value = true
  error.value = null
  isDummyData.value = false

  try {
    // First, check if environments table has any records
    const { count, error: countError } = await supabase
      .from('environments')
      .select('*', { count: 'exact', head: true })

    if (countError) throw countError

    // If table is empty, show dummy data
    if (count === 0) {
      isDummyData.value = true
      environment.value = {
        id: environmentId,
        name: 'Modern Home Office',
        description: 'A clean, contemporary home office setup perfect for professional content creation.',
        reference_image_url: 'https://images.unsplash.com/photo-1484154218962-a197022b5858?w=800&h=600&fit=crop',
        is_active: true,
        created_at: new Date().toISOString(),
        updated_at: new Date().toISOString(),
        environment_specs: {
          category: 'interior',
          lighting_type: 'natural',
          background_color: '#ffffff',
          ambient_intensity: 70,
          visual_style: 'modern',
          mood_tone: 'professional',
          wall_color: '#f5f5f5',
          floor_type: 'wood',
          include_windows: true,
          include_props: true,
          room_size: 'medium'
        }
      }
    } else {
      // Table has data, fetch the specific environment
      const { data, error: fetchError } = await supabase
        .from('environments')
        .select('*')
        .eq('id', environmentId)
        .single()

      if (fetchError) {
        // Check if it's a "not found" error
        if (fetchError.code === 'PGRST116') {
          error.value = 'Environment not found'
          environment.value = null
        } else {
          throw fetchError
        }
      } else {
        environment.value = data
      }
    }
  } catch (err) {
    console.error('Error fetching environment:', err)
    error.value = 'Failed to load environment details'
  } finally {
    isLoading.value = false
  }
}

async function handleToggleActive() {
  if (!environment.value) return

  try {
    const { error: updateError } = await supabase
      .from('environments')
      .update({
        is_active: !environment.value.is_active,
        updated_by: authStore.user.id,
        updated_at: new Date().toISOString()
      })
      .eq('id', environmentId)

    if (updateError) throw updateError

    environment.value.is_active = !environment.value.is_active
  } catch (err) {
    console.error('Error updating environment:', err)
    error.value = 'Failed to update environment status'
  }
}

async function handleDelete() {
  isDeleting.value = true

  try {
    const { error: deleteError } = await supabase
      .from('environments')
      .delete()
      .eq('id', environmentId)

    if (deleteError) throw deleteError

    router.push('/environments')
  } catch (err) {
    console.error('Error deleting environment:', err)
    error.value = 'Failed to delete environment'
    showDeleteModal.value = false
  } finally {
    isDeleting.value = false
  }
}

function handleEdit() {
  // Navigate to edit page (to be created)
  router.push(`/environments/${environmentId}/edit`)
}

function getStatusBadgeClass(status) {
  const classes = {
    draft: 'bg-neutral-100 text-neutral-700',
    in_progress: 'bg-primary-500 text-white',
    completed: 'bg-success-500 text-white'
  }
  return classes[status] || classes.draft
}

function getStatusLabel(status) {
  const labels = {
    draft: 'DRAFT',
    in_progress: 'RENDERING',
    completed: 'COMPLETED'
  }
  return labels[status] || status.toUpperCase()
}

function formatDate(dateString) {
  return new Date(dateString).toLocaleDateString('en-US', {
    month: 'short',
    day: 'numeric',
    year: 'numeric'
  })
}

const specs = computed(() => environment.value?.environment_specs || {})
const usageCount = computed(() => projectsUsingEnvironment.value.length)
</script>

<template>
  <div class="min-h-screen bg-neutral-50">
    <Sidebar />
    <AppHeader />

    <main class="ml-64 px-6 py-8">
      <!-- Loading State -->
      <div v-if="isLoading" class="text-center py-12">
        <div class="loading-spinner mx-auto"></div>
        <p class="mt-4 text-neutral-600">Loading environment...</p>
      </div>

      <!-- Error State -->
      <div v-else-if="error && !environment" class="max-w-4xl mx-auto">
        <div class="text-center py-16">
          <div class="w-20 h-20 rounded-full bg-error-100 flex items-center justify-center mx-auto mb-6">
            <svg class="w-10 h-10 text-error-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z" />
            </svg>
          </div>
          <h2 class="text-2xl font-bold text-neutral-900 mb-2">Environment Not Found</h2>
          <p class="text-neutral-600 mb-8 max-w-md mx-auto">
            The environment you're looking for doesn't exist or may have been deleted.
          </p>
          <div class="flex items-center justify-center gap-3">
            <button
              @click="router.push('/environments')"
              class="btn-secondary"
            >
              <svg class="w-5 h-5 mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M10 19l-7-7m0 0l7-7m-7 7h18" />
              </svg>
              Back to Environments
            </button>
            <button
              @click="router.push('/environments/new')"
              class="btn-primary"
            >
              <svg class="w-5 h-5 mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v16m8-8H4" />
              </svg>
              Create New Environment
            </button>
          </div>
        </div>
      </div>

      <!-- Environment Details -->
      <div v-else-if="environment" class="max-w-7xl mx-auto">
        <!-- Demo Banner -->
        <div v-if="isDummyData" class="mb-6 bg-blue-50 border border-blue-200 rounded-lg p-4 flex items-start gap-3">
          <div class="flex-shrink-0">
            <svg class="w-6 h-6 text-blue-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
            </svg>
          </div>
          <div class="flex-1">
            <h3 class="text-sm font-bold text-blue-900 mb-1">Example Environment</h3>
            <p class="text-sm text-blue-700">
              This is example content to help you understand environments. Create your first environment to get started.
            </p>
          </div>
          <button
            @click="router.push('/environments/new')"
            class="flex-shrink-0 btn-primary btn-sm bg-blue-600 hover:bg-blue-700"
          >
            Create Environment
          </button>
        </div>

        <!-- Breadcrumb -->
        <div class="flex items-center gap-2 mb-6 text-sm text-neutral-500">
          <router-link to="/environments" class="hover:text-neutral-900">ENVIRONMENTS</router-link>
          <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5l7 7-7 7" />
          </svg>
          <span class="text-neutral-900 font-medium">{{ environment.name }}</span>
        </div>

        <!-- Header Section -->
        <div class="flex items-start justify-between mb-8">
          <div class="flex-1">
            <div class="flex items-center gap-3 mb-2">
              <h1 class="text-4xl font-black text-neutral-900">{{ environment.name }}</h1>
              <span
                v-if="isDummyData"
                class="inline-flex items-center px-3 py-1 rounded-full text-xs font-bold tracking-wide bg-blue-100 text-blue-700"
              >
                DEMO
              </span>
              <span
                v-else
                :class="[
                  'inline-flex items-center px-3 py-1 rounded-full text-xs font-bold tracking-wide',
                  environment.is_active
                    ? 'bg-success-100 text-success-700'
                    : 'bg-neutral-100 text-neutral-700'
                ]"
              >
                {{ environment.is_active ? 'ACTIVE' : 'INACTIVE' }}
              </span>
            </div>
            <p v-if="environment.description" class="text-base text-neutral-600 max-w-3xl">
              {{ environment.description }}
            </p>
          </div>

          <div v-if="!isDummyData" class="flex items-center gap-3">
            <button
              @click="handleToggleActive"
              :class="[
                'btn-secondary',
                environment.is_active ? '' : 'bg-success-50 text-success-700 border-success-200 hover:bg-success-100'
              ]"
            >
              {{ environment.is_active ? 'Deactivate' : 'Activate' }}
            </button>
            <button @click="handleEdit" class="btn-secondary">
              <svg class="w-5 h-5 mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M11 5H6a2 2 0 00-2 2v11a2 2 0 002 2h11a2 2 0 002-2v-5m-1.414-9.414a2 2 0 112.828 2.828L11.828 15H9v-2.828l8.586-8.586z" />
              </svg>
              Edit
            </button>
            <button @click="showDeleteModal = true" class="btn-secondary text-error-600 border-error-200 hover:bg-error-50">
              <svg class="w-5 h-5 mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16" />
              </svg>
              Delete
            </button>
          </div>
        </div>

        <!-- Error Message -->
        <div v-if="error" class="mb-6 bg-error-50 border border-error-200 text-error-700 px-4 py-3 rounded-lg">
          {{ error }}
        </div>

        <div class="grid grid-cols-1 lg:grid-cols-3 gap-6">
          <!-- Left Column - Preview & Details -->
          <div class="lg:col-span-2 space-y-6">
            <!-- Preview Image -->
            <div class="card">
              <h2 class="text-lg font-bold text-neutral-900 mb-4">Preview</h2>
              <div class="relative rounded-lg overflow-hidden bg-neutral-100" style="aspect-ratio: 16/9;">
                <img
                  v-if="environment.reference_image_url"
                  :src="environment.reference_image_url"
                  :alt="environment.name"
                  class="w-full h-full object-cover"
                />
                <div v-else class="w-full h-full flex items-center justify-center">
                  <div class="text-center text-neutral-400">
                    <svg class="w-16 h-16 mx-auto mb-3" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 16l4.586-4.586a2 2 0 012.828 0L16 16m-2-2l1.586-1.586a2 2 0 012.828 0L20 14m-6-6h.01M6 20h12a2 2 0 002-2V6a2 2 0 00-2-2H6a2 2 0 00-2 2v12a2 2 0 002 2z" />
                    </svg>
                    <p class="text-sm">No preview image</p>
                  </div>
                </div>
              </div>
            </div>

            <!-- Specifications -->
            <div class="card">
              <div class="flex items-start gap-3 mb-6">
                <div class="w-10 h-10 rounded-lg bg-primary-100 flex items-center justify-center flex-shrink-0">
                  <svg class="w-5 h-5 text-primary-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2" />
                  </svg>
                </div>
                <div>
                  <h2 class="text-xl font-bold text-neutral-900">Specifications</h2>
                  <p class="text-sm text-neutral-600">Environment configuration and settings.</p>
                </div>
              </div>

              <div class="grid grid-cols-2 gap-6">
                <!-- Category -->
                <div>
                  <label class="block text-sm font-semibold text-neutral-900 mb-2">CATEGORY</label>
                  <div class="px-4 py-3 bg-neutral-50 rounded-lg">
                    <span class="text-neutral-900 font-medium capitalize">{{ specs.category || 'N/A' }}</span>
                  </div>
                </div>

                <!-- Lighting Type -->
                <div>
                  <label class="block text-sm font-semibold text-neutral-900 mb-2">LIGHTING TYPE</label>
                  <div class="px-4 py-3 bg-neutral-50 rounded-lg">
                    <span class="text-neutral-900 font-medium capitalize">{{ specs.lighting_type || 'N/A' }}</span>
                  </div>
                </div>

                <!-- Visual Style -->
                <div v-if="specs.visual_style">
                  <label class="block text-sm font-semibold text-neutral-900 mb-2">VISUAL STYLE</label>
                  <div class="px-4 py-3 bg-neutral-50 rounded-lg">
                    <span class="text-neutral-900 font-medium capitalize">{{ specs.visual_style }}</span>
                  </div>
                </div>

                <!-- Mood/Tone -->
                <div v-if="specs.mood_tone">
                  <label class="block text-sm font-semibold text-neutral-900 mb-2">MOOD / TONE</label>
                  <div class="px-4 py-3 bg-neutral-50 rounded-lg">
                    <span class="text-neutral-900 font-medium capitalize">{{ specs.mood_tone }}</span>
                  </div>
                </div>

                <!-- Ambient Intensity -->
                <div>
                  <label class="block text-sm font-semibold text-neutral-900 mb-2">AMBIENT INTENSITY</label>
                  <div class="px-4 py-3 bg-neutral-50 rounded-lg">
                    <span class="text-neutral-900 font-medium">{{ specs.ambient_intensity || 0 }}%</span>
                  </div>
                </div>

                <!-- Room Size -->
                <div v-if="specs.room_size">
                  <label class="block text-sm font-semibold text-neutral-900 mb-2">ROOM SIZE</label>
                  <div class="px-4 py-3 bg-neutral-50 rounded-lg">
                    <span class="text-neutral-900 font-medium capitalize">{{ specs.room_size }}</span>
                  </div>
                </div>

                <!-- Background Color -->
                <div v-if="specs.background_color">
                  <label class="block text-sm font-semibold text-neutral-900 mb-2">BACKGROUND COLOR</label>
                  <div class="flex items-center gap-3 px-4 py-3 bg-neutral-50 rounded-lg">
                    <div
                      class="w-8 h-8 rounded border-2 border-neutral-200"
                      :style="{ backgroundColor: specs.background_color }"
                    ></div>
                    <span class="text-neutral-900 font-medium">{{ specs.background_color }}</span>
                  </div>
                </div>

                <!-- Wall Color -->
                <div v-if="specs.wall_color">
                  <label class="block text-sm font-semibold text-neutral-900 mb-2">WALL COLOR</label>
                  <div class="flex items-center gap-3 px-4 py-3 bg-neutral-50 rounded-lg">
                    <div
                      class="w-8 h-8 rounded border-2 border-neutral-200"
                      :style="{ backgroundColor: specs.wall_color }"
                    ></div>
                    <span class="text-neutral-900 font-medium">{{ specs.wall_color }}</span>
                  </div>
                </div>

                <!-- Floor Type -->
                <div v-if="specs.floor_type">
                  <label class="block text-sm font-semibold text-neutral-900 mb-2">FLOOR TYPE</label>
                  <div class="px-4 py-3 bg-neutral-50 rounded-lg">
                    <span class="text-neutral-900 font-medium capitalize">{{ specs.floor_type }}</span>
                  </div>
                </div>
              </div>

              <!-- Additional Features -->
              <div v-if="specs.include_windows || specs.include_props" class="mt-6 pt-6 border-t border-neutral-200">
                <label class="block text-sm font-semibold text-neutral-900 mb-3">ADDITIONAL FEATURES</label>
                <div class="flex flex-wrap gap-2">
                  <div v-if="specs.include_windows" class="inline-flex items-center gap-2 px-4 py-2 bg-success-50 text-success-700 rounded-lg">
                    <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7" />
                    </svg>
                    <span class="font-medium">Windows</span>
                  </div>
                  <div v-if="specs.include_props" class="inline-flex items-center gap-2 px-4 py-2 bg-success-50 text-success-700 rounded-lg">
                    <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7" />
                    </svg>
                    <span class="font-medium">Props & Decorations</span>
                  </div>
                </div>
              </div>
            </div>

            <!-- Projects Using This Environment -->
            <div class="card">
              <div class="flex items-start gap-3 mb-6">
                <div class="w-10 h-10 rounded-lg bg-primary-100 flex items-center justify-center flex-shrink-0">
                  <svg class="w-5 h-5 text-primary-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 6a2 2 0 012-2h2a2 2 0 012 2v2a2 2 0 01-2 2H6a2 2 0 01-2-2V6zM14 6a2 2 0 012-2h2a2 2 0 012 2v2a2 2 0 01-2 2h-2a2 2 0 01-2-2V6zM4 16a2 2 0 012-2h2a2 2 0 012 2v2a2 2 0 01-2 2H6a2 2 0 01-2-2v-2zM14 16a2 2 0 012-2h2a2 2 0 012 2v2a2 2 0 01-2 2h-2a2 2 0 01-2-2v-2z" />
                  </svg>
                </div>
                <div>
                  <h2 class="text-xl font-bold text-neutral-900">Projects Using This Environment</h2>
                  <p class="text-sm text-neutral-600">{{ usageCount }} project{{ usageCount !== 1 ? 's' : '' }} currently using this environment.</p>
                </div>
              </div>

              <div v-if="projectsUsingEnvironment.length > 0" class="space-y-3">
                <div
                  v-for="project in projectsUsingEnvironment"
                  :key="project.id"
                  class="flex items-center justify-between p-4 bg-neutral-50 rounded-lg hover:bg-neutral-100 transition-colors"
                >
                  <div>
                    <h3 class="font-bold text-neutral-900">{{ project.name }}</h3>
                    <p class="text-sm text-neutral-500">Created {{ formatDate(project.created_at) }}</p>
                  </div>
                  <span
                    :class="[
                      'inline-flex items-center px-2.5 py-1 rounded text-xs font-bold tracking-wide',
                      getStatusBadgeClass(project.status)
                    ]"
                  >
                    {{ getStatusLabel(project.status) }}
                  </span>
                </div>
              </div>
              <div v-else class="text-center py-8 text-neutral-500">
                <svg class="w-12 h-12 mx-auto mb-3 text-neutral-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M20 13V6a2 2 0 00-2-2H6a2 2 0 00-2 2v7m16 0v5a2 2 0 01-2 2H6a2 2 0 01-2-2v-5m16 0h-2.586a1 1 0 00-.707.293l-2.414 2.414a1 1 0 01-.707.293h-3.172a1 1 0 01-.707-.293l-2.414-2.414A1 1 0 006.586 13H4" />
                </svg>
                <p>No projects using this environment yet</p>
              </div>
            </div>
          </div>

          <!-- Right Column - Stats & Info -->
          <div class="space-y-6">
            <!-- Usage Stats -->
            <div class="card">
              <h3 class="text-sm font-bold text-neutral-900 uppercase mb-4">Usage Statistics</h3>
              <div class="space-y-4">
                <div>
                  <div class="flex items-center justify-between mb-1">
                    <span class="text-sm text-neutral-600">Total Projects</span>
                    <span class="text-2xl font-black text-primary-600">{{ usageCount }}</span>
                  </div>
                  <div class="w-full bg-neutral-200 rounded-full h-2">
                    <div
                      class="bg-primary-600 h-2 rounded-full"
                      :style="{ width: `${Math.min(usageCount * 20, 100)}%` }"
                    ></div>
                  </div>
                </div>

                <div class="pt-4 border-t border-neutral-200">
                  <div class="flex items-center justify-between text-sm mb-2">
                    <span class="text-neutral-600">Status</span>
                    <span :class="environment.is_active ? 'text-success-600 font-semibold' : 'text-neutral-600'">
                      {{ environment.is_active ? 'Active' : 'Inactive' }}
                    </span>
                  </div>
                  <div class="flex items-center justify-between text-sm">
                    <span class="text-neutral-600">Created</span>
                    <span class="text-neutral-900">{{ formatDate(environment.created_at) }}</span>
                  </div>
                </div>
              </div>
            </div>

            <!-- Quick Actions -->
            <div class="card bg-neutral-900 text-white">
              <div class="flex items-center gap-2 mb-4">
                <svg class="w-5 h-5 text-primary-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 10V3L4 14h7v7l9-11h-7z" />
                </svg>
                <h3 class="text-sm font-bold uppercase">Quick Actions</h3>
              </div>

              <div class="space-y-2">
                <template v-if="isDummyData">
                  <button
                    @click="router.push('/environments/new')"
                    class="w-full btn-primary bg-primary-600 hover:bg-primary-700"
                  >
                    <svg class="w-5 h-5 mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v16m8-8H4" />
                    </svg>
                    Create Your First Environment
                  </button>
                </template>
                <template v-else>
                  <button
                    @click="handleEdit"
                    class="w-full btn-secondary bg-neutral-800 hover:bg-neutral-700 border-neutral-700 text-white"
                  >
                    <svg class="w-5 h-5 mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M11 5H6a2 2 0 00-2 2v11a2 2 0 002 2h11a2 2 0 002-2v-5m-1.414-9.414a2 2 0 112.828 2.828L11.828 15H9v-2.828l8.586-8.586z" />
                    </svg>
                    Edit Environment
                  </button>

                  <button
                    @click="router.push('/projects/new')"
                    class="w-full btn-primary bg-primary-600 hover:bg-primary-700"
                  >
                    <svg class="w-5 h-5 mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v16m8-8H4" />
                    </svg>
                    Use in New Project
                  </button>

                  <button
                    @click="handleToggleActive"
                    :class="[
                      'w-full btn-secondary border-neutral-700',
                      environment.is_active
                        ? 'bg-neutral-800 hover:bg-neutral-700 text-white'
                        : 'bg-success-600 hover:bg-success-700 text-white border-success-600'
                    ]"
                  >
                    {{ environment.is_active ? 'Deactivate' : 'Activate' }}
                  </button>
                </template>
              </div>
            </div>
          </div>
        </div>
      </div>
    </main>

    <!-- Delete Confirmation Modal -->
    <div
      v-if="showDeleteModal"
      class="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50 p-4"
      @click.self="showDeleteModal = false"
    >
      <div class="bg-white rounded-lg max-w-md w-full p-6">
        <div class="flex items-start gap-4 mb-6">
          <div class="w-12 h-12 rounded-full bg-error-100 flex items-center justify-center flex-shrink-0">
            <svg class="w-6 h-6 text-error-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z" />
            </svg>
          </div>
          <div class="flex-1">
            <h2 class="text-xl font-bold text-neutral-900 mb-2">Delete Environment?</h2>
            <p class="text-sm text-neutral-600">
              Are you sure you want to delete "{{ environment.name }}"? This action cannot be undone.
            </p>
            <p v-if="usageCount > 0" class="text-sm text-error-600 mt-2 font-medium">
              Warning: This environment is currently being used by {{ usageCount }} project{{ usageCount !== 1 ? 's' : '' }}.
            </p>
          </div>
        </div>

        <div class="flex items-center gap-3 justify-end">
          <button
            @click="showDeleteModal = false"
            :disabled="isDeleting"
            class="btn-secondary"
          >
            Cancel
          </button>
          <button
            @click="handleDelete"
            :disabled="isDeleting"
            class="btn-primary bg-error-600 hover:bg-error-700"
          >
            {{ isDeleting ? 'Deleting...' : 'Delete Environment' }}
          </button>
        </div>
      </div>
    </div>
  </div>
</template>

<style scoped>
.loading-spinner {
  width: 48px;
  height: 48px;
  border: 5px solid #f3f4f6;
  border-bottom-color: #1313EC;
  border-radius: 50%;
  animation: rotation 1s linear infinite;
}

@keyframes rotation {
  0% {
    transform: rotate(0deg);
  }
  100% {
    transform: rotate(360deg);
  }
}
</style>
