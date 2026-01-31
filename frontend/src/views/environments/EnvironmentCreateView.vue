<script setup>
import { ref, computed, onMounted, onUnmounted } from 'vue'
import { useRouter } from 'vue-router'
import { useAuthStore } from '@/stores/auth'
import { supabase } from '@/lib/supabase'
import { useN8nIntegration } from '@/composables/useN8nIntegration'
import { useImageUpload } from '@/composables/useImageUpload'
import { useJobTracking } from '@/composables/useJobTracking'
import { useToast } from '@/composables/useToast'
import Sidebar from '@/components/common/Sidebar.vue'
import AppHeader from '@/components/common/AppHeader.vue'

const router = useRouter()
const authStore = useAuthStore()
const { sendToEndpoint } = useN8nIntegration()
const { showToast } = useToast()
const {
  isUploading,
  uploadProgress,
  uploadError,
  validateImage,
  uploadImage,
  uploadImageWithRetry
} = useImageUpload()
const {
  createJob,
  subscribeToJob,
  resubscribeToPendingJobs,
  getExistingJob
} = useJobTracking()

// n8n configuration
const n8nConfig = ref(null)

// Form data
const environmentName = ref('')
const description = ref('')
const selectedImage = ref(null)
const imagePreviewUrl = ref(null)
const uploadedImageUrl = ref(null)
const category = ref('interior')
const lightingType = ref('natural')
const backgroundColor = ref('#ffffff')
const ambientIntensity = ref(70)
const visualStyle = ref(null)
const moodTone = ref(null)

// Additional environment specs
const wallColor = ref('#f5f5f5')
const floorType = ref('wood')
const includeWindows = ref(true)
const includeProps = ref(true)
const roomSize = ref('medium')

// UI state
const isLoading = ref(false)
const isProcessing = ref(false)
const error = ref(null)
const showImageUploader = ref(false)
const creationStep = ref(null) // null | 'uploading' | 'saving' | 'completed'

// Options
const categoryOptions = [
  { value: 'interior', label: 'Interior', icon: '🏠', description: 'Indoor spaces like offices, homes' },
  { value: 'exterior', label: 'Exterior', icon: '🌳', description: 'Outdoor settings like parks, streets' },
  { value: 'commercial', label: 'Commercial', icon: '🏬', description: 'Retail stores, cafes, shops' },
  { value: 'vehicle', label: 'Vehicle', icon: '🚗', description: 'Car interiors, transportation' }
]

const lightingOptions = [
  { value: 'natural', label: 'Natural', icon: '☀️', description: 'Soft daylight, realistic' },
  { value: 'studio', label: 'Studio', icon: '💡', description: 'Professional, controlled' },
  { value: 'ambient', label: 'Ambient', icon: '🌙', description: 'Mood lighting, atmospheric' },
  { value: 'bright', label: 'Bright', icon: '✨', description: 'High-key, energetic' }
]

const visualStyleOptions = [
  { value: 'modern', label: 'Modern', description: 'Clean, minimalist aesthetic' },
  { value: 'classic', label: 'Classic', description: 'Timeless, traditional design' },
  { value: 'industrial', label: 'Industrial', description: 'Raw, urban elements' },
  { value: 'cozy', label: 'Cozy', description: 'Warm, comfortable atmosphere' },
  { value: 'luxury', label: 'Luxury', description: 'Premium, high-end look' }
]

const moodToneOptions = [
  { value: 'professional', label: 'Professional', emoji: '💼' },
  { value: 'casual', label: 'Casual', emoji: '😊' },
  { value: 'energetic', label: 'Energetic', emoji: '⚡' },
  { value: 'calm', label: 'Calm', emoji: '🌊' },
  { value: 'warm', label: 'Warm', emoji: '🔥' }
]

const roomSizeOptions = [
  { value: 'small', label: 'Small', description: 'Intimate, close-up' },
  { value: 'medium', label: 'Medium', description: 'Balanced space' },
  { value: 'large', label: 'Large', description: 'Spacious, open' }
]

const floorTypeOptions = [
  { value: 'wood', label: 'Wood', emoji: '🪵' },
  { value: 'tile', label: 'Tile', emoji: '⬜' },
  { value: 'carpet', label: 'Carpet', emoji: '🟫' },
  { value: 'concrete', label: 'Concrete', emoji: '⬛' },
  { value: 'marble', label: 'Marble', emoji: '⚪' }
]

const characterCount = computed(() => description.value.length)
const maxCharacters = 500

// Fetch n8n configuration on mount
onMounted(async () => {
  try {
    const { data, error: fetchError } = await supabase
      .from('admin_settings')
      .select('platform_settings')
      .eq('id', 1)
      .single()

    if (fetchError) throw fetchError

    if (data?.platform_settings?.n8n_integration) {
      n8nConfig.value = data.platform_settings.n8n_integration
    }
  } catch (err) {
    console.error('Error fetching n8n config:', err)
  }

  // Resubscribe to any pending jobs on mount
  await resubscribeToPendingJobs()
})

function validateForm() {
  const errors = []

  if (!environmentName.value.trim()) {
    errors.push('Environment name is required')
  }
  if (ambientIntensity.value < 0 || ambientIntensity.value > 100) {
    errors.push('Ambient intensity must be between 0-100')
  }

  return errors
}

function handleImageSelect(event) {
  const file = event.target.files[0]
  if (!file) return

  const validation = validateImage(file)
  if (!validation.valid) {
    error.value = validation.error
    selectedImage.value = null
    imagePreviewUrl.value = null
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
  uploadedImageUrl.value = null
}

function handleJobUpdate(job) {
  console.log('Job updated:', job)

  if (job.status === 'completed') {
    isProcessing.value = false
  } else if (job.status === 'failed') {
    isProcessing.value = false
  }
}

async function sendToN8nWithTracking(environmentData) {
  console.log('[n8n] sendToN8nWithTracking called', {
    environmentId: environmentData.id,
    hasConfig: !!n8nConfig.value,
    enabled: n8nConfig.value?.enabled,
    endpointUrl: n8nConfig.value?.endpoints?.environments?.url
  })

  if (!n8nConfig.value?.enabled || !n8nConfig.value?.endpoints?.environments?.url) {
    console.warn('[n8n] n8n not configured or disabled')
    return { success: false, error: 'n8n not configured' }
  }

  const TIMEOUT_MS = 15000

  try {
    // Check for existing job
    console.log('[n8n] Checking for existing job...')
    const existingJob = await getExistingJob(environmentData.id)

    if (existingJob && existingJob.status === 'generating') {
      console.log('[n8n] Existing job found, subscribing', existingJob.id)
      subscribeToJob(existingJob.id, handleJobUpdate)
      showToast('Generation already in progress...', 'info', 3000)
      return { success: true, jobId: existingJob.id }
    }

    // Create new job record
    console.log('[n8n] Creating new job record...')
    const job = await createJob({
      workflow_type: 'environment_creation',
      environment_id: environmentData.id
    })
    console.log('[n8n] Job created:', job.id)

    // Subscribe to job updates
    subscribeToJob(job.id, handleJobUpdate)

    // Send to n8n with timeout
    const payload = {
      event: 'environment_created',
      timestamp: new Date().toISOString(),
      user_id: authStore.user.id,
      user_email: authStore.user.email,
      job_id: job.id,
      image_url: environmentData.reference_image_url || null,
      environment: environmentData
    }

    console.log('[n8n] Sending to n8n endpoint...', {
      url: n8nConfig.value.endpoints.environments.url,
      hasToken: !!n8nConfig.value.api_token,
      jobId: job.id,
      imageUrl: payload.image_url
    })

    const result = await Promise.race([
      sendToEndpoint(
        n8nConfig.value.endpoints.environments.url,
        n8nConfig.value.api_token,
        payload
      ),
      new Promise((_, reject) =>
        setTimeout(() => reject(new Error('timeout')), TIMEOUT_MS)
      )
    ])

    console.log('[n8n] n8n response:', result)

    if (!result.success) throw new Error(result.error)
    return { success: true, jobId: job.id }

  } catch (err) {
    console.error('Error sending to n8n:', err)

    const existingJob = await getExistingJob(environmentData.id)

    if (err.message === 'timeout') {
      if (existingJob) {
        showToast('Request timed out, but job is being processed.', 'warning', 5000)
        subscribeToJob(existingJob.id, handleJobUpdate)
        return { success: true, jobId: existingJob.id }
      } else {
        showToast('Request timed out. Please retry.', 'error', 0)
        return { success: false, error: 'timeout' }
      }
    }

    if (existingJob) {
      showToast('Request failed. Please retry.', 'error', 0)
    }

    return { success: false, error: err.message }
  }
}

async function handleSaveDraft() {
  if (isProcessing.value) {
    showToast('Already processing...', 'warning', 2000)
    return
  }

  const validationErrors = validateForm()
  if (validationErrors.length > 0) {
    error.value = validationErrors.join('. ')
    return
  }

  isLoading.value = true
  isProcessing.value = true
  error.value = null

  try {
    // Step 1: Upload image FIRST (if selected)
    let finalImageUrl = null

    if (selectedImage.value) {
      const uploadResult = await uploadImageWithRetry(selectedImage.value)

      if (!uploadResult.success) {
        throw new Error(uploadResult.error || 'Image upload failed')
      }

      finalImageUrl = uploadResult.url
      uploadedImageUrl.value = finalImageUrl
    }

    // Step 2: Create environment with uploaded image URL
    const environmentSpecs = {
      category: category.value,
      lighting_type: lightingType.value,
      background_color: backgroundColor.value,
      ambient_intensity: ambientIntensity.value,
      visual_style: visualStyle.value,
      mood_tone: moodTone.value,
      wall_color: wallColor.value,
      floor_type: floorType.value,
      include_windows: includeWindows.value,
      include_props: includeProps.value,
      room_size: roomSize.value
    }

    const { data: createdEnvironment, error: createError } = await supabase
      .from('environments')
      .insert({
        user_id: authStore.user.id,
        name: environmentName.value,
        description: description.value || null,
        reference_image_url: finalImageUrl,
        environment_specs: environmentSpecs,
        is_active: true,
        created_by: authStore.user.id,
        updated_by: authStore.user.id
      })
      .select('id, name, reference_image_url, environment_specs')
      .single()

    if (createError) throw createError

    // Step 3: Send to n8n with job tracking (non-blocking)
    console.log('Environment saved, sending to n8n...', {
      environmentId: createdEnvironment.id,
      hasImageUrl: !!createdEnvironment.reference_image_url,
      imageUrl: createdEnvironment.reference_image_url,
      n8nEnabled: n8nConfig.value?.enabled,
      n8nEndpoint: n8nConfig.value?.endpoints?.environments?.url
    })

    sendToN8nWithTracking(createdEnvironment).catch(err => {
      console.error('n8n tracking error (non-blocking):', err)
    })

    // Step 4: Show success and redirect
    showToast('Environment saved successfully!', 'success', 3000)
    router.push('/environments')

  } catch (err) {
    console.error('Error creating environment:', err)
    error.value = err.message || 'Failed to create environment'
    isProcessing.value = false
  } finally {
    isLoading.value = false
  }
}

async function handleCreateAndActivate() {
  if (isProcessing.value) {
    showToast('Already processing...', 'warning', 2000)
    return
  }

  const validationErrors = validateForm()
  if (validationErrors.length > 0) {
    error.value = validationErrors.join('. ')
    return
  }

  isLoading.value = true
  isProcessing.value = true
  error.value = null

  try {
    // Step 1: Upload image FIRST (if selected)
    let finalImageUrl = null

    if (selectedImage.value) {
      creationStep.value = 'uploading'

      const uploadResult = await uploadImageWithRetry(selectedImage.value)

      if (!uploadResult.success) {
        // Enhanced error messages
        let errorMsg = 'Image upload failed'
        if (uploadResult.error.includes('timeout')) {
          errorMsg = 'Upload timed out. Please check your connection and try again.'
        } else if (uploadResult.error.includes('storage quota')) {
          errorMsg = 'Storage limit reached. Please contact support.'
        } else {
          errorMsg = uploadResult.error
        }
        throw new Error(errorMsg)
      }

      finalImageUrl = uploadResult.url
      uploadedImageUrl.value = finalImageUrl
    }

    // Step 2: Create environment with uploaded image URL
    creationStep.value = 'saving'
    const environmentSpecs = {
      category: category.value,
      lighting_type: lightingType.value,
      background_color: backgroundColor.value,
      ambient_intensity: ambientIntensity.value,
      visual_style: visualStyle.value,
      mood_tone: moodTone.value,
      wall_color: wallColor.value,
      floor_type: floorType.value,
      include_windows: includeWindows.value,
      include_props: includeProps.value,
      room_size: roomSize.value
    }

    const { data: createdEnvironment, error: createError } = await supabase
      .from('environments')
      .insert({
        user_id: authStore.user.id,
        name: environmentName.value,
        description: description.value || null,
        reference_image_url: finalImageUrl,
        environment_specs: environmentSpecs,
        is_active: true,
        created_by: authStore.user.id,
        updated_by: authStore.user.id
      })
      .select('id, name, reference_image_url, environment_specs')
      .single()

    if (createError) throw createError

    // Step 3: Send to n8n with job tracking (non-blocking)
    console.log('Environment created, sending to n8n...', {
      environmentId: createdEnvironment.id,
      hasImageUrl: !!createdEnvironment.reference_image_url,
      imageUrl: createdEnvironment.reference_image_url,
      n8nEnabled: n8nConfig.value?.enabled,
      n8nEndpoint: n8nConfig.value?.endpoints?.environments?.url
    })

    sendToN8nWithTracking(createdEnvironment).catch(err => {
      console.error('n8n tracking error (non-blocking):', err)
    })

    // Step 4: Show success and redirect
    creationStep.value = 'completed'
    showToast('Environment created successfully!', 'success', 3000)

    // Small delay so user sees success state
    setTimeout(() => {
      router.push('/environments')
    }, 500)

  } catch (err) {
    console.error('Error creating environment:', err)
    error.value = err.message || 'Failed to create environment'
    isProcessing.value = false
  } finally {
    isLoading.value = false
    creationStep.value = null
  }
}

// Cleanup on unmount
onUnmounted(() => {
  if (imagePreviewUrl.value) {
    URL.revokeObjectURL(imagePreviewUrl.value)
  }
})
</script>

<template>
  <div class="min-h-screen bg-neutral-50">
    <Sidebar />
    <AppHeader />

    <!-- Main Content -->
    <main class="ml-64 px-6 py-8">
      <div class="max-w-6xl mx-auto">
        <!-- Breadcrumb -->
        <div class="flex items-center gap-2 mb-6 text-sm text-neutral-500">
          <router-link to="/environments" class="hover:text-neutral-900">ENVIRONMENTS</router-link>
          <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5l7 7-7 7" />
          </svg>
          <span class="text-neutral-900 font-medium">NEW ENVIRONMENT</span>
        </div>

        <!-- Page Header -->
        <div class="flex items-center justify-between mb-8">
          <div>
            <h1 class="text-4xl font-black text-neutral-900 mb-2">Create Environment</h1>
            <p class="text-base text-neutral-600">
              Design a virtual environment for your AI-generated video content.
            </p>
          </div>

          <div class="flex items-center gap-3">
            <button
              @click="router.push('/environments')"
              class="btn-secondary"
            >
              Cancel
            </button>
            <button
              @click="handleSaveDraft"
              :disabled="isLoading"
              class="btn-secondary"
            >
              Save Draft
            </button>
            <button
              @click="handleCreateAndActivate"
              :disabled="isLoading || !environmentName"
              class="btn-primary flex items-center gap-2 shadow-lg shadow-primary-600/40"
            >
              <!-- Show different icon based on state -->
              <svg v-if="creationStep === 'uploading' || creationStep === 'saving'"
                   class="animate-spin w-5 h-5" fill="none" viewBox="0 0 24 24">
                <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle>
                <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
              </svg>
              <svg v-else class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7" />
              </svg>

              <!-- Show different text based on state -->
              <span v-if="creationStep === 'uploading'">Uploading Image...</span>
              <span v-else-if="creationStep === 'saving'">Creating Environment...</span>
              <span v-else>Create Environment</span>
            </button>
          </div>
        </div>

        <!-- Error Message -->
        <div v-if="error" class="mb-6 bg-error-50 border border-error-200 text-error-700 px-4 py-3 rounded-lg">
          {{ error }}
        </div>

        <div class="grid grid-cols-1 lg:grid-cols-3 gap-6">
          <!-- Left Column - Main Form -->
          <div class="lg:col-span-2 space-y-6">
            <!-- Basic Information Section -->
            <div class="card">
              <div class="flex items-start gap-3 mb-6">
                <div class="w-10 h-10 rounded-lg bg-primary-100 flex items-center justify-center flex-shrink-0">
                  <svg class="w-5 h-5 text-primary-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 11H5m14 0a2 2 0 012 2v6a2 2 0 01-2 2H5a2 2 0 01-2-2v-6a2 2 0 012-2m14 0V9a2 2 0 00-2-2M5 11V9a2 2 0 012-2m0 0V5a2 2 0 012-2h6a2 2 0 012 2v2M7 7h10" />
                  </svg>
                </div>
                <div>
                  <h2 class="text-xl font-bold text-neutral-900">Basic Information</h2>
                  <p class="text-sm text-neutral-600">Define the name and purpose of your environment.</p>
                </div>
              </div>

              <!-- Environment Name -->
              <div class="mb-6">
                <label class="block text-sm font-semibold text-neutral-900 mb-2">
                  ENVIRONMENT NAME *
                </label>
                <input
                  v-model="environmentName"
                  type="text"
                  placeholder="e.g., Modern Home Office"
                  class="input-field"
                />
              </div>

              <!-- Description -->
              <div class="mb-6">
                <div class="flex items-center justify-between mb-2">
                  <label class="text-sm font-semibold text-neutral-900">
                    DESCRIPTION
                  </label>
                  <span class="text-xs text-neutral-500">{{ characterCount }} / {{ maxCharacters }} CHARACTERS</span>
                </div>
                <textarea
                  v-model="description"
                  :maxlength="maxCharacters"
                  rows="4"
                  placeholder="Describe the environment, its purpose, or any specific details..."
                  class="input-field resize-none"
                ></textarea>
              </div>

              <!-- Reference Image Upload -->
              <div>
                <label class="block text-sm font-semibold text-neutral-900 mb-2">
                  REFERENCE IMAGE
                </label>

                <!-- Upload Area -->
                <div
                  v-if="!imagePreviewUrl"
                  class="relative border-2 border-dashed border-neutral-300 rounded-lg p-8 text-center hover:border-primary-600 transition-colors cursor-pointer"
                  @click="$refs.fileInput.click()"
                >
                  <input
                    ref="fileInput"
                    type="file"
                    accept="image/jpeg,image/jpg,image/png,image/webp"
                    class="hidden"
                    @change="handleImageSelect"
                  />

                  <div class="flex flex-col items-center">
                    <svg class="w-12 h-12 text-neutral-400 mb-3" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 16l4.586-4.586a2 2 0 012.828 0L16 16m-2-2l1.586-1.586a2 2 0 012.828 0L20 14m-6-6h.01M6 20h12a2 2 0 002-2V6a2 2 0 00-2-2H6a2 2 0 00-2 2v12a2 2 0 002 2z" />
                    </svg>
                    <p class="text-sm font-medium text-neutral-700 mb-1">
                      Click to upload reference image
                    </p>
                    <p class="text-xs text-neutral-500">
                      JPG, PNG, or WebP (max 5MB)
                    </p>
                  </div>
                </div>

                <!-- Image Preview -->
                <div v-else class="relative rounded-lg overflow-hidden border-2 border-neutral-200">
                  <img
                    :src="imagePreviewUrl"
                    alt="Reference image preview"
                    class="w-full h-64 object-cover"
                  />

                  <!-- Remove button -->
                  <button
                    @click="removeImage"
                    type="button"
                    class="absolute top-2 right-2 bg-error-600 hover:bg-error-700 text-white rounded-full p-2 shadow-lg transition-colors"
                  >
                    <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12" />
                    </svg>
                  </button>

                  <!-- Upload indicator -->
                  <div v-if="isUploading" class="absolute inset-0 bg-black bg-opacity-50 flex items-center justify-center">
                    <div class="text-white text-center max-w-xs px-4">
                      <!-- Spinner -->
                      <svg class="animate-spin h-10 w-10 mx-auto mb-3" fill="none" viewBox="0 0 24 24">
                        <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle>
                        <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
                      </svg>

                      <!-- Progress bar -->
                      <div class="w-full bg-neutral-700 rounded-full h-2 mb-2">
                        <div
                          class="bg-primary-600 h-2 rounded-full transition-all duration-300 ease-out"
                          :style="{ width: `${uploadProgress}%` }"
                        ></div>
                      </div>

                      <!-- Status text with percentage -->
                      <p class="text-sm font-medium mb-1">
                        Uploading... {{ uploadProgress }}%
                      </p>

                      <!-- File size info -->
                      <p class="text-xs text-neutral-300" v-if="selectedImage">
                        {{ (selectedImage.size / 1024 / 1024).toFixed(2) }} MB
                      </p>
                    </div>
                  </div>
                </div>

                <p class="text-xs text-neutral-500 mt-2">
                  Optional: Upload a reference image for this environment
                </p>
              </div>
            </div>

            <!-- Environment Type Section -->
            <div class="card">
              <div class="flex items-start gap-3 mb-6">
                <div class="w-10 h-10 rounded-lg bg-primary-100 flex items-center justify-center flex-shrink-0">
                  <svg class="w-5 h-5 text-primary-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M7 21a4 4 0 01-4-4V5a2 2 0 012-2h4a2 2 0 012 2v12a4 4 0 01-4 4zm0 0h12a2 2 0 002-2v-4a2 2 0 00-2-2h-2.343M11 7.343l1.657-1.657a2 2 0 012.828 0l2.829 2.829a2 2 0 010 2.828l-8.486 8.485M7 17h.01" />
                  </svg>
                </div>
                <div>
                  <h2 class="text-xl font-bold text-neutral-900">Environment Type</h2>
                  <p class="text-sm text-neutral-600">Select the category and style for this environment.</p>
                </div>
              </div>

              <!-- Category Selection -->
              <div class="mb-6">
                <label class="block text-sm font-semibold text-neutral-900 mb-3">CATEGORY *</label>
                <div class="grid grid-cols-2 md:grid-cols-4 gap-3">
                  <button
                    v-for="cat in categoryOptions"
                    :key="cat.value"
                    @click="category = cat.value"
                    type="button"
                    :class="[
                      'p-4 rounded-lg border-2 text-center transition-all',
                      category === cat.value
                        ? 'border-primary-600 bg-primary-50'
                        : 'border-neutral-200 hover:border-neutral-300'
                    ]"
                  >
                    <div class="text-2xl mb-2">{{ cat.icon }}</div>
                    <div class="font-bold text-neutral-900 text-sm">{{ cat.label }}</div>
                    <div class="text-xs text-neutral-600 mt-1">{{ cat.description }}</div>
                  </button>
                </div>
              </div>

              <!-- Room Size (for Interior/Commercial) -->
              <div v-if="category === 'interior' || category === 'commercial'" class="mb-6">
                <label class="block text-sm font-semibold text-neutral-900 mb-3">ROOM SIZE</label>
                <div class="flex gap-3">
                  <button
                    v-for="size in roomSizeOptions"
                    :key="size.value"
                    @click="roomSize = size.value"
                    type="button"
                    :class="[
                      'flex-1 p-3 rounded-lg border-2 transition-all',
                      roomSize === size.value
                        ? 'border-primary-600 bg-primary-50'
                        : 'border-neutral-200 hover:border-neutral-300'
                    ]"
                  >
                    <div class="font-bold text-neutral-900 text-sm">{{ size.label }}</div>
                    <div class="text-xs text-neutral-600">{{ size.description }}</div>
                  </button>
                </div>
              </div>
            </div>

            <!-- Lighting & Atmosphere Section -->
            <div class="card">
              <div class="flex items-start gap-3 mb-6">
                <div class="w-10 h-10 rounded-lg bg-primary-100 flex items-center justify-center flex-shrink-0">
                  <svg class="w-5 h-5 text-primary-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 3v1m0 16v1m9-9h-1M4 12H3m15.364 6.364l-.707-.707M6.343 6.343l-.707-.707m12.728 0l-.707.707M6.343 17.657l-.707.707M16 12a4 4 0 11-8 0 4 4 0 018 0z" />
                  </svg>
                </div>
                <div>
                  <h2 class="text-xl font-bold text-neutral-900">Lighting & Atmosphere</h2>
                  <p class="text-sm text-neutral-600">Configure lighting and environmental mood.</p>
                </div>
              </div>

              <!-- Lighting Type -->
              <div class="mb-6">
                <label class="block text-sm font-semibold text-neutral-900 mb-3">LIGHTING TYPE *</label>
                <div class="grid grid-cols-2 md:grid-cols-4 gap-3">
                  <button
                    v-for="light in lightingOptions"
                    :key="light.value"
                    @click="lightingType = light.value"
                    type="button"
                    :class="[
                      'p-4 rounded-lg border-2 text-center transition-all',
                      lightingType === light.value
                        ? 'border-primary-600 bg-primary-50'
                        : 'border-neutral-200 hover:border-neutral-300'
                    ]"
                  >
                    <div class="text-2xl mb-2">{{ light.icon }}</div>
                    <div class="font-bold text-neutral-900 text-sm">{{ light.label }}</div>
                    <div class="text-xs text-neutral-600 mt-1">{{ light.description }}</div>
                  </button>
                </div>
              </div>

              <!-- Ambient Intensity Slider -->
              <div class="mb-6">
                <div class="flex items-center justify-between mb-3">
                  <label class="text-sm font-semibold text-neutral-900">AMBIENT INTENSITY</label>
                  <span class="text-2xl font-black text-primary-600">{{ ambientIntensity }}%</span>
                </div>
                <input
                  v-model="ambientIntensity"
                  type="range"
                  min="0"
                  max="100"
                  step="5"
                  class="w-full h-2 bg-neutral-200 rounded-lg appearance-none cursor-pointer accent-primary-600"
                />
                <div class="flex items-center justify-between text-xs mt-2">
                  <span class="text-neutral-500">Dim</span>
                  <span class="text-neutral-500">Bright</span>
                </div>
              </div>

              <!-- Color Pickers -->
              <div class="grid grid-cols-2 gap-4">
                <div>
                  <label class="block text-sm font-semibold text-neutral-900 mb-2">BACKGROUND COLOR</label>
                  <div class="flex items-center gap-3">
                    <input
                      v-model="backgroundColor"
                      type="color"
                      class="w-12 h-12 rounded border-2 border-neutral-200 cursor-pointer"
                    />
                    <input
                      v-model="backgroundColor"
                      type="text"
                      class="input-field flex-1"
                      placeholder="#ffffff"
                    />
                  </div>
                </div>

                <div v-if="category === 'interior' || category === 'commercial'">
                  <label class="block text-sm font-semibold text-neutral-900 mb-2">WALL COLOR</label>
                  <div class="flex items-center gap-3">
                    <input
                      v-model="wallColor"
                      type="color"
                      class="w-12 h-12 rounded border-2 border-neutral-200 cursor-pointer"
                    />
                    <input
                      v-model="wallColor"
                      type="text"
                      class="input-field flex-1"
                      placeholder="#f5f5f5"
                    />
                  </div>
                </div>
              </div>
            </div>

            <!-- Style & Details Section -->
            <div class="card">
              <div class="flex items-start gap-3 mb-6">
                <div class="w-10 h-10 rounded-lg bg-primary-100 flex items-center justify-center flex-shrink-0">
                  <svg class="w-5 h-5 text-primary-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 16l4.586-4.586a2 2 0 012.828 0L16 16m-2-2l1.586-1.586a2 2 0 012.828 0L20 14m-6-6h.01M6 20h12a2 2 0 002-2V6a2 2 0 00-2-2H6a2 2 0 00-2 2v12a2 2 0 002 2z" />
                  </svg>
                </div>
                <div>
                  <h2 class="text-xl font-bold text-neutral-900">Style & Details</h2>
                  <p class="text-sm text-neutral-600">Define the aesthetic and additional elements.</p>
                </div>
              </div>

              <!-- Visual Style -->
              <div class="mb-6">
                <label class="block text-sm font-semibold text-neutral-900 mb-3">VISUAL STYLE</label>
                <div class="grid grid-cols-2 md:grid-cols-3 gap-3">
                  <button
                    v-for="style in visualStyleOptions"
                    :key="style.value"
                    @click="visualStyle = style.value"
                    type="button"
                    :class="[
                      'p-4 rounded-lg border-2 text-left transition-all',
                      visualStyle === style.value
                        ? 'border-primary-600 bg-primary-50'
                        : 'border-neutral-200 hover:border-neutral-300'
                    ]"
                  >
                    <div class="font-bold text-neutral-900 text-sm mb-1">{{ style.label }}</div>
                    <div class="text-xs text-neutral-600">{{ style.description }}</div>
                  </button>
                </div>
              </div>

              <!-- Mood/Tone -->
              <div class="mb-6">
                <label class="block text-sm font-semibold text-neutral-900 mb-3">MOOD / TONE</label>
                <div class="flex flex-wrap gap-2">
                  <button
                    v-for="mood in moodToneOptions"
                    :key="mood.value"
                    @click="moodTone = mood.value"
                    type="button"
                    :class="[
                      'px-4 py-2 rounded-lg border-2 transition-all flex items-center gap-2',
                      moodTone === mood.value
                        ? 'border-primary-600 bg-primary-50 text-primary-700'
                        : 'border-neutral-200 hover:border-neutral-300'
                    ]"
                  >
                    <span>{{ mood.emoji }}</span>
                    <span class="font-medium">{{ mood.label }}</span>
                  </button>
                </div>
              </div>

              <!-- Floor Type (for Interior/Commercial) -->
              <div v-if="category === 'interior' || category === 'commercial'" class="mb-6">
                <label class="block text-sm font-semibold text-neutral-900 mb-3">FLOOR TYPE</label>
                <div class="flex flex-wrap gap-2">
                  <button
                    v-for="floor in floorTypeOptions"
                    :key="floor.value"
                    @click="floorType = floor.value"
                    type="button"
                    :class="[
                      'px-4 py-2 rounded-lg border-2 transition-all flex items-center gap-2',
                      floorType === floor.value
                        ? 'border-primary-600 bg-primary-50 text-primary-700'
                        : 'border-neutral-200 hover:border-neutral-300'
                    ]"
                  >
                    <span>{{ floor.emoji }}</span>
                    <span class="font-medium">{{ floor.label }}</span>
                  </button>
                </div>
              </div>

              <!-- Additional Options -->
              <div class="space-y-3">
                <label v-if="category === 'interior' || category === 'commercial'" class="flex items-center gap-3 cursor-pointer">
                  <input
                    v-model="includeWindows"
                    type="checkbox"
                    class="w-5 h-5 text-primary-600 rounded border-neutral-300 focus:ring-primary-500"
                  />
                  <div>
                    <div class="text-sm font-semibold text-neutral-900">Include Windows</div>
                    <div class="text-xs text-neutral-600">Add window elements to the environment</div>
                  </div>
                </label>

                <label class="flex items-center gap-3 cursor-pointer">
                  <input
                    v-model="includeProps"
                    type="checkbox"
                    class="w-5 h-5 text-primary-600 rounded border-neutral-300 focus:ring-primary-500"
                  />
                  <div>
                    <div class="text-sm font-semibold text-neutral-900">Include Props & Decorations</div>
                    <div class="text-xs text-neutral-600">Add furniture, plants, and decorative elements</div>
                  </div>
                </label>
              </div>
            </div>
          </div>

          <!-- Right Column - Preview & Summary -->
          <div class="space-y-6">
            <!-- Preview -->
            <div class="card">
              <h3 class="text-sm font-bold text-neutral-900 uppercase mb-4">Preview</h3>
              <div class="relative rounded-lg overflow-hidden bg-neutral-100" style="aspect-ratio: 4/3;">
                <img
                  v-if="imagePreviewUrl"
                  :src="imagePreviewUrl"
                  alt="Environment preview"
                  class="w-full h-full object-cover"
                />
                <div v-else class="w-full h-full flex items-center justify-center">
                  <div class="text-center text-neutral-400">
                    <svg class="w-12 h-12 mx-auto mb-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 16l4.586-4.586a2 2 0 012.828 0L16 16m-2-2l1.586-1.586a2 2 0 012.828 0L20 14m-6-6h.01M6 20h12a2 2 0 002-2V6a2 2 0 00-2-2H6a2 2 0 00-2 2v12a2 2 0 002 2z" />
                    </svg>
                    <p class="text-sm">No preview image</p>
                  </div>
                </div>
              </div>
            </div>

            <!-- Environment Summary -->
            <div class="card bg-neutral-900 text-white">
              <div class="flex items-center gap-2 mb-4">
                <svg class="w-5 h-5 text-primary-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2" />
                </svg>
                <h3 class="text-sm font-bold uppercase">Environment Summary</h3>
              </div>

              <div class="space-y-3">
                <div class="flex items-center justify-between py-2 border-b border-neutral-800">
                  <span class="text-sm text-neutral-400">Category</span>
                  <span class="font-bold capitalize">{{ category }}</span>
                </div>
                <div class="flex items-center justify-between py-2 border-b border-neutral-800">
                  <span class="text-sm text-neutral-400">Lighting</span>
                  <span class="font-bold capitalize">{{ lightingType }}</span>
                </div>
                <div v-if="visualStyle" class="flex items-center justify-between py-2 border-b border-neutral-800">
                  <span class="text-sm text-neutral-400">Style</span>
                  <span class="font-bold capitalize">{{ visualStyle }}</span>
                </div>
                <div v-if="moodTone" class="flex items-center justify-between py-2 border-b border-neutral-800">
                  <span class="text-sm text-neutral-400">Mood</span>
                  <span class="font-bold capitalize">{{ moodTone }}</span>
                </div>
                <div class="flex items-center justify-between py-2 border-b border-neutral-800">
                  <span class="text-sm text-neutral-400">Ambient</span>
                  <span class="font-bold">{{ ambientIntensity }}%</span>
                </div>
                <div v-if="category === 'interior' || category === 'commercial'" class="flex items-center justify-between py-2 border-b border-neutral-800">
                  <span class="text-sm text-neutral-400">Room Size</span>
                  <span class="font-bold capitalize">{{ roomSize }}</span>
                </div>
                <div v-if="includeWindows && (category === 'interior' || category === 'commercial')" class="flex items-center justify-between py-2 border-b border-neutral-800">
                  <span class="text-sm text-neutral-400">Windows</span>
                  <span class="font-bold text-success-400">Included</span>
                </div>
                <div v-if="includeProps" class="flex items-center justify-between py-2 border-b border-neutral-800">
                  <span class="text-sm text-neutral-400">Props</span>
                  <span class="font-bold text-success-400">Included</span>
                </div>
              </div>

              <button
                @click="handleCreateAndActivate"
                :disabled="isLoading || !environmentName"
                class="btn-primary w-full mt-6 bg-primary-600 hover:bg-primary-700 disabled:bg-neutral-700 disabled:text-neutral-500"
              >
                CREATE ENVIRONMENT
              </button>

              <p class="text-xs text-neutral-500 text-center mt-3">
                Ready to use in your projects
              </p>
            </div>
          </div>
        </div>
      </div>
    </main>
  </div>
</template>

<style scoped>
/* Custom slider styling */
input[type="range"]::-webkit-slider-thumb {
  appearance: none;
  width: 20px;
  height: 20px;
  border-radius: 50%;
  background: #1313EC;
  cursor: pointer;
  box-shadow: 0 2px 4px rgba(0, 0, 0, 0.2);
}

input[type="range"]::-moz-range-thumb {
  width: 20px;
  height: 20px;
  border-radius: 50%;
  background: #1313EC;
  cursor: pointer;
  box-shadow: 0 2px 4px rgba(0, 0, 0, 0.2);
  border: none;
}
</style>
