<script setup>
import { ref, watch } from 'vue'
import { useProfileSettings } from '@/composables/useProfileSettings'
import { useToast } from '@/composables/useToast'

const { profile, isLoading, error, validateName, validateUrl, updateProfile } = useProfileSettings()
const { showToast } = useToast()

const formData = ref({
  full_name: '',
  avatar_url: ''
})

const errors = ref({
  full_name: '',
  avatar_url: ''
})

// Watch profile and populate form when loaded
watch(profile, (newProfile) => {
  if (newProfile) {
    formData.value.full_name = newProfile.full_name || ''
    formData.value.avatar_url = newProfile.avatar_url || ''
  }
}, { immediate: true })

function validateField(field) {
  errors.value[field] = ''

  if (field === 'full_name') {
    if (!validateName(formData.value.full_name)) {
      errors.value.full_name = 'Name must be between 1 and 100 characters'
    }
  }

  if (field === 'avatar_url') {
    if (formData.value.avatar_url && !validateUrl(formData.value.avatar_url)) {
      errors.value.avatar_url = 'Invalid URL format (must include http:// or https://)'
    }
  }
}

async function handleSave() {
  // Validate all fields
  validateField('full_name')
  validateField('avatar_url')

  if (errors.value.full_name || errors.value.avatar_url) {
    showToast('Please fix validation errors', 'error')
    return
  }

  const { error: saveError } = await updateProfile({
    full_name: formData.value.full_name,
    avatar_url: formData.value.avatar_url || null
  })

  if (saveError) {
    showToast(`Failed to update profile: ${saveError}`, 'error')
  } else {
    showToast('Profile updated successfully', 'success')
  }
}
</script>

<template>
  <div class="card">
    <div class="px-6 py-4 border-b border-gray-200">
      <h3 class="text-lg font-semibold text-neutral-900">Profile Information</h3>
      <p class="text-sm text-gray-600 mt-1">Update your personal information</p>
    </div>

    <div class="p-6 space-y-4">
      <!-- Full Name -->
      <div>
        <label class="input-label">
          Full Name <span class="text-error-600">*</span>
        </label>
        <input
          v-model="formData.full_name"
          type="text"
          class="input-field"
          :class="{ 'border-error-500': errors.full_name }"
          placeholder="John Doe"
          maxlength="100"
          @blur="validateField('full_name')"
        >
        <p v-if="errors.full_name" class="input-error">{{ errors.full_name }}</p>
      </div>

      <!-- Avatar URL -->
      <div>
        <label class="input-label">
          Avatar URL
        </label>
        <input
          v-model="formData.avatar_url"
          type="url"
          class="input-field"
          :class="{ 'border-error-500': errors.avatar_url }"
          placeholder="https://example.com/avatar.jpg"
          @blur="validateField('avatar_url')"
        >
        <p v-if="errors.avatar_url" class="input-error">{{ errors.avatar_url }}</p>
        <p v-else class="input-hint">Optional: URL to your profile picture</p>
      </div>

      <!-- Save Button -->
      <div class="pt-2">
        <button
          @click="handleSave"
          :disabled="isLoading || !!errors.full_name || !!errors.avatar_url"
          class="btn-primary"
        >
          <span v-if="isLoading" class="spinner mr-2"></span>
          {{ isLoading ? 'Saving...' : 'Save Changes' }}
        </button>
      </div>

      <!-- Error Message -->
      <div v-if="error" class="alert-error">
        {{ error }}
      </div>
    </div>
  </div>
</template>
