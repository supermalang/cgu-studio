<script setup>
import { ref, computed, watch } from 'vue'
import { useProfileSettings } from '@/composables/useProfileSettings'
import { useToast } from '@/composables/useToast'

const { profile, isLoading, updateProfile } = useProfileSettings()
const { showToast } = useToast()

const apiKey = ref('')
const showKey = ref(false)
const hasExistingKey = computed(() => !!profile.value?.elevenlabs_api_key)

// Watch profile to check if key exists (but don't show the actual key for security)
watch(profile, (newProfile) => {
  if (newProfile && newProfile.elevenlabs_api_key) {
    // Don't populate the actual key, just show placeholder
    apiKey.value = ''
  }
}, { immediate: true })

function toggleShowKey() {
  showKey.value = !showKey.value
}

async function handleSave() {
  if (!apiKey.value.trim()) {
    showToast('Please enter an API key', 'error')
    return
  }

  const { error } = await updateProfile({
    elevenlabs_api_key: apiKey.value.trim()
  })

  if (error) {
    showToast(`Failed to update API key: ${error}`, 'error')
  } else {
    showToast('API key updated successfully', 'success')
    apiKey.value = ''
    showKey.value = false
  }
}

async function handleRemove() {
  if (!confirm('Are you sure you want to remove your ElevenLabs API key?')) {
    return
  }

  const { error } = await updateProfile({
    elevenlabs_api_key: null
  })

  if (error) {
    showToast(`Failed to remove API key: ${error}`, 'error')
  } else {
    showToast('API key removed successfully', 'success')
    apiKey.value = ''
  }
}
</script>

<template>
  <div class="card">
    <div class="px-6 py-4 border-b border-gray-200">
      <h3 class="text-lg font-semibold text-neutral-900">API Keys</h3>
      <p class="text-sm text-gray-600 mt-1">Manage your third-party API integrations</p>
    </div>

    <div class="p-6 space-y-4">
      <!-- ElevenLabs API Key -->
      <div>
        <label class="input-label">
          ElevenLabs API Key
        </label>

        <div v-if="hasExistingKey && !apiKey" class="space-y-3">
          <div class="flex items-center gap-2 p-3 bg-success-50 border border-success-200 rounded-lg">
            <svg class="w-5 h-5 text-success-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7" />
            </svg>
            <span class="text-sm font-medium text-success-900">API key is configured</span>
          </div>
          <div class="flex gap-2">
            <button
              @click="apiKey = 'update'"
              class="btn-secondary btn-sm"
            >
              Update Key
            </button>
            <button
              @click="handleRemove"
              :disabled="isLoading"
              class="btn-danger btn-sm"
            >
              Remove Key
            </button>
          </div>
        </div>

        <div v-else class="space-y-3">
          <div class="relative">
            <input
              v-model="apiKey"
              :type="showKey ? 'text' : 'password'"
              class="input-field pr-20"
              placeholder="sk_..."
            >
            <button
              @click="toggleShowKey"
              type="button"
              class="absolute right-2 top-1/2 -translate-y-1/2 text-sm text-primary-600 hover:text-primary-700 font-medium"
            >
              {{ showKey ? 'Hide' : 'Show' }}
            </button>
          </div>
          <p class="input-hint">
            Your ElevenLabs API key is used for text-to-speech generation. Get your key from
            <a href="https://elevenlabs.io" target="_blank" rel="noopener" class="text-primary-600 hover:underline">
              elevenlabs.io
            </a>
          </p>
          <div class="flex gap-2">
            <button
              @click="handleSave"
              :disabled="isLoading || !apiKey.trim()"
              class="btn-primary btn-sm"
            >
              <span v-if="isLoading" class="spinner mr-2"></span>
              {{ isLoading ? 'Saving...' : 'Save API Key' }}
            </button>
            <button
              v-if="apiKey"
              @click="apiKey = ''; showKey = false"
              class="btn-ghost btn-sm"
            >
              Cancel
            </button>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>
