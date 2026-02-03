<script setup>
import { ref, computed, onMounted } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { useAuthStore } from '@/stores/auth'
import { supabase } from '@/lib/supabase'
import { useN8nIntegration } from '@/composables/useN8nIntegration'
import { useImageUpload } from '@/composables/useImageUpload'
import { useJobTracking } from '@/composables/useJobTracking'
import { useToast } from '@/composables/useToast'
import Sidebar from '@/components/common/Sidebar.vue'
import AppHeader from '@/components/common/AppHeader.vue'

const route = useRoute()
const router = useRouter()
const authStore = useAuthStore()
const { sendToEndpoint } = useN8nIntegration()
const { showToast } = useToast()
const {
  isUploading,
  uploadProgress,
  validateImage,
  uploadImageWithRetry
} = useImageUpload()
const {
  createJob,
  subscribeToJob,
  getExistingJob
} = useJobTracking()

const environmentId = route.params.id

// n8n configuration
const n8nConfig = ref(null)

// State
const isLoading = ref(false)
const error = ref(null)

// Form data
const environmentName = ref('')
const description = ref('')
const selectedImage = ref(null)
const imagePreviewUrl = ref(null)
const currentReferenceImageUrl = ref(null) // Track existing image
const category = ref('interior')
const lightingType = ref('natural')
const backgroundColor = ref('#ffffff')
const ambientIntensity = ref(70)
const visualStyle = ref(null)
const moodTone = ref(null)

// Additional environment specs
const wallColor = ref('#f5f5f5')
const floorType = ref('wood')
const roomSize = ref('medium')
const includeWindows = ref(true)
const includeProps = ref(true)

// Dropdown options (same as create view)
const categoryOptions = [
  { value: 'interior', label: 'Interior', icon: '🏠' },
  { value: 'outdoor', label: 'Outdoor', icon: '🌳' },
  { value: 'studio', label: 'Studio', icon: '🎬' }
]

const lightingOptions = [
  { value: 'natural', label: 'Natural', icon: '☀️', description: 'Daylight' },
  { value: 'studio', label: 'Studio', icon: '💡', description: 'Professional' },
  { value: 'ambient', label: 'Ambient', icon: '🌙', description: 'Soft' },
  { value: 'dramatic', label: 'Dramatic', icon: '⚡', description: 'High contrast' }
]

const visualStyleOptions = [
  { value: 'modern', label: 'Modern' },
  { value: 'minimalist', label: 'Minimalist' },
  { value: 'vintage', label: 'Vintage' },
  { value: 'industrial', label: 'Industrial' },
  { value: 'cozy', label: 'Cozy' }
]

const moodToneOptions = [
  { value: 'professional', label: 'Professional', emoji: '💼' },
  { value: 'warm', label: 'Warm', emoji: '🔥' },
  { value: 'cool', label: 'Cool', emoji: '❄️' },
  { value: 'energetic', label: 'Energetic', emoji: '⚡' },
  { value: 'calm', label: 'Calm', emoji: '🧘' }
]

const roomSizeOptions = [
  { value: 'small', label: 'Small (< 100 sq ft)' },
  { value: 'medium', label: 'Medium (100-300 sq ft)' },
  { value: 'large', label: 'Large (> 300 sq ft)' }
]

const floorTypeOptions = [
  { value: 'wood', label: 'Wood', emoji: '🪵' },
  { value: 'carpet', label: 'Carpet', emoji: '🧶' },
  { value: 'tile', label: 'Tile', emoji: '⬜' },
  { value: 'concrete', label: 'Concrete', emoji: '🏗️' }
]

// Fetch existing environment
async function fetchEnvironment() {
  isLoading.value = true
  error.value = null

  try {
    const { data, error: fetchError } = await supabase
      .from('environments')
      .select('*')
      .eq('id', environmentId)
      .single()

    if (fetchError) throw fetchError

    // Populate form
    environmentName.value = data.name
    description.value = data.description || ''
    currentReferenceImageUrl.value = data.reference_image_url

    const specs = data.environment_specs || {}
    category.value = specs.category || 'interior'
    lightingType.value = specs.lighting_type || 'natural'
    backgroundColor.value = specs.background_color || '#ffffff'
    ambientIntensity.value = specs.ambient_intensity || 70
    visualStyle.value = specs.visual_style || null
    moodTone.value = specs.mood_tone || null
    wallColor.value = specs.wall_color || '#f5f5f5'
    floorType.value = specs.floor_type || 'wood'
    roomSize.value = specs.room_size || 'medium'
    includeWindows.value = specs.include_windows ?? true
    includeProps.value = specs.include_props ?? true
  } catch (err) {
    console.error('Error fetching environment:', err)
    error.value = 'Failed to load environment'
  } finally {
    isLoading.value = false
  }
}

// Handle reference image change
function handleImageSelect(event) {
  const file = event.target.files[0]
  if (!file) return

  const validation = validateImage(file)
  if (!validation.valid) {
    error.value = validation.error
    return
  }

  selectedImage.value = file
  imagePreviewUrl.value = URL.createObjectURL(file)
  error.value = null
}

function removeImage() {
  if (imagePreviewUrl.value) {
    URL.revokeObjectURL(imagePreviewUrl.value)
  }
  selectedImage.value = null
  imagePreviewUrl.value = null
}

function handleCancel() {
  router.push(`/environments/${environmentId}`)
}

// Update environment and trigger n8n
async function handleUpdate() {
  if (!environmentName.value.trim()) {
    error.value = 'Environment name is required'
    return
  }

  isLoading.value = true
  error.value = null

  try {
    // Step 1: Upload new reference image if changed
    let finalImageUrl = currentReferenceImageUrl.value

    if (selectedImage.value) {
      const uploadResult = await uploadImageWithRetry(selectedImage.value, 'Environments', 'reference')
      if (!uploadResult.success) {
        throw new Error(uploadResult.error || 'Image upload failed')
      }
      finalImageUrl = uploadResult.url
    }

    // Step 2: Update environment (clear result_image_url to trigger regeneration)
    const environmentSpecs = {
      category: category.value,
      lighting_type: lightingType.value,
      background_color: backgroundColor.value,
      ambient_intensity: ambientIntensity.value,
      visual_style: visualStyle.value,
      mood_tone: moodTone.value,
      wall_color: wallColor.value,
      floor_type: floorType.value,
      room_size: roomSize.value,
      include_windows: includeWindows.value,
      include_props: includeProps.value
    }

    const { data: updatedEnvironment, error: updateError } = await supabase
      .from('environments')
      .update({
        name: environmentName.value,
        description: description.value || null,
        reference_image_url: finalImageUrl,
        result_image_url: null, // Clear to indicate needs regeneration
        environment_specs: environmentSpecs,
        updated_by: authStore.user.id,
        updated_at: new Date().toISOString()
      })
      .eq('id', environmentId)
      .select('*')
      .single()

    if (updateError) throw updateError

    // Step 3: Trigger n8n workflow (same as create)
    sendToN8nWithTracking(updatedEnvironment).catch(err => {
      console.error('n8n error (non-blocking):', err)
    })

    showToast('Environment updated! AI regeneration started.', 'success', 3000)
    router.push(`/environments/${environmentId}`)
  } catch (err) {
    console.error('Error updating environment:', err)
    error.value = err.message || 'Failed to update environment'
  } finally {
    isLoading.value = false
  }
}

// Send to n8n with job tracking
async function sendToN8nWithTracking(environmentData) {
  try {
    // Fetch n8n webhook config
    const { data: config, error: configError } = await supabase
      .from('admin_settings')
      .select('value')
      .eq('key', 'n8n_webhook_url')
      .single()

    if (configError || !config?.value) {
      console.warn('n8n webhook not configured, skipping')
      return
    }

    n8nConfig.value = config.value

    // Check for existing incomplete job
    const existingJob = await getExistingJob(environmentData.id)

    if (existingJob) {
      console.log('Resuming existing job:', existingJob.id)
    } else {
      // Create job record
      const job = await createJob(environmentData.id, 'environment_generation', {
        environment_name: environmentData.name,
        reference_image_url: environmentData.reference_image_url,
        environment_specs: environmentData.environment_specs
      })

      console.log('Created new job:', job.id)

      // Subscribe to job updates
      subscribeToJob(job.id, (updatedJob) => {
        console.log('Job update:', updatedJob.status)
      })
    }

    // Send to n8n
    const payload = {
      environment_id: environmentData.id,
      environment_name: environmentData.name,
      reference_image_url: environmentData.reference_image_url,
      environment_specs: environmentData.environment_specs,
      created_by: authStore.user.id
    }

    await sendToEndpoint(n8nConfig.value, payload)
    console.log('n8n webhook triggered successfully')
  } catch (err) {
    console.error('Error in n8n tracking:', err)
  }
}

function formatDate(dateString) {
  return new Date(dateString).toLocaleDateString('en-US', {
    month: 'short',
    day: 'numeric',
    year: 'numeric'
  })
}

onMounted(() => {
  fetchEnvironment()
})
</script>

<template>
  <div class="min-h-screen bg-neutral-50">
    <Sidebar />
    <AppHeader />

    <main class="ml-64 px-6 py-8">
      <!-- Loading State -->
      <div v-if="isLoading && !environmentName" class="text-center py-12">
        <div class="loading-spinner mx-auto"></div>
        <p class="mt-4 text-neutral-600">Loading environment...</p>
      </div>

      <!-- Edit Form -->
      <div v-else class="max-w-7xl mx-auto">
        <!-- Breadcrumb -->
        <div class="flex items-center gap-2 mb-6 text-sm text-neutral-500">
          <router-link to="/environments" class="hover:text-neutral-900">ENVIRONMENTS</router-link>
          <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5l7 7-7 7" />
          </svg>
          <router-link :to="`/environments/${environmentId}`" class="hover:text-neutral-900">
            {{ environmentName || 'Environment' }}
          </router-link>
          <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5l7 7-7 7" />
          </svg>
          <span class="text-neutral-900 font-medium">Edit</span>
        </div>

        <!-- Header Section -->
        <div class="flex items-start justify-between mb-8">
          <div class="flex-1">
            <h1 class="text-4xl font-black text-neutral-900 mb-2">Edit Environment</h1>
            <p class="text-base text-neutral-600">Update environment settings and trigger AI regeneration</p>
          </div>

          <div class="flex items-center gap-3">
            <button @click="handleCancel" class="btn-secondary" :disabled="isLoading">
              Cancel
            </button>
            <button @click="handleUpdate" class="btn-primary" :disabled="isLoading">
              <svg v-if="!isLoading" class="w-5 h-5 mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7" />
              </svg>
              {{ isLoading ? 'Updating...' : 'Update & Regenerate' }}
            </button>
          </div>
        </div>

        <!-- Error Message -->
        <div v-if="error" class="mb-6 bg-error-50 border border-error-200 text-error-700 px-4 py-3 rounded-lg">
          {{ error }}
        </div>

        <div class="grid grid-cols-1 lg:grid-cols-3 gap-6">
          <!-- Left Column - Form -->
          <div class="lg:col-span-2 space-y-6">
            <!-- Reference Image Upload -->
            <div class="card">
              <div class="flex items-start gap-3 mb-6">
                <div class="w-10 h-10 rounded-lg bg-primary-100 flex items-center justify-center flex-shrink-0">
                  <svg class="w-5 h-5 text-primary-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 16l4.586-4.586a2 2 0 012.828 0L16 16m-2-2l1.586-1.586a2 2 0 012.828 0L20 14m-6-6h.01M6 20h12a2 2 0 002-2V6a2 2 0 00-2-2H6a2 2 0 00-2 2v12a2 2 0 002 2z" />
                  </svg>
                </div>
                <div>
                  <h2 class="text-xl font-bold text-neutral-900">Reference Image</h2>
                  <p class="text-sm text-neutral-600">Update the reference image (optional).</p>
                </div>
              </div>

              <!-- Current Image Display -->
              <div v-if="currentReferenceImageUrl && !imagePreviewUrl" class="mb-4">
                <label class="block text-xs font-semibold text-neutral-600 mb-2 uppercase">Current Image</label>
                <div class="relative rounded-lg overflow-hidden bg-neutral-100" style="aspect-ratio: 16/9;">
                  <img :src="currentReferenceImageUrl" alt="Current reference" class="w-full h-full object-cover" />
                </div>
              </div>

              <!-- Upload Area -->
              <div>
                <label class="block text-sm font-semibold text-neutral-900 mb-2">
                  {{ imagePreviewUrl ? 'NEW IMAGE' : 'UPLOAD NEW IMAGE (OPTIONAL)' }}
                </label>

                <!-- Preview -->
                <div v-if="imagePreviewUrl" class="relative mb-4 rounded-lg overflow-hidden bg-neutral-100" style="aspect-ratio: 16/9;">
                  <img :src="imagePreviewUrl" alt="Preview" class="w-full h-full object-cover" />
                  <button
                    @click="removeImage"
                    type="button"
                    class="absolute top-2 right-2 w-8 h-8 bg-error-600 hover:bg-error-700 text-white rounded-full flex items-center justify-center"
                  >
                    ✕
                  </button>
                </div>

                <!-- Upload Button -->
                <div v-if="!imagePreviewUrl" class="relative">
                  <input
                    type="file"
                    @change="handleImageSelect"
                    accept="image/jpeg,image/jpg,image/png,image/webp"
                    class="absolute inset-0 w-full h-full opacity-0 cursor-pointer"
                    id="image-upload"
                  />
                  <label
                    for="image-upload"
                    class="flex flex-col items-center justify-center w-full h-32 border-2 border-dashed border-neutral-300 rounded-lg cursor-pointer bg-neutral-50 hover:bg-neutral-100 transition-colors"
                  >
                    <svg class="w-8 h-8 text-neutral-400 mb-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M7 16a4 4 0 01-.88-7.903A5 5 0 1115.9 6L16 6a5 5 0 011 9.9M15 13l-3-3m0 0l-3 3m3-3v12" />
                    </svg>
                    <p class="text-sm text-neutral-600">Click to upload or drag and drop</p>
                    <p class="text-xs text-neutral-500 mt-1">JPG, PNG or WebP (max 5MB)</p>
                  </label>
                </div>
              </div>
            </div>

            <!-- Basic Details -->
            <div class="card">
              <div class="flex items-start gap-3 mb-6">
                <div class="w-10 h-10 rounded-lg bg-primary-100 flex items-center justify-center flex-shrink-0">
                  <svg class="w-5 h-5 text-primary-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
                  </svg>
                </div>
                <div>
                  <h2 class="text-xl font-bold text-neutral-900">Environment Details</h2>
                  <p class="text-sm text-neutral-600">Update name and description.</p>
                </div>
              </div>

              <!-- Environment Name -->
              <div class="mb-4">
                <label class="block text-sm font-semibold text-neutral-900 mb-2">
                  ENVIRONMENT NAME <span class="text-error-600">*</span>
                </label>
                <input
                  v-model="environmentName"
                  type="text"
                  placeholder="e.g., Modern Home Office, Urban Cafe, etc."
                  class="input-field"
                  required
                />
              </div>

              <!-- Description -->
              <div class="mb-4">
                <label class="block text-sm font-semibold text-neutral-900 mb-2">DESCRIPTION (OPTIONAL)</label>
                <textarea
                  v-model="description"
                  rows="3"
                  placeholder="Describe the environment..."
                  class="input-field resize-none"
                ></textarea>
              </div>

              <!-- Category -->
              <div>
                <label class="block text-sm font-semibold text-neutral-900 mb-3">CATEGORY</label>
                <div class="grid grid-cols-3 gap-3">
                  <button
                    v-for="option in categoryOptions"
                    :key="option.value"
                    type="button"
                    @click="category = option.value"
                    :class="[
                      'p-4 rounded-lg border-2 transition-all text-center',
                      category === option.value
                        ? 'border-primary-600 bg-primary-50'
                        : 'border-neutral-200 hover:border-neutral-300 bg-white'
                    ]"
                  >
                    <div class="text-2xl mb-1">{{ option.icon }}</div>
                    <div class="font-semibold text-neutral-900">{{ option.label }}</div>
                  </button>
                </div>
              </div>

              <!-- Lighting Type -->
              <div class="mt-6">
                <label class="block text-sm font-semibold text-neutral-900 mb-3">LIGHTING TYPE</label>
                <div class="grid grid-cols-2 md:grid-cols-4 gap-3">
                  <button
                    v-for="option in lightingOptions"
                    :key="option.value"
                    type="button"
                    @click="lightingType = option.value"
                    :class="[
                      'p-4 rounded-lg border-2 transition-all text-left',
                      lightingType === option.value
                        ? 'border-primary-600 bg-primary-50'
                        : 'border-neutral-200 hover:border-neutral-300 bg-white'
                    ]"
                  >
                    <div class="text-2xl mb-2">{{ option.icon }}</div>
                    <div class="font-semibold text-neutral-900 mb-1">{{ option.label }}</div>
                    <div class="text-xs text-neutral-600">{{ option.description }}</div>
                  </button>
                </div>
              </div>
            </div>

            <!-- Additional Settings -->
            <div class="card">
              <div class="flex items-start gap-3 mb-6">
                <div class="w-10 h-10 rounded-lg bg-primary-100 flex items-center justify-center flex-shrink-0">
                  <svg class="w-5 h-5 text-primary-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 6V4m0 2a2 2 0 100 4m0-4a2 2 0 110 4m-6 8a2 2 0 100-4m0 4a2 2 0 110-4m0 4v2m0-6V4m6 6v10m6-2a2 2 0 100-4m0 4a2 2 0 110-4m0 4v2m0-6V4" />
                  </svg>
                </div>
                <div>
                  <h2 class="text-xl font-bold text-neutral-900">Additional Settings</h2>
                  <p class="text-sm text-neutral-600">Fine-tune environment specifications.</p>
                </div>
              </div>

              <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
                <!-- Visual Style -->
                <div>
                  <label class="block text-sm font-semibold text-neutral-900 mb-2">VISUAL STYLE</label>
                  <select v-model="visualStyle" class="input-field">
                    <option :value="null">None</option>
                    <option v-for="style in visualStyleOptions" :key="style.value" :value="style.value">
                      {{ style.label }}
                    </option>
                  </select>
                </div>

                <!-- Mood/Tone -->
                <div>
                  <label class="block text-sm font-semibold text-neutral-900 mb-2">MOOD/TONE</label>
                  <select v-model="moodTone" class="input-field">
                    <option :value="null">None</option>
                    <option v-for="mood in moodToneOptions" :key="mood.value" :value="mood.value">
                      {{ mood.emoji }} {{ mood.label }}
                    </option>
                  </select>
                </div>

                <!-- Ambient Intensity -->
                <div>
                  <label class="block text-sm font-semibold text-neutral-900 mb-2">
                    AMBIENT INTENSITY: {{ ambientIntensity }}%
                  </label>
                  <input v-model.number="ambientIntensity" type="range" min="0" max="100" class="w-full" />
                </div>

                <!-- Room Size -->
                <div>
                  <label class="block text-sm font-semibold text-neutral-900 mb-2">ROOM SIZE</label>
                  <select v-model="roomSize" class="input-field">
                    <option v-for="size in roomSizeOptions" :key="size.value" :value="size.value">
                      {{ size.label }}
                    </option>
                  </select>
                </div>

                <!-- Floor Type -->
                <div>
                  <label class="block text-sm font-semibold text-neutral-900 mb-2">FLOOR TYPE</label>
                  <select v-model="floorType" class="input-field">
                    <option v-for="floor in floorTypeOptions" :key="floor.value" :value="floor.value">
                      {{ floor.emoji }} {{ floor.label }}
                    </option>
                  </select>
                </div>

                <!-- Background Color -->
                <div>
                  <label class="block text-sm font-semibold text-neutral-900 mb-2">BACKGROUND COLOR</label>
                  <input v-model="backgroundColor" type="color" class="w-full h-10 rounded-lg border-2 border-neutral-200" />
                </div>

                <!-- Wall Color -->
                <div>
                  <label class="block text-sm font-semibold text-neutral-900 mb-2">WALL COLOR</label>
                  <input v-model="wallColor" type="color" class="w-full h-10 rounded-lg border-2 border-neutral-200" />
                </div>
              </div>

              <!-- Checkboxes -->
              <div class="mt-6 space-y-3">
                <label class="flex items-center gap-2 cursor-pointer">
                  <input v-model="includeWindows" type="checkbox" class="w-5 h-5" />
                  <span class="text-sm font-medium text-neutral-900">Include Windows</span>
                </label>
                <label class="flex items-center gap-2 cursor-pointer">
                  <input v-model="includeProps" type="checkbox" class="w-5 h-5" />
                  <span class="text-sm font-medium text-neutral-900">Include Props</span>
                </label>
              </div>
            </div>
          </div>

          <!-- Right Column - Preview -->
          <div class="space-y-6">
            <!-- Image Preview -->
            <div class="card sticky top-6">
              <h3 class="text-sm font-bold text-neutral-900 uppercase mb-4">Preview</h3>
              <div class="relative rounded-lg overflow-hidden bg-neutral-100" style="aspect-ratio: 4/3;">
                <img
                  v-if="imagePreviewUrl"
                  :src="imagePreviewUrl"
                  alt="New reference image"
                  class="w-full h-full object-cover"
                />
                <img
                  v-else-if="currentReferenceImageUrl"
                  :src="currentReferenceImageUrl"
                  alt="Current reference image"
                  class="w-full h-full object-cover"
                />
                <div v-else class="w-full h-full flex items-center justify-center">
                  <div class="text-center text-neutral-400">
                    <svg class="w-12 h-12 mx-auto mb-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 16l4.586-4.586a2 2 0 012.828 0L16 16m-2-2l1.586-1.586a2 2 0 012.828 0L20 14m-6-6h.01M6 20h12a2 2 0 002-2V6a2 2 0 00-2-2H6a2 2 0 00-2 2v12a2 2 0 002 2z" />
                    </svg>
                    <p class="text-xs">No image</p>
                  </div>
                </div>
              </div>

              <!-- Image Status -->
              <div class="mt-4 p-3 bg-warning-50 rounded-lg border border-warning-200">
                <div class="flex items-start gap-2">
                  <svg class="w-5 h-5 text-warning-600 flex-shrink-0 mt-0.5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z" />
                  </svg>
                  <div>
                    <p class="text-xs font-semibold text-warning-800 mb-1">AI Regeneration</p>
                    <p class="text-xs text-warning-700">
                      Updating will clear the current result image and trigger AI regeneration.
                    </p>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </main>
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
