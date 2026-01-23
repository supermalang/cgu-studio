<script setup>
import { ref, watch } from 'vue'

const props = defineProps({
  settings: {
    type: Object,
    default: null
  }
})

const emit = defineEmits(['update'])

const formData = ref({
  company_name: '',
  description: '',
  support_email: '',
  contact_phone: '',
  contact_email: '',
  logo_url: ''
})

const errors = ref({
  company_name: '',
  support_email: '',
  contact_email: '',
  logo_url: ''
})

// Watch settings and populate form
watch(() => props.settings, (newSettings) => {
  if (newSettings?.company_settings) {
    formData.value = { ...newSettings.company_settings }
  }
}, { immediate: true, deep: true })

function validateEmail(email) {
  if (!email) return true
  const regex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/
  return regex.test(email)
}

function validateUrl(url) {
  if (!url) return true
  try {
    new URL(url)
    return true
  } catch {
    return false
  }
}

function validateField(field) {
  errors.value[field] = ''

  if (field === 'company_name') {
    if (!formData.value.company_name.trim()) {
      errors.value.company_name = 'Company name is required'
    } else if (formData.value.company_name.length > 100) {
      errors.value.company_name = 'Company name must be less than 100 characters'
    }
  }

  if (field === 'support_email') {
    if (!formData.value.support_email.trim()) {
      errors.value.support_email = 'Support email is required'
    } else if (!validateEmail(formData.value.support_email)) {
      errors.value.support_email = 'Invalid email format'
    }
  }

  if (field === 'contact_email') {
    if (formData.value.contact_email && !validateEmail(formData.value.contact_email)) {
      errors.value.contact_email = 'Invalid email format'
    }
  }

  if (field === 'logo_url') {
    if (formData.value.logo_url && !validateUrl(formData.value.logo_url)) {
      errors.value.logo_url = 'Invalid URL format (must include http:// or https://)'
    }
  }
}

function emitUpdate() {
  emit('update', { ...formData.value })
}

defineExpose({
  errors
})
</script>

<template>
  <div class="card">
    <div class="px-6 py-4 border-b border-gray-200">
      <h3 class="text-lg font-semibold text-neutral-900">Company Settings</h3>
      <p class="text-sm text-gray-600 mt-1">Basic information about your organization</p>
    </div>

    <div class="p-6 space-y-4">
      <!-- Company Name -->
      <div>
        <label class="input-label">
          Company Name <span class="text-error-600">*</span>
        </label>
        <input
          v-model="formData.company_name"
          type="text"
          class="input-field"
          :class="{ 'border-error-500': errors.company_name }"
          placeholder="UCG Studio"
          maxlength="100"
          @blur="validateField('company_name'); emitUpdate()"
        >
        <p v-if="errors.company_name" class="input-error">{{ errors.company_name }}</p>
      </div>

      <!-- Description -->
      <div>
        <label class="input-label">
          Description
        </label>
        <textarea
          v-model="formData.description"
          class="input-field"
          rows="3"
          placeholder="AI-powered video production platform"
          @blur="emitUpdate()"
        ></textarea>
        <p class="input-hint">Brief description of your platform</p>
      </div>

      <!-- Support Email -->
      <div>
        <label class="input-label">
          Support Email <span class="text-error-600">*</span>
        </label>
        <input
          v-model="formData.support_email"
          type="email"
          class="input-field"
          :class="{ 'border-error-500': errors.support_email }"
          placeholder="support@ucgstudio.com"
          @blur="validateField('support_email'); emitUpdate()"
        >
        <p v-if="errors.support_email" class="input-error">{{ errors.support_email }}</p>
        <p v-else class="input-hint">Email for user support requests</p>
      </div>

      <!-- Contact Phone -->
      <div>
        <label class="input-label">
          Contact Phone
        </label>
        <input
          v-model="formData.contact_phone"
          type="tel"
          class="input-field"
          placeholder="+1 (555) 123-4567"
          @blur="emitUpdate()"
        >
        <p class="input-hint">Optional: Business phone number</p>
      </div>

      <!-- Contact Email -->
      <div>
        <label class="input-label">
          Contact Email
        </label>
        <input
          v-model="formData.contact_email"
          type="email"
          class="input-field"
          :class="{ 'border-error-500': errors.contact_email }"
          placeholder="contact@ucgstudio.com"
          @blur="validateField('contact_email'); emitUpdate()"
        >
        <p v-if="errors.contact_email" class="input-error">{{ errors.contact_email }}</p>
        <p v-else class="input-hint">Optional: General contact email</p>
      </div>

      <!-- Logo URL -->
      <div>
        <label class="input-label">
          Logo URL
        </label>
        <input
          v-model="formData.logo_url"
          type="url"
          class="input-field"
          :class="{ 'border-error-500': errors.logo_url }"
          placeholder="https://example.com/logo.png"
          @blur="validateField('logo_url'); emitUpdate()"
        >
        <p v-if="errors.logo_url" class="input-error">{{ errors.logo_url }}</p>
        <p v-else class="input-hint">Optional: URL to your company logo</p>
      </div>
    </div>
  </div>
</template>
