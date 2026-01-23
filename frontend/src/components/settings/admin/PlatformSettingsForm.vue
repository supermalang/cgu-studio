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
  // AI Model
  ai_model_provider: 'openai',
  ai_model_name: 'gpt-4-turbo-preview',

  // Credit Costs
  credit_cost_breakdown: 10,
  credit_cost_audio_per_shot: 2,
  credit_cost_video_per_shot: 50,

  // Storage & Limits
  max_audio_upload_size_mb: 2,
  max_storage_per_user_gb: 1,
  low_credit_threshold: 100,

  // Rate Limiting
  rate_limit_enabled: false,
  rate_limit_generations_per_hour: 100,

  // Generation Settings
  generation_timeout_seconds: 180,
  retry_enabled: true,
  max_retries: 3
})

const errors = ref({})

// Watch settings and populate form
watch(() => props.settings, (newSettings) => {
  if (newSettings?.platform_settings) {
    formData.value = { ...newSettings.platform_settings }
  }
}, { immediate: true, deep: true })

function validateField(field, min = 0) {
  errors.value[field] = ''
  const value = formData.value[field]

  if (value < min) {
    errors.value[field] = `Value must be at least ${min}`
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
      <h3 class="text-lg font-semibold text-neutral-900">Platform Settings</h3>
      <p class="text-sm text-gray-600 mt-1">Configure platform-wide behavior and limits</p>
    </div>

    <div class="p-6 space-y-6">
      <!-- AI Model Section -->
      <div class="pb-6 border-b border-gray-200">
        <h4 class="text-sm font-semibold text-neutral-900 mb-4">AI Model Configuration</h4>
        <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
          <div>
            <label class="input-label">Provider</label>
            <select v-model="formData.ai_model_provider" class="input-field" @change="emitUpdate()">
              <option value="openai">OpenAI</option>
              <option value="anthropic">Anthropic</option>
            </select>
          </div>
          <div>
            <label class="input-label">Model Name</label>
            <input
              v-model="formData.ai_model_name"
              type="text"
              class="input-field"
              placeholder="gpt-4-turbo-preview"
              @blur="emitUpdate()"
            >
          </div>
        </div>
      </div>

      <!-- Credit Costs Section -->
      <div class="pb-6 border-b border-gray-200">
        <h4 class="text-sm font-semibold text-neutral-900 mb-4">Credit Costs</h4>
        <div class="grid grid-cols-1 md:grid-cols-3 gap-4">
          <div>
            <label class="input-label">Breakdown</label>
            <div class="relative">
              <input
                v-model.number="formData.credit_cost_breakdown"
                type="number"
                min="0"
                class="input-field"
                :class="{ 'border-error-500': errors.credit_cost_breakdown }"
                @blur="validateField('credit_cost_breakdown', 0); emitUpdate()"
              >
              <span class="absolute right-3 top-1/2 -translate-y-1/2 text-sm text-gray-500">credits</span>
            </div>
            <p v-if="errors.credit_cost_breakdown" class="input-error">{{ errors.credit_cost_breakdown }}</p>
            <p v-else class="input-hint">Per script breakdown</p>
          </div>
          <div>
            <label class="input-label">Audio / Shot</label>
            <div class="relative">
              <input
                v-model.number="formData.credit_cost_audio_per_shot"
                type="number"
                min="0"
                class="input-field"
                :class="{ 'border-error-500': errors.credit_cost_audio_per_shot }"
                @blur="validateField('credit_cost_audio_per_shot', 0); emitUpdate()"
              >
              <span class="absolute right-3 top-1/2 -translate-y-1/2 text-sm text-gray-500">credits</span>
            </div>
            <p v-if="errors.credit_cost_audio_per_shot" class="input-error">{{ errors.credit_cost_audio_per_shot }}</p>
            <p v-else class="input-hint">Per audio generation</p>
          </div>
          <div>
            <label class="input-label">Video / Shot</label>
            <div class="relative">
              <input
                v-model.number="formData.credit_cost_video_per_shot"
                type="number"
                min="0"
                class="input-field"
                :class="{ 'border-error-500': errors.credit_cost_video_per_shot }"
                @blur="validateField('credit_cost_video_per_shot', 0); emitUpdate()"
              >
              <span class="absolute right-3 top-1/2 -translate-y-1/2 text-sm text-gray-500">credits</span>
            </div>
            <p v-if="errors.credit_cost_video_per_shot" class="input-error">{{ errors.credit_cost_video_per_shot }}</p>
            <p v-else class="input-hint">Per video generation</p>
          </div>
        </div>
      </div>

      <!-- Storage & Limits Section -->
      <div class="pb-6 border-b border-gray-200">
        <h4 class="text-sm font-semibold text-neutral-900 mb-4">Storage & Limits</h4>
        <div class="grid grid-cols-1 md:grid-cols-3 gap-4">
          <div>
            <label class="input-label">Max Upload Size</label>
            <div class="relative">
              <input
                v-model.number="formData.max_audio_upload_size_mb"
                type="number"
                min="1"
                class="input-field"
                :class="{ 'border-error-500': errors.max_audio_upload_size_mb }"
                @blur="validateField('max_audio_upload_size_mb', 1); emitUpdate()"
              >
              <span class="absolute right-3 top-1/2 -translate-y-1/2 text-sm text-gray-500">MB</span>
            </div>
            <p v-if="errors.max_audio_upload_size_mb" class="input-error">{{ errors.max_audio_upload_size_mb }}</p>
            <p v-else class="input-hint">Audio file size limit</p>
          </div>
          <div>
            <label class="input-label">User Storage Limit</label>
            <div class="relative">
              <input
                v-model.number="formData.max_storage_per_user_gb"
                type="number"
                min="1"
                class="input-field"
                :class="{ 'border-error-500': errors.max_storage_per_user_gb }"
                @blur="validateField('max_storage_per_user_gb', 1); emitUpdate()"
              >
              <span class="absolute right-3 top-1/2 -translate-y-1/2 text-sm text-gray-500">GB</span>
            </div>
            <p v-if="errors.max_storage_per_user_gb" class="input-error">{{ errors.max_storage_per_user_gb }}</p>
            <p v-else class="input-hint">Per user total storage</p>
          </div>
          <div>
            <label class="input-label">Low Credit Threshold</label>
            <div class="relative">
              <input
                v-model.number="formData.low_credit_threshold"
                type="number"
                min="0"
                class="input-field"
                :class="{ 'border-error-500': errors.low_credit_threshold }"
                @blur="validateField('low_credit_threshold', 0); emitUpdate()"
              >
              <span class="absolute right-3 top-1/2 -translate-y-1/2 text-sm text-gray-500">credits</span>
            </div>
            <p v-if="errors.low_credit_threshold" class="input-error">{{ errors.low_credit_threshold }}</p>
            <p v-else class="input-hint">Warning threshold</p>
          </div>
        </div>
      </div>

      <!-- Rate Limiting Section -->
      <div class="pb-6 border-b border-gray-200">
        <h4 class="text-sm font-semibold text-neutral-900 mb-4">Rate Limiting</h4>
        <div class="space-y-4">
          <div class="flex items-center">
            <input
              v-model="formData.rate_limit_enabled"
              type="checkbox"
              id="rate-limit-enabled"
              class="w-4 h-4 text-primary-600 border-gray-300 rounded focus:ring-primary-500"
              @change="emitUpdate()"
            >
            <label for="rate-limit-enabled" class="ml-2 text-sm font-medium text-gray-900">
              Enable rate limiting
            </label>
          </div>
          <div>
            <label class="input-label">Max Generations / Hour</label>
            <input
              v-model.number="formData.rate_limit_generations_per_hour"
              type="number"
              min="1"
              class="input-field"
              :disabled="!formData.rate_limit_enabled"
              :class="{ 'opacity-50': !formData.rate_limit_enabled, 'border-error-500': errors.rate_limit_generations_per_hour }"
              @blur="validateField('rate_limit_generations_per_hour', 1); emitUpdate()"
            >
            <p v-if="errors.rate_limit_generations_per_hour" class="input-error">{{ errors.rate_limit_generations_per_hour }}</p>
            <p v-else class="input-hint">Maximum requests per user per hour</p>
          </div>
        </div>
      </div>

      <!-- Generation Settings Section -->
      <div>
        <h4 class="text-sm font-semibold text-neutral-900 mb-4">Generation Settings</h4>
        <div class="space-y-4">
          <div>
            <label class="input-label">Timeout</label>
            <div class="relative">
              <input
                v-model.number="formData.generation_timeout_seconds"
                type="number"
                min="30"
                class="input-field"
                :class="{ 'border-error-500': errors.generation_timeout_seconds }"
                @blur="validateField('generation_timeout_seconds', 30); emitUpdate()"
              >
              <span class="absolute right-3 top-1/2 -translate-y-1/2 text-sm text-gray-500">seconds</span>
            </div>
            <p v-if="errors.generation_timeout_seconds" class="input-error">{{ errors.generation_timeout_seconds }}</p>
            <p v-else class="input-hint">Max time to wait for generation</p>
          </div>
          <div class="flex items-center">
            <input
              v-model="formData.retry_enabled"
              type="checkbox"
              id="retry-enabled"
              class="w-4 h-4 text-primary-600 border-gray-300 rounded focus:ring-primary-500"
              @change="emitUpdate()"
            >
            <label for="retry-enabled" class="ml-2 text-sm font-medium text-gray-900">
              Enable automatic retries
            </label>
          </div>
          <div>
            <label class="input-label">Max Retries</label>
            <input
              v-model.number="formData.max_retries"
              type="number"
              min="1"
              max="10"
              class="input-field"
              :disabled="!formData.retry_enabled"
              :class="{ 'opacity-50': !formData.retry_enabled, 'border-error-500': errors.max_retries }"
              @blur="validateField('max_retries', 1); emitUpdate()"
            >
            <p v-if="errors.max_retries" class="input-error">{{ errors.max_retries }}</p>
            <p v-else class="input-hint">Number of retry attempts on failure</p>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>
