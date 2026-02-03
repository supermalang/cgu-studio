<script setup>
import { ref, watch, computed } from 'vue'
import { useN8nIntegration } from '@/composables/useN8nIntegration'
import { useToast } from '@/composables/useToast'

const props = defineProps({
  settings: {
    type: Object,
    default: null
  }
})

const emit = defineEmits(['update'])

const formData = ref({
  enabled: false,
  host_url: '',
  api_token: '',
  callback_endpoint: '',
  endpoints: {
    avatars: {
      url: '',
      status: 'untested',
      last_test_at: null,
      last_test_result: {
        success: false,
        response_time_ms: null,
        error: null
      }
    },
    environments: {
      url: '',
      status: 'untested',
      last_test_at: null,
      last_test_result: {
        success: false,
        response_time_ms: null,
        error: null
      }
    },
    projects: {
      url: '',
      status: 'untested',
      last_test_at: null,
      last_test_result: {
        success: false,
        response_time_ms: null,
        error: null
      }
    }
  }
})

const showToken = ref(false)
const errors = ref({
  host_url: '',
  api_token: '',
  callback_endpoint: '',
  avatars_url: '',
  environments_url: '',
  projects_url: ''
})

const { isTesting, testResults, testEndpoint, testAllEndpoints, validateUrl } = useN8nIntegration()
const { showToast } = useToast()

// Watch settings and populate form
watch(() => props.settings, (newSettings) => {
  if (newSettings?.platform_settings?.n8n_integration) {
    formData.value = { ...newSettings.platform_settings.n8n_integration }
  }
}, { immediate: true, deep: true })

function validateField(field) {
  errors.value[field] = ''

  if (field === 'host_url') {
    if (formData.value.enabled && !formData.value.host_url.trim()) {
      errors.value.host_url = 'Host URL is required when enabled'
    } else if (formData.value.host_url && !validateUrl(formData.value.host_url)) {
      errors.value.host_url = 'Must be a valid URL (http:// or https://)'
    }
  }

  if (field === 'api_token') {
    if (formData.value.enabled && !formData.value.api_token.trim()) {
      errors.value.api_token = 'API token is required when enabled'
    }
  }

  if (field === 'callback_endpoint' && formData.value.callback_endpoint) {
    if (!validateUrl(formData.value.callback_endpoint)) {
      errors.value.callback_endpoint = 'Must be a valid URL (http:// or https://)'
    }
  }

  if (field === 'avatars_url' && formData.value.endpoints.avatars.url) {
    if (!validateUrl(formData.value.endpoints.avatars.url)) {
      errors.value.avatars_url = 'Must be a valid URL'
    }
  }

  if (field === 'environments_url' && formData.value.endpoints.environments.url) {
    if (!validateUrl(formData.value.endpoints.environments.url)) {
      errors.value.environments_url = 'Must be a valid URL'
    }
  }

  if (field === 'projects_url' && formData.value.endpoints.projects.url) {
    if (!validateUrl(formData.value.endpoints.projects.url)) {
      errors.value.projects_url = 'Must be a valid URL'
    }
  }
}

function emitUpdate() {
  emit('update', { ...formData.value })
}

async function handleTestEndpoint(endpointName) {
  const endpoint = formData.value.endpoints[endpointName]
  if (!endpoint.url) {
    showToast(`Please enter ${endpointName} endpoint URL first`, 'error')
    return
  }

  if (!formData.value.api_token) {
    showToast('Please enter API token first', 'error')
    return
  }

  const result = await testEndpoint(endpointName, endpoint.url, formData.value.api_token)

  // Update form data with test results
  formData.value.endpoints[endpointName].status = result.status
  formData.value.endpoints[endpointName].last_test_at = result.tested_at
  formData.value.endpoints[endpointName].last_test_result = {
    success: result.success,
    response_time_ms: result.response_time_ms,
    error: result.error
  }

  // Show result
  if (result.success) {
    showToast(`${capitalize(endpointName)}: Connected successfully (${result.response_time_ms}ms)`, 'success')
  } else {
    showToast(`${capitalize(endpointName)}: ${result.error}`, 'error')
  }

  emitUpdate()
}

async function handleTestAll() {
  if (!formData.value.host_url || !formData.value.api_token) {
    showToast('Please enter host URL and API token first', 'error')
    return
  }

  const results = await testAllEndpoints(formData.value.endpoints, formData.value.api_token)

  // Update all endpoints with results
  results.forEach((result, index) => {
    const endpointName = ['avatars', 'environments', 'projects'][index]
    if (result.status === 'fulfilled' && result.value) {
      const testResult = result.value
      formData.value.endpoints[endpointName].status = testResult.status
      formData.value.endpoints[endpointName].last_test_at = testResult.tested_at
      formData.value.endpoints[endpointName].last_test_result = {
        success: testResult.success,
        response_time_ms: testResult.response_time_ms,
        error: testResult.error
      }
    }
  })

  // Show summary
  const successCount = results.filter(r => r.status === 'fulfilled' && r.value?.success).length
  const failCount = results.length - successCount

  if (successCount === results.length) {
    showToast('All endpoints connected successfully', 'success')
  } else if (successCount > 0) {
    showToast(`${successCount} connected, ${failCount} failed`, 'warning')
  } else {
    showToast('All endpoints failed to connect', 'error')
  }

  emitUpdate()
}

function getStatusClass(status) {
  switch (status) {
    case 'connected':
      return 'bg-success-100 text-success-700'
    case 'failed':
      return 'bg-error-100 text-error-700'
    default:
      return 'bg-gray-100 text-gray-600'
  }
}

function getStatusIcon(status) {
  switch (status) {
    case 'connected':
      return '●'
    case 'failed':
      return '✗'
    default:
      return '○'
  }
}

function capitalize(str) {
  return str.charAt(0).toUpperCase() + str.slice(1)
}

function formatTimestamp(timestamp) {
  if (!timestamp) return null
  const date = new Date(timestamp)
  const now = new Date()
  const diff = Math.floor((now - date) / 1000) // seconds

  if (diff < 60) return 'Just now'
  if (diff < 3600) return `${Math.floor(diff / 60)}m ago`
  if (diff < 86400) return `${Math.floor(diff / 3600)}h ago`
  return date.toLocaleDateString()
}

const canTestAll = computed(() => {
  return formData.value.enabled &&
         formData.value.host_url &&
         formData.value.api_token &&
         (formData.value.endpoints.avatars.url ||
          formData.value.endpoints.environments.url ||
          formData.value.endpoints.projects.url)
})

defineExpose({
  errors
})
</script>

<template>
  <div class="card">
    <div class="px-6 py-4 border-b border-gray-200">
      <h3 class="text-lg font-semibold text-neutral-900">n8n Integration</h3>
      <p class="text-sm text-gray-600 mt-1">Configure n8n webhooks for AI generation workflows</p>
    </div>

    <div class="p-6 space-y-6">
      <!-- Enable Toggle -->
      <div class="flex items-center">
        <input
          v-model="formData.enabled"
          type="checkbox"
          id="n8n-enabled"
          class="w-4 h-4 text-primary-600 border-gray-300 rounded focus:ring-primary-500"
          @change="validateField('host_url'); validateField('api_token'); emitUpdate()"
        >
        <label for="n8n-enabled" class="ml-2 text-sm font-medium text-gray-900">
          Enable n8n Integration
        </label>
      </div>

      <!-- Host URL -->
      <div>
        <label class="input-label">
          n8n Host URL <span v-if="formData.enabled" class="text-error-600">*</span>
        </label>
        <input
          v-model="formData.host_url"
          type="url"
          class="input-field"
          :class="{ 'border-error-500': errors.host_url }"
          :disabled="!formData.enabled"
          placeholder="https://n8n.example.com"
          @blur="validateField('host_url'); emitUpdate()"
        >
        <p v-if="errors.host_url" class="input-error">{{ errors.host_url }}</p>
        <p v-else class="input-hint">Base URL for all n8n webhooks</p>
      </div>

      <!-- API Token -->
      <div>
        <label class="input-label">
          API Token <span v-if="formData.enabled" class="text-error-600">*</span>
        </label>
        <div class="relative">
          <input
            v-model="formData.api_token"
            :type="showToken ? 'text' : 'password'"
            class="input-field pr-20"
            :class="{ 'border-error-500': errors.api_token }"
            :disabled="!formData.enabled"
            placeholder="n8n_api_..."
            @blur="validateField('api_token'); emitUpdate()"
          >
          <button
            @click="showToken = !showToken"
            type="button"
            class="absolute right-2 top-1/2 -translate-y-1/2 px-3 py-1 text-sm text-primary-600 hover:text-primary-700 font-medium"
            :disabled="!formData.enabled"
          >
            {{ showToken ? 'Hide' : 'Show' }}
          </button>
        </div>
        <p v-if="errors.api_token" class="input-error">{{ errors.api_token }}</p>
        <p v-else class="input-hint">Authentication token for n8n API</p>
      </div>

      <!-- Callback Endpoint -->
      <div class="pb-6 border-b border-gray-200">
        <label class="input-label">Callback Endpoint URL</label>
        <input
          v-model="formData.callback_endpoint"
          type="url"
          class="input-field"
          :class="{ 'border-error-500': errors.callback_endpoint }"
          :disabled="!formData.enabled"
          placeholder="https://your-domain.com/api/callback"
          @blur="validateField('callback_endpoint'); emitUpdate()"
        >
        <p v-if="errors.callback_endpoint" class="input-error">{{ errors.callback_endpoint }}</p>
        <p v-else class="input-hint">HTTP(S) endpoint to receive callbacks for video generation completion events</p>
      </div>

      <!-- Webhook Endpoints Section -->
      <div class="pb-6 border-b border-gray-200">
        <h4 class="text-sm font-semibold text-neutral-900 mb-4">Webhook Endpoints</h4>

        <!-- Avatars Endpoint -->
        <div class="space-y-3 mb-4">
          <div class="flex items-center justify-between">
            <label class="input-label">Avatars Endpoint</label>
            <div class="flex items-center gap-2">
              <div
                class="inline-flex items-center gap-2 px-3 py-1 rounded-lg text-xs font-medium"
                :class="getStatusClass(formData.endpoints.avatars.status)"
              >
                <span>{{ getStatusIcon(formData.endpoints.avatars.status) }}</span>
                <span>{{ capitalize(formData.endpoints.avatars.status) }}</span>
                <span v-if="formData.endpoints.avatars.last_test_result.response_time_ms">
                  ({{ formData.endpoints.avatars.last_test_result.response_time_ms }}ms)
                </span>
              </div>
              <button
                @click="handleTestEndpoint('avatars')"
                :disabled="isTesting.avatars || !formData.enabled"
                class="btn-secondary btn-sm"
              >
                <span v-if="isTesting.avatars" class="spinner mr-1"></span>
                {{ isTesting.avatars ? 'Testing...' : 'Test' }}
              </button>
            </div>
          </div>
          <input
            v-model="formData.endpoints.avatars.url"
            type="url"
            class="input-field"
            :class="{ 'border-error-500': errors.avatars_url }"
            :disabled="!formData.enabled"
            placeholder="/webhook/avatars"
            @blur="validateField('avatars_url'); emitUpdate()"
          >
          <p v-if="errors.avatars_url" class="input-error">{{ errors.avatars_url }}</p>
          <p v-else-if="formData.endpoints.avatars.last_test_at" class="text-xs text-gray-500">
            Last tested: {{ formatTimestamp(formData.endpoints.avatars.last_test_at) }}
          </p>
          <p v-if="formData.endpoints.avatars.last_test_result.error" class="text-xs text-error-600">
            {{ formData.endpoints.avatars.last_test_result.error }}
          </p>
        </div>

        <!-- Environments Endpoint -->
        <div class="space-y-3 mb-4">
          <div class="flex items-center justify-between">
            <label class="input-label">Environments Endpoint</label>
            <div class="flex items-center gap-2">
              <div
                class="inline-flex items-center gap-2 px-3 py-1 rounded-lg text-xs font-medium"
                :class="getStatusClass(formData.endpoints.environments.status)"
              >
                <span>{{ getStatusIcon(formData.endpoints.environments.status) }}</span>
                <span>{{ capitalize(formData.endpoints.environments.status) }}</span>
                <span v-if="formData.endpoints.environments.last_test_result.response_time_ms">
                  ({{ formData.endpoints.environments.last_test_result.response_time_ms }}ms)
                </span>
              </div>
              <button
                @click="handleTestEndpoint('environments')"
                :disabled="isTesting.environments || !formData.enabled"
                class="btn-secondary btn-sm"
              >
                <span v-if="isTesting.environments" class="spinner mr-1"></span>
                {{ isTesting.environments ? 'Testing...' : 'Test' }}
              </button>
            </div>
          </div>
          <input
            v-model="formData.endpoints.environments.url"
            type="url"
            class="input-field"
            :class="{ 'border-error-500': errors.environments_url }"
            :disabled="!formData.enabled"
            placeholder="/webhook/environments"
            @blur="validateField('environments_url'); emitUpdate()"
          >
          <p v-if="errors.environments_url" class="input-error">{{ errors.environments_url }}</p>
          <p v-else-if="formData.endpoints.environments.last_test_at" class="text-xs text-gray-500">
            Last tested: {{ formatTimestamp(formData.endpoints.environments.last_test_at) }}
          </p>
          <p v-if="formData.endpoints.environments.last_test_result.error" class="text-xs text-error-600">
            {{ formData.endpoints.environments.last_test_result.error }}
          </p>
        </div>

        <!-- Projects Endpoint -->
        <div class="space-y-3 mb-4">
          <div class="flex items-center justify-between">
            <label class="input-label">Projects Endpoint</label>
            <div class="flex items-center gap-2">
              <div
                class="inline-flex items-center gap-2 px-3 py-1 rounded-lg text-xs font-medium"
                :class="getStatusClass(formData.endpoints.projects.status)"
              >
                <span>{{ getStatusIcon(formData.endpoints.projects.status) }}</span>
                <span>{{ capitalize(formData.endpoints.projects.status) }}</span>
                <span v-if="formData.endpoints.projects.last_test_result.response_time_ms">
                  ({{ formData.endpoints.projects.last_test_result.response_time_ms }}ms)
                </span>
              </div>
              <button
                @click="handleTestEndpoint('projects')"
                :disabled="isTesting.projects || !formData.enabled"
                class="btn-secondary btn-sm"
              >
                <span v-if="isTesting.projects" class="spinner mr-1"></span>
                {{ isTesting.projects ? 'Testing...' : 'Test' }}
              </button>
            </div>
          </div>
          <input
            v-model="formData.endpoints.projects.url"
            type="url"
            class="input-field"
            :class="{ 'border-error-500': errors.projects_url }"
            :disabled="!formData.enabled"
            placeholder="/webhook/projects"
            @blur="validateField('projects_url'); emitUpdate()"
          >
          <p v-if="errors.projects_url" class="input-error">{{ errors.projects_url }}</p>
          <p v-else-if="formData.endpoints.projects.last_test_at" class="text-xs text-gray-500">
            Last tested: {{ formatTimestamp(formData.endpoints.projects.last_test_at) }}
          </p>
          <p v-if="formData.endpoints.projects.last_test_result.error" class="text-xs text-error-600">
            {{ formData.endpoints.projects.last_test_result.error }}
          </p>
        </div>
      </div>

      <!-- Test All Button -->
      <div>
        <button
          @click="handleTestAll"
          :disabled="isTesting.all || !canTestAll"
          class="btn-primary"
        >
          <span v-if="isTesting.all" class="spinner mr-2"></span>
          {{ isTesting.all ? 'Testing All Endpoints...' : 'Test All Endpoints' }}
        </button>
        <p v-if="!formData.enabled" class="text-sm text-gray-500 mt-2">
          Enable n8n integration to test endpoints
        </p>
      </div>
    </div>
  </div>
</template>
